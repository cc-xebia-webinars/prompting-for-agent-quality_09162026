using FeeQuote.Clients;
using FeeQuote.Config;
using FeeQuote.Core;
using FeeQuote.Models;

namespace FeeQuote.Services;

/// <summary>A transfer that has been priced and accepted by the gateway.</summary>
public sealed record SubmittedTransfer(Quote Quote, SubmissionReceipt Receipt);

/// <summary>
/// Application entry point for quoting and submitting transfers. Validation
/// lives here so every channel (CLI, API, batch) gets the same rules.
/// </summary>
public sealed class TransferService(IPaymentClient client)
{
    private readonly IPaymentClient _client = client ?? throw new ArgumentNullException(nameof(client));

    /// <summary>Prices a transfer without submitting it.</summary>
    public Quote Quote(Transfer transfer)
    {
        Validate(transfer);

        long fee = Pricing.ComputeFee(transfer.AmountCents);
        IReadOnlyList<BreakdownLine> breakdown = [new BreakdownLine("Domestic fee", fee)];

        return new Quote(transfer.Id, fee, checked(transfer.AmountCents + fee), breakdown);
    }

    /// <summary>Prices a transfer, then hands it to the gateway.</summary>
    public SubmittedTransfer Submit(Transfer transfer)
    {
        Quote quote = Quote(transfer);
        SubmissionReceipt receipt = _client.Submit(transfer);
        return new SubmittedTransfer(quote, receipt);
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

        RequireKnown(Settings.Currencies, transfer.Currency, "currency");
        RequireKnown(Settings.Countries, transfer.OriginCountry, "origin country");
        RequireKnown(Settings.Countries, transfer.DestinationCountry, "destination country");
        RequireKnown(Settings.Channels, transfer.Channel, "channel");
    }

    private static void RequireKnown(IReadOnlyList<string> allowed, string value, string field)
    {
        if (!allowed.Contains(value, StringComparer.Ordinal))
        {
            throw new ArgumentException(
                $"Unknown {field} '{value}'. Expected one of: {string.Join(", ", allowed)}.");
        }
    }
}
