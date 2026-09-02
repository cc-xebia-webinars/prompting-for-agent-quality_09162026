import { describe, expect, it } from 'vitest';
import {
  DOMESTIC_POLICY,
  computeFee,
  priceWithPolicy,
  roundHalfEvenDiv,
  type FeePolicy,
} from '../src/core/pricing.js';

describe('computeFee worked examples', () => {
  it.each([
    ['ticket 4821 rounding', 123500, 1112],
    ['cap applies', 500000, 2500],
    ['minimum applies', 5000, 100],
    ['plain', 100000, 900],
  ])('%s', (_name, amountCents, expected) => {
    expect(computeFee(amountCents)).toBe(expected);
  });
});

describe('roundHalfEvenDiv', () => {
  it('returns an exact quotient unchanged', () => {
    expect(roundHalfEvenDiv(9000000n, 10000n)).toBe(900n);
  });

  it('rounds a tie up when the truncated quotient is odd', () => {
    expect(roundHalfEvenDiv(11115n, 10n)).toBe(1112n);
  });

  it('rounds a tie down when the truncated quotient is even', () => {
    expect(roundHalfEvenDiv(11125n, 10n)).toBe(1112n);
  });

  it('rounds below a half down and above a half up', () => {
    expect(roundHalfEvenDiv(11110500n, 10000n)).toBe(1111n);
    expect(roundHalfEvenDiv(22239000n, 10000n)).toBe(2224n);
  });

  it('keeps half to even symmetric for negative values', () => {
    expect(roundHalfEvenDiv(-11115n, 10n)).toBe(-1112n);
    expect(roundHalfEvenDiv(-11125n, 10n)).toBe(-1112n);
  });

  it('rejects a zero denominator', () => {
    expect(() => roundHalfEvenDiv(1n, 0n)).toThrow(RangeError);
  });
});

describe('priceWithPolicy', () => {
  const wideOpen: FeePolicy = { minimumCents: 0, capCents: Number.MAX_SAFE_INTEGER };

  it('applies an arbitrary rate with half to even rounding', () => {
    expect(priceWithPolicy(247100, 50, wideOpen)).toBe(1236);
  });

  it('applies the minimum and the cap after rounding', () => {
    expect(priceWithPolicy(247100, 50, { minimumCents: 1500, capCents: 2000 })).toBe(1500);
    expect(priceWithPolicy(1000000, 50, { minimumCents: 1500, capCents: 2000 })).toBe(2000);
  });

  it('uses the domestic policy for computeFee', () => {
    expect(computeFee(500000)).toBe(DOMESTIC_POLICY.capCents);
    expect(computeFee(5000)).toBe(DOMESTIC_POLICY.minimumCents);
  });

  it('rejects amounts that are not whole non-negative cents', () => {
    expect(() => priceWithPolicy(12.5, 90, wideOpen)).toThrow(RangeError);
    expect(() => priceWithPolicy(-1, 90, wideOpen)).toThrow(RangeError);
    expect(() => priceWithPolicy(Number.NaN, 90, wideOpen)).toThrow(RangeError);
  });

  it('rejects a policy whose minimum exceeds its cap', () => {
    expect(() => priceWithPolicy(100000, 90, { minimumCents: 5000, capCents: 100 })).toThrow(RangeError);
  });
});
