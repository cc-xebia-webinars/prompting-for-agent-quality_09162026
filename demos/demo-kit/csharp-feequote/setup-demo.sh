#!/usr/bin/env bash
# Builds the demo git history for FeeQuote from the files on disk.
#
# Produces five conventional commits, tags v0.1.0 and v0.2.0, and a demo-start
# branch at the baseline commit (before any Copilot customization files or
# release-notes scripts exist; the scripts arrive with the skill commit).
# Refuses to touch an existing .git directory unless --force is given, and
# --force only runs on a clean main checkout at v0.2.0 with no extra worktrees,
# because the history is rebuilt from the files on disk.
#
# Also creates a demo-checks branch, tagged demo-checks-base: v0.2.0 plus one
# commit, "refactor: tidy transfer service usings", whose defect the tests and
# the build do not catch (usings out of order and no final newline in
# src/FeeQuote/Services/TransferService.cs) but dotnet format does. To restore
# the branch after an experiment: git branch -f demo-checks demo-checks-base
#
# The presenter's files (DEMO_SCRIPT.md, prompts.txt, RUN_COMPARISON.md, tier-check/,
# run-stats.py and these scripts) live in demo-kit, outside the repository, so agents
# working in the repository or its worktrees never read the expected answers.
#
# It works on ../../csharp-feequote next to this demo-kit folder
# (~/demos/csharp-feequote), so it can be run from anywhere. Usage on macOS, Linux or
# Windows (Git Bash):
#
#   bash ~/demos/demo-kit/csharp-feequote/setup-demo.sh
#       refuses to run if .git already exists
#   bash ~/demos/demo-kit/csharp-feequote/setup-demo.sh --force
#       deletes .git and rebuilds the history; only from a clean main checkout
#       with no extra worktrees
#
# Runs on the stock bash 3.2 and BSD tools that ship with macOS as well as on Linux.
set -euo pipefail

kit="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo="$(cd "$kit/../../csharp-feequote" 2>/dev/null && pwd)" || {
    echo "setup-demo.sh: ../../csharp-feequote not found. Keep demo-kit and csharp-feequote side by side under ~/demos." >&2
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
            echo "setup-demo.sh: unknown argument '$arg' (usage: bash setup-demo.sh [--force])" >&2
            exit 2
            ;;
    esac
done

# Files that arrive after the baseline commit, in the order they are committed.
customization_files=(
    .github/copilot-instructions.md .github/instructions AGENTS.md
    .github/agents
    .github/skills scripts
    .vscode/mcp.json
)

for path in "${customization_files[@]}"; do
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
    if [ "$branch" != "main" ] || [ -n "$(git status --porcelain)" ] || [ "$worktrees" -gt 1 ] \
        || [ -z "$release" ] || [ "$head" != "$release" ]; then
        if [ -z "$release" ]; then
            at_release="no v0.2.0 tag"
        elif [ "$head" = "$release" ]; then
            at_release="yes"
        else
            at_release="no"
        fi
        echo "setup-demo.sh: --force only runs on a clean main checkout at v0.2.0 with no extra worktrees" >&2
        echo "  (current branch: ${branch:-detached}, worktrees: $worktrees, HEAD at v0.2.0: $at_release)." >&2
        echo "  Close VS Code and every Copilot CLI session first, then run the full rehearsal reset" >&2
        echo "  from DEMO_SCRIPT.md, then git checkout -q main, and try again." >&2
        echo "  To restore only demo-checks: git branch -f demo-checks demo-checks-base" >&2
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

# 1. Baseline: everything except the customization files and the release-notes scripts.
git add -A . ':!.github' ':!AGENTS.md' ':!.vscode' ':!scripts'
git commit -q -m "feat: add FeeQuote domain, pricing, transfer service and CLI"
git tag v0.1.0
git branch demo-start

# 2. Repository instructions.
git add .github/copilot-instructions.md .github/instructions AGENTS.md
git commit -q -m "chore: add repository instructions and AGENTS.md"

# 3. Custom agent.
git add .github/agents
git commit -q -m "feat: add reviewer custom agent"

# 4. Skill and the release-notes scripts it runs. The shell script is committed
#    executable even when the files came from a zip (no mode bits) or from Windows.
chmod +x scripts/*.sh
git add .github/skills scripts
git update-index --chmod=+x scripts/*.sh
git commit -q -m "feat: add release-notes skill"

# 5. MCP configuration.
git add .vscode/mcp.json
git commit -q -m "chore: add MCP server configuration"
git tag v0.2.0

# 6. Checks demo branch: dotnet test and the build stay green, dotnet format fails
#    (IMPORTS: usings out of order; FINALNEWLINE: no newline at end of file).
#    Tolerates LF or CRLF files and stops loudly if the file no longer matches.
#    The file is rewritten with bash's own read and printf builtins (no awk or sed),
#    always with LF endings, so the commit is byte-identical on macOS, Linux and
#    Windows (Git Bash) and matches the one setup-demo.ps1 makes.
git checkout -q -b demo-checks
service=src/FeeQuote/Services/TransferService.cs
models_using='using FeeQuote.Models;'
clients_using='using FeeQuote.Clients;'
lines=()
while IFS= read -r line || [ -n "$line" ]; do
    lines+=("${line%$'\r'}")
done < "$service"
models_count=0
for line in "${lines[@]}"; do
    if [ "$line" = "$models_using" ]; then
        models_count=$((models_count + 1))
    fi
done
if [ "$models_count" -ne 1 ] || [ "${lines[0]}" != "$clients_using" ]; then
    echo "setup-demo.sh: could not prepare demo-checks; $service no longer matches the expected usings." >&2
    exit 1
fi
# Models moves above Clients; trailing blank lines and the final newline are dropped.
out=("$models_using")
for line in "${lines[@]}"; do
    if [ "$line" != "$models_using" ]; then
        out+=("$line")
    fi
done
last=$((${#out[@]} - 1))
while [ "$last" -gt 0 ] && [ -z "${out[$last]}" ]; do
    unset "out[$last]"
    last=$((last - 1))
done
{
    i=0
    while [ "$i" -lt "$last" ]; do
        printf '%s\n' "${out[$i]}"
        i=$((i + 1))
    done
    printf '%s' "${out[$last]}"
} > "$service"
# Both defects must be in place: Models above Clients, and no newline after the last brace.
if [ "$(grep -c '^using FeeQuote\.Models;' "$service")" -ne 1 ] \
    || [ "$(grep -c '^using FeeQuote\.Clients;' "$service")" -ne 1 ] \
    || ! head -n 1 "$service" | grep -q '^using FeeQuote\.Models;' \
    || ! sed -n '2p' "$service" | grep -q '^using FeeQuote\.Clients;' \
    || [ "$(tail -c 1 "$service")" != "}" ]; then
    echo "setup-demo.sh: could not prepare demo-checks; $service no longer matches the expected usings." >&2
    exit 1
fi
git commit -q -am "refactor: tidy transfer service usings"
git tag demo-checks-base
git checkout -q main

if [ -n "$(git status --porcelain)" ]; then
    echo "setup-demo.sh: warning, some files were left uncommitted:" >&2
    git status --short >&2
fi

echo "Demo history created:"
git --no-pager log --oneline --decorate
