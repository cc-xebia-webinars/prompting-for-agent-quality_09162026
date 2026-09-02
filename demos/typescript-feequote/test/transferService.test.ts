import { describe, expect, it } from 'vitest';
import { GatewayUnavailableError, StubPaymentClient, type PaymentGateway } from '../src/clients/paymentClient.js';
import { computeFee } from '../src/core/pricing.js';
import type { Transfer } from '../src/models.js';
import { DOMESTIC_FEE_LABEL, quote, submit } from '../src/services/transferService.js';

function domesticTransfer(amountCents: number, id = 'T-1001'): Transfer {
  return {
    id,
    amountCents,
    currency: 'AUD',
    originCountry: 'AU',
    destinationCountry: 'AU',
    channel: 'online',
  };
}

describe('transfer service quote', () => {
  it('regression ticket 4821: domestic fee rounds half to even', () => {
    // The legacy helper returns 1111 here because it truncates. See ticket 4821.
    const result = quote(domesticTransfer(123500));

    expect(result.feeCents, 'domestic fee must round half to even (ticket 4821)').toBe(1112);
    expect(computeFee(123500)).toBe(1112);
  });

  it('adds the fee to the amount for the total', () => {
    const result = quote(domesticTransfer(100000));

    expect(result.feeCents).toBe(900);
    expect(result.totalCents).toBe(100900);
  });

  it('lists the domestic fee as the only breakdown line', () => {
    const result = quote(domesticTransfer(500000, 'T-2002'));

    expect(result.transferId).toBe('T-2002');
    expect(result.breakdown).toEqual([{ label: DOMESTIC_FEE_LABEL, amountCents: 2500 }]);
  });

  it('reports the sum of the breakdown as the fee', () => {
    const result = quote(domesticTransfer(5000));
    const lineTotal = result.breakdown.reduce((sum, line) => sum + line.amountCents, 0);

    expect(result.feeCents).toBe(lineTotal);
  });
});

describe('transfer service submit', () => {
  it('quotes the transfer and then submits it through the gateway', async () => {
    const gateway = new StubPaymentClient({ now: () => new Date('2026-03-01T00:00:00Z') });
    const transfer = domesticTransfer(100000);

    const result = await submit(transfer, gateway);

    expect(result.quote).toEqual(quote(transfer));
    expect(result.receipt).toEqual({
      transferId: 'T-1001',
      reference: 'STUB-000001',
      acceptedAt: '2026-03-01T00:00:00.000Z',
    });
    expect(gateway.submitted).toEqual([transfer]);
  });

  it('sends the gateway an idempotency key', async () => {
    const keys: string[] = [];
    const gateway: PaymentGateway = {
      async submit(transfer, idempotencyKey) {
        keys.push(idempotencyKey);
        return { transferId: transfer.id, reference: 'GW-1', acceptedAt: '2026-03-01T00:00:00.000Z' };
      },
    };

    await submit(domesticTransfer(100000), gateway);

    expect(keys).toHaveLength(1);
    expect(keys[0]).toBeTruthy();
  });

  it('propagates a gateway failure to the caller', async () => {
    const gateway: PaymentGateway = {
      async submit() {
        throw new GatewayUnavailableError();
      },
    };

    await expect(submit(domesticTransfer(100000), gateway)).rejects.toBeInstanceOf(GatewayUnavailableError);
  });
});
