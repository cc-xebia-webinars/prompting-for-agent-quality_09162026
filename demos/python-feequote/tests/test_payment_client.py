"""Payment gateway client."""

import pytest

from feequote.clients.payment_client import GatewayError, PaymentClient
from feequote.models import Transfer


def make_transfer(transfer_id: str = "tr-1", amount_cents: int = 100000) -> Transfer:
    return Transfer(
        id=transfer_id,
        amount_cents=amount_cents,
        currency="AUD",
        origin_country="AU",
        destination_country="AU",
        channel="online",
    )


def test_submit_returns_an_accepted_receipt() -> None:
    receipt = PaymentClient().submit(make_transfer())
    assert receipt.transfer_id == "tr-1"
    assert receipt.status == "accepted"
    assert receipt.reference == "STUB-000001"


def test_stub_references_are_sequential_per_client() -> None:
    client = PaymentClient()
    first = client.submit(make_transfer("tr-1")).reference
    second = client.submit(make_transfer("tr-2")).reference
    assert (first, second) == ("STUB-000001", "STUB-000002")


def test_separate_clients_have_separate_sequences() -> None:
    assert PaymentClient().submit(make_transfer()).reference == "STUB-000001"
    assert PaymentClient().submit(make_transfer()).reference == "STUB-000001"


def test_submit_uses_the_injected_transport() -> None:
    client = PaymentClient(transport=lambda transfer, _key: f"GW-{transfer.id}")
    assert client.submit(make_transfer("tr-7")).reference == "GW-tr-7"


def test_submit_sends_an_idempotency_key() -> None:
    keys: list[str] = []

    def transport(transfer: Transfer, idempotency_key: str) -> str:
        keys.append(idempotency_key)
        return "GW-1"

    PaymentClient(transport=transport).submit(make_transfer())
    assert len(keys) == 1
    assert keys[0]


def test_submit_rejects_non_positive_amounts() -> None:
    with pytest.raises(GatewayError, match="non-positive"):
        PaymentClient().submit(make_transfer(amount_cents=0))


def test_submit_propagates_transport_failures() -> None:
    def failing_transport(transfer: Transfer, idempotency_key: str) -> str:
        raise GatewayError(f"gateway unavailable for {transfer.id}")

    with pytest.raises(GatewayError, match="gateway unavailable for tr-1"):
        PaymentClient(transport=failing_transport).submit(make_transfer())
