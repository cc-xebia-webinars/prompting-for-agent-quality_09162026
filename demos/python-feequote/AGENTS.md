# FeeQuote agent notes

- Money is integer cents; never use floating point for amounts or fees.
- Fee math goes through core pricing (`price_with_policy`, `compute_fee`); never call anything under `legacy/` from new code (ticket 4821).
- Run `python -m pytest -q`, `ruff check .` and `mypy feequote tests` before calling a task done.
- New behavior ships with a test in the same change, built on the worked examples from the fee policy.
- When a requirement is ambiguous, list the options and ask before implementing.

`.github/copilot-instructions.md` is the source of truth for these conventions; keep this file in sync with it.
