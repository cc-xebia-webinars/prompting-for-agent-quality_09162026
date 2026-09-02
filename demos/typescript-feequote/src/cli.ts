// Command line entry point. Prints a quote as JSON so it can be piped elsewhere.
//
//   npm run quote -- quote --amount 123500 --from AU --to AU
import { pathToFileURL } from 'node:url';
import {
  COUNTRIES,
  CURRENCIES,
  DEFAULT_CHANNEL,
  DEFAULT_CURRENCY,
  isChannel,
  isCountry,
  isCurrency,
} from './config.js';
import type { Transfer } from './models.js';
import { quote } from './services/transferService.js';

export interface CliIo {
  readonly out: (line: string) => void;
  readonly err: (line: string) => void;
}

export const USAGE = [
  'Usage: quote --amount <cents> --from <country> --to <country>',
  '             [--currency <code>] [--channel <name>] [--id <transfer id>]',
  `Countries:  ${COUNTRIES.join(', ')}`,
  `Currencies: ${CURRENCIES.join(', ')}`,
].join('\n');

export class UsageError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'UsageError';
  }
}

function readOptions(args: readonly string[]): Map<string, string> {
  const options = new Map<string, string>();
  for (let i = 0; i < args.length; i += 2) {
    const flag = args[i];
    const value = args[i + 1];
    if (flag === undefined || !flag.startsWith('--') || value === undefined) {
      throw new UsageError(`unexpected argument: ${flag ?? ''}`);
    }
    options.set(flag.slice(2), value);
  }
  return options;
}

function requireOption(options: ReadonlyMap<string, string>, name: string): string {
  const value = options.get(name);
  if (value === undefined) {
    throw new UsageError(`--${name} is required`);
  }
  return value;
}

export function parseTransfer(args: readonly string[]): Transfer {
  const options = readOptions(args);

  const amountText = requireOption(options, 'amount');
  if (!/^\d+$/.test(amountText) || !Number.isSafeInteger(Number(amountText)) || Number(amountText) === 0) {
    throw new UsageError('--amount must be a positive whole number of cents');
  }

  const originCountry = requireOption(options, 'from');
  const destinationCountry = requireOption(options, 'to');
  const currency = options.get('currency') ?? DEFAULT_CURRENCY;
  const channel = options.get('channel') ?? DEFAULT_CHANNEL;
  if (!isCountry(originCountry)) throw new UsageError(`unknown country: ${originCountry}`);
  if (!isCountry(destinationCountry)) throw new UsageError(`unknown country: ${destinationCountry}`);
  if (!isCurrency(currency)) throw new UsageError(`unknown currency: ${currency}`);
  if (!isChannel(channel)) throw new UsageError(`unknown channel: ${channel}`);

  return {
    id: options.get('id') ?? 'cli-quote',
    amountCents: Number(amountText),
    currency,
    originCountry,
    destinationCountry,
    channel,
  };
}

/** Runs one command. Returns the process exit code. */
export function runCli(argv: readonly string[], io: CliIo): number {
  const [command, ...rest] = argv;
  if (command === undefined || command === 'help' || command === '--help') {
    io.out(USAGE);
    return command === undefined ? 2 : 0;
  }
  if (command !== 'quote') {
    io.err(`unknown command: ${command}`);
    io.err(USAGE);
    return 2;
  }
  try {
    io.out(JSON.stringify(quote(parseTransfer(rest)), null, 2));
    return 0;
  } catch (error) {
    if (error instanceof UsageError) {
      io.err(error.message);
      io.err(USAGE);
      return 2;
    }
    io.err(error instanceof Error ? error.message : String(error));
    return 1;
  }
}

const entryPoint = process.argv[1];
if (entryPoint !== undefined && import.meta.url === pathToFileURL(entryPoint).href) {
  process.exitCode = runCli(process.argv.slice(2), {
    out: (line) => console.log(line),
    err: (line) => console.error(line),
  });
}
