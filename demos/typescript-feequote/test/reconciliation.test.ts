import { describe, expect, it } from 'vitest';
import { reconcileBatch, summarize, type BatchLine } from '../src/jobs/reconciliation.js';

// Fees below are what the batch system recorded at settlement time, which is
// the truncated amount times rate. The job must reproduce those values exactly.
const settledLines: BatchLine[] = [
  { transferId: 'B-1', amountCents: 123500, rateBps: 90, feeCents: 1111 },
  { transferId: 'B-2', amountCents: 500000, rateBps: 90, feeCents: 4500 },
  { transferId: 'B-3', amountCents: 5000, rateBps: 90, feeCents: 45 },
];

describe('reconcileBatch', () => {
  it('reproduces the recorded totals for a clean batch', () => {
    const report = reconcileBatch(settledLines);

    expect(report.lineCount).toBe(3);
    expect(report.recordedTotalCents).toBe(5656);
    expect(report.recomputedTotalCents).toBe(5656);
    expect(report.mismatches).toEqual([]);
  });

  it('flags a line whose recorded fee differs from the recomputed fee', () => {
    const tampered: BatchLine = { transferId: 'B-9', amountCents: 123500, rateBps: 90, feeCents: 1200 };

    const report = reconcileBatch([...settledLines, tampered]);

    expect(report.mismatches).toEqual([
      { transferId: 'B-9', recordedFeeCents: 1200, recomputedFeeCents: 1111 },
    ]);
    expect(report.recordedTotalCents - report.recomputedTotalCents).toBe(89);
  });

  it('handles an empty batch', () => {
    expect(reconcileBatch([])).toEqual({
      lineCount: 0,
      recordedTotalCents: 0,
      recomputedTotalCents: 0,
      mismatches: [],
    });
  });
});

describe('summarize', () => {
  it('marks a clean batch as balanced', () => {
    expect(summarize(reconcileBatch(settledLines))).toBe(
      'balanced: 3 lines, recorded 5656, recomputed 5656, 0 mismatched',
    );
  });

  it('marks a batch with differences as a mismatch', () => {
    const report = reconcileBatch([{ transferId: 'B-9', amountCents: 100000, rateBps: 90, feeCents: 901 }]);

    expect(summarize(report)).toBe('MISMATCH: 1 lines, recorded 901, recomputed 900, 1 mismatched');
  });
});
