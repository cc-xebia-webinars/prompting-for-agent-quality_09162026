package com.feequote.core;

/**
 * Bounds applied to a fee after it has been rounded to whole cents.
 *
 * @param minimumCents the smallest fee that may be charged
 * @param capCents the largest fee that may be charged
 */
public record FeePolicy(long minimumCents, long capCents) {

    public FeePolicy {
        if (minimumCents < 0) {
            throw new IllegalArgumentException("minimumCents must not be negative");
        }
        if (capCents < minimumCents) {
            throw new IllegalArgumentException("capCents must not be below minimumCents");
        }
    }

    /** Clamps {@code feeCents} into the range [minimumCents, capCents]. */
    public long apply(long feeCents) {
        return Math.max(minimumCents, Math.min(capCents, feeCents));
    }
}
