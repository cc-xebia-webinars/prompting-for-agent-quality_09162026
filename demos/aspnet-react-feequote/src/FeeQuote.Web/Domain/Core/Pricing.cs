namespace FeeQuote.Web.Domain.Core;

/// <summary>Floor and ceiling applied to a fee after rounding.</summary>
public sealed record FeePolicy(long MinimumCents, long CapCents);

/// <summary>
/// Core pricing. Every fee the service charges is computed here so that the
/// rounding rule and the policy order (round, then minimum, then cap) are
/// applied identically for every fee type.
/// </summary>
public static class Pricing
{
    /// <summary>Domestic transfer rate in basis points.</summary>
    public const int DomesticRateBps = 90;

    /// <summary>Domestic transfer floor and ceiling, in cents.</summary>
    public static FeePolicy DomesticPolicy { get; } = new(MinimumCents: 100, CapCents: 2500);

    /// <summary>
    /// Divides <paramref name="numerator"/> by <paramref name="denominator"/> and
    /// rounds the quotient half to even (banker's rounding). Both arguments are
    /// integers so the result is exact; no intermediate floating point.
    /// </summary>
    public static long RoundHalfEvenDiv(long numerator, long denominator)
    {
        ArgumentOutOfRangeException.ThrowIfNegative(numerator);
        ArgumentOutOfRangeException.ThrowIfNegativeOrZero(denominator);

        var quotient = numerator / denominator;
        var remainder = numerator % denominator;
        var twiceRemainder = remainder * 2;

        if (twiceRemainder > denominator)
        {
            return quotient + 1;
        }

        if (twiceRemainder == denominator && quotient % 2 != 0)
        {
            return quotient + 1;
        }

        return quotient;
    }

    /// <summary>
    /// Prices <paramref name="amountCents"/> at <paramref name="rateBps"/> basis
    /// points, rounds half to even, then applies the policy minimum and cap.
    /// This is the building block for every fee type.
    /// </summary>
    public static long PriceWithPolicy(long amountCents, int rateBps, FeePolicy policy)
    {
        ArgumentNullException.ThrowIfNull(policy);
        ArgumentOutOfRangeException.ThrowIfNegative(amountCents);
        ArgumentOutOfRangeException.ThrowIfNegative(rateBps);

        var rounded = RoundHalfEvenDiv(amountCents * rateBps, 10_000);
        return Math.Min(Math.Max(rounded, policy.MinimumCents), policy.CapCents);
    }

    /// <summary>The domestic transfer fee for <paramref name="amountCents"/>.</summary>
    public static long ComputeFee(long amountCents) =>
        PriceWithPolicy(amountCents, DomesticRateBps, DomesticPolicy);
}
