using System.Collections.Concurrent;
using FeeQuote.Web.Domain.Models;

namespace FeeQuote.Web.Domain.Clients;

/// <summary>Acknowledgement returned by the payment gateway for an accepted transfer.</summary>
public sealed record SubmissionReceipt(string TransferId, string Reference, DateTimeOffset AcceptedAt);

/// <summary>Raised when the gateway is reachable but cannot take the request right now.</summary>
public class GatewayUnavailableException : Exception
{
    public GatewayUnavailableException()
    {
    }

    public GatewayUnavailableException(string message) : base(message)
    {
    }

    public GatewayUnavailableException(string message, Exception innerException) : base(message, innerException)
    {
    }
}

/// <summary>The gateway did not respond in time.</summary>
public sealed class GatewayTimeoutException : GatewayUnavailableException
{
    public GatewayTimeoutException()
    {
    }

    public GatewayTimeoutException(string message) : base(message)
    {
    }

    public GatewayTimeoutException(string message, Exception innerException) : base(message, innerException)
    {
    }
}

/// <summary>The gateway declined the transfer.</summary>
public sealed class GatewayDeclinedException : GatewayUnavailableException
{
    public GatewayDeclinedException()
    {
    }

    public GatewayDeclinedException(string message) : base(message)
    {
    }

    public GatewayDeclinedException(string message, Exception innerException) : base(message, innerException)
    {
    }
}

/// <summary>Sends a transfer to the gateway and returns the gateway reference.</summary>
public delegate string GatewayTransport(Transfer transfer, string idempotencyKey);

public interface IPaymentClient
{
    SubmissionReceipt Submit(Transfer transfer);
}

/// <summary>
/// Gateway client. The real gateway is not wired up in this service yet, so the
/// default transport mints a local reference and returns immediately. The
/// transport can be swapped for tests or for a real adapter without touching
/// the callers.
/// </summary>
public sealed class PaymentClient : IPaymentClient
{
    private readonly TimeProvider _clock;
    private readonly GatewayTransport _transport;
    private readonly ConcurrentDictionary<string, string> _referencesByKey = new(StringComparer.Ordinal);

    public PaymentClient() : this(TimeProvider.System)
    {
    }

    public PaymentClient(TimeProvider clock)
    {
        _clock = clock;
        _transport = StubTransport;
    }

    public PaymentClient(TimeProvider clock, GatewayTransport transport)
    {
        ArgumentNullException.ThrowIfNull(transport);
        _clock = clock;
        _transport = transport;
    }

    public SubmissionReceipt Submit(Transfer transfer)
    {
        ArgumentNullException.ThrowIfNull(transfer);
        var reference = Send(transfer);
        return new SubmissionReceipt(transfer.Id, reference, _clock.GetUtcNow());
    }

    private string Send(Transfer transfer) => _transport(transfer, NewIdempotencyKey());

    private static string NewIdempotencyKey() => Guid.NewGuid().ToString("N");

    internal string StubTransport(Transfer transfer, string idempotencyKey) =>
        _referencesByKey.GetOrAdd(idempotencyKey, _ => $"PG-{Guid.NewGuid():N}"[..14].ToUpperInvariant());
}
