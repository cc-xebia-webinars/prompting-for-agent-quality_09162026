---
applyTo: "tests/**,src/FeeQuote.Web/ClientApp/src/**/*.test.tsx"
---
# Test conventions

- Name tests `Method_Scenario_Expectation` in C# (`Quote_DomesticTransfer_TotalIsAmountPlusFee`) and as plain sentences in Vitest (`it("renders the breakdown")`). The name should explain the failure without opening the file.
- One behavior per test. Several assertions about the same result are fine; several scenarios in one test are not.
- Use the worked examples from the fee policy (ticket 4821 rounding, cap applies, minimum applies, plain) rather than invented amounts, so a failure maps to a known case.
- No sleeps and no network. Inject a fake clock or delay, mock `fetch`, and use `WebApplicationFactory` for the API.
- Put the file next to the code it covers: `TransferServiceTests.cs` for `TransferService`, `App.test.tsx` beside `App.tsx`.
