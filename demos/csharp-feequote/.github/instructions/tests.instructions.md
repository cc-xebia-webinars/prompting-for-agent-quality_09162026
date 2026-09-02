---
applyTo: "tests/**"
---
# Test conventions

- Name tests `Method_Scenario_Expectation` (for example `Quote_TotalIsPrincipalPlusFee`) and put them in the file named after the production type under test.
- One behavior per test. If a test needs two unrelated assertions, split it; a `[Theory]` with `[InlineData]` is the right tool for the same behavior over several inputs.
- Use the worked examples from the fee policy (123500, 500000, 5000, 100000 cents) rather than invented amounts, and keep the case names from `PricingTests` so failures trace back to the rule.
- No sleeps, timers, network calls or real gateway traffic. Inject a delay callback or a fake `IPaymentClient` instead.
- Assert with xunit's specific helpers (`Assert.Single`, `Assert.Empty`, `Assert.Throws<T>`) and pass a message to `Assert.True` when the failure would otherwise be cryptic.
