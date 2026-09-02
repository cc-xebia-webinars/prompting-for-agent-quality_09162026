using FeeQuote.Clients;
using FeeQuote.Models;

namespace FeeQuote.Tests;

public class PaymentClientTests
{
    private static readonly Transfer Sample = new("abc123", 100000, "AUD", "AU", "AU", "online");

    [Fact]
    public void Submit_ReturnsReceiptForTransfer()
    {
        var client = new PaymentClient();

        SubmissionReceipt receipt = client.Submit(Sample);

        Assert.Equal("abc123", receipt.TransferId);
        Assert.Equal(100000, receipt.AmountCents);
    }

    [Fact]
    public void Submit_DerivesGatewayReferenceFromTransferId()
    {
        var client = new PaymentClient();

        SubmissionReceipt receipt = client.Submit(Sample);

        Assert.Equal("PAY-ABC123", receipt.GatewayReference);
    }

    [Fact]
    public void Submit_UsesTheInjectedTransport()
    {
        var client = new PaymentClient((transfer, _) => $"GW-{transfer.Id}");

        SubmissionReceipt receipt = client.Submit(Sample);

        Assert.Equal("GW-abc123", receipt.GatewayReference);
    }

    [Fact]
    public void Submit_SendsAnIdempotencyKey()
    {
        var keys = new List<string>();
        var client = new PaymentClient((_, idempotencyKey) =>
        {
            keys.Add(idempotencyKey);
            return "GW-1";
        });

        client.Submit(Sample);

        string key = Assert.Single(keys);
        Assert.False(string.IsNullOrWhiteSpace(key));
    }

    [Fact]
    public void Submit_RejectsNullTransfer()
    {
        var client = new PaymentClient();

        Assert.Throws<ArgumentNullException>(() => client.Submit(null!));
    }
}
