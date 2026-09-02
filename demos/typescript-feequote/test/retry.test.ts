import { describe, expect, it } from 'vitest';
import { withRetry } from '../src/clients/retry.js';

// Records the requested pauses instead of waiting, so the suite never sleeps.
const recordingSleep = (log: number[]) => async (ms: number) => {
  log.push(ms);
};

// An async call that fails the given number of times, then resolves with value.
function flaky<T>(failures: number, value: T): () => Promise<T> {
  let calls = 0;
  return async () => {
    calls += 1;
    if (calls <= failures) {
      throw new Error(`failure ${calls}`);
    }
    return value;
  };
}

describe('withRetry', () => {
  it('returns the first successful result without sleeping', async () => {
    const pauses: number[] = [];

    const result = await withRetry(async () => 'ok', 3, 100, recordingSleep(pauses));

    expect(result).toBe('ok');
    expect(pauses).toEqual([]);
  });

  it('retries with a doubling pause until the call succeeds', async () => {
    const pauses: number[] = [];

    const result = await withRetry(flaky(2, 'ok'), 3, 100, recordingSleep(pauses));

    expect(result).toBe('ok');
    expect(pauses).toEqual([100, 200]);
  });

  it('rethrows the last error once attempts are exhausted', async () => {
    const pauses: number[] = [];

    await expect(withRetry(flaky(5, 'ok'), 3, 50, recordingSleep(pauses))).rejects.toThrow('failure 3');
    expect(pauses).toEqual([50, 100]);
  });

  it('does not retry errors the filter rejects', async () => {
    const pauses: number[] = [];

    // A second call would succeed, so rejecting with the first failure means one call.
    await expect(withRetry(flaky(1, 'ok'), 3, 100, recordingSleep(pauses), () => false)).rejects.toThrow(
      'failure 1',
    );
    expect(pauses).toEqual([]);
  });

  it('rejects a non-positive attempt count', async () => {
    await expect(withRetry(async () => 'ok', 0, 100, recordingSleep([]))).rejects.toThrow(RangeError);
  });
});
