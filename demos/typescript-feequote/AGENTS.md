# FeeQuote agent notes

- Money is integer cents; never floating point.
- Fee math goes through core pricing (`priceWithPolicy`, `computeFee`); new code never calls anything under `src/legacy/` (ticket 4821).
- Run `npm run check` (tests, lint, typecheck) before calling a task done.
- New behavior ships with a test in the same change; prefer the worked examples from the fee policy.
- When a requirement is ambiguous, list the options and ask before implementing.

`.github/copilot-instructions.md` is the source of truth for these conventions; keep this file in sync with it.
