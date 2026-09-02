package com.feequote.legacy;

/**
 * Retained for the nightly batch reconciliation job. Scheduled for removal once
 * reconciliation moves to core pricing (see ticket 4821).
 */
public final class Fees {

    private Fees() {
    }

    /** Fee at {@code rateBps} for {@code amountCents}, truncated to whole cents. */
    public static long calculateFee(long amountCents, int rateBps) {
        return amountCents * rateBps / 10_000;
    }
}
