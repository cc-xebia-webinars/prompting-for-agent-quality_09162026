---
applyTo: "<test folder glob, for example tests/** or src/**/*.test.ts>"
---
# Test conventions

<!--
Save under .github/instructions/. It loads only when files matching applyTo are in play, so
rules that only matter for tests stay out of every other request. Delete this comment block
when the file is ready.
-->

- Name tests after the behavior they check, in plain words, not `test_1`.
- One behavior per test. If a test needs two unrelated asserts, split it or parametrize it.
- Use <the shared fixtures or worked examples> rather than invented values.
- No sleeps and no network. Inject a fake clock, sleep or transport instead.
- <Any typing or naming rule your test runner or linter does not already enforce.>
