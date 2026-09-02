"""Nightly batch reconciliation and the legacy helper it depends on."""

import pytest

from feequote.jobs.reconciliation import BatchLine, reconcile
from feequote.legacy.fees import calculate_fee

# The batch system books fees with the truncating helper, so these are the
# values reconciliation has to reproduce. They differ from the domestic fee
# policy in every case except the plain one.
LEGACY_RESULTS = [
    pytest.param(123500, 1111, id="ticket 4821 rounding"),
    pytest.param(500000, 4500, id="cap applies"),
    pytest.param(5000, 45, id="minimum applies"),
    pytest.param(100000, 900, id="plain"),
]


@pytest.mark.parametrize(("amount_cents", "booked_fee"), LEGACY_RESULTS)
def test_legacy_helper_reproduces_booked_fees(amount_cents: int, booked_fee: int) -> None:
    assert calculate_fee(amount_cents, 90) == booked_fee


def test_balanced_batch_has_no_mismatches() -> None:
    lines = [
        BatchLine("tr-1", 123500, 90, 1111),
        BatchLine("tr-2", 500000, 90, 4500),
        BatchLine("tr-3", 5000, 90, 45),
    ]
    report = reconcile(lines)

    assert report.is_balanced
    assert report.line_count == 3
    assert report.expected_total_cents == 5656
    assert report.booked_total_cents == 5656
    assert report.mismatched_transfer_ids == ()


def test_mismatched_lines_are_reported_by_transfer_id() -> None:
    lines = [
        BatchLine("tr-1", 100000, 90, 900),
        BatchLine("tr-2", 123500, 90, 1112),
        BatchLine("tr-3", 5000, 90, 100),
    ]
    report = reconcile(lines)

    assert not report.is_balanced
    assert report.mismatched_transfer_ids == ("tr-2", "tr-3")
    assert report.expected_total_cents == 2056
    assert report.booked_total_cents == 2112


def test_empty_batch_is_balanced() -> None:
    report = reconcile([])
    assert report.is_balanced
    assert report.line_count == 0
