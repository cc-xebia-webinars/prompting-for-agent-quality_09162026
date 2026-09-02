---
name: release-notes
description: Generate release notes for FeeQuote from the git log between two tags, grouped by type (feature, fix, chore) in the house format. Use when asked for release notes, a changelog, or "what shipped".
---
# Release notes

1. From the repository root, run `bash scripts/release-notes.sh <from-tag> <to-tag>` on macOS and Linux, or `pwsh scripts/release-notes.ps1 <from-tag> <to-tag>` on Windows. Both print the commits grouped by conventional-commit type.
2. Turn the output into the house format below. Keep each line under 100 characters. Do not invent changes that are not in the log.

## House format

## FeeQuote <to-tag>

### Features
- ...

### Fixes
- ...

### Chores
- ...
