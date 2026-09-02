<#
.SYNOPSIS
Builds the demo git history for this repository from the files on disk.

.DESCRIPTION
Works on ../../typescript-feequote next to this demo-kit folder
(~/demos/typescript-feequote), so it can be run from anywhere.

Creates five conventional commits on main, tags v0.1.0 and v0.2.0, a
demo-start branch at the baseline commit (no customization files), and a
demo-checks branch with one extra commit on top of v0.2.0:
  refactor: simplify quote argument parsing                      branch demo-checks, tag demo-checks-base

demo-checks carries a defect the test suite does not catch (the CLI no
longer rejects an unknown --channel, leaving an unused import) but ESLint
and tsc do. To restore it after an experiment:
  git branch -f demo-checks demo-checks-base

Refuses to run if a .git directory already exists unless -Force is given.
-Force only runs on a clean main checkout at v0.2.0 with no extra worktrees,
because the history is rebuilt from the files on disk.

The presenter's files (DEMO_SCRIPT.md, prompts.txt, RUN_COMPARISON.md, tier-check/,
run-stats.py and these scripts) live in demo-kit, outside the repository, so agents
working in the repository or its worktrees never read the expected answers.

.PARAMETER Force
Delete an existing .git directory and rebuild the history.

.EXAMPLE
~/demos/demo-kit/typescript-feequote/setup-demo.ps1
.EXAMPLE
~/demos/demo-kit/typescript-feequote/setup-demo.ps1 -Force
#>
[CmdletBinding()]
param(
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
$repo = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) "typescript-feequote"
if (-not (Test-Path -LiteralPath $repo -PathType Container)) {
    [Console]::Error.WriteLine("setup-demo.ps1: $repo not found. Keep demo-kit and typescript-feequote side by side under ~/demos.")
    exit 1
}
Set-Location -LiteralPath $repo

function Invoke-Git {
    & git @args
    if ($LASTEXITCODE -ne 0) {
        throw "git $($args -join ' ') failed with exit code $LASTEXITCODE"
    }
}

# Files that arrive after the baseline commit. They must all exist before
# anything runs, or the history would be built from an incomplete copy.
$customizationFiles = @(
    '.github/copilot-instructions.md',
    '.github/instructions',
    'AGENTS.md',
    '.github/agents',
    '.github/skills',
    'scripts',
    '.vscode/mcp.json'
)
# Committed with the executable bit, so checkouts on macOS and Linux can run them directly.
$executableFiles = @('scripts/release-notes.mjs')

foreach ($path in $customizationFiles) {
    if (-not (Test-Path -LiteralPath $path)) {
        [Console]::Error.WriteLine("setup-demo.ps1: $path is missing. Run this from a complete copy of the repository on main.")
        exit 1
    }
}

if (Test-Path -LiteralPath '.git') {
    if (-not $Force) {
        throw 'A .git directory already exists. Re-run with -Force to rebuild the history.'
    }
    # The history is rebuilt from the files on disk, so they must be the full main state.
    $branch = & git symbolic-ref --short -q HEAD
    $dirty = & git status --porcelain
    $worktrees = @(& git worktree list --porcelain | Where-Object { $_ -like 'worktree *' }).Count
    $head = & git rev-parse -q --verify HEAD
    $release = & git rev-parse -q --verify 'v0.2.0^{commit}'
    $atRelease = [bool]$release -and $head -eq $release
    if ($branch -ne 'main' -or $dirty -or $worktrees -gt 1 -or -not $atRelease) {
        [Console]::Error.WriteLine("setup-demo.ps1: -Force only runs on a clean main checkout at v0.2.0 with no extra worktrees (current branch: $branch, worktrees: $worktrees, HEAD at v0.2.0: $atRelease).")
        [Console]::Error.WriteLine('  Close VS Code and every Copilot CLI session first, then run the full rehearsal reset from DEMO_SCRIPT.md and git checkout main before trying again.')
        [Console]::Error.WriteLine('  To restore only demo-checks: git branch -f demo-checks demo-checks-base')
        exit 1
    }
    Write-Host 'Removing the existing .git directory and rebuilding the history.'
    Remove-Item -LiteralPath '.git' -Recurse -Force
}

Invoke-Git -c init.defaultBranch=main init -q
Invoke-Git symbolic-ref HEAD refs/heads/main
Invoke-Git config user.name 'FeeQuote Demo'
Invoke-Git config user.email 'demo@example.com'
Invoke-Git config core.autocrlf false
Invoke-Git config commit.gpgsign false
Invoke-Git config tag.gpgsign false

# 1. Baseline: everything except the customization files.
Invoke-Git add -A -- . ':(exclude).github' ':(exclude)AGENTS.md' ':(exclude).vscode/mcp.json' ':(exclude)scripts'
Invoke-Git commit -q -m 'feat: add FeeQuote domain, pricing, transfer service and CLI'
Invoke-Git tag v0.1.0
Invoke-Git branch demo-start

# 2. Repository instructions.
Invoke-Git add -- .github/copilot-instructions.md .github/instructions AGENTS.md
Invoke-Git commit -q -m 'chore: add repository instructions and AGENTS.md'

# 3. Reviewer agent.
Invoke-Git add -- .github/agents
Invoke-Git commit -q -m 'feat: add reviewer custom agent'

# 4. Release-notes skill and its script.
Invoke-Git add -- .github/skills scripts
# core.fileMode is false on Windows, so the executable bit has to be set in the index.
Invoke-Git update-index --chmod=+x -- @executableFiles
Invoke-Git commit -q -m 'feat: add release-notes skill'

# 5. MCP configuration.
Invoke-Git add -- .vscode/mcp.json
Invoke-Git commit -q -m 'chore: add MCP server configuration'
Invoke-Git tag v0.2.0

# 6. Checks demo branch: tests stay green, ESLint (no-unused-vars) and tsc (TS2322) fail.
Invoke-Git checkout -q -b demo-checks
$cliPath = Join-Path $repo 'src/cli.ts'
$cli = [System.IO.File]::ReadAllText($cliPath)
$newline = if ($cli.Contains("`r`n")) { "`r`n" } else { "`n" }
$channelCheck = '  if (!isChannel(channel)) throw new UsageError(`unknown channel: ${channel}`);' + $newline
if (-not $cli.Contains($channelCheck)) { throw 'setup-demo.ps1: could not prepare demo-checks' }
$cli = $cli.Replace($channelCheck, '')
# The channel check must be gone while the isChannel import stays behind.
if ($cli.Contains('isChannel(channel)') -or -not $cli.Contains('isChannel')) { throw 'setup-demo.ps1: could not prepare demo-checks' }
[System.IO.File]::WriteAllText($cliPath, $cli, [System.Text.UTF8Encoding]::new($false))
& git diff --quiet -- src/cli.ts
if ($LASTEXITCODE -eq 0) { throw 'setup-demo.ps1: could not prepare demo-checks' }
Invoke-Git commit -q -am 'refactor: simplify quote argument parsing'
Invoke-Git tag demo-checks-base
Invoke-Git checkout -q main

$leftover = & git status --porcelain
if ($leftover) {
    [Console]::Error.WriteLine('setup-demo.ps1: warning, some files were left uncommitted:')
    & git status --short
}

Write-Host 'History created:'
Invoke-Git log --oneline --decorate
