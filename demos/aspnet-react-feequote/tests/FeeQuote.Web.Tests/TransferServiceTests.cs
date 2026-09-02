using FeeQuote.Web.Domain.Clients;
using FeeQuote.Web.Domain.Models;
using FeeQuote.Web.Domain.Services;

namespace FeeQuote.Web.Tests;

public sealed class TransferServiceTests
{
    private readonly RecordingClient _client = new();
    private readonly TransferService _service;

    public TransferServiceTests()
    {
        _service = new TransferService(_client);
    }

    private static Transfer Domestic(long amountCents, string id = "t-1") =>
        new(id, amountCents, "AUD", "AU", "AU", "online");

    [Fact]
    public void Quote_RegressionTicket4821_RoundsHalfToEven()
    {
        // The legacy helper returns 1111 here because it truncates. See ticket 4821.
        var quote = _service.Quote(Domestic(123500));

        Assert.Equal(1112, quote.FeeCents);
    }

    [Fact]
    public void Quote_DomesticTransfer_TotalIsAmountPlusFee()
    {
        var quote = _service.Quote(Domestic(100000));

        Assert.Equal(900, quote.FeeCents);
        Assert.Equal(100900, quote.TotalCents);
    }

    [Fact]
    public void Quote_DomesticTransfer_BreakdownHasSingleDomesticLine()
    {
        var quote = _service.Quote(Domestic(100000));

        var line = Assert.Single(quote.Breakdown);
        Assert.Equal("Domestic fee", line.Label);
        Assert.Equal(900, line.AmountCents);
    }

    [Fact]
    public void Quote_CarriesTransferId()
    {
        var quote = _service.Quote(Domestic(100000, id: "abc-123"));

        Assert.Equal("abc-123", quote.TransferId);
    }

    [Theory]
    [InlineData(0)]
    [InlineData(-500)]
    public void Quote_NonPositiveAmount_Throws(long amountCents)
    {
        var ex = Assert.Throws<ArgumentException>(() => _service.Quote(Domestic(amountCents)));

        Assert.Contains("positive", ex.Message, StringComparison.Ordinal);
    }

    [Fact]
    public void Quote_UnsupportedCurrency_Throws()
    {
        var transfer = Domestic(100000) with { Currency = "XXX" };

        var ex = Assert.Throws<ArgumentException>(() => _service.Quote(transfer));

        Assert.Contains("XXX", ex.Message, StringComparison.Ordinal);
    }

    [Fact]
    public void Quote_UnsupportedCountry_Throws()
    {
        var transfer = Domestic(100000) with { DestinationCountry = "ZZ" };

        Assert.Throws<ArgumentException>(() => _service.Quote(transfer));
    }

    [Fact]
    public void Submit_ValidTransfer_QuotesThenSubmitsOnce()
    {
        var (quote, receipt) = _service.Submit(Domestic(100000));

        Assert.Equal(900, quote.FeeCents);
        Assert.Equal("t-1", receipt.TransferId);
        Assert.Single(_client.Submitted);
    }

    [Fact]
    public void Submit_InvalidTransfer_DoesNotReachGateway()
    {
        Assert.Throws<ArgumentException>(() => _service.Submit(Domestic(0)));

        Assert.Empty(_client.Submitted);
    }

    private sealed class RecordingClient : IPaymentClient
    {
        public List<Transfer> Submitted { get; } = [];

        public SubmissionReceipt Submit(Transfer transfer)
        {
            Submitted.Add(transfer);
            return new SubmissionReceipt(transfer.Id, "PG-TEST", DateTimeOffset.UnixEpoch);
        }
    }
}
