"""Source-level rules for the feequote package.

These tests read the production sources as text so they hold regardless of
how a module is imported or aliased.
"""

import re
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
PACKAGE_ROOT = REPO_ROOT / "feequote"
LEGACY_ROOT = PACKAGE_ROOT / "legacy"
LEGACY_HELPER = re.compile(r"\bcalculate_fee\b")

# Modules that are allowed to reference the legacy helper. The reconciliation
# job reproduces historical batch totals and must match the batch system
# until ticket 4821 moves both to core pricing.
ALLOWED_LEGACY_CALLERS = {PACKAGE_ROOT / "jobs" / "reconciliation.py"}


def production_sources() -> list[Path]:
    return sorted(
        path
        for path in PACKAGE_ROOT.rglob("*.py")
        if LEGACY_ROOT not in path.parents and path not in ALLOWED_LEGACY_CALLERS
    )


def references_to(pattern: re.Pattern[str], path: Path) -> list[str]:
    lines = path.read_text(encoding="utf-8").splitlines()
    return [
        f"{path.relative_to(REPO_ROOT).as_posix()}:{number}: {line.strip()}"
        for number, line in enumerate(lines, start=1)
        if pattern.search(line)
    ]


def test_scan_covers_the_service_and_cli_modules() -> None:
    scanned = {path.relative_to(PACKAGE_ROOT).as_posix() for path in production_sources()}
    assert "services/transfer_service.py" in scanned
    assert "__main__.py" in scanned
    assert "jobs/reconciliation.py" not in scanned
    assert "legacy/fees.py" not in scanned


def test_only_reconciliation_references_the_legacy_fee_helper() -> None:
    offenders = [
        reference
        for path in production_sources()
        for reference in references_to(LEGACY_HELPER, path)
    ]
    assert not offenders, (
        "New code must not call the legacy fee helper. Use core pricing "
        "(price_with_policy or compute_fee) instead. See ticket 4821.\n"
        + "\n".join(f"  {reference}" for reference in offenders)
    )
