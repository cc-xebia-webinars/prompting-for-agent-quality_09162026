# FeeQuote

FeeQuote quotes the fee for a customer payment transfer. It is a small TypeScript
service with a command line entry point, a stub payment gateway client, and the
nightly batch reconciliation job.

All money is handled as an integer number of minor units (cents). Binary floating
point is never used for amounts or fees.

## Requirements

- Node.js 24 or later (see the `engines` field in `package.json`).
- npm (bundled with Node.js).

## Setup

macOS and Linux:

```sh
npm install
```

Windows (PowerShell or Command Prompt):

```powershell
npm install
```

There are no runtime dependencies; `npm install` only fetches the development
toolchain (TypeScript, Vitest, ESLint, tsx).

## Quoting a transfer

The CLI prints a quote as JSON. Note the extra `--` that separates npm's own
options from the command's arguments; it is the same on every platform.

```sh
npm run quote -- quote --amount 123500 --from AU --to AU
```

```json
{
  "transferId": "cli-quote",
  "feeCents": 1112,
  "totalCents": 124612,
  "breakdown": [
    { "label": "Domestic fee", "amountCents": 1112 }
  ]
}
```

Optional flags: `--currency` (default `AUD`), `--channel` (default `online`),
`--id` (default `cli-quote`). Run `npm run quote -- help` for the full usage.

## Running the checks

```sh
npm test            # Vitest, runs test/*.test.ts
npm run lint        # ESLint (flat config in eslint.config.js)
npm run typecheck   # tsc --noEmit with strict settings
```

`npm run check` runs all three in sequence and stops at the first failure.

## Fee calculation

All fee calculations go through the generic helper `calculateFee(amountCents, rateBps)`
in the legacy fees module. Pass the rate in basis points.

```ts
import { calculateFee } from './src/legacy/fees.js';

const feeCents = calculateFee(123500, 90); // 90 basis points
```

## Project layout

```
src/
  models.ts                  Transfer and Quote types
  config.ts                  Currency, country and channel reference data
  core/pricing.ts            Fee policy (minimum, cap) and rounding
  legacy/fees.ts             Generic fee helper, rate in basis points
  jobs/reconciliation.ts     Nightly batch reconciliation
  clients/paymentClient.ts   Payment gateway interface and stub client
  clients/retry.ts           Retry with exponential backoff for external calls
  services/transferService.ts Quote and submit a transfer
  cli.ts                     Command line entry point
  index.ts                   Public re-exports
test/
  *.test.ts                  One test file per module, plus architecture.test.ts
```
