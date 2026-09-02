package com.feequote.core;

/**
 * Core fee pricing.
 *
 * <p>Amounts are integer minor units (cents) and rates are integer basis points.
 * Nothing in this class touches binary floating point; the division is done with
 * integers so the result is exact for any amount the ledger can hold.
 */
public final class Pricing {

    /** Basis points in one whole unit, so 10000 bps is 100 percent. */
    public static final int BPS_PER_UNIT = 10_000;

    /** The domestic transfer rate, 90 basis points. */
    public static final int DOMESTIC_RATE_BPS = 90;

    /** Minimum 100 cents, cap 2500 cents. */
    public static final FeePolicy DOMESTIC_POLICY = new FeePolicy(100, 2500);

    private Pricing() {
    }

    /**
     * Divides two non-negative integers and rounds the quotient half to even.
     *
     * <p>This is banker's rounding on an exact rational, so 1111.5 becomes 1112,
     * 1112.5 becomes 1112 and 1111.05 becomes 1111.
     *
     * @param numerator the dividend, which must not be negative
     * @param denominator the divisor, which must be positive
     * @return the quotient rounded half to even
     */
    public static long roundHalfEvenDiv(long numerator, long denominator) {
        if (denominator <= 0) {
            throw new IllegalArgumentException("denominator must be positive");
        }
        if (numerator < 0) {
            throw new IllegalArgumentException("numerator must not be negative");
        }
        long quotient = numerator / denominator;
        long doubledRemainder = (numerator % denominator) * 2;
        if (doubledRemainder > denominator || (doubledRemainder == denominator && quotient % 2 == 1)) {
            return quotient + 1;
        }
        return quotient;
    }

    /**
     * Fee for {@code amountCents} at {@code rateBps}, rounded, then bounded by {@code policy}.
     *
     * <p>This is the building block for every fee type. Rounding happens before the
     * minimum and the cap are applied, so the bounds always win.
     *
     * @param amountCents the transfer amount in cents
     * @param rateBps the rate in basis points
     * @param policy the minimum and cap to apply after rounding
     * @return the fee in whole cents
     */
    public static long priceWithPolicy(long amountCents, int rateBps, FeePolicy policy) {
        if (amountCents < 0) {
            throw new IllegalArgumentException("amountCents must not be negative");
        }
        if (rateBps < 0) {
            throw new IllegalArgumentException("rateBps must not be negative");
        }
        long rawFee = roundHalfEvenDiv(Math.multiplyExact(amountCents, rateBps), BPS_PER_UNIT);
        return policy.apply(rawFee);
    }

    /** Domestic transfer fee: 90 bps under the standard domestic policy. */
    public static long computeFee(long amountCents) {
        return priceWithPolicy(amountCents, DOMESTIC_RATE_BPS, DOMESTIC_POLICY);
    }
}
