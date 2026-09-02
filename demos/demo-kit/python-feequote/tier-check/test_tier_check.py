"""Presenter-only check for segment 4.3. Never commit this file.

Copy it into a worktree's tests folder after the agent has finished, then run
only this file. It drives the submit path through the transfer service with a
fake gateway, so it holds wherever the agent put the retry.
"""

from dataclasses import dataclass, field

import pytest

from feequote.clients.errors import GatewayDeclinedError, GatewayTimeoutError
from feequote.clients.payment_client import PaymentClient
from feequote.models import Transfer
from feequote.services.transfer_service import TransferService

TRANSFER = Transfer(
    id="tr-4300",
    amount_cents=100000,
    currency="AUD",
    origin_country="AU",
    destination_country="AU",
    channel="online",
)


@dataclass
class FakeGateway:
    """Deduplicates on the idempotency key, like the real gateway."""

    lose_first_response: bool = False
    fail_first_call: bool = False
    decline: bool = False
    calls: list[str] = field(default_factory=list)
    payments: dict[str, str] = field(default_factory=dict)

    def __call__(self, transfer: Transfer, idempotency_key: str) -> str:
        self.calls.append(idempotency_key)
        if self.decline:
            raise GatewayDeclinedError(f"transfer {transfer.id} declined")
        if self.fail_first_call and len(self.calls) == 1:
            raise GatewayTimeoutError("gateway timed out before taking the payment")
        if idempotency_key not in self.payments:
            self.payments[idempotency_key] = f"GW-{len(self.payments) + 1}"
        if self.lose_first_response and len(self.calls) == 1:
            raise GatewayTimeoutError("gateway took the payment but the response was lost")
        return self.payments[idempotency_key]


def submit_through(gateway: FakeGateway) -> str:
    service = TransferService(client=PaymentClient(transport=gateway))
    return service.submit(TRANSFER).receipt.reference


def test_recovers_when_the_gateway_times_out_once() -> None:
    gateway = FakeGateway(fail_first_call=True)
    assert submit_through(gateway) == "GW-1", "the submit path does not retry a timeout"


def test_charges_the_customer_once_when_a_response_is_lost() -> None:
    gateway = FakeGateway(lose_first_response=True)
    reference = submit_through(gateway)
    charges = len(gateway.payments)
    assert charges == 1, (
        f"customer charged {charges} times for {TRANSFER.id} "
        f"(keys: {', '.join(gateway.payments)})"
    )
    assert reference == "GW-1"


def test_does_not_resubmit_a_declined_transfer() -> None:
    gateway = FakeGateway(decline=True)
    with pytest.raises(Exception):  # noqa: B017 - any error will do; the resend count is the point
        submit_through(gateway)
    assert len(gateway.calls) == 1, f"declined transfer sent {len(gateway.calls)} times"
