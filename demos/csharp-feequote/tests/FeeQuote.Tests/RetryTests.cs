using FeeQuote.Clients;

namespace FeeQuote.Tests;

public class RetryTests
{
    [Fact]
    public void WithRetry_ReturnsFirstSuccessfulResult()
    {
        int calls = 0;

        int result = Retry.WithRetry(() => ++calls, delay: _ => { });

        Assert.Equal(1, result);
        Assert.Equal(1, calls);
    }

    [Fact]
    public void WithRetry_RetriesGatewayFailuresWithDoublingBackoff()
    {
        int calls = 0;
        var waits = new List<int>();

        string result = Retry.WithRetry(
            () => ++calls < 3 ? throw new PaymentGatewayException("timeout") : "ok",
            attempts: 3,
            backoffMs: 100,
            delay: waits.Add);

        Assert.Equal("ok", result);
        Assert.Equal(3, calls);
        Assert.Equal([100, 200], waits);
    }

    [Fact]
    public void WithRetry_GivesUpAfterConfiguredAttempts()
    {
        int calls = 0;

        Assert.Throws<PaymentGatewayException>(() => Retry.WithRetry<int>(
            () => { calls++; throw new PaymentGatewayException("down"); },
            attempts: 3,
            delay: _ => { }));

        Assert.Equal(3, calls);
    }

    [Fact]
    public void WithRetry_DoesNotRetryNonGatewayExceptions()
    {
        int calls = 0;

        Assert.Throws<InvalidOperationException>(() => Retry.WithRetry<int>(
            () => { calls++; throw new InvalidOperationException("bug"); },
            delay: _ => { }));

        Assert.Equal(1, calls);
    }

    [Fact]
    public void WithRetry_DoesNotRetryGatewayFailuresRejectedByTheFilter()
    {
        int calls = 0;
        var waits = new List<int>();

        Assert.Throws<PaymentGatewayException>(() => Retry.WithRetry<int>(
            () => { calls++; throw new PaymentGatewayException("down"); },
            delay: waits.Add,
            shouldRetry: _ => false));

        Assert.Equal(1, calls);
        Assert.Empty(waits);
    }

    [Fact]
    public void WithRetry_RejectsZeroAttempts()
    {
        Assert.Throws<ArgumentOutOfRangeException>(() => Retry.WithRetry(() => 1, attempts: 0));
    }

    [Fact]
    public void WithRetry_RejectsNegativeBackoff()
    {
        Assert.Throws<ArgumentOutOfRangeException>(() => Retry.WithRetry(() => 1, backoffMs: -1));
    }
}
