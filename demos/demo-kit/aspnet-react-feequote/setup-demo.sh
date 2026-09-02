#!/usr/bin/env bash
# Builds the demo git history for this repository from the files on disk.
#
#   1. feat: add FeeQuote domain, pricing, transfer service and web app   (tag v0.1.0, branch demo-start)
#   2. chore: add repository instructions and AGENTS.md
#   3. feat: add reviewer custom agent
#   4. feat: add release-notes skill
#   5. chore: add MCP server configuration                                (tag v0.2.0)
#   6. refactor: tidy quote form submit handler                           (branch demo-checks, tag demo-checks-base)
#
# demo-checks carries one extra commit whose defect the test suites do not
# catch (an unused import and a console.log in ClientApp/src/App.tsx) but
# eslint and tsc do. To restore it after an experiment:
# git branch -f demo-checks demo-checks-base
#
# The presenter's files (DEMO_SCRIPT.md, prompts.txt, RUN_COMPARISON.md, tier-check/,
# run-stats.py and these scripts) live in demo-kit, outside the repository, so agents
# working in the repository or its worktrees never read the expected answers.
#
# It works on ../../aspnet-react-feequote next to this demo-kit folder
# (~/demos/aspnet-react-feequote), so it can be run from anywhere.
#
# Usage: bash ~/demos/demo-kit/aspnet-react-feequote/setup-demo.sh [--force]
# Refuses to run if .git already exists unless --force is given, in which
# case the existing .git is deleted and the history is rebuilt. --force only
# runs on a clean main checkout at v0.2.0 with no extra worktrees, because the
# history is rebuilt from the files on disk.
#
# Works with the bash 3.2 and BSD tools that ship with macOS as well as on Linux.
set -euo pipefail

kit="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo="$(cd "$kit/../../aspnet-react-feequote" 2>/dev/null && pwd)" || {
  echo "setup-demo.sh: ../../aspnet-react-feequote not found. Keep demo-kit and aspnet-react-feequote side by side under ~/demos." >&2
  exit 1
}
cd "$repo"

force=0
for arg in "$@"; do
  case "$arg" in
    --force) force=1 ;;
    -h | --help)
      sed -n '2,/^set -euo pipefail/p' "$kit/setup-demo.sh" | sed '$d' | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *) echo "usage: bash setup-demo.sh [--force]" >&2; exit 2 ;;
  esac
done

# Files that arrive after the baseline commit. They must all exist before
# anything runs, or the history would be built without them.
customization_files=(
  .github/copilot-instructions.md .github/instructions AGENTS.md
  .github/agents
  .github/skills scripts
  .vscode/mcp.json
)

for path in "${customization_files[@]}"; do
  if [ ! -e "$path" ]; then
    echo "error: $path is missing. Run this from a complete copy of the repository on main." >&2
    exit 1
  fi
done

if [ -d .git ]; then
  if [ "$force" -ne 1 ]; then
    echo "error: .git already exists. Re-run with --force to rebuild the demo history." >&2
    exit 1
  fi
  # The history is rebuilt from the files on disk, so they must be the full main state.
  branch="$(git symbolic-ref --short -q HEAD || true)"
  worktrees="$(git worktree list --porcelain | grep -c '^worktree ' || true)"
  head="$(git rev-parse -q --verify HEAD || true)"
  release="$(git rev-parse -q --verify 'v0.2.0^{commit}' || true)"
  if [ "$branch" != "main" ] || [ -n "$(git status --porcelain)" ] || [ "$worktrees" -gt 1 ] \
    || [ -z "$release" ] || [ "$head" != "$release" ]; then
    echo "error: --force only runs on a clean main checkout at v0.2.0 with no extra worktrees" >&2
    echo "  (current branch: ${branch:-detached}, worktrees: $worktrees)." >&2
    echo "  Close VS Code and every Copilot CLI session first, run the full rehearsal reset" >&2
    echo "  from DEMO_SCRIPT.md, then git checkout -q main and try again." >&2
    echo "  To restore only demo-checks: git branch -f demo-checks demo-checks-base" >&2
    exit 1
  fi
  rm -rf .git
fi

git init -q -b main
git config user.name "FeeQuote Demo"
git config user.email "demo@example.com"
git config commit.gpgsign false
git config tag.gpgsign false
git config core.autocrlf false

commit() {
  git commit -q -m "$1"
  echo "committed: $1"
}

# 1. Baseline: everything except the customization files.
git add -A -- . \
  ':(exclude).github' \
  ':(exclude)AGENTS.md' \
  ':(exclude).vscode' \
  ':(exclude)scripts'
commit "feat: add FeeQuote domain, pricing, transfer service and web app"
git tag v0.1.0
git branch demo-start

# 2. Repository instructions.
git add .github/copilot-instructions.md .github/instructions AGENTS.md
commit "chore: add repository instructions and AGENTS.md"

# 3. Reviewer agent.
git add .github/agents
commit "feat: add reviewer custom agent"

# 4. Release-notes skill and its script. The shell script is committed as
#    executable (mode 100755) even when the copy on disk lost its execute bit
#    (a zip extraction) or the file system has no modes (core.fileMode false).
chmod +x scripts/*.sh
git add .github/skills scripts
git update-index --chmod=+x scripts/*.sh
commit "feat: add release-notes skill"

# 5. MCP configuration.
git add .vscode/mcp.json
commit "chore: add MCP server configuration"
git tag v0.2.0

# 6. Checks demo branch: vitest stays green, eslint (no-unused-vars,
#    no-console) and tsc (TS6133) fail. Tolerates LF or CRLF on disk.
git checkout -q -b demo-checks
app=src/FeeQuote.Web/ClientApp/src/App.tsx
awk '
  { cr = sub(/\r$/, "") ? "\r" : "" }
  $0 == "import { useState } from \"react\";" { print "import { useEffect, useState } from \"react\";" cr; next }
  { print $0 cr }
  $0 == "    const amountCents = parseAmountToCents(form.amount);" { print "    console.log(\"quote request\", amountCents);" cr }
' "$app" > "$app.tmp"
mv "$app.tmp" "$app"
if ! grep -q '^import { useEffect, useState } from "react";' "$app" \
  || ! grep -q '^    console.log("quote request", amountCents);' "$app"; then
  echo "error: could not prepare demo-checks; $app did not match the expected text." >&2
  exit 1
fi
git add "$app"
commit "refactor: tidy quote form submit handler"
git tag demo-checks-base
git checkout -q main

if [ -n "$(git status --porcelain)" ]; then
  echo "warning: some files were left uncommitted:" >&2
  git status --short >&2
fi

echo
git log --oneline --graph --decorate --all
echo
echo "Ready. 'git checkout demo-start' resets to the baseline; 'git checkout main' restores everything;"
echo "'git checkout demo-checks' has the defect for the guardrails demo; 'git branch -f demo-checks demo-checks-base' restores it."
