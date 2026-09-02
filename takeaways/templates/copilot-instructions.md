# <Project name> conventions

<!--
Save as .github/copilot-instructions.md. This file is sent with every request, on every
surface, so every line costs tokens on every turn. The six rules:
1. Keep it short: eight to twelve lines.
2. One rule per line, with the reason. The reason is what the model generalizes from.
3. Be concrete: name the helper to use and the one to avoid, and the ticket that explains why.
4. Leave out what tools already enforce. If the linter catches it, the line is wasted tokens.
5. Make the checks part of done.
6. Change it rarely, through a pull request, with CODEOWNERS on the .github folder.
Delete this comment block when the file is ready.
-->

- <A domain rule>, because <what goes wrong without it>.
- <Use this helper or module> for <this kind of work>; do not call <the look-alike to avoid>, because <reason> (<ticket>).
- Run `<test command>`, `<lint command>` and `<type-check or build command>` before declaring a task complete. A task with failing checks is not done.
- New behavior needs a test in the same change, built on <the worked examples or fixtures to prefer>.
- Keep side effects in <where they belong>; keep <core logic location> pure.
- Do not change public signatures without updating every caller and <the docs that describe them>.
- Do not edit a test's expected value to make it pass unless the requirement itself changed; say which requirement changed.
- When a requirement is ambiguous, list the options and ask before implementing.
