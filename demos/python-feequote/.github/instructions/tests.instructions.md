---
applyTo: "tests/**"
---
# Test conventions

- Name tests after the behavior they check, in plain words: `test_quote_applies_minimum_and_cap`, not `test_1`.
- One behavior per test. If a test needs two unrelated asserts, split it or parametrize it.
- Use the worked examples from the fee policy (123500, 500000, 5000, 100000 cents) rather than invented amounts.
- No sleeps and no network. Inject a fake `sleep` or transport instead; the suite must stay under a few seconds.
- Every test function is annotated `-> None` so `mypy --strict` stays clean.
