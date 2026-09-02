import { describe, expect, it } from 'vitest';
import { GatewayUnavailableError, StubPaymentClient } from '../src/clients/paymentClient.js';
import type { Transfer } from '../src/models.js';

const transfer: Transfer = {
  id: 'T-3003',
  amountCents: 100000,
  currency: 'AUD',
  originCountry: 'AU',
  destinationCountry: 'NZ',
  channel: 'api',
};

describe('StubPaymentClient', () => {
  it('returns a receipt and records the submission', async () => {
    const client = new StubPaymentClient({ now: () => new Date('2026-03-01T09:30:00Z') });

    const receipt = await client.submit(transfer, 'key-1');

    expect(receipt).toEqual({
      transferId: 'T-3003',
      reference: 'STUB-000001',
      acceptedAt: '2026-03-01T09:30:00.000Z',
    });
    expect(client.submitted).toEqual([transfer]);
  });

  it('numbers references in submission order', async () => {
    const client = new StubPaymentClient();

    await client.submit(transfer, 'key-1');
    const second = await client.submit({ ...transfer, id: 'T-3004' }, 'key-2');

    expect(second.reference).toBe('STUB-000002');
  });

  it('fails the configured number of times before accepting', async () => {
    const client = new StubPaymentClient({ failuresBeforeSuccess: 2 });

    await expect(client.submit(transfer, 'key-1')).rejects.toBeInstanceOf(GatewayUnavailableError);
    await expect(client.submit(transfer, 'key-1')).rejects.toBeInstanceOf(GatewayUnavailableError);
    await expect(client.submit(transfer, 'key-1')).resolves.toMatchObject({ transferId: 'T-3003' });
  });

  it('does not retry on its own when the gateway is unavailable', async () => {
    const client = new StubPaymentClient({ failuresBeforeSuccess: 1 });

    await expect(client.submit(transfer, 'key-1')).rejects.toBeInstanceOf(GatewayUnavailableError);
    expect(client.submitted).toEqual([]);
  });
});
