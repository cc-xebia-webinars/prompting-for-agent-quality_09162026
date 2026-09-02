using FeeQuote.Web.Domain.Clients;
using FeeQuote.Web.Domain.Config;
using FeeQuote.Web.Domain.Core;
using FeeQuote.Web.Domain.Models;

namespace FeeQuote.Web.Domain.Services;

/// <summary>
/// Quotes and submits transfers. Pricing decisions are delegated to
/// <see cref="Pricing"/>; this class only assembles the breakdown and talks to
/// the gateway.
/// </summary>
public sealed class TransferService
{
    private readonly IPaymentClient _client;

    public TransferService(IPaymentClient client)
    {
        _client = client;
    }

    /// <summary>Prices a transfer without submitting it.</summary>
    /// <exception cref="ArgumentException">The transfer fails validation.</exception>
    public Quote Quote(Transfer transfer)
    {
        Validate(transfer);

        var domesticFee = Pricing.ComputeFee(transfer.AmountCents);
        var breakdown = new List<BreakdownLine>
        {
            new("Domestic fee", domesticFee),
        };
        var feeCents = breakdown.Sum(line => line.AmountCents);

        return new Quote(transfer.Id, feeCents, transfer.AmountCents + feeCents, breakdown);
    }

    /// <summary>Prices a transfer and, if it is valid, sends it to the gateway.</summary>
    public (Quote Quote, SubmissionReceipt Receipt) Submit(Transfer transfer)
    {
        var quote = Quote(transfer);
        var receipt = _client.Submit(transfer);
        return (quote, receipt);
    }

    private static void Validate(Transfer transfer)
    {
        ArgumentNullException.ThrowIfNull(transfer);

        if (string.IsNullOrWhiteSpace(transfer.Id))
        {
            throw new ArgumentException("Transfer id is required.", nameof(transfer));
        }

        if (transfer.AmountCents <= 0)
        {
            throw new ArgumentException("Amount must be a positive number of cents.", nameof(transfer));
        }

        if (!Settings.Currencies.Contains(transfer.Currency))
        {
            throw new ArgumentException($"Unsupported currency '{transfer.Currency}'.", nameof(transfer));
        }

        if (!Settings.Countries.Contains(transfer.OriginCountry))
        {
            throw new ArgumentException($"Unsupported origin country '{transfer.OriginCountry}'.", nameof(transfer));
        }

        if (!Settings.Countries.Contains(transfer.DestinationCountry))
        {
            throw new ArgumentException($"Unsupported destination country '{transfer.DestinationCountry}'.", nameof(transfer));
        }

        if (!Settings.Channels.Contains(transfer.Channel))
        {
            throw new ArgumentException($"Unsupported channel '{transfer.Channel}'.", nameof(transfer));
        }
    }
}
