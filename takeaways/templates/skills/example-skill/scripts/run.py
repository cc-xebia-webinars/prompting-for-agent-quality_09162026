"""Deterministic half of the <skill-name> skill.

Collect the facts the skill needs and print them in a stable, plain-text shape. The agent turns
this output into the final format; the script never guesses.
"""

from __future__ import annotations

import subprocess
import sys


def main(argv: list[str]) -> int:
    if len(argv) != 2:
        print("usage: run.py <from-ref> <to-ref>", file=sys.stderr)
        return 2
    from_ref, to_ref = argv
    log = subprocess.run(
        ["git", "log", "--format=%s", f"{from_ref}..{to_ref}"],
        check=True,
        capture_output=True,
        text=True,
    ).stdout.splitlines()
    print(f"Commits {from_ref}..{to_ref}: {len(log)}")
    for subject in log:
        print(f"- {subject}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv[1:]))
