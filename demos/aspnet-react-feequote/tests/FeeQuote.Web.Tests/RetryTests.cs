using FeeQuote.Web.Domain.Clients;

namespace FeeQuote.Web.Tests;

public sealed class RetryTests
{
    [Fact]
    public void WithRetry_SucceedsFirstTime_DoesNotWait()
    {
        var waits = new List<int>();

        var result = Retry.WithRetry(() => 42, delay: waits.Add);

        Assert.Equal(42, result);
        Assert.Empty(waits);
    }

    [Fact]
    public void WithRetry_TransientFailures_BacksOffExponentially()
    {
        var waits = new List<int>();
        var calls = 0;

        var result = Retry.WithRetry(
            () => ++calls < 3 ? throw new GatewayUnavailableException("busy") : "ok",
            attempts: 3,
            backoffMs: 100,
            delay: waits.Add);

        Assert.Equal("ok", result);
        Assert.Equal(3, calls);
        Assert.Equal([100, 200], waits);
    }

    [Fact]
    public void WithRetry_ExhaustsAttempts_RethrowsLastFailure()
    {
        var calls = 0;

        Assert.Throws<GatewayUnavailableException>(() => Retry.WithRetry<int>(
            () => { calls++; throw new GatewayUnavailableException("busy"); },
            attempts: 3,
            delay: _ => { }));

        Assert.Equal(3, calls);
    }

    [Fact]
    public void WithRetry_NonTransientFailure_IsNotRetried()
    {
        var calls = 0;

        Assert.Throws<InvalidOperationException>(() => Retry.WithRetry<int>(
            () => { calls++; throw new InvalidOperationException("rejected"); },
            delay: _ => { }));

        Assert.Equal(1, calls);
    }

    [Fact]
    public void WithRetry_FailureRejectedByFilter_IsNotRetried()
    {
        var waits = new List<int>();
        var calls = 0;

        Assert.Throws<GatewayUnavailableException>(() => Retry.WithRetry<int>(
            () => { calls++; throw new GatewayUnavailableException("busy"); },
            delay: waits.Add,
            shouldRetry: _ => false));

        Assert.Equal(1, calls);
        Assert.Empty(waits);
    }

    [Fact]
    public void WithRetry_ZeroAttempts_IsRejected()
    {
        Assert.Throws<ArgumentOutOfRangeException>(() => Retry.WithRetry(() => 1, attempts: 0));
    }
}
