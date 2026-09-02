import { describe, expect, it } from 'vitest';
import { parseTransfer, runCli, USAGE } from '../src/cli.js';

function run(args: string[]): { code: number; stdout: string; stderr: string } {
  const stdout: string[] = [];
  const stderr: string[] = [];
  const code = runCli(args, { out: (line) => stdout.push(line), err: (line) => stderr.push(line) });
  return { code, stdout: stdout.join('\n'), stderr: stderr.join('\n') };
}

describe('parseTransfer', () => {
  it('builds a transfer from the required flags with defaults for the rest', () => {
    expect(parseTransfer(['--amount', '123500', '--from', 'AU', '--to', 'AU'])).toEqual({
      id: 'cli-quote',
      amountCents: 123500,
      currency: 'AUD',
      originCountry: 'AU',
      destinationCountry: 'AU',
      channel: 'online',
    });
  });

  it('accepts the optional flags', () => {
    const transfer = parseTransfer([
      '--amount', '100000', '--from', 'AU', '--to', 'NZ',
      '--currency', 'NZD', '--channel', 'api', '--id', 'T-77',
    ]);

    expect(transfer).toMatchObject({ id: 'T-77', currency: 'NZD', destinationCountry: 'NZ', channel: 'api' });
  });

  it.each([
    { name: 'missing amount', args: ['--from', 'AU', '--to', 'AU'] },
    { name: 'fractional amount', args: ['--amount', '12.5', '--from', 'AU', '--to', 'AU'] },
    { name: 'zero amount', args: ['--amount', '0', '--from', 'AU', '--to', 'AU'] },
    { name: 'unknown country', args: ['--amount', '100', '--from', 'AU', '--to', 'XX'] },
    { name: 'unknown currency', args: ['--amount', '100', '--from', 'AU', '--to', 'AU', '--currency', 'JPY'] },
    { name: 'dangling flag', args: ['--amount', '100', '--from', 'AU', '--to'] },
  ])('rejects $name', ({ args }) => {
    expect(() => parseTransfer(args)).toThrow(/required|must be|unknown|unexpected/);
  });
});

describe('runCli', () => {
  it('prints the quote as JSON', () => {
    const result = run(['quote', '--amount', '123500', '--from', 'AU', '--to', 'AU']);

    expect(result.code).toBe(0);
    expect(JSON.parse(result.stdout)).toEqual({
      transferId: 'cli-quote',
      feeCents: 1112,
      totalCents: 124612,
      breakdown: [{ label: 'Domestic fee', amountCents: 1112 }],
    });
  });

  it('prints usage and exits with 2 when no command is given', () => {
    const result = run([]);

    expect(result.code).toBe(2);
    expect(result.stdout).toBe(USAGE);
  });

  it('prints usage and exits with 0 for help', () => {
    expect(run(['help'])).toEqual({ code: 0, stdout: USAGE, stderr: '' });
  });

  it('reports an unknown command on stderr', () => {
    const result = run(['refund']);

    expect(result.code).toBe(2);
    expect(result.stderr).toContain('unknown command: refund');
  });

  it('reports a usage error on stderr with exit code 2', () => {
    const result = run(['quote', '--amount', 'lots', '--from', 'AU', '--to', 'AU']);

    expect(result.code).toBe(2);
    expect(result.stderr).toContain('--amount must be a positive whole number of cents');
    expect(result.stdout).toBe('');
  });
});
