# FeeQuote

FeeQuote quotes the fee for a customer payment transfer. Channel systems send a
transfer (amount, currency, origin and destination country, channel) and get
back a quote with an itemised breakdown and the total to debit.

Money is always integer minor units (cents). Never use binary floating point
for amounts or fees.

The service is an ASP.NET Core MVC application (`src/FeeQuote.Web`) with a
JSON API at `POST /api/quotes` and a small React front-end (`ClientApp/`)
that is served from `/app/`.

## Prerequisites

- .NET SDK 10.0 or later
- Node.js 24 or later (with npm)
- Git 2.28 or later

## Setup

Windows (PowerShell):

```powershell
dotnet restore
cd src\FeeQuote.Web\ClientApp
npm install
cd ..\..\..
```

macOS / Linux:

```bash
dotnet restore
(cd src/FeeQuote.Web/ClientApp && npm install)
```

## Running

Start the API and MVC site (listens on http://localhost:5080, configured in
`src/FeeQuote.Web/Properties/launchSettings.json` and `appsettings.json`):

```bash
dotnet run --project src/FeeQuote.Web
```

Then:

- http://localhost:5080/ is the landing page.
- http://localhost:5080/health returns `{"status":"ok"}`.
- `POST http://localhost:5080/api/quotes` prices a transfer:

```bash
curl -s -X POST http://localhost:5080/api/quotes \
  -H "Content-Type: application/json" \
  -d '{"amountCents":123500,"currency":"AUD","originCountry":"AU","destinationCountry":"AU","channel":"online"}'
```

The response carries `transferId`, `amountCents`, `currency`, `feeCents`,
`totalCents` and a `breakdown` array of `{ "label", "amountCents" }`.

### Front-end

For day-to-day work run the Vite dev server next to the API. It proxies
`/api` to http://localhost:5080:

```bash
cd src/FeeQuote.Web/ClientApp
npm run dev
```

To serve the React app from the .NET site, build it. `vite.config.ts` sets
`outDir` to `../wwwroot/app` (with `emptyOutDir`), so the build lands inside
the web project and is served at http://localhost:5080/app/ by the static
file middleware. The build output is not committed; run this after cloning:

```bash
cd src/FeeQuote.Web/ClientApp
npm run build
```

## Project layout

```
FeeQuote.sln
src/FeeQuote.Web/
  Program.cs                      host, DI registrations, /health
  Controllers/HomeController.cs   landing page
  Controllers/Api/QuotesController.cs   POST /api/quotes
  Views/                          Razor views for the landing page
  Domain/Models/                  Transfer, Quote, BreakdownLine
  Domain/Config/Settings.cs       currencies, countries, channels
  Domain/Core/Pricing.cs          fee policy and rounding
  Domain/Legacy/Fees.cs           legacy fee helper
  Domain/Jobs/Reconciliation.cs   nightly batch reconciliation
  Domain/Clients/PaymentClient.cs gateway client
  Domain/Clients/Retry.cs         retry with exponential backoff
  Domain/Services/TransferService.cs   quote and submit
  ClientApp/                      React + TypeScript front-end (Vite)
  wwwroot/                        static files; wwwroot/app is the React build
tests/FeeQuote.Web.Tests/         xunit tests, including one API integration test
scripts/                          release-notes helpers
```

## Fee calculation

All fee calculations go through the generic helper
`Fees.CalculateFee(amountCents, rateBps)` in the legacy fees module
(`Domain/Legacy/Fees.cs`). Pass the rate in basis points.

```csharp
using FeeQuote.Web.Domain.Legacy;

var feeCents = Fees.CalculateFee(amountCents: 100000, rateBps: 90); // 900
```

## Running the checks

Backend, from the repository root:

```bash
dotnet test
dotnet format --verify-no-changes
dotnet build -warnaserror
```

Front-end, from `src/FeeQuote.Web/ClientApp`:

```bash
npm test
npm run lint
npm run typecheck
npm run build
```

`npm run check` runs the four front-end checks in sequence. All of the above
must pass before a change is considered done.

## Conventions

- Tests use the worked examples from the fee policy rather than invented
  numbers, and each test covers one behavior.
- `.editorconfig` drives both `dotnet format` and the analyzers; the build
  treats warnings as errors.
- The React app's `api.ts` mirrors the JSON contract of `QuotesController`.
  Change both sides in the same change.
