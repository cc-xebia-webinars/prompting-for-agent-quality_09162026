---
name: <skill-name>
description: <One sentence saying what the skill does and when to use it, including the words people will type, for example "release notes", "changelog" or "what shipped".>
---
# <Skill title>

<!--
Save as .github/skills/<skill-name>/SKILL.md. Only the name and description sit in context
until the task matches, so write the description for matching. Put the repeatable part of the
procedure in a script: one script call replaces a dozen tool calls and runs the same way every
time. Skills run scripts, so review a shared skill like any other dependency. Delete this
comment block when the file is ready.
-->

1. Run `python .github/skills/<skill-name>/scripts/run.py <arguments>` from the repository root. It prints <what the output contains>.
2. Turn the output into the format below. <Length limits, tone, anything to leave out.> Do not invent content that is not in the script output.

## Output format

## <Heading>

### <Section>
- ...
