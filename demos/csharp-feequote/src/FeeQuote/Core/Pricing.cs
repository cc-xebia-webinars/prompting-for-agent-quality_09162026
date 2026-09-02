namespace FeeQuote.Core;

/// <summary>
/// Limits applied to a fee after rounding. The fee is raised to
/// <see cref="MinimumCents"/> and lowered to <see cref="CapCents"/>.
/// </summary>
public sealed record FeePolicy
{
    public FeePolicy(long minimumCents, long capCents)
    {
        if (minimumCents < 0)
        {
            throw new ArgumentOutOfRangeException(nameof(minimumCents), "Minimum fee must not be negative.");
        }

        if (capCents < minimumCents)
        {
            throw new ArgumentOutOfRangeException(nameof(capCents), "Cap must not be below the minimum fee.");
        }

        MinimumCents = minimumCents;
        CapCents = capCents;
    }

    public long MinimumCents { get; }

    public long CapCents { get; }
}

/// <summary>
/// Fee arithmetic shared by every fee type. All inputs and outputs are whole
/// cents; the only division happens in <see cref="RoundHalfEvenDiv"/> so the
/// rounding rule is applied in exactly one place.
/// </summary>
public static class Pricing
{
    /// <summary>Basis points in one whole unit (100 percent).</summary>
    public const int BasisPointsPerUnit = 10_000;

    /// <summary>Rate for the domestic transfer fee.</summary>
    public const int DomesticRateBps = 90;

    /// <summary>Minimum and cap for the domestic transfer fee.</summary>
    public static FeePolicy DomesticPolicy { get; } = new(minimumCents: 100, capCents: 2_500);

    /// <summary>
    /// Divides <paramref name="numerator"/> by <paramref name="denominator"/> and
    /// rounds the quotient half to even (banker's rounding). Both inputs are
    /// integers so the midpoint test is exact.
    /// </summary>
    public static long RoundHalfEvenDiv(long numerator, long denominator)
    {
        if (numerator < 0)
        {
            throw new ArgumentOutOfRangeException(nameof(numerator), "Numerator must not be negative.");
        }

        if (denominator <= 0)
        {
            throw new ArgumentOutOfRangeException(nameof(denominator), "Denominator must be positive.");
        }

        long quotient = numerator / denominator;
        long twiceRemainder = (numerator % denominator) * 2;

        if (twiceRemainder > denominator)
        {
            return quotient + 1;
        }

        if (twiceRemainder < denominator)
        {
            return quotient;
        }

        // Exactly halfway: round to the even neighbour.
        return quotient % 2 == 0 ? quotient : quotient + 1;
    }

    /// <summary>
    /// Prices an amount at <paramref name="rateBps"/> basis points, rounds half
    /// to even, then applies the policy minimum and cap in that order.
    /// </summary>
    public static long PriceWithPolicy(long amountCents, int rateBps, FeePolicy policy)
    {
        ArgumentNullException.ThrowIfNull(policy);

        if (amountCents < 0)
        {
            throw new ArgumentOutOfRangeException(nameof(amountCents), "Amount must not be negative.");
        }

        if (rateBps < 0)
        {
            throw new ArgumentOutOfRangeException(nameof(rateBps), "Rate must not be negative.");
        }

        long rounded = RoundHalfEvenDiv(checked(amountCents * rateBps), BasisPointsPerUnit);
        return Math.Clamp(rounded, policy.MinimumCents, policy.CapCents);
    }

    /// <summary>The domestic transfer fee for an amount.</summary>
    public static long ComputeFee(long amountCents)
    {
        return PriceWithPolicy(amountCents, DomesticRateBps, DomesticPolicy);
    }
}
