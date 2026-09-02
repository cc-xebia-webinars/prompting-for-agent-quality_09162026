#!/usr/bin/env bash
# Builds the demo git history for the FeeQuote TypeScript repository from the
# files on disk. It works on ../../typescript-feequote next to this demo-kit folder
# (~/demos/typescript-feequote), so it can be run from anywhere:
#
#   bash .../demo-kit/typescript-feequote/setup-demo.sh          create the history (refuses if .git exists)
#   bash .../demo-kit/typescript-feequote/setup-demo.sh --force  delete an existing .git and rebuild; only from a
#                                                                clean main checkout at v0.2.0 with no extra worktrees
#   bash .../demo-kit/typescript-feequote/setup-demo.sh --help   print this text
#
# Result: five conventional commits on main, tags v0.1.0 and v0.2.0, a
# demo-start branch at the baseline commit (no customization files), and a
# demo-checks branch with one extra commit on top of v0.2.0:
#   refactor: simplify quote argument parsing                      branch demo-checks, tag demo-checks-base
#
# demo-checks carries a defect the test suite does not catch (the CLI no
# longer rejects an unknown --channel, leaving an unused import) but ESLint
# and tsc do. To restore it after an experiment:
#   git branch -f demo-checks demo-checks-base
#
# The presenter's files (DEMO_SCRIPT.md, prompts.txt, RUN_COMPARISON.md, tier-check/,
# run-stats.py and these scripts) live in demo-kit, outside the repository, so agents
# working in the repository or its worktrees never read the expected answers.
#
# Portable to macOS (bash 3.2, BSD tools), Linux and Git Bash on Windows.
set -euo pipefail

force=0
for arg in "$@"; do
  case "$arg" in
    --force) force=1 ;;
    -h | --help)
      sed -n '2,/^set -euo pipefail/p' "${BASH_SOURCE[0]}" | sed '$d' | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "setup-demo.sh: unknown argument '$arg' (try --force or --help)" >&2
      exit 2
      ;;
  esac
done

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../typescript-feequote" 2>/dev/null && pwd)" || {
  echo "setup-demo.sh: ../../typescript-feequote not found. Keep demo-kit and typescript-feequote side by side under ~/demos." >&2
  exit 1
}
cd "$repo"

# Files that arrive after the baseline commit. They must all exist before
# anything runs, or the history would be built from an incomplete copy.
customization_files=(
  .github/copilot-instructions.md
  .github/instructions
  AGENTS.md
  .github/agents
  .github/skills
  scripts
  .vscode/mcp.json
)
# Committed with the executable bit, so checkouts on macOS and Linux can run them directly.
executable_files=(scripts/release-notes.mjs)

for path in "${customization_files[@]}"; do
  if [ ! -e "$path" ]; then
    echo "setup-demo.sh: $path is missing. Run this from a complete copy of the repository on main." >&2
    exit 1
  fi
done

if [ -e .git ]; then
  if [ "$force" != 1 ]; then
    echo "A .git directory already exists. Re-run with --force to rebuild the history." >&2
    exit 1
  fi
  # The history is rebuilt from the files on disk, so they must be the full main state.
  branch="$(git symbolic-ref --short -q HEAD || true)"
  worktrees="$(git worktree list --porcelain | grep -c '^worktree ' || true)"
  head="$(git rev-parse -q --verify HEAD || true)"
  release="$(git rev-parse -q --verify 'v0.2.0^{commit}' || true)"
  at_release=no
  if [ -n "$release" ] && [ "$head" = "$release" ]; then at_release=yes; fi
  if [ "$branch" != "main" ] || [ -n "$(git status --porcelain)" ] || [ "$worktrees" -gt 1 ] || [ "$at_release" != yes ]; then
    echo "setup-demo.sh: --force only runs on a clean main checkout at v0.2.0 with no extra worktrees" >&2
    echo "  (current branch: ${branch:-detached}, worktrees: $worktrees, HEAD at v0.2.0: $at_release)." >&2
    echo "  Close VS Code and every Copilot CLI session first, then run the full rehearsal reset" >&2
    echo "  from DEMO_SCRIPT.md and git checkout main before trying again." >&2
    echo "  To restore only demo-checks: git branch -f demo-checks demo-checks-base" >&2
    exit 1
  fi
  echo "Removing the existing .git directory and rebuilding the history."
  rm -rf .git
fi

git -c init.defaultBranch=main init -q
git symbolic-ref HEAD refs/heads/main
git config user.name "FeeQuote Demo"
git config user.email "demo@example.com"
git config core.autocrlf false
git config commit.gpgsign false
git config tag.gpgsign false

# 1. Baseline: everything except the customization files.
git add -A -- . \
  ':(exclude).github' \
  ':(exclude)AGENTS.md' \
  ':(exclude).vscode/mcp.json' \
  ':(exclude)scripts'
git commit -q -m "feat: add FeeQuote domain, pricing, transfer service and CLI"
git tag v0.1.0
git branch demo-start

# 2. Repository instructions.
git add -- .github/copilot-instructions.md .github/instructions AGENTS.md
git commit -q -m "chore: add repository instructions and AGENTS.md"

# 3. Reviewer agent.
git add -- .github/agents
git commit -q -m "feat: add reviewer custom agent"

# 4. Release-notes skill and its script.
git add -- .github/skills scripts
# core.fileMode is false on Windows, so set the mode in the index as well as on disk.
chmod +x "${executable_files[@]}"
git update-index --chmod=+x -- "${executable_files[@]}"
git commit -q -m "feat: add release-notes skill"

# 5. MCP configuration.
git add -- .vscode/mcp.json
git commit -q -m "chore: add MCP server configuration"
git tag v0.2.0

# 6. Checks demo branch: tests stay green, ESLint (no-unused-vars) and tsc (TS2322) fail.
git checkout -q -b demo-checks
# Node does the edit so the file keeps its line endings (LF or CRLF). It fails
# unless exactly the channel check was removed and the isChannel import remains.
node -e '
  const fs = require("node:fs");
  const text = fs.readFileSync("src/cli.ts", "utf8");
  const edited = text.replace(/^ *if \(!isChannel\(channel\)\) throw .*\r?\n/m, "");
  if (edited === text || edited.includes("isChannel(channel)") || !edited.includes("isChannel")) process.exit(1);
  fs.writeFileSync("src/cli.ts", edited);
' || { echo "setup-demo.sh: could not prepare demo-checks" >&2; exit 1; }
if git diff --quiet -- src/cli.ts; then
  echo "setup-demo.sh: could not prepare demo-checks" >&2
  exit 1
fi
git commit -q -am "refactor: simplify quote argument parsing"
git tag demo-checks-base
git checkout -q main

if [ -n "$(git status --porcelain)" ]; then
  echo "setup-demo.sh: warning, some files were left uncommitted:" >&2
  git status --short >&2
fi

echo "History created:"
git log --oneline --decorate
