"""Print the commits between two git refs grouped by conventional-commit type.

Usage:
    python scripts/release_notes.py <from-ref> <to-ref>

Example:
    python scripts/release_notes.py v0.1.0 v0.2.0

Only the standard library is used and git is invoked through subprocess, so
the script runs unchanged on Windows, macOS and Linux. The output is a plain
grouped listing; turning it into the published release notes is a separate
editing step.
"""

from __future__ import annotations

import re
import subprocess
import sys
from collections import defaultdict
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent

# Order matters: this is the order the groups are printed in.
GROUP_TITLES = {"feat": "Features", "fix": "Fixes", "chore": "Chores", "other": "Other"}

SUBJECT_PATTERN = re.compile(r"^(?P<type>[a-z]+)(?:\([^)]*\))?!?:\s*(?P<summary>.+)$")


def git_subjects(from_ref: str, to_ref: str) -> list[tuple[str, str]]:
    """Return (short hash, subject) for every non-merge commit in the range."""
    command = [
        "git",
        "log",
        "--no-merges",
        "--reverse",
        "--format=%h%x09%s",
        f"{from_ref}..{to_ref}",
    ]
    result = subprocess.run(
        command,
        cwd=REPO_ROOT,
        capture_output=True,
        text=True,
        encoding="utf-8",
        check=True,
    )
    subjects: list[tuple[str, str]] = []
    for line in result.stdout.splitlines():
        short_hash, _, subject = line.partition("\t")
        if short_hash:
            subjects.append((short_hash, subject.strip()))
    return subjects


def classify(subject: str) -> tuple[str, str]:
    """Split a commit subject into its group key and summary text."""
    match = SUBJECT_PATTERN.match(subject)
    if match is None:
        return "other", subject
    commit_type = match.group("type")
    group = commit_type if commit_type in GROUP_TITLES else "other"
    return group, match.group("summary")


def render(from_ref: str, to_ref: str, subjects: list[tuple[str, str]]) -> str:
    grouped: dict[str, list[str]] = defaultdict(list)
    for short_hash, subject in subjects:
        group, summary = classify(subject)
        grouped[group].append(f"- {summary} ({short_hash})")

    lines = [f"Commits {from_ref}..{to_ref}: {len(subjects)}", ""]
    for group, title in GROUP_TITLES.items():
        entries = grouped.get(group, [])
        if group == "other" and not entries:
            continue
        lines.append(f"{title} ({len(entries)})")
        lines.extend(entries or ["- none"])
        lines.append("")
    return "\n".join(lines).rstrip() + "\n"


def main(argv: list[str]) -> int:
    if len(argv) != 3:
        print("usage: python scripts/release_notes.py <from-ref> <to-ref>", file=sys.stderr)
        return 2
    from_ref, to_ref = argv[1], argv[2]
    try:
        subjects = git_subjects(from_ref, to_ref)
    except FileNotFoundError:
        print("error: git was not found on PATH", file=sys.stderr)
        return 1
    except subprocess.CalledProcessError as exc:
        reason = exc.stderr.strip().splitlines()[0] if exc.stderr.strip() else "unknown error"
        print(f"error: git log failed: {reason}", file=sys.stderr)
        return 1
    sys.stdout.write(render(from_ref, to_ref, subjects))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
