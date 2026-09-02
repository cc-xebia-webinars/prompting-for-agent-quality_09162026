// Retained for the nightly batch reconciliation job. Scheduled for removal once
// reconciliation moves to core pricing (see ticket 4821).

namespace FeeQuote.Web.Domain.Legacy;

public static class Fees
{
    /// <summary>
    /// Fee for <paramref name="amountCents"/> at <paramref name="rateBps"/> basis
    /// points, as the batch system has always computed it.
    /// </summary>
    public static long CalculateFee(long amountCents, int rateBps) =>
        amountCents * rateBps / 10_000;
}
