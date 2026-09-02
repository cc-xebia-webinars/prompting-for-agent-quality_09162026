// Nightly batch reconciliation. Recomputes the fee on every line of a settled
// batch and reports lines whose recorded fee does not match.
//
// The recomputation deliberately uses the same helper the batch system used
// when the fees were recorded, so the report only flags genuine data problems
// rather than differences in rounding. Moving this job to core pricing is
// tracked under ticket 4821.
import { calculateFee } from '../legacy/fees.js';

/** One line of a settled batch as exported by the batch system. */
export interface BatchLine {
  readonly transferId: string;
  readonly amountCents: number;
  readonly rateBps: number;
  readonly feeCents: number;
}

export interface BatchMismatch {
  readonly transferId: string;
  readonly recordedFeeCents: number;
  readonly recomputedFeeCents: number;
}

export interface ReconciliationReport {
  readonly lineCount: number;
  readonly recordedTotalCents: number;
  readonly recomputedTotalCents: number;
  readonly mismatches: readonly BatchMismatch[];
}

export function reconcileBatch(lines: readonly BatchLine[]): ReconciliationReport {
  let recordedTotalCents = 0;
  let recomputedTotalCents = 0;
  const mismatches: BatchMismatch[] = [];

  for (const line of lines) {
    const recomputedFeeCents = calculateFee(line.amountCents, line.rateBps);
    recordedTotalCents += line.feeCents;
    recomputedTotalCents += recomputedFeeCents;
    if (recomputedFeeCents !== line.feeCents) {
      mismatches.push({
        transferId: line.transferId,
        recordedFeeCents: line.feeCents,
        recomputedFeeCents,
      });
    }
  }

  return { lineCount: lines.length, recordedTotalCents, recomputedTotalCents, mismatches };
}

/** One-line summary suitable for the job log. */
export function summarize(report: ReconciliationReport): string {
  const status = report.mismatches.length === 0 ? 'balanced' : 'MISMATCH';
  return (
    `${status}: ${report.lineCount} lines, recorded ${report.recordedTotalCents}, ` +
    `recomputed ${report.recomputedTotalCents}, ${report.mismatches.length} mismatched`
  );
}
