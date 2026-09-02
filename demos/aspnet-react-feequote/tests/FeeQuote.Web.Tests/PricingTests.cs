using FeeQuote.Web.Domain.Core;

namespace FeeQuote.Web.Tests;

public sealed class PricingTests
{
    // Worked examples from the domestic fee policy. Keep the names and values as
    // they appear in the policy document so a failure is easy to talk about.
    [Theory]
    [InlineData("ticket 4821 rounding", 123500, 1112)]
    [InlineData("cap applies", 500000, 2500)]
    [InlineData("minimum applies", 5000, 100)]
    [InlineData("plain", 100000, 900)]
    public void ComputeFee_WorkedExamples(string caseName, long amountCents, long expectedFeeCents)
    {
        Assert.NotEmpty(caseName);

        Assert.Equal(expectedFeeCents, Pricing.ComputeFee(amountCents));
    }

    [Theory]
    [InlineData(7, 2, 4)]     // 3.5 rounds up to the even neighbour
    [InlineData(5, 2, 2)]     // 2.5 rounds down to the even neighbour
    [InlineData(1, 2, 0)]     // 0.5 rounds to zero
    [InlineData(11, 4, 3)]    // 2.75 is above the midpoint
    [InlineData(9, 4, 2)]     // 2.25 is below the midpoint
    [InlineData(12, 4, 3)]    // exact division is untouched
    public void RoundHalfEvenDiv_RoundsQuotientHalfToEven(long numerator, long denominator, long expected)
    {
        Assert.Equal(expected, Pricing.RoundHalfEvenDiv(numerator, denominator));
    }

    [Fact]
    public void RoundHalfEvenDiv_ZeroDenominator_Throws()
    {
        Assert.Throws<ArgumentOutOfRangeException>(() => Pricing.RoundHalfEvenDiv(1, 0));
    }

    [Fact]
    public void PriceWithPolicy_AppliesRoundingBeforeMinimumAndCap()
    {
        var policy = new FeePolicy(MinimumCents: 10, CapCents: 1000);

        // 123450 * 25 / 10000 = 308.625, rounds to 309, inside the policy band.
        Assert.Equal(309, Pricing.PriceWithPolicy(123450, 25, policy));
        // 2000 * 25 / 10000 = 5, lifted to the minimum.
        Assert.Equal(10, Pricing.PriceWithPolicy(2000, 25, policy));
        // 1000000 * 25 / 10000 = 2500, held at the cap.
        Assert.Equal(1000, Pricing.PriceWithPolicy(1000000, 25, policy));
    }

    [Fact]
    public void PriceWithPolicy_ZeroAmount_ReturnsMinimum()
    {
        Assert.Equal(100, Pricing.PriceWithPolicy(0, 90, Pricing.DomesticPolicy));
    }

    [Fact]
    public void PriceWithPolicy_NegativeAmount_Throws()
    {
        Assert.Throws<ArgumentOutOfRangeException>(
            () => Pricing.PriceWithPolicy(-1, 90, Pricing.DomesticPolicy));
    }

    [Fact]
    public void DomesticPolicy_MatchesPublishedFeeSchedule()
    {
        Assert.Equal(90, Pricing.DomesticRateBps);
        Assert.Equal(100, Pricing.DomesticPolicy.MinimumCents);
        Assert.Equal(2500, Pricing.DomesticPolicy.CapCents);
    }
}
