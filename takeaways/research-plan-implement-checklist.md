# Research, plan, implement: one-page checklist

## The loop

**Research (read-only)**

- [ ] Use read-only tools only: VS Code's Plan agent, Copilot CLI plan mode (Shift+Tab), or `/research`.
- [ ] Find the tests that describe the behavior before reading the docs.
- [ ] Look for look-alike names and stale documentation. When the README and the tests disagree, start from the tests.
- [ ] Ask the clarifying question now, while it is cheap.

**Plan (reviewable)**

- [ ] The plan names the files to touch, the approach, the helper or module to reuse, and the verification steps.
- [ ] A person reads it. If the approach is wrong, correct the plan in one line before any code exists.
- [ ] Keep the plan: paste it into the pull request description or the issue.

**Implement (scoped and verified)**

- [ ] Stay within the plan. If the plan needs to change, change the plan first, then the code.
- [ ] Run the tests, the linter and the type checker (or the build with warnings as errors) before calling it done.
- [ ] Change a test's expected value only when the requirement changed, and say which requirement.
- [ ] The change still ends at a pull request that a person reviews.

**Before you start any of this**

- [ ] Pick the model tier for the task: a lower tier for mechanical, well-specified, verifiable, local work; a higher tier for design decisions, unfamiliar or misleading code, ambiguous requirements and planning.
- [ ] Attach the files you know matter (`#file` in VS Code, `@file` in the CLI) instead of the whole workspace.
- [ ] Standing rules live in `.github/copilot-instructions.md`, not in the prompt.

## Compare one real task with and without a plan

Run the same task twice from the same starting commit, on the same model tier: once with a single
prompt, once with research and a plan first. Reset between runs.

| Measure | Single prompt | Research, plan, implement |
|---|---|---|
| Model | | |
| Files read before the first edit | | |
| Correct result on the first attempt (yes or no) | | |
| Tests added for the requirement | | |
| Full suite green the first time | | |
| Checks run (tests, linter, type checker) | | |
| Files touched | | |
| Turns and tool calls | | |
| Tokens (input and output) | | |
| AI credits (`/usage` in the CLI, the context window control in VS Code) | | |

If the planned run costs more credits, look at where they went: reading before writing is cheap
input, and rework is expensive output plus the whole transcript re-sent on every turn.

For a team, baseline three numbers this month and read them again next month: first-attempt
green rate on agent tasks, credits per merged pull request, and rework turns per task.
