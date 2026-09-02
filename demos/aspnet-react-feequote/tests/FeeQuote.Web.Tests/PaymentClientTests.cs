using FeeQuote.Web.Domain.Clients;
using FeeQuote.Web.Domain.Models;

namespace FeeQuote.Web.Tests;

public sealed class PaymentClientTests
{
    private static readonly Transfer Sample = new("t-9", 100000, "AUD", "AU", "AU", "online");

    [Fact]
    public void Submit_ReturnsReceiptForTransfer()
    {
        var clock = new FixedClock(new DateTimeOffset(2024, 3, 1, 9, 30, 0, TimeSpan.Zero));
        var client = new PaymentClient(clock);

        var receipt = client.Submit(Sample);

        Assert.Equal("t-9", receipt.TransferId);
        Assert.StartsWith("PG-", receipt.Reference, StringComparison.Ordinal);
        Assert.Equal(clock.GetUtcNow(), receipt.AcceptedAt);
    }

    [Fact]
    public void Submit_MintsDistinctReferences()
    {
        var client = new PaymentClient();

        var first = client.Submit(Sample);
        var second = client.Submit(Sample);

        Assert.NotEqual(first.Reference, second.Reference);
    }

    [Fact]
    public void Submit_SendsThroughTransportWithIdempotencyKey()
    {
        var keys = new List<string>();
        var client = new PaymentClient(TimeProvider.System, (transfer, idempotencyKey) =>
        {
            keys.Add(idempotencyKey);
            return $"GW-{transfer.Id}";
        });

        var receipt = client.Submit(Sample);

        Assert.Equal("GW-t-9", receipt.Reference);
        var key = Assert.Single(keys);
        Assert.False(string.IsNullOrEmpty(key));
    }

    [Fact]
    public void Submit_NullTransfer_Throws()
    {
        var client = new PaymentClient();

        Assert.Throws<ArgumentNullException>(() => client.Submit(null!));
    }

    private sealed class FixedClock : TimeProvider
    {
        private readonly DateTimeOffset _now;

        public FixedClock(DateTimeOffset now)
        {
            _now = now;
        }

        public override DateTimeOffset GetUtcNow() => _now;
    }
}
