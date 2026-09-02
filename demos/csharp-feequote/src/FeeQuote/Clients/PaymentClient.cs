using FeeQuote.Models;

namespace FeeQuote.Clients;

/// <summary>Acknowledgement returned by the gateway once it has accepted a transfer.</summary>
public sealed record SubmissionReceipt(string TransferId, string GatewayReference, long AmountCents);

/// <summary>Boundary to the payment gateway. Kept as an interface so services can be tested without it.</summary>
public interface IPaymentClient
{
    SubmissionReceipt Submit(Transfer transfer);
}

/// <summary>Sends a transfer to the gateway and returns the gateway reference.</summary>
public delegate string GatewayTransport(Transfer transfer, string idempotencyKey);

/// <summary>
/// Gateway client. The transport is stubbed in this build: the default
/// constructor answers immediately with a synthetic reference. The transport
/// can be swapped for tests or for a real adapter without touching the callers.
/// </summary>
public sealed class PaymentClient : IPaymentClient
{
    private readonly GatewayTransport _transport;

    /// <summary>Creates a client that talks to the stub transport.</summary>
    public PaymentClient()
        : this(CreateStubTransport())
    {
    }

    /// <summary>Creates a client that sends through <paramref name="transport"/>.</summary>
    public PaymentClient(GatewayTransport transport)
    {
        ArgumentNullException.ThrowIfNull(transport);
        _transport = transport;
    }

    /// <summary>Submits a transfer to the gateway and returns its acknowledgement.</summary>
    public SubmissionReceipt Submit(Transfer transfer)
    {
        ArgumentNullException.ThrowIfNull(transfer);

        string reference = Send(transfer);
        return new SubmissionReceipt(transfer.Id, reference, transfer.AmountCents);
    }

    /// <summary>
    /// The stub transport: references are derived from the transfer id, and a
    /// further payment for the same transfer gets a numbered suffix.
    /// </summary>
    public static GatewayTransport CreateStubTransport()
    {
        var referencesByKey = new Dictionary<string, string>(StringComparer.Ordinal);
        var paymentsByTransfer = new Dictionary<string, int>(StringComparer.Ordinal);

        return (transfer, idempotencyKey) =>
        {
            if (referencesByKey.TryGetValue(idempotencyKey, out string? existing))
            {
                return existing;
            }

            int payment = paymentsByTransfer.GetValueOrDefault(transfer.Id) + 1;
            paymentsByTransfer[transfer.Id] = payment;

            string reference = $"PAY-{transfer.Id.ToUpperInvariant()}";
            if (payment > 1)
            {
                reference += $"-{payment}";
            }

            referencesByKey[idempotencyKey] = reference;
            return reference;
        };
    }

    private static string NewIdempotencyKey() => Guid.NewGuid().ToString("N");

    private string Send(Transfer transfer) => _transport(transfer, NewIdempotencyKey());
}
