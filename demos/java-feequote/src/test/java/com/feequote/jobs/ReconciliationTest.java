package com.feequote.jobs;

import static org.assertj.core.api.Assertions.assertThat;

import com.feequote.jobs.Reconciliation.BatchLine;
import com.feequote.jobs.Reconciliation.ReconciliationReport;
import java.util.List;
import org.junit.jupiter.api.Test;

class ReconciliationTest {

    @Test
    void expectedFeeReproducesTheTruncatingBatchArithmetic() {
        // The batch system books 1111 for this line; core pricing would say 1112.
        assertThat(Reconciliation.expectedFee(new BatchLine("tr-1", 123500, 90, 1111))).isEqualTo(1111);
    }

    @Test
    void expectedFeeIgnoresTheDomesticMinimumAndCap() {
        assertThat(Reconciliation.expectedFee(new BatchLine("tr-2", 5000, 90, 45))).isEqualTo(45);
        assertThat(Reconciliation.expectedFee(new BatchLine("tr-3", 500000, 90, 4500))).isEqualTo(4500);
    }

    @Test
    void aBatchThatAgreesIsBalanced() {
        ReconciliationReport report = Reconciliation.reconcile(List.of(
                new BatchLine("tr-1", 123500, 90, 1111),
                new BatchLine("tr-2", 100000, 90, 900)));

        assertThat(report.lineCount()).isEqualTo(2);
        assertThat(report.expectedTotalCents()).isEqualTo(2011);
        assertThat(report.bookedTotalCents()).isEqualTo(2011);
        assertThat(report.isBalanced()).isTrue();
        assertThat(report.mismatchedTransferIds()).isEmpty();
    }

    @Test
    void aBatchThatDisagreesNamesTheOffendingTransfers() {
        ReconciliationReport report = Reconciliation.reconcile(List.of(
                new BatchLine("tr-1", 123500, 90, 1112),
                new BatchLine("tr-2", 100000, 90, 900)));

        assertThat(report.isBalanced()).isFalse();
        assertThat(report.mismatchedTransferIds()).containsExactly("tr-1");
        assertThat(report.expectedTotalCents()).isEqualTo(2011);
        assertThat(report.bookedTotalCents()).isEqualTo(2012);
    }

    @Test
    void anEmptyBatchIsBalanced() {
        ReconciliationReport report = Reconciliation.reconcile(List.of());

        assertThat(report.lineCount()).isZero();
        assertThat(report.expectedTotalCents()).isZero();
        assertThat(report.isBalanced()).isTrue();
    }
}
