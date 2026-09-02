#!/usr/bin/env bash
# Prints the commits between two refs grouped by conventional-commit type.
# Usage: bash scripts/release-notes.sh <from-tag> <to-tag>
# Runs on the stock bash 3.2 that ships with macOS as well as on Linux.
set -euo pipefail

if [ "$#" -ne 2 ]; then
    echo "usage: bash scripts/release-notes.sh <from-tag> <to-tag>" >&2
    exit 2
fi

from="$1"
to="$2"

cd "$(git rev-parse --show-toplevel)"

for ref in "$from" "$to"; do
    if ! git rev-parse -q --verify "${ref}^{commit}" >/dev/null; then
        echo "error: unknown ref '$ref'" >&2
        exit 1
    fi
done

features=()
fixes=()
chores=()
other=()

while IFS= read -r subject; do
    [ -z "$subject" ] && continue

    type="${subject%%:*}"
    description="${subject#*: }"
    type="${type%%(*}"   # drop an optional scope, e.g. feat(cli)
    type="${type%!}"     # drop a breaking-change marker

    case "$type" in
        feat) features+=("$description") ;;
        fix) fixes+=("$description") ;;
        chore|docs|refactor|test|ci|build|perf|style) chores+=("$description") ;;
        *) other+=("$subject") ;;
    esac
done < <(git log --no-merges --reverse --format='%s' "${from}..${to}")

print_group() {
    local title="$1"
    shift
    echo "### $title"
    if [ "$#" -eq 0 ]; then
        echo "- (none)"
    else
        for line in "$@"; do
            echo "- $line"
        done
    fi
    echo
}

echo "## FeeQuote $to"
echo "Commits ${from}..${to}"
echo

# The ${arr[@]+"${arr[@]}"} form keeps bash 3.2 happy with empty arrays under set -u.
print_group "Features" ${features[@]+"${features[@]}"}
print_group "Fixes" ${fixes[@]+"${fixes[@]}"}
print_group "Chores" ${chores[@]+"${chores[@]}"}
print_group "Other (not conventional-commit formatted)" ${other[@]+"${other[@]}"}
