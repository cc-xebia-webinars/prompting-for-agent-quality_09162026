using FeeQuote.Web.Domain.Legacy;

namespace FeeQuote.Web.Domain.Jobs;

/// <summary>One settled transfer as it appears in the nightly batch file.</summary>
public sealed record BatchLine(string TransferId, long AmountCents);

/// <summary>Outcome of comparing our recomputed fee total with the batch file's total.</summary>
public sealed record ReconciliationResult(long ExpectedFeeCents, long ReportedFeeCents)
{
    public long DifferenceCents => ReportedFeeCents - ExpectedFeeCents;

    public bool IsBalanced => DifferenceCents == 0;
}

/// <summary>
/// Reproduces historical batch fee totals. The batch system truncates fees and
/// applies no floor or cap, so this job must use the same arithmetic it did or
/// every historical batch would show a spurious difference.
/// </summary>
public static class Reconciliation
{
    public static long HistoricalFeeTotal(IEnumerable<BatchLine> lines, int rateBps)
    {
        ArgumentNullException.ThrowIfNull(lines);
        return lines.Sum(line => Fees.CalculateFee(line.AmountCents, rateBps));
    }

    public static ReconciliationResult Reconcile(IEnumerable<BatchLine> lines, int rateBps, long reportedFeeCents)
    {
        var expected = HistoricalFeeTotal(lines, rateBps);
        return new ReconciliationResult(expected, reportedFeeCents);
    }
}
