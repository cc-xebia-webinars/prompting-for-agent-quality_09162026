"""Transfer service: quoting and submission."""

import pytest

from feequote.clients.payment_client import PaymentClient
from feequote.models import Transfer
from feequote.services.transfer_service import TransferService, TransferValidationError


def make_transfer(amount_cents: int, **overrides: str) -> Transfer:
    fields = {
        "id": "tr-1",
        "currency": "AUD",
        "origin_country": "AU",
        "destination_country": "AU",
        "channel": "online",
    }
    fields.update(overrides)
    return Transfer(amount_cents=amount_cents, **fields)


def test_regression_ticket_4821() -> None:
    # The legacy helper returns 1111 here because it truncates. See ticket 4821.
    quote = TransferService().quote(make_transfer(123500))
    assert quote.fee_cents == 1112


def test_quote_breakdown_has_a_single_domestic_line() -> None:
    quote = TransferService().quote(make_transfer(100000))
    assert [(line.label, line.amount_cents) for line in quote.breakdown] == [("domestic_fee", 900)]


def test_quote_total_is_amount_plus_fee() -> None:
    quote = TransferService().quote(make_transfer(100000, id="tr-9"))
    assert quote.transfer_id == "tr-9"
    assert quote.fee_cents == 900
    assert quote.total_cents == 100900


def test_quote_applies_minimum_and_cap() -> None:
    service = TransferService()
    assert service.quote(make_transfer(5000)).fee_cents == 100
    assert service.quote(make_transfer(500000)).fee_cents == 2500


def test_quote_to_dict_is_json_ready() -> None:
    quote = TransferService().quote(make_transfer(100000))
    assert quote.to_dict() == {
        "transfer_id": "tr-1",
        "fee_cents": 900,
        "total_cents": 100900,
        "breakdown": [{"label": "domestic_fee", "amount_cents": 900}],
    }


@pytest.mark.parametrize(
    ("overrides", "message"),
    [
        ({"currency": "XXX"}, "unsupported currency"),
        ({"origin_country": "ZZ"}, "unsupported origin country"),
        ({"destination_country": "ZZ"}, "unsupported destination country"),
        ({"channel": "fax"}, "unsupported channel"),
    ],
)
def test_quote_rejects_unsupported_transfers(overrides: dict[str, str], message: str) -> None:
    with pytest.raises(TransferValidationError, match=message):
        TransferService().quote(make_transfer(100000, **overrides))


def test_quote_rejects_non_positive_amounts() -> None:
    with pytest.raises(TransferValidationError, match="amount_cents"):
        TransferService().quote(make_transfer(0))


def test_submit_quotes_then_sends_through_the_client() -> None:
    sent: list[Transfer] = []

    def transport(transfer: Transfer, idempotency_key: str) -> str:
        sent.append(transfer)
        return "REF-1"

    service = TransferService(client=PaymentClient(transport=transport))
    submission = service.submit(make_transfer(100000))

    assert submission.quote.fee_cents == 900
    assert submission.receipt.reference == "REF-1"
    assert submission.receipt.status == "accepted"
    assert [t.id for t in sent] == ["tr-1"]


def test_submit_does_not_reach_the_client_when_validation_fails() -> None:
    sent: list[Transfer] = []

    def transport(transfer: Transfer, idempotency_key: str) -> str:
        sent.append(transfer)
        return "REF-1"

    service = TransferService(client=PaymentClient(transport=transport))
    with pytest.raises(TransferValidationError):
        service.submit(make_transfer(100000, currency="XXX"))
    assert sent == []
