using FeeQuote.Clients;
using FeeQuote.Models;
using FeeQuote.Services;

namespace FeeQuote.Tests;

public class TransferServiceTests
{
    private static Transfer DomesticTransfer(long amountCents, string id = "t-1")
    {
        return new Transfer(id, amountCents, "AUD", "AU", "AU", "online");
    }

    [Fact]
    public void Quote_UsesHalfEvenRounding_RegressionTicket4821()
    {
        var service = new TransferService(new PaymentClient());

        Quote quote = service.Quote(DomesticTransfer(123500));

        // The legacy helper returns 1111 here because it truncates. See ticket 4821.
        Assert.Equal(1112, quote.FeeCents);
    }

    [Fact]
    public void Quote_TotalIsPrincipalPlusFee()
    {
        var service = new TransferService(new PaymentClient());

        Quote quote = service.Quote(DomesticTransfer(100000));

        Assert.Equal(900, quote.FeeCents);
        Assert.Equal(100900, quote.TotalCents);
    }

    [Fact]
    public void Quote_BreakdownHasSingleDomesticLineMatchingFee()
    {
        var service = new TransferService(new PaymentClient());

        Quote quote = service.Quote(DomesticTransfer(100000, id: "t-breakdown"));

        BreakdownLine line = Assert.Single(quote.Breakdown);
        Assert.Equal("Domestic fee", line.Label);
        Assert.Equal(quote.FeeCents, line.AmountCents);
        Assert.Equal("t-breakdown", quote.TransferId);
    }

    [Fact]
    public void Quote_RejectsUnknownCurrency()
    {
        var service = new TransferService(new PaymentClient());
        Transfer transfer = DomesticTransfer(100000) with { Currency = "XXX" };

        ArgumentException ex = Assert.Throws<ArgumentException>(() => service.Quote(transfer));

        Assert.Contains("currency", ex.Message, StringComparison.Ordinal);
    }

    [Fact]
    public void Quote_RejectsNonPositiveAmount()
    {
        var service = new TransferService(new PaymentClient());

        Assert.Throws<ArgumentException>(() => service.Quote(DomesticTransfer(0)));
    }

    [Fact]
    public void Submit_QuotesThenSubmitsThroughClient()
    {
        var client = new RecordingClient();
        var service = new TransferService(client);
        Transfer transfer = DomesticTransfer(100000, id: "t-submit");

        SubmittedTransfer result = service.Submit(transfer);

        Assert.Same(transfer, Assert.Single(client.Submitted));
        Assert.Equal(900, result.Quote.FeeCents);
        Assert.Equal("t-submit", result.Receipt.TransferId);
    }

    [Fact]
    public void Submit_DoesNotReachClientWhenValidationFails()
    {
        var client = new RecordingClient();
        var service = new TransferService(client);
        Transfer transfer = DomesticTransfer(100000) with { DestinationCountry = "ZZ" };

        Assert.Throws<ArgumentException>(() => service.Submit(transfer));

        Assert.Empty(client.Submitted);
    }

    private sealed class RecordingClient : IPaymentClient
    {
        public List<Transfer> Submitted { get; } = [];

        public SubmissionReceipt Submit(Transfer transfer)
        {
            Submitted.Add(transfer);
            return new SubmissionReceipt(transfer.Id, "TEST-REF", transfer.AmountCents);
        }
    }
}
