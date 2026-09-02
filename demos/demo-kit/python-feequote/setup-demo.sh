#!/usr/bin/env bash
# Builds the demo git history for the FeeQuote Python repository from the
# files on disk. It works on ../../python-feequote next to this demo-kit folder
# (~/demos/python-feequote), so it can be run from anywhere:
#
#   bash .../demo-kit/python-feequote/setup-demo.sh         # refuses to run if .git already exists
#   bash .../demo-kit/python-feequote/setup-demo.sh --force # deletes .git and rebuilds the history; only from a
#                              # clean main checkout with no extra worktrees
#
# Resulting history (oldest first):
#   feat: add FeeQuote domain, pricing, transfer service and CLI   tag v0.1.0, branch demo-start
#   chore: add repository instructions and AGENTS.md
#   feat: add reviewer custom agent
#   feat: add release-notes skill
#   chore: add MCP server configuration                            tag v0.2.0
#   refactor: tidy domestic fee policy                              branch demo-checks, tag demo-checks-base
#
# demo-checks carries one extra commit whose defect the test suite does not
# catch (a float cap and an unused import) but ruff and mypy do. To restore it
# after an experiment: git branch -f demo-checks demo-checks-base
#
# The presenter's files (DEMO_SCRIPT.md, prompts.txt, RUN_COMPARISON.md, tier-check/,
# run-stats.py and these scripts) live in demo-kit, outside the repository, so agents
# working in the repository or its worktrees never read the expected answers.
set -euo pipefail

kit="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo="$(cd "$kit/../../python-feequote" 2>/dev/null && pwd)" || {
  echo "setup-demo.sh: ../../python-feequote not found. Keep demo-kit and python-feequote side by side under ~/demos." >&2
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
    *)
      echo "setup-demo.sh: unknown argument '$arg' (try --force)" >&2
      exit 2
      ;;
  esac
done

# Files that arrive after the baseline commit, in the order they are committed.
instruction_files=(.github/copilot-instructions.md .github/instructions AGENTS.md)
agent_files=(.github/agents)
skill_files=(.github/skills scripts/release_notes.py)
mcp_files=(.vscode/mcp.json)

for path in "${instruction_files[@]}" "${agent_files[@]}" "${skill_files[@]}" "${mcp_files[@]}"; do
  if [ ! -e "$path" ]; then
    echo "setup-demo.sh: $path is missing. Run this from a complete copy of the repository on main." >&2
    exit 1
  fi
done

if [ -e .git ]; then
  if [ "$force" -ne 1 ]; then
    echo "setup-demo.sh: .git already exists. Re-run with --force to delete it and rebuild." >&2
    exit 1
  fi
  # The history is rebuilt from the files on disk, so they must be the full main state.
  branch="$(git symbolic-ref --short -q HEAD || true)"
  worktrees="$(git worktree list --porcelain | grep -c '^worktree ' || true)"
  head="$(git rev-parse -q --verify HEAD || true)"
  release="$(git rev-parse -q --verify 'v0.2.0^{commit}' || true)"
  if [ "$branch" != "main" ] || [ -n "$(git status --porcelain)" ] || [ "$worktrees" -gt 1 ] || [ -z "$head" ] || [ "$head" != "$release" ]; then
    echo "setup-demo.sh: --force only runs on a clean main checkout at v0.2.0 with no extra worktrees" >&2
    echo "  (current branch: ${branch:-detached}, worktrees: $worktrees)." >&2
    echo "  Close VS Code and every Copilot CLI session, run the full rehearsal reset, then git checkout -q main." >&2
    echo "  To restore only demo-checks: git branch -f demo-checks demo-checks-base" >&2
    exit 1
  fi
  rm -rf .git
fi

git init -q
git symbolic-ref HEAD refs/heads/main
git config user.name "FeeQuote Demo"
git config user.email "demo@example.com"
git config commit.gpgsign false
git config tag.gpgsign false
git config core.autocrlf false

# Baseline: everything on disk except the customization files.
git add -A
git reset -q -- "${instruction_files[@]}" "${agent_files[@]}" "${skill_files[@]}" "${mcp_files[@]}"
git commit -q -m "feat: add FeeQuote domain, pricing, transfer service and CLI"
git tag -a v0.1.0 -m "FeeQuote 0.1.0"
git branch demo-start

git add -A -- "${instruction_files[@]}"
git commit -q -m "chore: add repository instructions and AGENTS.md"

git add -A -- "${agent_files[@]}"
git commit -q -m "feat: add reviewer custom agent"

git add -A -- "${skill_files[@]}"
git commit -q -m "feat: add release-notes skill"

git add -A -- "${mcp_files[@]}"
git commit -q -m "chore: add MCP server configuration"
git tag -a v0.2.0 -m "FeeQuote 0.2.0"

# Checks demo branch: tests stay green, ruff (F401) and mypy (arg-type) fail.
git checkout -q -b demo-checks
awk -v BINMODE=3 '
  /^from dataclasses import dataclass/ { print "import math" }
  { sub(/cap_cents=2500\)/, "cap_cents=2500.0)"); print }
' feequote/core/pricing.py > feequote/core/pricing.py.tmp
mv feequote/core/pricing.py.tmp feequote/core/pricing.py
if ! grep -q 'cap_cents=2500.0)' feequote/core/pricing.py || ! grep -q '^import math' feequote/core/pricing.py; then
  echo "setup-demo.sh: could not prepare demo-checks" >&2
  exit 1
fi
git commit -q -am "refactor: tidy domestic fee policy"
git tag demo-checks-base
git checkout -q main

if [ -n "$(git status --porcelain)" ]; then
  echo "setup-demo.sh: warning, some files were left uncommitted:" >&2
  git status --short >&2
fi

echo "Demo history created on branch main:"
git log --oneline --decorate
