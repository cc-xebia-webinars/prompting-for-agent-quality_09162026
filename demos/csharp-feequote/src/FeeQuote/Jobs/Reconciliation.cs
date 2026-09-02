using FeeQuote.Legacy;
using FeeQuote.Models;

namespace FeeQuote.Jobs;

/// <summary>Outcome of comparing a recomputed batch fee total with the recorded one.</summary>
public sealed record ReconciliationResult(string BatchId, long ExpectedFeeCents, long RecordedFeeCents)
{
    public long DifferenceCents => RecordedFeeCents - ExpectedFeeCents;

    public bool IsBalanced => DifferenceCents == 0;
}

/// <summary>
/// Nightly check that the fee total recorded for a settled batch matches what
/// the batch should have been charged. Batches in the archive were priced with
/// the legacy helper, so the same arithmetic is used here to reproduce their
/// totals exactly; using the current rounding rule would report spurious
/// one-cent differences on almost every batch.
/// </summary>
public static class Reconciliation
{
    /// <summary>Rate the archived batches were priced at.</summary>
    public const int HistoricalRateBps = 90;

    /// <summary>Recomputes the fee total for a batch using the archive's arithmetic.</summary>
    public static long HistoricalFeeTotal(IEnumerable<Transfer> batch, int rateBps = HistoricalRateBps)
    {
        ArgumentNullException.ThrowIfNull(batch);

        long total = 0;
        foreach (Transfer transfer in batch)
        {
            total = checked(total + Fees.CalculateFee(transfer.AmountCents, rateBps));
        }

        return total;
    }

    /// <summary>Compares the recorded fee total for a batch with the recomputed one.</summary>
    public static ReconciliationResult Reconcile(string batchId, IEnumerable<Transfer> batch, long recordedFeeCents)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(batchId);
        return new ReconciliationResult(batchId, HistoricalFeeTotal(batch), recordedFeeCents);
    }
}
