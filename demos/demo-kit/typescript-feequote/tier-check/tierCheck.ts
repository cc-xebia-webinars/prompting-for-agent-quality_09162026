// Presenter-only check for segment 4.3. Never commit this file.
//
// Copy it into a worktree's test folder as tierCheck.test.ts after the agent has
// finished, then run only that file. It drives the submit path through the
// transfer service with a fake gateway, so it holds wherever the agent put the
// retry. Here it has no .test suffix, so Vitest in this repository skips it, and
// tier-check/eslint.config.js keeps the folder out of the lint run.
import { describe, expect, it } from 'vitest';
import {
  GatewayDeclinedError,
  GatewayTimeoutError,
  type PaymentGateway,
  type SubmissionReceipt,
} from '../src/clients/paymentClient.js';
import type { Transfer } from '../src/models.js';
import { submit } from '../src/services/transferService.js';

const TRANSFER: Transfer = {
  id: 'T-4300',
  amountCents: 100000,
  currency: 'AUD',
  originCountry: 'AU',
  destinationCountry: 'AU',
  channel: 'online',
};

interface FakeGatewayOptions {
  readonly loseFirstResponse?: boolean;
  readonly failFirstCall?: boolean;
  readonly decline?: boolean;
}

/** Deduplicates on the idempotency key, like the real gateway. */
class FakeGateway implements PaymentGateway {
  readonly calls: string[] = [];
  readonly payments = new Map<string, SubmissionReceipt>();
  private readonly options: FakeGatewayOptions;

  constructor(options: FakeGatewayOptions = {}) {
    this.options = options;
  }

  async submit(transfer: Transfer, idempotencyKey: string): Promise<SubmissionReceipt> {
    this.calls.push(idempotencyKey);
    if (this.options.decline) {
      throw new GatewayDeclinedError(`transfer ${transfer.id} declined`);
    }
    if (this.options.failFirstCall && this.calls.length === 1) {
      throw new GatewayTimeoutError('gateway timed out before taking the payment');
    }
    let receipt = this.payments.get(idempotencyKey);
    if (receipt === undefined) {
      receipt = {
        transferId: transfer.id,
        reference: `GW-${this.payments.size + 1}`,
        acceptedAt: '2026-03-01T00:00:00.000Z',
      };
      this.payments.set(idempotencyKey, receipt);
    }
    if (this.options.loseFirstResponse && this.calls.length === 1) {
      throw new GatewayTimeoutError('gateway took the payment but the response was lost');
    }
    return receipt;
  }
}

async function submitThrough(gateway: FakeGateway): Promise<string> {
  const result = await submit(TRANSFER, gateway);
  return result.receipt.reference;
}

describe('tier check', () => {
  it('recovers when the gateway times out once', async () => {
    const gateway = new FakeGateway({ failFirstCall: true });

    expect(await submitThrough(gateway), 'the submit path does not retry a timeout').toBe('GW-1');
  });

  it('charges the customer once when a response is lost', async () => {
    const gateway = new FakeGateway({ loseFirstResponse: true });

    const reference = await submitThrough(gateway);
    const charges = gateway.payments.size;

    expect(
      charges,
      `customer charged ${charges} times for ${TRANSFER.id} (keys: ${[...gateway.payments.keys()].join(', ')})`,
    ).toBe(1);
    expect(reference).toBe('GW-1');
  });

  it('does not resubmit a declined transfer', async () => {
    const gateway = new FakeGateway({ decline: true });

    await expect(submitThrough(gateway)).rejects.toThrow();
    expect(gateway.calls.length, `declined transfer sent ${gateway.calls.length} times`).toBe(1);
  });
});
