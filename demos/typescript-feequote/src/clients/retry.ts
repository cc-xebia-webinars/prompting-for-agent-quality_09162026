// Retry with exponential backoff for calls to external services (payment
// gateway, batch export). Nothing wires it in by default; a caller opts in by
// wrapping the call. The pause is injectable so tests never wait on a timer.

export type SleepFn = (ms: number) => Promise<void>;

const wait: SleepFn = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

/**
 * Runs fn up to `attempts` times. The pause before each retry starts at
 * backoffMs and doubles every time (backoffMs, 2 * backoffMs, 4 * backoffMs).
 * Only errors for which `shouldRetry` returns true are retried (by default,
 * every error); anything else propagates immediately. The last error is
 * rethrown once attempts are exhausted.
 */
export async function withRetry<T>(
  fn: () => Promise<T>,
  attempts = 3,
  backoffMs = 100,
  sleep: SleepFn = wait,
  shouldRetry: (error: unknown) => boolean = () => true,
): Promise<T> {
  if (!Number.isInteger(attempts) || attempts < 1) {
    throw new RangeError(`attempts must be a positive integer, got ${attempts}`);
  }
  let lastError: unknown;
  for (let attempt = 1; attempt <= attempts; attempt += 1) {
    try {
      return await fn();
    } catch (error) {
      if (!shouldRetry(error)) {
        throw error;
      }
      lastError = error;
      if (attempt < attempts) {
        await sleep(backoffMs * 2 ** (attempt - 1));
      }
    }
  }
  throw lastError;
}
