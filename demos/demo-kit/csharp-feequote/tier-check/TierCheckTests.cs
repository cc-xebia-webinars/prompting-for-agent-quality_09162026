using FeeQuote.Clients;
using FeeQuote.Models;
using FeeQuote.Services;

namespace FeeQuote.Tests;

/// <summary>
/// Presenter-only check for segment 4.3. Never commit this file.
/// Copy it into a worktree's test project after the agent has finished, then
/// run only this class. It drives the submit path through the transfer service
/// with a fake gateway, so it holds wherever the agent put the retry.
/// </summary>
public class TierCheckTests
{
    private static readonly Transfer TierCheckTransfer = new("tr-4300", 100000, "AUD", "AU", "AU", "online");

    [Fact]
    public void Submit_RecoversWhenTheGatewayTimesOutOnce()
    {
        var gateway = new FakeGateway { FailFirstCall = true };

        string reference = SubmitThrough(gateway);

        Assert.True(reference == "GW-1", "the submit path does not retry a timeout");
    }

    [Fact]
    public void Submit_ChargesTheCustomerOnceWhenAResponseIsLost()
    {
        var gateway = new FakeGateway { LoseFirstResponse = true };

        string reference = SubmitThrough(gateway);

        int charges = gateway.Payments.Count;
        Assert.True(
            charges == 1,
            $"customer charged {charges} times for {TierCheckTransfer.Id} (keys: {string.Join(", ", gateway.PaymentKeys)})");
        Assert.Equal("GW-1", reference);
    }

    [Fact]
    public void Submit_DoesNotResubmitADeclinedTransfer()
    {
        var gateway = new FakeGateway { Decline = true };

        Assert.ThrowsAny<Exception>(() => SubmitThrough(gateway));

        Assert.True(gateway.Calls.Count == 1, $"declined transfer sent {gateway.Calls.Count} times");
    }

    private static string SubmitThrough(FakeGateway gateway)
    {
        var service = new TransferService(new PaymentClient(gateway.Send));
        return service.Submit(TierCheckTransfer).Receipt.GatewayReference;
    }

    /// <summary>Deduplicates on the idempotency key, like the real gateway.</summary>
    private sealed class FakeGateway
    {
        public bool LoseFirstResponse { get; init; }

        public bool FailFirstCall { get; init; }

        public bool Decline { get; init; }

        public List<string> Calls { get; } = [];

        public Dictionary<string, string> Payments { get; } = new(StringComparer.Ordinal);

        public List<string> PaymentKeys { get; } = [];

        public string Send(Transfer transfer, string idempotencyKey)
        {
            Calls.Add(idempotencyKey);
            if (Decline)
            {
                throw new GatewayDeclinedException($"transfer {transfer.Id} declined");
            }

            if (FailFirstCall && Calls.Count == 1)
            {
                throw new GatewayTimeoutException("gateway timed out before taking the payment");
            }

            if (!Payments.ContainsKey(idempotencyKey))
            {
                Payments[idempotencyKey] = $"GW-{Payments.Count + 1}";
                PaymentKeys.Add(idempotencyKey);
            }

            if (LoseFirstResponse && Calls.Count == 1)
            {
                throw new GatewayTimeoutException("gateway took the payment but the response was lost");
            }

            return Payments[idempotencyKey];
        }
    }
}
