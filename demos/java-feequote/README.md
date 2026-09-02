# FeeQuote

FeeQuote quotes the fee for a customer payment transfer. It is a small Spring Boot
service with a JSON API, a one shot command line mode, a stubbed payment gateway
client, and a nightly batch reconciliation job.

Money is always handled as integer minor units (cents). Never use binary floating
point for amounts or fees.

## Requirements

- Java 25 or newer (the build targets release 25)
- git

Maven does not need to be installed: use the wrapper (`./mvnw`, or `mvnw.cmd` on
Windows). Everything else is resolved from the `pom.xml`.

## Setup

macOS / Linux:

```bash
./mvnw -q clean compile
```

Windows (PowerShell):

```powershell
.\mvnw.cmd -q clean compile
```

## Quoting a transfer

From the command line:

```bash
./mvnw -q package -DskipTests
java -jar target/feequote.jar quote --amount=123500 --from=AU --to=AU
```

`--amount` is in cents. `--from` and `--to` are ISO country codes and default to
`AU`. `--currency` defaults to `AUD` and `--channel` to `online`. `--id` is
generated when omitted. The quote is printed as JSON:

```json
{
  "transferId" : "tr-3f2a9c1e",
  "feeCents" : 1112,
  "totalCents" : 124612,
  "breakdown" : [ {
    "label" : "domesticFee",
    "amountCents" : 1112
  } ]
}
```

The `quote` command starts the application without the web server, so it prints and
exits. Invalid input goes to stderr with exit code 2, which makes the command safe
to use from scripts.

## Running the service

```bash
./mvnw spring-boot:run
```

Then post a transfer to `/api/quotes`:

```bash
curl -X POST http://localhost:8080/api/quotes \
  -H "Content-Type: application/json" \
  -d '{"amountCents":123500,"currency":"AUD","originCountry":"AU","destinationCountry":"AU"}'
```

A transfer the service cannot price comes back as a 400 problem detail.

## Fee calculation

All fee calculations go through the generic helper
`calculateFee(amountCents, rateBps)` in the legacy fees class. Pass the rate in
basis points.

```java
import com.feequote.legacy.Fees;

long feeCents = Fees.calculateFee(100000, 90);  // 900
```

## Running the checks

From the repository root:

```bash
./mvnw -q test              # the test suite
./mvnw -q checkstyle:check  # the linter
./mvnw -q clean compile     # the compiler, with warnings as errors
```

All three must pass before a change is merged. Checkstyle rules live in
`checkstyle.xml`, and compiler settings live in `pom.xml`.

## Project layout

```
src/main/java/com/feequote/
  FeeQuoteApplication.java          entry point, service and command modes
  config/Settings.java              supported currencies, countries and channels
  core/FeePolicy.java               the minimum and cap applied to a fee
  core/Pricing.java                 fee policy and pricing arithmetic
  legacy/Fees.java                  legacy fee helper
  jobs/Reconciliation.java          nightly batch reconciliation
  clients/PaymentClient.java        gateway client stub
  clients/Retry.java                retry with exponential backoff for external calls
  models/                           Transfer, Quote and BreakdownLine records
  services/TransferService.java     quoting and submission
  web/QuotesController.java         POST /api/quotes
  cli/QuoteRunner.java              the quote command
src/test/java/com/feequote/         JUnit 5 suite, one file per class
```

## Reconciliation

`Reconciliation.reconcile` takes the lines of a settled batch and reports any line
whose booked fee does not match the recomputed fee. It is run by the nightly batch
job and is not part of the request path.
