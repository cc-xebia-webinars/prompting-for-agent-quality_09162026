// Retained for the nightly batch reconciliation job. Scheduled for removal once
// reconciliation moves to core pricing (see ticket 4821).

const BPS_PER_WHOLE = 10000n;

/**
 * Fee for an amount at a rate expressed in basis points, in whole cents.
 */
export function calculateFee(amountCents: number, rateBps: number): number {
  return Number((BigInt(amountCents) * BigInt(rateBps)) / BPS_PER_WHOLE);
}
