# FeeQuote agent notes

- Money is integer cents; never floating point.
- Fee math goes through core pricing (`Pricing.PriceWithPolicy`, `Pricing.ComputeFee`); nothing under `Domain/Legacy/` is called from new code.
- Run `dotnet test`, `dotnet format --verify-no-changes`, `dotnet build -warnaserror`, and the ClientApp `npm run check` before calling a task done.
- New behavior ships with a test in the same change, using the worked examples from the fee policy.
- `.github/copilot-instructions.md` is the source of truth for these conventions; this file is a summary.
