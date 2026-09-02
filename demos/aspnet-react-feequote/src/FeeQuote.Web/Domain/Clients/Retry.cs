namespace FeeQuote.Web.Domain.Clients;

/// <summary>
/// Retry with exponential backoff for calls to external systems. Kept separate
/// from the individual clients so the backoff policy is defined once; a client
/// that needs it wraps its call in <see cref="WithRetry{T}"/>.
/// </summary>
public static class Retry
{
    /// <summary>
    /// Runs <paramref name="operation"/> up to <paramref name="attempts"/> times,
    /// waiting <paramref name="backoffMs"/> before the second attempt and doubling
    /// the wait after each further failure. Only
    /// <see cref="GatewayUnavailableException"/> is retried; anything else is a
    /// bug or a rejected request and is rethrown at once.
    /// </summary>
    /// <param name="delay">Wait implementation, replaceable in tests. Defaults to Thread.Sleep.</param>
    /// <param name="shouldRetry">
    /// Optional filter that narrows the retry further. A
    /// <see cref="GatewayUnavailableException"/> for which it returns <c>false</c> is
    /// rethrown at once, without a wait. When omitted, every one is retried.
    /// </param>
    public static T WithRetry<T>(
        Func<T> operation,
        int attempts = 3,
        int backoffMs = 200,
        Action<int>? delay = null,
        Func<GatewayUnavailableException, bool>? shouldRetry = null)
    {
        ArgumentNullException.ThrowIfNull(operation);
        ArgumentOutOfRangeException.ThrowIfLessThan(attempts, 1);
        ArgumentOutOfRangeException.ThrowIfNegative(backoffMs);
        delay ??= Thread.Sleep;

        var wait = backoffMs;
        for (var attempt = 1; ; attempt++)
        {
            try
            {
                return operation();
            }
            catch (GatewayUnavailableException ex) when (attempt < attempts && (shouldRetry is null || shouldRetry(ex)))
            {
                delay(wait);
                wait *= 2;
            }
        }
    }
}
