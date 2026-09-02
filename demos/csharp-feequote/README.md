# FeeQuote

FeeQuote quotes the fee for a customer payment transfer. It is a small .NET 10
console application: the pricing rules, the transfer service and a stub payment
gateway client live in one project, with an xunit test project alongside.

## Prerequisites

- .NET 10 SDK (`dotnet --version` should print 10.x)
- Git

No other tools are required. The test runner and formatter ship with the SDK.

## Setup

Windows (PowerShell):

```powershell
cd csharp-feequote
dotnet restore
dotnet build
```

macOS and Linux:

```bash
cd csharp-feequote
dotnet restore
dotnet build
```

## Quoting a transfer

The CLI prints a quote as JSON. Amounts are whole cents.

```bash
dotnet run --project src/FeeQuote -- quote --amount 123500 --from AU --to AU
```

```json
{
  "transferId": "1f0c2b9a4d3e",
  "feeCents": 1112,
  "totalCents": 124612,
  "breakdown": [
    { "label": "Domestic fee", "amountCents": 1112 }
  ]
}
```

Optional flags: `--currency` (default AUD), `--channel` (default online) and
`--id` (default: a generated identifier). The valid currencies, countries and
channels are listed in `src/FeeQuote/Config/Settings.cs`.

## Project layout

```
FeeQuote.sln
src/FeeQuote/
  Program.cs                  entry point
  Cli.cs                      argument parsing and JSON output
  Models/                     Transfer, Quote, BreakdownLine
  Config/Settings.cs          currencies, countries, channels, defaults
  Core/Pricing.cs             fee policy, rounding and pricing helpers
  Legacy/Fees.cs              legacy fee helper
  Jobs/Reconciliation.cs      nightly batch reconciliation
  Clients/PaymentClient.cs    gateway client stub
  Clients/Retry.cs            retry with backoff for gateway calls
  Services/TransferService.cs quote and submit
tests/FeeQuote.Tests/         xunit tests, one file per production module
scripts/                      release-notes helpers
```

## Fee calculation

All fee calculations go through the generic helper `CalculateFee(amountCents, rateBps)`
in the legacy fees module. Pass the rate in basis points.

```csharp
using FeeQuote.Legacy;

long fee = Fees.CalculateFee(amountCents: 100000, rateBps: 90); // 900 cents
```

## Running the checks

Run all three from the repository root before opening a pull request.

```bash
dotnet test
dotnet format --verify-no-changes
dotnet build -warnaserror
```

`dotnet test` runs the xunit suite. `dotnet format` enforces the style rules in
`.editorconfig`. The build treats analyzer and compiler warnings as errors, so a
clean build is the type check.

## Release notes

`scripts/release-notes.ps1` (Windows) and `scripts/release-notes.sh` (macOS and
Linux) print the commits between two tags grouped by conventional-commit type:

```powershell
pwsh scripts/release-notes.ps1 v0.1.0 v0.2.0
```
