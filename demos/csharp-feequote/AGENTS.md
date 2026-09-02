# FeeQuote agent notes

- Money is integer cents; never floating point.
- Fee math goes through `Pricing.PriceWithPolicy` or `Pricing.ComputeFee`; nothing new calls `Legacy/` (ticket 4821).
- Run `dotnet test`, `dotnet format --verify-no-changes` and `dotnet build -warnaserror` before calling a task done.
- Every behavior change ships with a test that uses the fee policy's worked examples.
- `.github/copilot-instructions.md` is the source of truth for these rules; this file is the short version.
