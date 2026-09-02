using FeeQuote.Core;

namespace FeeQuote.Tests;

/// <summary>
/// Worked examples from the domestic fee policy. The case names match the
/// policy document so a failure can be traced back to the rule it covers.
/// </summary>
public class PricingTests
{
    [Theory]
    [InlineData("ticket 4821 rounding", 123500, 1112)]
    [InlineData("cap applies", 500000, 2500)]
    [InlineData("minimum applies", 5000, 100)]
    [InlineData("plain", 100000, 900)]
    public void ComputeFee_MatchesWorkedExamples(string caseName, long amountCents, long expectedFeeCents)
    {
        long fee = Pricing.ComputeFee(amountCents);

        Assert.True(fee == expectedFeeCents, $"{caseName}: expected {expectedFeeCents} but got {fee}");
    }

    [Theory]
    [InlineData(11115000, 10000, 1112)] // 1111.5 rounds to the even neighbour, up
    [InlineData(11125000, 10000, 1112)] // 1112.5 rounds to the even neighbour, down
    [InlineData(11110500, 10000, 1111)] // 1111.05 is below the midpoint
    [InlineData(11119000, 10000, 1112)] // 1111.9 is above the midpoint
    [InlineData(9000000, 10000, 900)] // exact quotient
    [InlineData(0, 10000, 0)]
    [InlineData(5, 10, 0)] // 0.5 rounds to 0
    [InlineData(15, 10, 2)] // 1.5 rounds to 2
    public void RoundHalfEvenDiv_RoundsMidpointsToEven(long numerator, long denominator, long expected)
    {
        Assert.Equal(expected, Pricing.RoundHalfEvenDiv(numerator, denominator));
    }

    [Fact]
    public void RoundHalfEvenDiv_RejectsNonPositiveDenominator()
    {
        Assert.Throws<ArgumentOutOfRangeException>(() => Pricing.RoundHalfEvenDiv(1, 0));
    }

    [Fact]
    public void PriceWithPolicy_AppliesRateThenMinimumAndCap()
    {
        var policy = new FeePolicy(minimumCents: 50, capCents: 400);

        Assert.Equal(50, Pricing.PriceWithPolicy(1000, 50, policy)); // raw 5, raised to minimum
        Assert.Equal(200, Pricing.PriceWithPolicy(40000, 50, policy)); // raw 200, unchanged
        Assert.Equal(400, Pricing.PriceWithPolicy(1000000, 50, policy)); // raw 5000, capped
    }

    [Fact]
    public void PriceWithPolicy_RoundsBeforeApplyingPolicy()
    {
        var policy = new FeePolicy(minimumCents: 0, capCents: 1236);

        // 247100 at 50 bps is 1235.5; half to even gives 1236, which sits exactly on the cap.
        Assert.Equal(1236, Pricing.PriceWithPolicy(247100, 50, policy));
    }

    [Fact]
    public void PriceWithPolicy_RejectsNegativeAmount()
    {
        Assert.Throws<ArgumentOutOfRangeException>(
            () => Pricing.PriceWithPolicy(-1, Pricing.DomesticRateBps, Pricing.DomesticPolicy));
    }

    [Fact]
    public void DomesticPolicy_HasDocumentedLimits()
    {
        Assert.Equal(100, Pricing.DomesticPolicy.MinimumCents);
        Assert.Equal(2500, Pricing.DomesticPolicy.CapCents);
        Assert.Equal(90, Pricing.DomesticRateBps);
    }

    [Fact]
    public void FeePolicy_RejectsCapBelowMinimum()
    {
        Assert.Throws<ArgumentOutOfRangeException>(() => new FeePolicy(minimumCents: 100, capCents: 99));
    }
}
