"""Core pricing: the worked examples from the domestic fee policy."""

import pytest

from feequote.core.pricing import (
    DOMESTIC_POLICY,
    FeePolicy,
    compute_fee,
    price_with_policy,
    round_half_even_div,
)

WORKED_EXAMPLES = [
    pytest.param(123500, 1112, id="ticket 4821 rounding"),
    pytest.param(500000, 2500, id="cap applies"),
    pytest.param(5000, 100, id="minimum applies"),
    pytest.param(100000, 900, id="plain"),
]


@pytest.mark.parametrize(("amount_cents", "expected_fee"), WORKED_EXAMPLES)
def test_compute_fee_worked_examples(amount_cents: int, expected_fee: int) -> None:
    assert compute_fee(amount_cents) == expected_fee


def test_domestic_policy_values() -> None:
    assert (DOMESTIC_POLICY.minimum_cents, DOMESTIC_POLICY.cap_cents) == (100, 2500)


@pytest.mark.parametrize(
    ("numerator", "denominator", "expected"),
    [
        (2223, 2, 1112),  # 1111.5 rounds up to the even neighbour
        (2225, 2, 1112),  # 1112.5 rounds down to the even neighbour
        (22221, 20, 1111),  # 1111.05 is below the half way point
        (7, 2, 4),
        (5, 2, 2),
        (1, 2, 0),
        (9, 4, 2),
        (0, 7, 0),
        (14, 7, 2),
    ],
)
def test_round_half_even_div(numerator: int, denominator: int, expected: int) -> None:
    assert round_half_even_div(numerator, denominator) == expected


def test_round_half_even_div_rejects_bad_inputs() -> None:
    with pytest.raises(ValueError, match="denominator"):
        round_half_even_div(1, 0)
    with pytest.raises(ValueError, match="numerator"):
        round_half_even_div(-1, 2)


def test_price_with_policy_rounds_before_bounding() -> None:
    policy = FeePolicy(minimum_cents=0, cap_cents=1000)
    assert price_with_policy(123500, 90, policy) == 1000
    assert price_with_policy(1000, 15, policy) == 2  # 1.5 rounds to even


def test_price_with_policy_accepts_any_rate() -> None:
    policy = FeePolicy(minimum_cents=0, cap_cents=10_000_000)
    assert price_with_policy(247100, 50, policy) == 1236
    assert price_with_policy(247100, 0, policy) == 0


def test_price_with_policy_rejects_negative_inputs() -> None:
    with pytest.raises(ValueError, match="amount_cents"):
        price_with_policy(-1, 90, DOMESTIC_POLICY)
    with pytest.raises(ValueError, match="rate_bps"):
        price_with_policy(100, -1, DOMESTIC_POLICY)


def test_fee_policy_rejects_inverted_bounds() -> None:
    with pytest.raises(ValueError, match="cap_cents"):
        FeePolicy(minimum_cents=500, cap_cents=100)
    with pytest.raises(ValueError, match="minimum_cents"):
        FeePolicy(minimum_cents=-1, cap_cents=100)
