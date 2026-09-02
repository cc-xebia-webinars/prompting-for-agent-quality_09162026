"""Nightly batch reconciliation.

Recomputes the fee on every line of a settled batch the way the batch system
booked it and reports the lines that do not agree. The batch system still
books fees with the legacy truncating helper, so this job has to use the same
helper to reproduce historical totals. Ticket 4821 tracks moving both sides
to core pricing.
"""

from __future__ import annotations

from collections.abc import Iterable
from dataclasses import dataclass

from feequote.legacy.fees import calculate_fee


@dataclass(frozen=True)
class BatchLine:
    """One settled transfer as recorded by the batch system."""

    transfer_id: str
    amount_cents: int
    rate_bps: int
    booked_fee_cents: int


@dataclass(frozen=True)
class ReconciliationReport:
    line_count: int
    expected_total_cents: int
    booked_total_cents: int
    mismatched_transfer_ids: tuple[str, ...]

    @property
    def is_balanced(self) -> bool:
        return not self.mismatched_transfer_ids


def expected_fee(line: BatchLine) -> int:
    """The fee the batch system should have booked for ``line``."""
    return calculate_fee(line.amount_cents, line.rate_bps)


def reconcile(lines: Iterable[BatchLine]) -> ReconciliationReport:
    """Compare booked fees against recomputed fees for a whole batch."""
    line_count = 0
    expected_total = 0
    booked_total = 0
    mismatches: list[str] = []
    for line in lines:
        line_count += 1
        expected = expected_fee(line)
        expected_total += expected
        booked_total += line.booked_fee_cents
        if expected != line.booked_fee_cents:
            mismatches.append(line.transfer_id)
    return ReconciliationReport(
        line_count=line_count,
        expected_total_cents=expected_total,
        booked_total_cents=booked_total,
        mismatched_transfer_ids=tuple(mismatches),
    )
