"""Quoting and submission of customer transfers."""

from __future__ import annotations

from dataclasses import dataclass

from feequote import config
from feequote.clients.payment_client import PaymentClient, SubmissionReceipt
from feequote.core.pricing import compute_fee
from feequote.models import BreakdownLine, Quote, Transfer


class TransferValidationError(ValueError):
    """The transfer cannot be quoted as supplied."""


@dataclass(frozen=True)
class Submission:
    quote: Quote
    receipt: SubmissionReceipt


def validate_transfer(transfer: Transfer) -> None:
    """Reject transfers the service cannot price or route."""
    if transfer.amount_cents <= 0:
        raise TransferValidationError("amount_cents must be positive")
    if transfer.currency not in config.CURRENCIES:
        raise TransferValidationError(f"unsupported currency: {transfer.currency}")
    for label, country in (
        ("origin", transfer.origin_country),
        ("destination", transfer.destination_country),
    ):
        if country not in config.COUNTRIES:
            raise TransferValidationError(f"unsupported {label} country: {country}")
    if transfer.channel not in config.CHANNELS:
        raise TransferValidationError(f"unsupported channel: {transfer.channel}")


class TransferService:
    """Quotes transfers and submits them to the payment gateway."""

    def __init__(self, client: PaymentClient | None = None) -> None:
        self._client = client or PaymentClient()

    def quote(self, transfer: Transfer) -> Quote:
        """Price ``transfer`` and return the quote with its fee breakdown."""
        validate_transfer(transfer)
        domestic_fee = compute_fee(transfer.amount_cents)
        breakdown = (BreakdownLine(label="domestic_fee", amount_cents=domestic_fee),)
        fee_cents = sum(line.amount_cents for line in breakdown)
        return Quote(
            transfer_id=transfer.id,
            fee_cents=fee_cents,
            total_cents=transfer.amount_cents + fee_cents,
            breakdown=breakdown,
        )

    def submit(self, transfer: Transfer) -> Submission:
        """Quote ``transfer`` and hand it to the gateway."""
        quote = self.quote(transfer)
        receipt = self._client.submit(transfer)
        return Submission(quote=quote, receipt=receipt)
