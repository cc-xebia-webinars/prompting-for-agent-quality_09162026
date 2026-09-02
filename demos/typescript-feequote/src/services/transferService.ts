// Transfer service: prices a transfer and hands it to the payment gateway.
import { randomUUID } from 'node:crypto';
import type { PaymentGateway, SubmissionReceipt } from '../clients/paymentClient.js';
import { computeFee } from '../core/pricing.js';
import type { Quote, Transfer } from '../models.js';

export const DOMESTIC_FEE_LABEL = 'Domestic fee';

export interface SubmissionResult {
  readonly quote: Quote;
  readonly receipt: SubmissionReceipt;
}

/** Builds the customer-facing quote for a transfer. Pure; safe to call repeatedly. */
export function quote(transfer: Transfer): Quote {
  const feeCents = computeFee(transfer.amountCents);
  return {
    transferId: transfer.id,
    feeCents,
    totalCents: transfer.amountCents + feeCents,
    breakdown: [{ label: DOMESTIC_FEE_LABEL, amountCents: feeCents }],
  };
}

/** Quotes the transfer and submits it. The quote is returned alongside the receipt. */
export async function submit(transfer: Transfer, gateway: PaymentGateway): Promise<SubmissionResult> {
  const quoted = quote(transfer);
  const receipt = await send(transfer, gateway);
  return { quote: quoted, receipt };
}

function send(transfer: Transfer, gateway: PaymentGateway): Promise<SubmissionReceipt> {
  return gateway.submit(transfer, newIdempotencyKey());
}

function newIdempotencyKey(): string {
  return randomUUID();
}
