# FeeQuote conventions

- Money is integer cents (`long`). Never use floating point or `BigDecimal` for amounts or fees; rounding errors here are customer-visible.
- Fee math goes through core pricing (`priceWithPolicy`, `computeFee`). Anything under `legacy/` must not be called from new code; it truncates and ignores the fee policy (ticket 4821).
- Run the full test suite, the linter, and the compiler before declaring a task complete. A task with failing checks is not done: `./mvnw -q test`, `./mvnw -q checkstyle:check`, `./mvnw -q clean compile`.
- New behavior needs a test in the same change. Prefer the worked examples from the fee policy over invented numbers.
- Keep methods small and pure where possible; side effects live in `clients/` and `jobs/`.
- Do not change public method signatures without updating every caller and the README.
- Prefer editing an existing class over creating a new one for a small feature.
- When a requirement is ambiguous, list the options and ask before implementing.
