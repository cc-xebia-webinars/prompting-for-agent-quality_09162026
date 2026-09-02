// Source-level rules that the type checker cannot express.
import { readdirSync, readFileSync } from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { describe, expect, it } from 'vitest';

const SRC_ROOT = fileURLToPath(new URL('../src', import.meta.url));
const LEGACY_DIR = path.join(SRC_ROOT, 'legacy');
const ALLOWED_LEGACY_CALLERS = new Set([path.join(SRC_ROOT, 'jobs', 'reconciliation.ts')]);
const LEGACY_FEE_HELPER = /\bcalculateFee\b/;

const LEGACY_RULE =
  'New code must not call the legacy fee helper. ' +
  'Use core pricing (priceWithPolicy or computeFee) instead. See ticket 4821.';

function listSourceFiles(dir: string): string[] {
  const files: string[] = [];
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      files.push(...listSourceFiles(full));
    } else if (entry.name.endsWith('.ts')) {
      files.push(full);
    }
  }
  return files.sort();
}

function isExemptFromLegacyRule(file: string): boolean {
  return file.startsWith(LEGACY_DIR + path.sep) || ALLOWED_LEGACY_CALLERS.has(file);
}

function filesReferencing(pattern: RegExp, files: readonly string[]): string[] {
  return files
    .filter((file) => pattern.test(readFileSync(file, 'utf8')))
    .map((file) => path.relative(SRC_ROOT, file).split(path.sep).join('/'));
}

describe('architecture', () => {
  it('scans the production tree, including the files the legacy rule exempts', () => {
    const referencing = filesReferencing(LEGACY_FEE_HELPER, listSourceFiles(SRC_ROOT));

    expect(referencing).toContain('legacy/fees.ts');
    expect(referencing).toContain('jobs/reconciliation.ts');
  });

  it('keeps the legacy fee helper out of everything except legacy/ and the reconciliation job', () => {
    const candidates = listSourceFiles(SRC_ROOT).filter((file) => !isExemptFromLegacyRule(file));
    const offenders = filesReferencing(LEGACY_FEE_HELPER, candidates);

    expect(offenders, `${LEGACY_RULE} Offending files: ${offenders.join(', ')}`).toEqual([]);
  });
});
