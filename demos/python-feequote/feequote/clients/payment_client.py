"""Payment gateway client.

The gateway integration is stubbed: submissions are accepted locally and
given a sequential reference. The transport can be swapped for tests or for
a real adapter without touching the callers.
"""

from __future__ import annotations

import uuid
from collections.abc import Callable
from dataclasses import dataclass

from feequote.clients.errors import GatewayDeclinedError, GatewayError, GatewayTimeoutError
from feequote.models import Transfer

__all__ = [
    "GatewayDeclinedError",
    "GatewayError",
    "GatewayTimeoutError",
    "PaymentClient",
    "SubmissionReceipt",
    "Transport",
]

Transport = Callable[[Transfer, str], str]
"""Sends a transfer to the gateway and returns the gateway reference."""


@dataclass(frozen=True)
class SubmissionReceipt:
    transfer_id: str
    reference: str
    status: str


def new_idempotency_key() -> str:
    return uuid.uuid4().hex


class PaymentClient:
    """Submits transfers to the payment gateway."""

    def __init__(self, transport: Transport | None = None) -> None:
        self._transport: Transport = transport or self._stub_transport
        self._sequence = 0
        self._references_by_key: dict[str, str] = {}

    def submit(self, transfer: Transfer) -> SubmissionReceipt:
        """Send ``transfer`` to the gateway and return its receipt."""
        if transfer.amount_cents <= 0:
            raise GatewayError(f"transfer {transfer.id} has a non-positive amount")
        reference = self._send(transfer)
        return SubmissionReceipt(transfer_id=transfer.id, reference=reference, status="accepted")

    def _send(self, transfer: Transfer) -> str:
        return self._transport(transfer, new_idempotency_key())

    def _stub_transport(self, transfer: Transfer, idempotency_key: str) -> str:
        if idempotency_key in self._references_by_key:
            return self._references_by_key[idempotency_key]
        self._sequence += 1
        reference = f"STUB-{self._sequence:06d}"
        self._references_by_key[idempotency_key] = reference
        return reference
