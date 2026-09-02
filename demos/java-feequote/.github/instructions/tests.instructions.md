---
applyTo: "src/test/**"
---
# Test conventions

- Name tests after the behavior they check, in plain words: `quoteAppliesMinimumAndCap`, not `test1`.
- One behavior per test. If a test needs two unrelated asserts, split it or turn it into a `@ParameterizedTest`.
- Use the worked examples from the fee policy (123500, 500000, 5000, 100000 cents) rather than invented amounts.
- No sleeps and no network. Inject a fake `Sleeper` or `Transport` instead; the suite must stay under a few seconds.
- Assert with AssertJ (`assertThat`), and keep test classes package-private to match the existing suite.
