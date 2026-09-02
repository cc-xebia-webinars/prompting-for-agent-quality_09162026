# FeeQuote agent notes

- Money is integer cents (`long`); never use floating point or `BigDecimal` for amounts or fees.
- Fee math goes through core pricing (`priceWithPolicy`, `computeFee`); never call anything under `legacy/` from new code (ticket 4821).
- Run `./mvnw -q test`, `./mvnw -q checkstyle:check` and `./mvnw -q clean compile` before calling a task done.
- New behavior ships with a test in the same change, built on the worked examples from the fee policy.
- When a requirement is ambiguous, list the options and ask before implementing.

`.github/copilot-instructions.md` is the source of truth for these conventions; keep this file in sync with it.
