# Which mechanism, and when

| Mechanism | What it is | Reach for it when | Where it lives |
|---|---|---|---|
| Custom instructions | Standing rules that are always in context | A rule applies to most of the work in the repository | `.github/copilot-instructions.md`, `.github/instructions/*.instructions.md`, `AGENTS.md` |
| Agent skill | A packaged capability loaded on demand: `SKILL.md` plus scripts and resources | A multi-step procedure keeps coming back, such as release notes, a migration, or a house-style review | `.github/skills/<name>/SKILL.md`, `~/.copilot/skills/` |
| Custom agent | A persona with its own instructions, tools, model and allowed subagents | You want a specialist you can pick from the agent picker or delegate to | `.github/agents/<name>.agent.md`, `~/.copilot/agents/`, organization level |
| MCP server (Model Context Protocol) | External tools and data the agent can call through a standard interface | The agent needs a system of record: issues, tickets, databases | Copilot CLI `/mcp` and `.mcp.json`; VS Code `mcp.json`; organization allowlist |
| Subagent | An isolated context that does one sub-task and returns a result | A sub-task would flood the parent context, or could run in parallel | Automatic delegation; the VS Code agent tool; Copilot CLI delegation and `/fleet` |
| A test or a check | Deterministic feedback the agent can run itself | Something must be caught every single time | Your test suite, linter, type checker and CI required checks |

The question to ask each time: does this have to happen every single time? If it does, it
belongs in a test or a check, backed by an instruction line, because delegation to agents is
probabilistic.

# Ask your administrator

1. Which models does our model policy enable, and is automatic selection available?
2. Are budgets hard-capped at the user level? What happens to a running session when a cap is hit? (Usage is blocked until the next billing cycle; nothing falls back to a cheaper model.)
3. Paid usage beyond the included AI Credits is enabled by default unless an administrator disables it. Do we keep it, cap it, or turn it off, and at which level are budgets set: enterprise, cost center, organization, or user?
4. Which Copilot CLI version is deployed, and is `/chronicle` present? Is the "Store local sessions in the Cloud" policy enabled for our Business or Enterprise organization, and what are the retention and deletion rules?
5. Is the GitHub Copilot app enabled for us (it depends on the Copilot CLI policy)? Is `/fleet` allowed, and is local sandboxing on by default?
6. Are organization-level instructions, custom agents or skills already in place that our repositories inherit?
7. Is there an MCP server allowlist or registry, and is it enforced?
8. Are we Enterprise Managed Users (accounts owned and managed by the company rather than by individuals), and does our data policy allow `/share` links, gists and session sync?
9. Who owns `.github` in each repository? Is there a CODEOWNERS entry and a review requirement for instruction changes?
10. Which surfaces reach our JetBrains users, and are organization agents and skills published to them?

## A rollout order that works

1. Instruction files and the check loop: they cost nothing and cut rework straight away.
2. The model tier rule.
3. Skills and a read-only reviewer agent.
4. Subagents, MCP servers beyond GitHub, and parallel sessions, once the first three are habits.
