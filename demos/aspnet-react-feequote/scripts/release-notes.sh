#!/usr/bin/env bash
# Prints the commits between two tags grouped by conventional-commit type.
# Usage: scripts/release-notes.sh <from-tag> <to-tag>
set -euo pipefail

if [ "$#" -ne 2 ]; then
  echo "usage: $0 <from-tag> <to-tag>" >&2
  exit 2
fi

from_tag="$1"
to_tag="$2"

for tag in "$from_tag" "$to_tag"; do
  if ! git rev-parse --verify --quiet "refs/tags/$tag" >/dev/null; then
    echo "error: tag '$tag' not found" >&2
    exit 1
  fi
done

features=()
fixes=()
chores=()
other=()

while IFS= read -r subject; do
  [ -z "$subject" ] && continue
  case "$subject" in
    feat:*|feat\(*) features+=("${subject#*: }") ;;
    fix:*|fix\(*) fixes+=("${subject#*: }") ;;
    chore:*|chore\(*|build:*|ci:*|docs:*|refactor:*|test:*) chores+=("${subject#*: }") ;;
    *) other+=("$subject") ;;
  esac
done < <(git log --no-merges --reverse --format=%s "$from_tag..$to_tag")

print_group() {
  local title="$1"
  shift
  echo "$title"
  if [ "$#" -eq 0 ]; then
    echo "- (none)"
  else
    for line in "$@"; do
      echo "- $line"
    done
  fi
  echo
}

echo "Commits $from_tag..$to_tag"
echo
print_group "Features" "${features[@]+"${features[@]}"}"
print_group "Fixes" "${fixes[@]+"${fixes[@]}"}"
print_group "Chores" "${chores[@]+"${chores[@]}"}"
if [ "${#other[@]}" -gt 0 ]; then
  print_group "Unclassified" "${other[@]}"
fi
