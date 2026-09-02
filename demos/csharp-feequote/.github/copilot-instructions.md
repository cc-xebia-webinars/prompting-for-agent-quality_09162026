# FeeQuote conventions

- Money is integer cents (`long`). Never use `double` or `float` for amounts or fees; rounding errors here are customer-visible.
- Fee math goes through core pricing (`Pricing.PriceWithPolicy`, `Pricing.ComputeFee`). Anything under `src/FeeQuote/Legacy/` must not be called from new code; it truncates and ignores the fee policy (ticket 4821).
- Run `dotnet test`, `dotnet format --verify-no-changes` and `dotnet build -warnaserror` before declaring a task complete. A task with failing checks is not done.
- New behavior needs a test in the same change. Prefer the worked examples from the fee policy over invented numbers.
- Keep methods small and pure where possible; side effects live in `Clients/` and `Jobs/`.
- Do not change public method signatures without updating every caller and the README.
- Prefer editing an existing file over creating a new one for a small feature.
- Follow the `.editorconfig` style: file-scoped namespaces, braces on every block, explicit types unless the type is obvious; `dotnet format` rejects anything else.
- When a requirement is ambiguous, list the options and ask before implementing.
