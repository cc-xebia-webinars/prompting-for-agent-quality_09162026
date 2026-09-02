using FeeQuote.Jobs;
using FeeQuote.Models;

namespace FeeQuote.Tests;

public class ReconciliationTests
{
    private static Transfer Archived(string id, long amountCents)
    {
        return new Transfer(id, amountCents, "AUD", "AU", "AU", "branch");
    }

    [Fact]
    public void HistoricalFeeTotal_ReproducesArchivedTruncatedFees()
    {
        // 123500 was archived as 1111 (truncated) and 5000 as 45 (no minimum applied).
        Transfer[] batch = [Archived("b1", 123500), Archived("b2", 5000), Archived("b3", 100000)];

        long total = Reconciliation.HistoricalFeeTotal(batch);

        Assert.Equal(1111 + 45 + 900, total);
    }

    [Fact]
    public void HistoricalFeeTotal_OfEmptyBatchIsZero()
    {
        Assert.Equal(0, Reconciliation.HistoricalFeeTotal([]));
    }

    [Fact]
    public void Reconcile_IsBalancedWhenRecordedTotalMatches()
    {
        Transfer[] batch = [Archived("b1", 123500), Archived("b2", 100000)];

        ReconciliationResult result = Reconciliation.Reconcile("2024-06-30", batch, recordedFeeCents: 2011);

        Assert.True(result.IsBalanced);
        Assert.Equal(0, result.DifferenceCents);
        Assert.Equal("2024-06-30", result.BatchId);
    }

    [Fact]
    public void Reconcile_ReportsSignedDifferenceWhenRecordedTotalDiffers()
    {
        Transfer[] batch = [Archived("b1", 123500)];

        ReconciliationResult result = Reconciliation.Reconcile("2024-07-01", batch, recordedFeeCents: 1112);

        Assert.False(result.IsBalanced);
        Assert.Equal(1111, result.ExpectedFeeCents);
        Assert.Equal(1, result.DifferenceCents);
    }
}
