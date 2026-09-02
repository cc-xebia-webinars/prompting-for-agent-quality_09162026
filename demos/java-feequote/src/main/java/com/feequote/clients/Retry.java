package com.feequote.clients;

import java.util.function.Predicate;
import java.util.function.Supplier;

/**
 * Retry with exponential backoff for calls to external systems.
 *
 * <p>Wrap any call that can fail transiently (gateway timeouts, connection resets)
 * with {@code withRetry} instead of writing a loop at the call site, so every path
 * retries the same way and tests can inject a fake sleeper.
 */
public final class Retry {

    public static final int DEFAULT_ATTEMPTS = 3;
    public static final long DEFAULT_BACKOFF_MS = 200;

    /** How the retry loop waits between attempts. Injectable so tests never sleep. */
    @FunctionalInterface
    public interface Sleeper {
        void sleep(long millis) throws InterruptedException;
    }

    private Retry() {
    }

    /** Calls {@code call} with the default three attempts and 200 ms doubling backoff. */
    public static <T> T withRetry(Supplier<T> call) {
        return withRetry(call, DEFAULT_ATTEMPTS, DEFAULT_BACKOFF_MS, Thread::sleep);
    }

    /**
     * Calls {@code call} until it succeeds or {@code attempts} is exhausted.
     *
     * <p>The delay starts at {@code backoffMs} and doubles after each failure, so the
     * defaults wait 200 ms and then 400 ms. Only {@link GatewayException} is retried;
     * anything else is a bug in the caller and propagates immediately. The last error
     * is re-thrown when the attempts run out.
     *
     * @param call the work to attempt
     * @param attempts how many times to try in total, at least one
     * @param backoffMs the first delay in milliseconds, doubling thereafter
     * @param sleeper how to wait between attempts
     * @param <T> what the call returns
     * @return whatever the call returned on the attempt that succeeded
     */
    public static <T> T withRetry(Supplier<T> call, int attempts, long backoffMs, Sleeper sleeper) {
        return withRetry(call, attempts, backoffMs, sleeper, GatewayException.class::isInstance);
    }

    /**
     * Calls {@code call} until it succeeds or {@code attempts} is exhausted.
     *
     * <p>The delay starts at {@code backoffMs} and doubles after each failure. Only
     * exceptions accepted by {@code retryOn} are retried; anything else propagates
     * immediately. The last error is re-thrown when the attempts run out.
     *
     * @param call the work to attempt
     * @param attempts how many times to try in total, at least one
     * @param backoffMs the first delay in milliseconds, doubling thereafter
     * @param sleeper how to wait between attempts
     * @param retryOn which exceptions to retry
     * @param <T> what the call returns
     * @return whatever the call returned on the attempt that succeeded
     */
    public static <T> T withRetry(
            Supplier<T> call, int attempts, long backoffMs, Sleeper sleeper,
            Predicate<? super RuntimeException> retryOn) {
        if (attempts < 1) {
            throw new IllegalArgumentException("attempts must be at least 1");
        }
        if (backoffMs < 0) {
            throw new IllegalArgumentException("backoffMs must not be negative");
        }
        long delayMs = backoffMs;
        for (int attempt = 1; ; attempt++) {
            try {
                return call.get();
            } catch (RuntimeException failure) {
                if (!retryOn.test(failure) || attempt >= attempts) {
                    throw failure;
                }
                try {
                    sleeper.sleep(delayMs);
                } catch (InterruptedException interrupted) {
                    Thread.currentThread().interrupt();
                    throw failure;
                }
                delayMs *= 2;
            }
        }
    }
}
