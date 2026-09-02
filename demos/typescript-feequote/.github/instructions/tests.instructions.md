---
applyTo: "test/**"
---
# Test conventions

- Name a test for the behavior it proves, and cite the ticket when there is one (for example "regression ticket 4821: domestic fee rounds half to even"). Test files are named after the module under test, not after the bug.
- One behavior per test. Several assertions are fine when they all describe that one behavior.
- Use the worked examples from the fee policy (ticket 4821 rounding, cap applies, minimum applies, plain) instead of invented numbers.
- No sleeps and no network. Inject a sleep function instead of waiting on a timer, and use `StubPaymentClient` instead of a real gateway.
- Tests are independent: build fixtures inside the test or in a small helper, and never rely on execution order.
