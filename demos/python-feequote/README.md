# FeeQuote

FeeQuote quotes the fee for a customer payment transfer. It is a small,
dependency-free Python package with a command line entry point, a stubbed
payment gateway client, and a nightly batch reconciliation job.

Money is always handled as integer minor units (cents). Never use binary
floating point for amounts or fees.

## Requirements

- Python 3.14 or newer
- git

There are no runtime dependencies. Development tools (pytest, ruff, mypy) are
listed in `requirements-dev.txt`.

## Setup

With [uv](https://docs.astral.sh/uv/), which fetches CPython 3.14 for you so no system
Python is needed:

```bash
uv venv --python 3.14
source .venv/bin/activate          # Windows: .\.venv\Scripts\Activate.ps1
uv pip install -r requirements-dev.txt
```

Or with a system Python 3.14:

```bash
python3 -m venv .venv              # Windows: py -3 -m venv .venv
source .venv/bin/activate          # Windows: .\.venv\Scripts\Activate.ps1
pip install -r requirements-dev.txt
```

Activate the environment before running anything else; the commands below assume it.

## Quoting a transfer

```bash
python -m feequote quote --amount 123500 --from AU --to AU
```

`--amount` is in cents. `--from` and `--to` are ISO country codes and default
to `AU`. `--currency` defaults to `AUD` and `--channel` to `online`. The quote
is printed as JSON:

```json
{
  "transfer_id": "tr-3f2a9c1e",
  "fee_cents": 1112,
  "total_cents": 124612,
  "breakdown": [
    { "label": "domestic_fee", "amount_cents": 1112 }
  ]
}
```

## Fee calculation

All fee calculations go through the generic helper
`calculate_fee(amount_cents, rate_bps)` in the legacy fees module. Pass the
rate in basis points.

```python
from feequote.legacy.fees import calculate_fee

fee_cents = calculate_fee(amount_cents=100000, rate_bps=90)  # 900
```

## Running the checks

From the repository root, with the virtual environment active:

```bash
python -m pytest -q
ruff check .
mypy feequote tests
```

All three must pass before a change is merged. Tool configuration lives in
`pyproject.toml`.

## Project layout

```
feequote/
  __main__.py                  command line entry point
  config.py                    supported currencies, countries and channels
  models.py                    Transfer, Quote and BreakdownLine records
  core/pricing.py              fee policy and pricing arithmetic
  legacy/fees.py               legacy fee helper
  jobs/reconciliation.py       nightly batch reconciliation
  clients/errors.py            errors raised by external adapters
  clients/payment_client.py    gateway client stub
  clients/retry.py             retry with exponential backoff for external calls
  services/transfer_service.py quoting and submission
tests/                         pytest suite, one file per module
```

## Reconciliation

`feequote.jobs.reconciliation.reconcile` takes the lines of a settled batch
and reports any line whose booked fee does not match the recomputed fee. It
is run by the nightly batch job and is not part of the request path.
