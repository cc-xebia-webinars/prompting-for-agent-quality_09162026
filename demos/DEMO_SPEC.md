# FeeQuote demo repositories: shared specification

These demo repositories support a two-hour webinar, "Prompting for Agent Quality: Why Optimizing Quality Beats Cutting Token Costs", delivered with GitHub Copilot in VS Code, the GitHub Copilot app, and Copilot CLI. Five repositories implement the same small domain in different stacks so the presenter can pick the one that matches the audience. Every repository must follow this specification exactly so the demo script is identical across stacks.

## 1. The domain

FeeQuote is a small service that quotes the fee for a customer payment transfer at a bank.

Money is always handled as integer minor units (cents). Never use binary floating point for money.

Domestic fee policy (the correct rule, implemented by the "core pricing" helper):

- Rate: 90 basis points (0.9 percent) of the transfer amount.
- Minimum fee: 100 cents.
- Maximum fee (cap): 2500 cents.
- Rounding: round half to even (banker's rounding) to whole cents. Compute `amount_cents * rate_bps / 10000` exactly (integer numerator, integer denominator) and round the quotient half to even.
- Order: compute the raw fee, round it, then apply the minimum and the cap.

Worked examples (use these in tests, with exactly these names and values):

| Case | Amount (cents) | Raw fee | Correct fee (cents) | Legacy helper result (cents) |
|---|---|---|---|---|
| ticket 4821 rounding | 123500 | 1111.5 | 1112 | 1111 |
| cap applies | 500000 | 4500 | 2500 | 4500 |
| minimum applies | 5000 | 45 | 100 | 45 |
| plain | 100000 | 900 | 900 | 900 |

## 2. The planted ambiguity (required, identical in every stack)

The repository contains two similarly named fee helpers. One is correct and one is a legacy helper that is subtly wrong. A one-shot agent that trusts the README will pick the wrong one. A planning agent that reads the tests first will not.

Correct helpers, in the core pricing module:

- `price_with_policy(amount_cents, rate_bps, policy) -> int` (name adapted to the language's conventions, for example `PriceWithPolicy` in C#, `priceWithPolicy` in TypeScript). Generic: any rate, any policy (minimum, cap), half-to-even rounding. This is the building block new fee types must use.
- `compute_fee(amount_cents) -> int`: the domestic fee, defined as `price_with_policy(amount_cents, 90, DOMESTIC_POLICY)`.

Legacy helper, in a module named `legacy` (Python `feequote/legacy/fees.py`, TypeScript `src/legacy/fees.ts`, C# `FeeQuote/Legacy/Fees.cs`):

- `calculate_fee(amount_cents, rate_bps) -> int`: truncates instead of rounding half to even, applies no minimum and no cap. It must NOT carry a loud deprecation marker. Its module docstring or header comment says only: "Retained for the nightly batch reconciliation job. Scheduled for removal once reconciliation moves to core pricing (see ticket 4821)." The one legitimate caller is `jobs/reconciliation` (a small module that reconciles batch totals).

The README must be stale in exactly this way: under a heading "Fee calculation" it says "All fee calculations go through the generic helper `calculate_fee(amount_cents, rate_bps)` in the legacy fees module. Pass the rate in basis points." with a short code example that calls it. It must not mention `price_with_policy` or `compute_fee` at all. Everything else in the README is accurate (setup, running tests, project layout).

Tests that catch the trap (both must exist in the baseline):

- `test_regression_ticket_4821` (name adapted to language conventions, but it must contain "4821"): asserts that a 123500 cent amount is priced at 1112 (through `compute_fee` or through the quote the transfer service returns), with a comment: "The legacy helper returns 1111 here because it truncates. See ticket 4821." The test file name must not advertise rounding; put it in a file named after the service (for example `test_transfer_service` or `TransferServiceTests`), not `test_rounding`.
- An architecture test (`test_architecture` / `ArchitectureTests`): scans the production source tree and asserts that nothing outside the `legacy` module and the reconciliation job references `calculate_fee`. On failure the message says: "New code must not call the legacy fee helper. Use core pricing (price_with_policy or compute_fee) instead. See ticket 4821." Make this test a plain source scan (read files, regex), so it works identically in every stack.

## 3. Modules (adapt names to the stack's conventions)

- `models`: `Transfer` (id, amount_cents, currency, origin_country, destination_country, channel), `Quote` (transfer_id, fee_cents, total_cents, breakdown as a list of labeled amounts).
- `core/pricing`: `FeePolicy` (minimum_cents, cap_cents), `DOMESTIC_POLICY`, `round_half_even_div(numerator, denominator)`, `price_with_policy`, `compute_fee`.
- `legacy/fees`: `calculate_fee` as described.
- `jobs/reconciliation`: uses `calculate_fee` to reproduce historical batch totals (this is the legitimate caller). Small.
- `clients/payment_client`: a stub gateway client with `submit(transfer)`. It has no retry logic and must not import the retry module. The transport takes `(transfer, idempotency_key)` and returns the gateway reference. No comment explains what the key does; the parameter name is the only hint. `submit` validates, then calls a small private send method that mints a fresh key and calls the transport in one expression. The stub transport returns the original reference for a repeated key.
- `clients/errors` (where the language needs it to avoid a circular import): the gateway error type, imported by both the client and the retry helper, so a client that adopts the retry helper still imports cleanly, plus two subtypes: a timeout ("The gateway did not respond in time.") and a decline ("The gateway declined the transfer."). No comment anywhere says when to retry.
- `clients/retry`: a `with_retry(fn, attempts=3, backoff_ms=...)` helper with exponential backoff and an injectable sleep, referenced only by its own tests. Its default retry filter is the base gateway error, so it also retries declines unless the caller narrows it. A design task in the model-tier demo asks the agent to add retry with backoff to the client. Finding the helper is easy; the trap is where the retry goes. Wrapping the private send method mints a new idempotency key on every attempt, so a timeout whose response was lost becomes a second payment. Retrying every gateway error resends a declined transfer. The correct change mints the key once and retries only timeouts. The hints are deliberately thin: with a comment that explained the key, `claude-haiku-4.5` in Copilot CLI sometimes got it right.
- `services/transfer_service`: `quote(transfer) -> Quote` using `compute_fee`, and `submit(transfer)` that quotes then submits through the client.
- `config`: currency list, country list, default channel.
- An entry point: a small CLI (`python -m feequote quote --amount 123500 --from AU --to AU`, `npm run quote -- ...`, `dotnet run --project ... -- quote ...`) that prints a quote as JSON. For the ASP.NET MVC + React repository the entry point is the web app and a `/api/quotes` endpoint instead.

Keep it small: roughly 12 to 18 production source files, tests that run in under ten seconds, a linter, and a type checker (or compiler warnings as errors).

## 4. The feature task used in the main demo (run A and run B)

The presenter will paste this prompt into the agent. Do not implement it; the repository must be in the state BEFORE this feature exists. Put the prompt verbatim in DEMO_SCRIPT.md.

> Add support for international transfers. A transfer is international when the destination country differs from the origin country. International transfers incur an additional FX fee of 50 basis points of the amount, subject to the same minimum, cap, and rounding policy as the domestic fee. The quote must show the FX fee as its own line in the breakdown and include it in the total. Acceptance examples: a 247100 cent international transfer quotes a domestic fee of 2224, an FX fee of 1236, and a total fee of 3460. A 1000000 cent international transfer quotes 2500 domestic, 2500 FX, total 5000. A domestic transfer is unchanged. Add tests for these examples and run the full test suite.

Why this traps a one-shot agent: the README points at `calculate_fee(amount_cents, rate_bps)`, whose rate parameter looks like exactly what an FX fee needs. Using it for the FX fee yields 2224 + 1235 = 3459 for the first example and 7500 instead of 5000 for the second, because the FX fee is never capped (using it for both fees yields 3458 and 14000), and the architecture test fails. A planning agent that reads the tests sees `test_regression_ticket_4821` and the architecture test, and reaches for `price_with_policy`.

## 5. Customization files (identical intent in every stack)

These files are added AFTER the baseline commit (see section 7) so the main demo can run without them.

`.github/copilot-instructions.md` (eight to twelve lines, one rule per line, each with a short reason):

```
# FeeQuote conventions

- Money is integer cents. Never use floating point for amounts or fees; rounding errors here are customer-visible.
- Fee math goes through core pricing (`price_with_policy`, `compute_fee`). Anything under `legacy/` must not be called from new code; it truncates and ignores the fee policy (ticket 4821).
- Run the full test suite, the linter, and the type checker before declaring a task complete. A task with failing checks is not done.
- New behavior needs a test in the same change. Prefer the worked examples from the fee policy over invented numbers.
- Keep functions small and pure where possible; side effects live in `clients/` and `jobs/`.
- Do not change public function signatures without updating every caller and the README.
- Prefer editing an existing module over creating a new one for a small feature.
- When a requirement is ambiguous, list the options and ask before implementing.
```

`.github/instructions/tests.instructions.md` with an `applyTo` frontmatter matching the test tree (`tests/**` for Python and C#, `src/**/*.test.ts` and `test/**` for TypeScript), containing four or five test conventions (naming, one behavior per test, use the worked examples, no sleeps or network).

`AGENTS.md` at the repository root: a short version of the same rules (five lines) with a line noting that `.github/copilot-instructions.md` is the source of truth.

`.github/agents/reviewer.agent.md`:

```
---
name: reviewer
description: Reviews a change against the FeeQuote conventions and the test suite. Read-only; never edits files.
# Two generations of tool name are in circulation. `read` and `search` are the
# cross-surface aliases; the rest are the older VS Code and Copilot CLI names.
# Every surface ignores names it does not recognize, so one file can carry both
# sets and stay read-only on all of them.
tools: ['read', 'search', 'codebase', 'usages', 'problems', 'runTests', 'view', 'grep', 'glob']
# `model` takes a single name on every surface; VS Code also accepts a prioritized
# list. Model IDs change frequently, so confirm this model is enabled for your account.
model: claude-sonnet-5
# `agents` is a VS Code key. In the CLI the same result comes from leaving the `agent` tool out of `tools`.
agents: []
user-invocable: true
---
You are a code reviewer for the FeeQuote repository. Review the working tree changes (or the change the user names) against `.github/copilot-instructions.md` and the test suite.

Report, in this order: correctness risks, convention violations (especially any use of the legacy fee helper outside `legacy/` and the reconciliation job), missing tests, and readability. Quote file paths and line numbers. Do not edit files. End with a one-line verdict: approve, approve with nits, or request changes.
```

`.github/skills/release-notes/SKILL.md` plus a script (`scripts/release_notes.py`, `.sh`, or `.ps1` as fits the stack, and it must run on macOS, Linux and Windows):

```
---
name: release-notes
description: Generate release notes for FeeQuote from the git log between two tags, grouped by type (feature, fix, chore) in the house format. Use when asked for release notes, a changelog, or "what shipped".
---
# Release notes

1. Run `scripts/release_notes.py <from-tag> <to-tag>` (or the stack's equivalent) from the repository root. It prints commits grouped by conventional-commit type.
2. Turn the output into the house format below. Keep each line under 100 characters. Do not invent changes that are not in the log.

## House format

## FeeQuote <to-tag>

### Features
- ...

### Fixes
- ...

### Chores
- ...
```

`.vscode/mcp.json`:

```json
{
  "servers": {
    "github": {
      "type": "http",
      "url": "https://api.githubcopilot.com/mcp/"
    }
  }
}
```

## 6. Commit messages and history

Use conventional-commit prefixes so the release-notes skill has something to group. The setup script (section 7) creates this history:

1. `feat: add FeeQuote domain, pricing, transfer service and CLI` (baseline: everything except the customization files) then tag `v0.1.0` and create branch `demo-start` pointing at it.
2. `chore: add repository instructions and AGENTS.md` (`.github/copilot-instructions.md`, `.github/instructions/`, `AGENTS.md`).
3. `feat: add reviewer custom agent` (`.github/agents/`).
4. `feat: add release-notes skill` (`.github/skills/`).
5. `chore: add MCP server configuration` (`.vscode/mcp.json`) then tag `v0.2.0`.
6. Branch `demo-checks` from `v0.2.0` with one commit (a realistic message such as `refactor: tidy domestic fee policy`) whose defect the test suite does not catch but the stack's other checks do: an unused import plus a wrong type or style violation for the linter and type checker (Python: `cap_cents=2500.0` and an unused `import math`, so pytest passes while ruff and mypy fail). In stacks where the build treats warnings as errors, the check may instead stop the build before any test runs; the demo script says which. The setup script makes the edit with an in-script text replacement, fails loudly if the replacement did not apply, and checks `main` out again.

## 7. Files every repository must include

Each stack has two folders side by side under `demos/`: the repository (`<stack>/`), which holds only the demo program and is what agents work in, and `demo-kit/<stack>/`, which holds the presenter's files (`DEMO_SCRIPT.md`, `prompts.txt`, `RUN_COMPARISON.md`, `setup-demo.sh`, `setup-demo.ps1`, `tier-check/`). `demo-kit/run-stats.py` is shared by all stacks. No presenter file may be placed inside a repository folder: agents read whatever is in their working folder, and these files hold the expected answers.


- Everything runs on macOS, Linux and Windows. Text files use LF line endings (`*.cmd` excepted), executable files (`mvnw`, shell scripts) are committed with mode 100755, file names match their imports exactly (Linux is case-sensitive), and `setup-demo.sh` runs under macOS's bash 3.2 and BSD tools (no `sed -i`, `grep -P`, `mapfile` or other GNU-only features).
- `README.md`: accurate setup and run instructions for Windows and macOS/Linux, project layout, the stale "Fee calculation" section described in section 2, and a short "Running the checks" section.
- `demo-kit/<stack>/DEMO_SCRIPT.md`: the presenter's script for this repository. Paths are written as `~/demos/...`, and wherever a command differs by operating system the script shows a **macOS and Linux** block followed by a **Windows** block. Every demo runs live; the script never refers to recordings or screenshots. Sections: How to read this script; Prerequisites and setup; Reset between rehearsals (including removing the segment 4.3 worktrees); then one section per segment, each opening with **Where**, **Branch** and **What this shows**, followed by numbered steps that each give **Do**, **Paste** (copy-paste ready), **Expected** (what a correct result looks like for that exact prompt), **Point at** and **Say**, and closing with **If something goes wrong** and **Where this shows up in real repositories** (generic patterns, never invented incidents). Segments:
  - 4.2 context window: in VS Code attach README, core pricing, the legacy fees module, the transfer service and the transfer service test with `#file`, and ask "Which fee helper should new code call, and why? Answer from the code, not the README."; then in Copilot CLI attach the same files with `@` plus a rule ("end every answer with a final line that starts with Sources:"), run `/context`, `/compact`, `/context`, ask a follow-up and check whether the rule survived.
  - 4.3 model tier: two git worktrees of `demo-start` and two CLI sessions, one on a lower tier and one on a higher tier, both given "Add retry with exponential backoff to the payment client submit path"; a presenter-only check (`demo-kit/<stack>/tier-check/`, copied into each worktree's test folder after the run) that drives the submit path through the transfer service against a fake gateway and reports `customer charged 2 times` for a run that minted a new key per attempt; `/usage` in both. The mechanical task "Rename `compute_fee` to `domestic_fee` across the code and tests, keep a deprecated alias for one release" is an optional step.
  - 4.5 run A in Copilot CLI standard mode and run B with the VS Code Plan agent: the feature prompt verbatim, a table of correct versus trap results, a command that prints the quote so the total can be checked, the comparison fields, and a pointer to `RUN_COMPARISON.md` for the rehearsal tally.
  - 4.7 on `demo-checks`: show the tests passing, then "Run every check listed in AGENTS.md and fix whatever they report. Do not change any tests."; then on `main` "Change the domestic cap to 3000 cents and update everything that depends on it", which breaks the cap tests until the agent updates them; then show the instruction files; then `/chronicle improve`.
  - 4.9: a subagent survey started first in VS Code ("Use a subagent for this so the file contents stay out of this chat. Survey every module that reads the domestic fee policy..."); the reviewer agent in VS Code; the release-notes skill with "Write release notes for v0.1.0 to v0.2.0"; the reviewer's agent file; the same reviewer via `copilot --agent reviewer -p "Review the uncommitted change to the domestic cap in <core pricing file> and the tests that cover it"` (the same prompt on both surfaces; it names the file because the reviewer has no shell tool); `/mcp show`, which lists the CLI's built-in `github-mcp-server`, and a GitHub MCP query against a public repository; back to the survey to show the subagent's own tool calls and credits (its model and elapsed time appear in the VS Code Agents window).
  - 4.10: Ctrl+O and Ctrl+T in the CLI timeline (Ctrl+E only mentioned, since on a short timeline it shows the same as Ctrl+O), optionally one collapsed tool call group in VS Code chat with the point that collapsing is display only, then the same question two ways in a plain terminal: `git grep -n compute_fee -- <source paths>` run by the presenter (no model, no cost) and headless `copilot -p "Using git grep, list every caller of compute_fee" --allow-tool "shell(git:*)"` without `-s`, so its `AI Credits` and `Tokens` summary shows the cost of the same answer (the same command in every shell).
  - Rehearsal checklist, including the `demo-checks` expectations and the two model names used in 4.3.
- `demo-kit/<stack>/prompts.txt`: every prompt and command the presenter pastes, generated from `DEMO_SCRIPT.md` in script order, grouped by segment, with macOS and Linux and Windows variants where the script has them, and no expected answers.
- `demo-kit/run-stats.py`: presenter-only, standard-library Python, shared by all stacks and run from the repository folder as `../demo-kit/run-stats.py`. After `/exit` it reads the newest Copilot CLI session saved for the current folder (`~/.copilot/session-state/<id>/events.jsonl`) and prints run A's comparison numbers (model, files read before the first edit, turns, tool calls, the agent's test runs, whether the architecture test failed, files edited, tokens, AI credits); `--vscode` reads the newest VS Code chat session saved for the folder (`workspaceStorage/<hash>/chatSessions/*.jsonl`, replaying its patches) and prints run B's numbers per request (mode, credits, tokens, time), tool calls including subagents, clarifying questions and files edited; `--git-only` prints only files touched, tests added and legacy helper use. Both modes warn when the agent read `DEMO_SCRIPT.md`, `RUN_COMPARISON.md`, `prompts.txt`, `tier-check/` or anything under `demo-kit/`.
- `demo-kit/<stack>/RUN_COMPARISON.md`: an optional fill-in record of run A against run B, as labelled lines rather than a table: today's live run for each, a rehearsal tally summary for each, and an attempt block to copy per rehearsal.
- `demo-kit/<stack>/setup-demo.ps1` and `setup-demo.sh`: create the git history of section 6 from the files on disk in `../../<stack>` (the repository next to `demo-kit`), wherever they are run from. Idempotent: refuse to run if `.git` already exists unless `-Force`/`--force` is passed, in which case they delete `.git` and rebuild, and only from a clean `main` checkout with every customization file present and no extra worktrees. Because the presenter's files are outside the repository, nothing needs excluding: they are never committed, never appear in a worktree, and `git clean` never touches them. They tag the `demo-checks` commit `demo-checks-base`, so `git branch -f demo-checks demo-checks-base` restores it. Set `git config user.name "FeeQuote Demo"` and `user.email "demo@example.com"` locally so commits work on a fresh machine. Both scripts must be tested (the .sh one on Linux and under bash 3.2; the .ps1 one on Windows).
- `.gitignore` appropriate to the stack (no `node_modules`, `bin`, `obj`, `.venv`, `__pycache__`, `.pytest_cache`, `.mypy_cache`, `.ruff_cache`, `dist`, `coverage`).
- Editor and tool configuration so linter and type checker run with one command each.

## 8. Rules for all text in these repositories

- No em dashes anywhere
- No first-person narration, stage directions or session timings; these files are read by attendees, not by the presenter (use commas, periods, or parentheses). `DEMO_SCRIPT.md` is the exception: it is the presenter's script, so it carries lines to say, prediction questions the presenter asks attendees to answer in chat, and references to checkpoints, but still no minute-by-minute timings.
- Do not mention the webinar length or any timings in repository files.
- Do not name the model vendors in code comments; `.agent.md` model names are the exception because the frontmatter requires them.
- Comments and docstrings should read like a real internal codebase, not like a demo. The only files that talk about the demo are in `demo-kit/`.
- Keep every file under 200 lines, except `DEMO_SCRIPT.md`, which is as long as it needs to be to stay unambiguous.

## 9. Verification the builder must perform before finishing

1. At the full (v0.2.0) state: the test suite passes, the linter passes, the type checker (or build with warnings as errors) passes.
2. At the baseline state (customization files absent): the same three checks pass. Since the customization files are not code, this is the same result; confirm nothing in the tooling depends on them.
2a. On `demo-checks`: the test suite passes (or, in a warnings-as-errors stack, the build stops before tests as the demo script describes) and the linter or type checker fails with the messages quoted in `DEMO_SCRIPT.md`.
3. Manually simulate the trap: temporarily change `transfer_service` to call `calculate_fee` and confirm `test_regression_ticket_4821` and the architecture test both fail with clear messages, then revert.
4. Run `demo-kit/<stack>/setup-demo.sh` against a scratch copy (repository and `demo-kit` side by side) and confirm `git log --oneline` shows the five commits, the tags `v0.1.0`, `v0.2.0` and `demo-checks-base`, and the `demo-start` and `demo-checks` branches; then delete the scratch copy's `.git` so no `.git` directory is left in the deliverable.
5. Confirm no `node_modules`, `bin`, `obj`, `.venv`, cache directories, or `.git` directories remain in the deliverable tree, and the total is under 60 files.
