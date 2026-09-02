# Prompting for Agent Quality: takeaways

Everything promised in the session, in one folder.

| File | What it is |
|---|---|
| `templates/copilot-instructions.md` | A starting point for `.github/copilot-instructions.md`, built on the six rules |
| `templates/tests.instructions.md` | A path-specific instructions file with an `applyTo` glob |
| `templates/AGENTS.md` | The portable short version of the same rules |
| `templates/reviewer.agent.md` | A read-only reviewer custom agent |
| `templates/skills/example-skill/SKILL.md` | A skill skeleton, with `scripts/run.py` as the script it calls |
| `research-plan-implement-checklist.md` | One page: the loop, plus a table to compare a run with and without a plan |
| `decision-table-and-admin-checklist.md` | Which customization mechanism to use when, and the questions to settle with your administrator |
| `links.md` | The documentation behind everything in the session |


The FeeQuote demo repositories (Python, TypeScript, C#, Java with Spring Boot, and ASP.NET with
React) are in `FeeQuoteDemos.zip`, with every customization file and a step-by-step demo
script for each language. The ASP.NET with React script ends with an exercise for running two
agent sessions in parallel.

Copy a template into your repository, replace every line in angle brackets, and delete any
rule that your linter or type checker already enforces.
