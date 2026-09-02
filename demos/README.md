# FeeQuote demo repositories

Five implementations of the same small domain (a bank's payment transfer fee quoting service), built to support the webinar "Prompting for Agent Quality: Why Optimizing Quality Beats Cutting Token Costs" delivered with GitHub Copilot in VS Code, the GitHub Copilot app, and Copilot CLI. All five follow `DEMO_SPEC.md` so the demo script is the same whichever stack the audience uses.

| Folder | Stack | Checks | Use it for |
|---|---|---|---|
| `python-feequote/` | Python 3.14 via `uv`, pytest 9, ruff, mypy 2 | `python -m pytest -q`, `ruff check .`, `mypy feequote tests` (in an activated venv; otherwise prefix each with `uv run`) | Default for every live segment (4.2, 4.3, 4.5, 4.7, 4.9, 4.10): fastest test runs, easiest to read on a shared screen |
| `typescript-feequote/` | Node 24 LTS, TypeScript 6, vitest 4, eslint 10 | `npm test`, `npm run lint`, `npm run typecheck` | Same script as Python for a web or platform audience |
| `csharp-feequote/` | .NET 10 console, xunit v3, dotnet format | `dotnet test`, `dotnet format --verify-no-changes`, `dotnet build -warnaserror` | Same script as Python for a .NET audience |
| `java-feequote/` | Java 25, Spring Boot 4.1, JUnit 5, Checkstyle 14, Maven wrapper | `./mvnw -q test`, `./mvnw -q checkstyle:check`, `./mvnw -q clean compile` | Same script as Python for a Java audience. Serves `POST /api/quotes` and also runs as a one shot `quote` command, so both the API and the CLI steps work |
| `aspnet-react-feequote/` | ASP.NET Core MVC (.NET 10) with a React 19 and TypeScript front-end (Vite 8, vitest 4) | backend checks as C# plus `npm test`, `npm run lint`, `npm run typecheck`, `npm run build` in `ClientApp` | Same script as Python for a full-stack .NET audience. Its script also carries a take-home exercise: two agent sessions in parallel (API and front end) in separate git worktrees |

Each repository folder holds only the demo program: its code, tests, customization files and its own `README.md` (the stale "Fee calculation" section is deliberate, see the spec). Everything for the presenter lives next to the repositories in `demo-kit/`, so an agent working in a repository or one of its worktrees can never read it:

| In `demo-kit/` | What it is |
|---|---|
| `<stack>/DEMO_SCRIPT.md` | Every prompt for every segment, with the expected results |
| `<stack>/prompts.txt` | The same prompts and commands ready to paste (no expected answers) |
| `<stack>/RUN_COMPARISON.md` | For recording run A against run B, if you want to |
| `<stack>/setup-demo.sh`, `<stack>/setup-demo.ps1` | Build the git history the demos depend on, in `../<stack>` |
| `<stack>/tier-check/` | The presenter-only check for the model-tier demo (segment 4.3) |
| `run-stats.py` | Prints the run A and run B comparison numbers from the saved Copilot CLI and VS Code sessions (segment 4.5) |

Every repository runs on macOS, Linux and Windows.

## What is planted in every repository

- Two fee helpers: the correct `compute_fee` and `price_with_policy` in core pricing (half-to-even rounding, minimum, cap) and a legacy `calculate_fee` that truncates and ignores the policy. The README points new readers at the wrong one.
- A regression test named after ticket 4821 (a 123500 cent transfer is priced at 1112; the legacy helper returns 1111) and an architecture test that fails if any new code references the legacy helper.
- Customization files added after the baseline commit: `.github/copilot-instructions.md`, `.github/instructions/tests.instructions.md`, `AGENTS.md`, `.github/agents/reviewer.agent.md`, `.github/skills/release-notes/SKILL.md` with its script, and `.vscode/mcp.json`.
- Git history created by the setup script: baseline commit tagged `v0.1.0` with a `demo-start` branch (no customization files), four commits adding the customization files, tagged `v0.2.0` on `main`, and a `demo-checks` branch (tag `demo-checks-base`) with one extra commit whose defect the tests do not catch but the linter, type checker, formatter or build does. Nothing from `demo-kit/` is in any repository, branch or worktree, and resets never touch it.

## Setting up (macOS, Linux or Windows)

1. Copy the five repository folders and `demo-kit` to `~/demos/` (on Windows, `C:\Users\<you>\demos\`), side by side, before running any setup, and keep them out of any synchronized folder (OneDrive, iCloud Drive, Dropbox). Package restores (`node_modules`, `bin`, `obj`, `.venv`, `target`) do not belong in a synced folder.
2. For each repository run its setup script from `demo-kit`, for example `bash ~/demos/demo-kit/python-feequote/setup-demo.sh` on macOS and Linux, `~/demos/demo-kit/python-feequote/setup-demo.ps1` on Windows (if execution policy blocks it: `pwsh -ExecutionPolicy Bypass -File ~/demos/demo-kit/python-feequote/setup-demo.ps1`). The script works on the repository folder next to `demo-kit`, wherever you run it from. The script refuses to run if `.git` already exists; pass `--force` (`-Force` in PowerShell) to rebuild the history.
3. Install the stack's dependencies and run the checks listed in the table above. Every suite should be green on both `main` and `demo-start`. On `demo-checks` the tests pass and at least one other check fails; that is intended. For Python: `uv venv --python 3.14`, then `uv pip install -r requirements-dev.txt`; uv downloads CPython 3.14 itself, so no system Python is required. Activate the venv (`source .venv/bin/activate` on macOS and Linux, `.\.venv\Scripts\Activate.ps1` on Windows) in whatever terminal you will run Copilot from, because the agent is instructed to run `python -m pytest -q` on its own, and outside the venv macOS and Linux usually have no `python` command while Windows resolves it to the Microsoft Store alias stub. Java on Windows uses `.\mvnw.cmd` in place of `./mvnw`.
4. Open the folder in VS Code and confirm the Copilot Chat agent picker shows `reviewer` and the MCP view lists `github` (on `main`).
5. Sign in to Copilot CLI (`copilot` in the repository root), then run `/mcp show` and `/chronicle` once so both are known to work on this machine. `/mcp show` lists the CLI's built-in `github-mcp-server`; `.vscode/mcp.json` is read only by VS Code. Run Copilot CLI in a terminal app (Terminal or iTerm2 on macOS, Windows Terminal on Windows), not the VS Code integrated terminal. On Windows use PowerShell 7 (`pwsh`): Windows PowerShell 5.1 cannot run the `&&` commands in the demo scripts.

The main demo (run A in Copilot CLI, run B with the VS Code Plan agent) starts from a clean `demo-start` every time. The reset commands are in each `demo-kit/<stack>/DEMO_SCRIPT.md`.

## Which repository for which segment

Each delivery runs every live segment on one stack; the stack does not change between segments. The table shows the default, Python. The other repositories are reference copies of the same demos, sent to attendees after the session.

| Segment | Repository | Surface |
|---|---|---|
| 4.2 Context window | python-feequote, `demo-start` | VS Code, then CLI |
| 4.3 Model tier | python-feequote, in two git worktrees of `demo-start` | Two CLI sessions side by side, one lower tier and one higher tier |
| 4.5 Research, plan, implement | python-feequote, `demo-start` reset before each run | CLI for run A, VS Code for run B, both on the same model tier |
| 4.7 Guardrails and instructions | python-feequote, `demo-checks` then `main` | CLI, then VS Code |
| 4.9 Custom agents, skills, MCP, subagents | python-feequote, `main` with the uncommitted 4.7 change | VS Code, then CLI, then back to VS Code |
| 4.10 Power-user tips (collapsing tool calls, headless) | python-feequote, `main` | CLI, VS Code, then a terminal |
| 4.11 Closing | no demo | Slides |

Every segment runs live.

The retry helper in every repository lives in its own module (`clients/retry` or the stack's equivalent) and is not imported by the payment client. In the model-tier demo the helper is easy to find; the test is where the retry goes. The payment client mints a fresh idempotency key inside the call an agent would naturally wrap, so a plain wrap charges the customer twice when a gateway response is lost. Each stack's `demo-kit/<stack>/tier-check/` folder holds the presenter-only check that shows it, outside the repository, so no agent can see it.

Python is the default because its suite is the fastest and its files read most easily on a shared screen. A Java audience can run every segment in the table on `java-feequote` instead: it carries the same planted ambiguity, the same acceptance numbers, and its own `DEMO_SCRIPT.md` with each prompt already translated. Each repository uses the identifiers and commands listed in the table above.

## Files in this folder

- `DEMO_SPEC.md`: the shared specification all five repositories follow.
- `python-feequote/`, `typescript-feequote/`, `csharp-feequote/`, `java-feequote/`, `aspnet-react-feequote/`: the repositories.
- `FeeQuoteDemos.zip`: the five repositories plus the attendee takeaways (`takeaways/`: templates, the one-page checklist, the decision table and administrator checklist, and links), as sent after the session.
