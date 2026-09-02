# FeeQuote conventions

- Money is integer cents. Never use floating point for amounts or fees; rounding errors here are customer-visible.
- Fee math goes through core pricing (`Pricing.PriceWithPolicy`, `Pricing.ComputeFee`). Anything under `Domain/Legacy/` must not be called from new code; it truncates and ignores the fee policy (ticket 4821).
- Run the full test suite, the linter, and the type checker before declaring a task complete. A task with failing checks is not done.
- New behavior needs a test in the same change. Prefer the worked examples from the fee policy over invented numbers.
- Keep functions small and pure where possible; side effects live in `Domain/Clients/` and `Domain/Jobs/`.
- Do not change public function signatures without updating every caller and the README.
- Prefer editing an existing module over creating a new one for a small feature.
- When a requirement is ambiguous, list the options and ask before implementing.
- The React app in `ClientApp/` mirrors the API contract in `api.ts`; change both sides in the same change and keep the JSON field names in sync.
