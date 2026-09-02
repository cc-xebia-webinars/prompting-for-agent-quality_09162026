"""Domain records shared across the package.

Every monetary field is an integer number of cents.
"""

from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class Transfer:
    """A customer payment transfer awaiting a quote or submission."""

    id: str
    amount_cents: int
    currency: str
    origin_country: str
    destination_country: str
    channel: str


@dataclass(frozen=True)
class BreakdownLine:
    """One labeled component of a quoted fee."""

    label: str
    amount_cents: int

    def to_dict(self) -> dict[str, object]:
        return {"label": self.label, "amount_cents": self.amount_cents}


@dataclass(frozen=True)
class Quote:
    """The fee quoted for a transfer.

    ``fee_cents`` is the sum of every breakdown line. ``total_cents`` is the
    transfer amount plus ``fee_cents``, which is what the customer is debited.
    """

    transfer_id: str
    fee_cents: int
    total_cents: int
    breakdown: tuple[BreakdownLine, ...]

    def to_dict(self) -> dict[str, object]:
        return {
            "transfer_id": self.transfer_id,
            "fee_cents": self.fee_cents,
            "total_cents": self.total_cents,
            "breakdown": [line.to_dict() for line in self.breakdown],
        }
