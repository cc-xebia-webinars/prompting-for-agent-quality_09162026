"""Retained for the nightly batch reconciliation job. Scheduled for removal once
reconciliation moves to core pricing (see ticket 4821).
"""

from __future__ import annotations


def calculate_fee(amount_cents: int, rate_bps: int) -> int:
    """Fee at ``rate_bps`` for ``amount_cents``, truncated to whole cents."""
    return amount_cents * rate_bps // 10_000
