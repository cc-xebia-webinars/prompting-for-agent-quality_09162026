namespace FeeQuote.Clients;

/// <summary>
/// Retry with exponential backoff for calls to external gateways. Callers wrap
/// the operation rather than the client, so a client stays a thin transport
/// and the retry policy is decided at the call site.
/// </summary>
public static class Retry
{
    /// <summary>Default number of attempts for <see cref="WithRetry{T}"/>.</summary>
    public const int DefaultAttempts = 3;

    /// <summary>Default wait before the second attempt; each later wait doubles.</summary>
    public const int DefaultBackoffMs = 200;

    /// <summary>
    /// Runs <paramref name="operation"/> up to <paramref name="attempts"/> times,
    /// waiting <paramref name="backoffMs"/> before the second attempt and doubling
    /// the wait after each further failure. Only <see cref="PaymentGatewayException"/>
    /// is retried; anything else is a programming error and propagates at once.
    /// <paramref name="delay"/> defaults to <see cref="Thread.Sleep(int)"/> and is
    /// injectable so tests do not have to wait. <paramref name="shouldRetry"/>, when
    /// given, narrows the retry further: a <see cref="PaymentGatewayException"/> for
    /// which it returns <c>false</c> also propagates at once, without a wait.
    /// </summary>
    public static T WithRetry<T>(
        Func<T> operation,
        int attempts = DefaultAttempts,
        int backoffMs = DefaultBackoffMs,
        Action<int>? delay = null,
        Func<PaymentGatewayException, bool>? shouldRetry = null)
    {
        ArgumentNullException.ThrowIfNull(operation);

        if (attempts < 1)
        {
            throw new ArgumentOutOfRangeException(nameof(attempts), "At least one attempt is required.");
        }

        if (backoffMs < 0)
        {
            throw new ArgumentOutOfRangeException(nameof(backoffMs), "Backoff must not be negative.");
        }

        delay ??= Thread.Sleep;
        int wait = backoffMs;

        for (int attempt = 1; ; attempt++)
        {
            try
            {
                return operation();
            }
            catch (PaymentGatewayException ex) when (attempt < attempts && (shouldRetry is null || shouldRetry(ex)))
            {
                delay(wait);
                wait = checked(wait * 2);
            }
        }
    }
}
