package com.feequote.jobs;

import com.feequote.legacy.Fees;
import java.util.ArrayList;
import java.util.List;

/**
 * Nightly batch reconciliation.
 *
 * <p>Recomputes the fee on every line of a settled batch the way the batch system
 * booked it and reports the lines that do not agree. The batch system still books
 * fees with the legacy truncating helper, so this job has to use the same helper to
 * reproduce historical totals. Ticket 4821 tracks moving both sides to core pricing.
 */
public final class Reconciliation {

    /**
     * One settled transfer as recorded by the batch system.
     *
     * @param transferId the transfer reference
     * @param amountCents the settled amount in cents
     * @param rateBps the rate the batch system applied
     * @param bookedFeeCents the fee the batch system actually booked
     */
    public record BatchLine(String transferId, long amountCents, int rateBps, long bookedFeeCents) {
    }

    /**
     * What a whole batch looked like once recomputed.
     *
     * @param lineCount how many lines were checked
     * @param expectedTotalCents the total the recomputation produced
     * @param bookedTotalCents the total the batch system booked
     * @param mismatchedTransferIds the transfers whose booked fee did not agree
     */
    public record ReconciliationReport(
            int lineCount,
            long expectedTotalCents,
            long bookedTotalCents,
            List<String> mismatchedTransferIds) {

        public ReconciliationReport {
            mismatchedTransferIds = List.copyOf(mismatchedTransferIds);
        }

        public boolean isBalanced() {
            return mismatchedTransferIds.isEmpty();
        }
    }

    private Reconciliation() {
    }

    /** The fee the batch system should have booked for {@code line}. */
    public static long expectedFee(BatchLine line) {
        return Fees.calculateFee(line.amountCents(), line.rateBps());
    }

    /** Compares booked fees against recomputed fees for a whole batch. */
    public static ReconciliationReport reconcile(Iterable<BatchLine> lines) {
        int lineCount = 0;
        long expectedTotal = 0;
        long bookedTotal = 0;
        List<String> mismatches = new ArrayList<>();
        for (BatchLine line : lines) {
            lineCount++;
            long expected = expectedFee(line);
            expectedTotal += expected;
            bookedTotal += line.bookedFeeCents();
            if (expected != line.bookedFeeCents()) {
                mismatches.add(line.transferId());
            }
        }
        return new ReconciliationReport(lineCount, expectedTotal, bookedTotal, mismatches);
    }
}
