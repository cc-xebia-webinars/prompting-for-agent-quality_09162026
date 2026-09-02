"""Core fee pricing.

Amounts are integer minor units (cents) and rates are integer basis points.
Nothing in this module touches binary floating point; the division is done
with integers so the result is exact for any amount the ledger can hold.
"""

from __future__ import annotations

from dataclasses import dataclass

BPS_PER_UNIT = 10_000


@dataclass(frozen=True)
class FeePolicy:
    """Bounds applied to a fee after it has been rounded to whole cents."""

    minimum_cents: int
    cap_cents: int

    def __post_init__(self) -> None:
        if self.minimum_cents < 0:
            raise ValueError("minimum_cents must not be negative")
        if self.cap_cents < self.minimum_cents:
            raise ValueError("cap_cents must not be below minimum_cents")

    def apply(self, fee_cents: int) -> int:
        """Clamp ``fee_cents`` into [minimum_cents, cap_cents]."""
        return max(self.minimum_cents, min(self.cap_cents, fee_cents))


DOMESTIC_RATE_BPS = 90
DOMESTIC_POLICY = FeePolicy(minimum_cents=100, cap_cents=2500)


def round_half_even_div(numerator: int, denominator: int) -> int:
    """Divide two non-negative integers and round the quotient half to even.

    This is banker's rounding on an exact rational, so 1111.5 becomes 1112,
    1112.5 becomes 1112 and 1111.05 becomes 1111.
    """
    if denominator <= 0:
        raise ValueError("denominator must be positive")
    if numerator < 0:
        raise ValueError("numerator must not be negative")
    quotient, remainder = divmod(numerator, denominator)
    doubled = remainder * 2
    if doubled > denominator or (doubled == denominator and quotient % 2 == 1):
        return quotient + 1
    return quotient


def price_with_policy(amount_cents: int, rate_bps: int, policy: FeePolicy) -> int:
    """Fee for ``amount_cents`` at ``rate_bps``, rounded, then bounded by ``policy``.

    This is the building block for every fee type. Rounding happens before
    the minimum and cap are applied, so the bounds always win.
    """
    if amount_cents < 0:
        raise ValueError("amount_cents must not be negative")
    if rate_bps < 0:
        raise ValueError("rate_bps must not be negative")
    raw_fee = round_half_even_div(amount_cents * rate_bps, BPS_PER_UNIT)
    return policy.apply(raw_fee)


def compute_fee(amount_cents: int) -> int:
    """Domestic transfer fee: 90 bps under the standard domestic policy."""
    return price_with_policy(amount_cents, DOMESTIC_RATE_BPS, DOMESTIC_POLICY)
