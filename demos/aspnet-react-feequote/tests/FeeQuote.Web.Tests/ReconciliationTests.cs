using FeeQuote.Web.Domain.Jobs;
using FeeQuote.Web.Domain.Legacy;

namespace FeeQuote.Web.Tests;

public sealed class ReconciliationTests
{
    private static readonly BatchLine[] Batch =
    [
        new("b-1", 123500),
        new("b-2", 500000),
        new("b-3", 5000),
        new("b-4", 100000),
    ];

    [Fact]
    public void HistoricalFeeTotal_ReproducesBatchArithmetic()
    {
        // The batch system truncates and applies no floor or cap:
        // 1111 + 4500 + 45 + 900. The reconciliation job must match it exactly.
        var total = Reconciliation.HistoricalFeeTotal(Batch, rateBps: 90);

        Assert.Equal(6556, total);
    }

    [Fact]
    public void Reconcile_MatchingTotal_IsBalanced()
    {
        var result = Reconciliation.Reconcile(Batch, rateBps: 90, reportedFeeCents: 6556);

        Assert.True(result.IsBalanced);
        Assert.Equal(0, result.DifferenceCents);
    }

    [Fact]
    public void Reconcile_ReportedTotalHigher_ShowsPositiveDifference()
    {
        var result = Reconciliation.Reconcile(Batch, rateBps: 90, reportedFeeCents: 6600);

        Assert.False(result.IsBalanced);
        Assert.Equal(44, result.DifferenceCents);
    }

    [Theory]
    [InlineData(123500, 1111)]
    [InlineData(500000, 4500)]
    [InlineData(5000, 45)]
    [InlineData(100000, 900)]
    public void LegacyCalculateFee_TruncatesAndIgnoresPolicy(long amountCents, long expected)
    {
        Assert.Equal(expected, Fees.CalculateFee(amountCents, 90));
    }
}
