#!/usr/bin/env bash
# Builds the demo git history for FeeQuote from the files on disk. It works on
# ../../java-feequote next to this demo-kit folder (~/demos/java-feequote), so it
# can be run from anywhere.
#
# Produces five conventional commits, tags v0.1.0 and v0.2.0, a demo-start
# branch at the baseline commit (before any Copilot customization files exist),
# and a demo-checks branch with one extra commit on top of v0.2.0:
#
#   refactor: tidy domestic fee policy                              branch demo-checks, tag demo-checks-base
#
# demo-checks carries a defect the test suite and the compiler do not catch (an
# unused import and a lowercase long suffix on the cap) but Checkstyle does. To
# restore it after an experiment: git branch -f demo-checks demo-checks-base
#
# The presenter's files (DEMO_SCRIPT.md, prompts.txt, RUN_COMPARISON.md, tier-check/,
# run-stats.py and these scripts) live in demo-kit, outside the repository, so agents
# working in the repository or its worktrees never read the expected answers.
#
# mvnw and scripts/*.sh are committed as executable (mode 100755) even when the
# files on disk lost that bit (a zip extraction, or Windows), so ./mvnw runs in
# every checkout and worktree on macOS and Linux.
#
# Refuses to touch an existing .git directory unless --force is given, and
# --force only runs on a clean main checkout at v0.2.0 with no extra worktrees,
# because the history is rebuilt from the files on disk.
#
# Usage: bash .../demo-kit/java-feequote/setup-demo.sh [--force]
#
# Runs on the stock bash 3.2 and BSD tools that ship with macOS as well as on
# Linux and Git Bash on Windows.
set -euo pipefail

kit="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo="$(cd "$kit/../../java-feequote" 2>/dev/null && pwd)" || {
    echo "setup-demo.sh: ../../java-feequote not found. Keep demo-kit and java-feequote side by side under ~/demos." >&2
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
            echo "usage: bash setup-demo.sh [--force]" >&2
            exit 2
            ;;
    esac
done

# Files that arrive after the baseline commit.
customization_files=(.github/copilot-instructions.md .github/instructions AGENTS.md .github/agents .github/skills scripts .vscode/mcp.json)
# Files that must be executable in every checkout.
executable_files=(mvnw scripts/*.sh)

for path in "${customization_files[@]}" "${executable_files[@]}"; do
    if [ ! -e "$path" ]; then
        echo "setup-demo.sh: $path is missing. Run this from a complete copy of the repository on main." >&2
        exit 1
    fi
done

if [ -e .git ]; then
    if [ "$force" -ne 1 ]; then
        echo "A .git directory already exists. Re-run with --force to delete it and rebuild the demo history." >&2
        exit 1
    fi
    # The history is rebuilt from the files on disk, so they must be the full main state.
    branch="$(git symbolic-ref --short -q HEAD || true)"
    worktrees="$(git worktree list --porcelain | grep -c '^worktree ' || true)"
    head="$(git rev-parse -q --verify HEAD || true)"
    release="$(git rev-parse -q --verify 'v0.2.0^{commit}' || true)"
    at_release=no
    if [ -n "$release" ] && [ "$head" = "$release" ]; then
        at_release=yes
    fi
    if [ "$branch" != "main" ] || [ -n "$(git status --porcelain)" ] || [ "$worktrees" -gt 1 ] \
        || [ "$at_release" != yes ]; then
        echo "setup-demo.sh: --force only runs on a clean main checkout at v0.2.0 with no extra worktrees" >&2
        echo "  (current branch: ${branch:-detached}, worktrees: $worktrees, HEAD at v0.2.0: $at_release)." >&2
        echo "  Close VS Code and every Copilot CLI session first, then run the full rehearsal reset" >&2
        echo "  from DEMO_SCRIPT.md instead. To restore only demo-checks: git branch -f demo-checks demo-checks-base" >&2
        exit 1
    fi
    echo "Removing existing .git directory (--force)."
    rm -rf .git
fi

git init -q
git symbolic-ref HEAD refs/heads/main

# Local identity and settings so commits work on a fresh machine.
git config user.name "FeeQuote Demo"
git config user.email "demo@example.com"
git config commit.gpgsign false
git config tag.gpgSign false
git config core.autocrlf false

# Executable on disk for this checkout (a no-op on Windows); the index entries are
# marked executable below, after each file is staged.
chmod +x "${executable_files[@]}"

# 1. Baseline: everything except the customization files.
git add -A . ':!.github' ':!AGENTS.md' ':!.vscode/mcp.json' ':!scripts'
git update-index --chmod=+x mvnw
git commit -q -m "feat: add FeeQuote domain, pricing, transfer service, API and CLI"
git tag v0.1.0
git branch demo-start

# 2. Repository instructions.
git add .github/copilot-instructions.md .github/instructions AGENTS.md
git commit -q -m "chore: add repository instructions and AGENTS.md"

# 3. Custom agent.
git add .github/agents
git commit -q -m "feat: add reviewer custom agent"

# 4. Skill.
git add .github/skills scripts
git update-index --chmod=+x scripts/*.sh
git commit -q -m "feat: add release-notes skill"

# 5. MCP configuration.
git add .vscode/mcp.json
git commit -q -m "chore: add MCP server configuration"
git tag v0.2.0

# Checks demo branch: tests and compile stay green, Checkstyle (UnusedImports, UpperEll) fails.
git checkout -q -b demo-checks
pricing=src/main/java/com/feequote/core/Pricing.java
# BINMODE=3 stops gawk on Windows (Git Bash) from dropping carriage returns; other awks ignore it.
awk -v BINMODE=3 '
    { eol = sub(/\r$/, "") ? "\r" : "" }
    { sub(/new FeePolicy\(100, 2500\)/, "new FeePolicy(100, 2500l)"); printf "%s%s\n", $0, eol }
    /^package com\.feequote\.core;$/ { printf "%s\nimport java.math.BigDecimal;%s\n", eol, eol }
' "$pricing" > "$pricing.tmp"
# Copy back instead of mv so the file keeps its mode (mv would change it if the copy on disk was executable).
cat "$pricing.tmp" > "$pricing"
rm -f "$pricing.tmp"
if ! grep -q 'new FeePolicy(100, 2500l)' "$pricing" || ! grep -q '^import java\.math\.BigDecimal;' "$pricing" \
    || [ "$(git diff --name-only)" != "$pricing" ]; then
    echo "setup-demo.sh: could not prepare demo-checks" >&2
    exit 1
fi
git commit -q -am "refactor: tidy domestic fee policy"
git tag demo-checks-base
git checkout -q main

echo "Demo history created:"
git --no-pager log --oneline --decorate
