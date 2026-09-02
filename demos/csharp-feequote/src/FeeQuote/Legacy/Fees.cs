// Retained for the nightly batch reconciliation job. Scheduled for removal once
// reconciliation moves to core pricing (see ticket 4821).

namespace FeeQuote.Legacy;

public static class Fees
{
    /// <summary>Applies a basis-point rate to an amount and returns whole cents.</summary>
    public static long CalculateFee(long amountCents, int rateBps)
    {
        return amountCents * rateBps / 10_000;
    }
}
