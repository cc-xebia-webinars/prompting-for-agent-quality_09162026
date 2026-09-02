# FeeQuote conventions

- Money is integer cents. Never use floating point for amounts or fees; rounding errors here are customer-visible.
- Fee math goes through core pricing (`priceWithPolicy`, `computeFee` in `src/core/pricing.ts`). Anything under `src/legacy/` must not be called from new code; it truncates and ignores the fee policy (ticket 4821).
- Run the full test suite, the linter, and the type checker (`npm run check`) before declaring a task complete. A task with failing checks is not done.
- New behavior needs a test in the same change. Prefer the worked examples from the fee policy over invented numbers.
- Keep functions small and pure where possible; side effects live in `src/clients/` and `src/jobs/`.
- Do not change public function signatures without updating every caller and the README.
- Prefer editing an existing module over creating a new one for a small feature.
- When a requirement is ambiguous, list the options and ask before implementing.
