// Core pricing. A fee is a rate in basis points applied to an amount in integer
// cents, rounded half to even, then held within a FeePolicy (minimum and cap).
//
// Amounts cross the public API as safe integers because that is what the rest
// of the codebase and JSON handle naturally. The division itself runs in bigint
// so no intermediate value is ever a binary float.

export interface FeePolicy {
  readonly minimumCents: number;
  readonly capCents: number;
}

export const DOMESTIC_RATE_BPS = 90;

export const DOMESTIC_POLICY: FeePolicy = Object.freeze({
  minimumCents: 100,
  capCents: 2500,
});

const BPS_PER_WHOLE = 10000n;

function assertCents(value: number, name: string): void {
  if (!Number.isSafeInteger(value) || value < 0) {
    throw new RangeError(`${name} must be a non-negative integer number of cents, got ${value}`);
  }
}

/**
 * Integer division that rounds the exact quotient half to even (banker's
 * rounding). Ties go to the even neighbour, so 1111.5 becomes 1112 and 1112.5
 * also becomes 1112.
 */
export function roundHalfEvenDiv(numerator: bigint, denominator: bigint): bigint {
  if (denominator === 0n) {
    throw new RangeError('denominator must not be zero');
  }
  const negative = numerator < 0n !== denominator < 0n;
  const n = numerator < 0n ? -numerator : numerator;
  const d = denominator < 0n ? -denominator : denominator;

  let quotient = n / d;
  const twiceRemainder = (n % d) * 2n;
  if (twiceRemainder > d || (twiceRemainder === d && quotient % 2n === 1n)) {
    quotient += 1n;
  }
  return negative ? -quotient : quotient;
}

/**
 * Prices an amount at a rate in basis points under a policy. The raw fee is
 * rounded first; the minimum and the cap are applied to the rounded value.
 * Every fee type in FeeQuote is built on this function.
 */
export function priceWithPolicy(amountCents: number, rateBps: number, policy: FeePolicy): number {
  assertCents(amountCents, 'amountCents');
  if (!Number.isSafeInteger(rateBps) || rateBps < 0) {
    throw new RangeError(`rateBps must be a non-negative integer, got ${rateBps}`);
  }
  if (policy.minimumCents > policy.capCents) {
    throw new RangeError('policy minimum must not exceed its cap');
  }

  const rounded = Number(roundHalfEvenDiv(BigInt(amountCents) * BigInt(rateBps), BPS_PER_WHOLE));
  if (rounded < policy.minimumCents) {
    return policy.minimumCents;
  }
  if (rounded > policy.capCents) {
    return policy.capCents;
  }
  return rounded;
}

/** The domestic transfer fee. */
export function computeFee(amountCents: number): number {
  return priceWithPolicy(amountCents, DOMESTIC_RATE_BPS, DOMESTIC_POLICY);
}
