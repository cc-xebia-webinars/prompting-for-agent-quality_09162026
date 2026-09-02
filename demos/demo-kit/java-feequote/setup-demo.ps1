<#
.SYNOPSIS
Builds the demo git history for FeeQuote from the files on disk.

.DESCRIPTION
Works on ../../java-feequote next to this demo-kit folder (~/demos/java-feequote),
so it can be run from anywhere.

Produces five conventional commits, tags v0.1.0 and v0.2.0, a demo-start
branch at the baseline commit (before any Copilot customization files exist),
and a demo-checks branch with one extra commit on top of v0.2.0:

  refactor: tidy domestic fee policy                              branch demo-checks, tag demo-checks-base

demo-checks carries a defect the test suite and the compiler do not catch (an
unused import and a lowercase long suffix on the cap) but Checkstyle does. To
restore it after an experiment: git branch -f demo-checks demo-checks-base

The presenter's files (DEMO_SCRIPT.md, prompts.txt, RUN_COMPARISON.md, tier-check/,
run-stats.py and these scripts) live in demo-kit, outside the repository, so agents
working in the repository or its worktrees never read the expected answers.

mvnw and scripts/*.sh are committed as executable (mode 100755), so ./mvnw runs
in every checkout and worktree on macOS and Linux.

Refuses to touch an existing .git directory unless -Force is given, and -Force
only runs on a clean main checkout at v0.2.0 with no extra worktrees, because
the history is rebuilt from the files on disk.
Works on Windows PowerShell 5.1 and PowerShell 7.

.EXAMPLE
~/demos/demo-kit/java-feequote/setup-demo.ps1
.EXAMPLE
~/demos/demo-kit/java-feequote/setup-demo.ps1 -Force
#>
[CmdletBinding()]
param(
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
$repo = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'java-feequote'
if (-not (Test-Path -LiteralPath $repo -PathType Container)) {
    [Console]::Error.WriteLine("setup-demo.ps1: $repo not found. Keep demo-kit and java-feequote side by side under ~/demos.")
    exit 1
}
Set-Location -LiteralPath $repo

# Simple function (no CmdletBinding) so flags like -q and -m reach git untouched.
function Invoke-Git {
    & git $args
    if ($LASTEXITCODE -ne 0) {
        throw "git $($args -join ' ') failed with exit code $LASTEXITCODE"
    }
}

# Files that arrive after the baseline commit.
$customizationFiles = @('.github/copilot-instructions.md', '.github/instructions', 'AGENTS.md', '.github/agents', '.github/skills', 'scripts', '.vscode/mcp.json')

foreach ($path in $customizationFiles) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "setup-demo.ps1: $path is missing. Run this from a complete copy of the repository on main."
    }
}

if (Test-Path -LiteralPath '.git') {
    if (-not $Force) {
        throw 'A .git directory already exists. Re-run with -Force to delete it and rebuild the demo history.'
    }
    # The history is rebuilt from the files on disk, so they must be the full main state.
    $branch = & git symbolic-ref --short -q HEAD
    $dirty = & git status --porcelain
    $worktrees = @(& git worktree list --porcelain | Where-Object { $_ -like 'worktree *' }).Count
    $head = & git rev-parse -q --verify HEAD
    $release = & git rev-parse -q --verify 'v0.2.0^{commit}'
    $atRelease = [bool]$release -and $head -eq $release
    if ($branch -ne 'main' -or $dirty -or $worktrees -gt 1 -or -not $atRelease) {
        throw "setup-demo.ps1: -Force only runs on a clean main checkout at v0.2.0 with no extra worktrees (current branch: $branch, worktrees: $worktrees, HEAD at v0.2.0: $atRelease). Close VS Code and every Copilot CLI session first, then run the full rehearsal reset from DEMO_SCRIPT.md instead. To restore only demo-checks: git branch -f demo-checks demo-checks-base"
    }
    Write-Host 'Removing existing .git directory (-Force).'
    Remove-Item -LiteralPath '.git' -Recurse -Force
}

Invoke-Git init -q
Invoke-Git symbolic-ref HEAD refs/heads/main

# Local identity and settings so commits work on a fresh machine.
Invoke-Git config user.name 'FeeQuote Demo'
Invoke-Git config user.email 'demo@example.com'
Invoke-Git config commit.gpgsign false
Invoke-Git config tag.gpgSign false
Invoke-Git config core.autocrlf false

# 1. Baseline: everything except the customization files.
Invoke-Git add -A . ':!.github' ':!AGENTS.md' ':!.vscode/mcp.json' ':!scripts'
# Windows does not record the executable bit, so set it in the index for macOS and Linux checkouts.
Invoke-Git update-index --chmod=+x mvnw
Invoke-Git commit -q -m 'feat: add FeeQuote domain, pricing, transfer service, API and CLI'
Invoke-Git tag v0.1.0
Invoke-Git branch demo-start

# 2. Repository instructions.
Invoke-Git add .github/copilot-instructions.md .github/instructions AGENTS.md
Invoke-Git commit -q -m 'chore: add repository instructions and AGENTS.md'

# 3. Custom agent.
Invoke-Git add .github/agents
Invoke-Git commit -q -m 'feat: add reviewer custom agent'

# 4. Skill.
Invoke-Git add .github/skills scripts
foreach ($script in @(Get-ChildItem -LiteralPath 'scripts' -Filter '*.sh')) {
    Invoke-Git update-index --chmod=+x "scripts/$($script.Name)"
}
Invoke-Git commit -q -m 'feat: add release-notes skill'

# 5. MCP configuration.
Invoke-Git add .vscode/mcp.json
Invoke-Git commit -q -m 'chore: add MCP server configuration'
Invoke-Git tag v0.2.0

# Checks demo branch: tests and compile stay green, Checkstyle (UnusedImports, UpperEll) fails.
Invoke-Git checkout -q -b demo-checks
$pricingPath = Join-Path $repo 'src/main/java/com/feequote/core/Pricing.java'
$pricing = [System.IO.File]::ReadAllText($pricingPath)
$newline = if ($pricing.Contains("`r`n")) { "`r`n" } else { "`n" }
$pricing = $pricing.Replace("package com.feequote.core;$newline", "package com.feequote.core;$newline${newline}import java.math.BigDecimal;$newline")
$pricing = $pricing.Replace('new FeePolicy(100, 2500)', 'new FeePolicy(100, 2500l)')
if (-not ($pricing.Contains('import java.math.BigDecimal;') -and $pricing.Contains('new FeePolicy(100, 2500l)'))) {
    throw 'setup-demo.ps1: could not prepare demo-checks'
}
[System.IO.File]::WriteAllText($pricingPath, $pricing, [System.Text.UTF8Encoding]::new($false))
$changed = @(& git diff --name-only)
if ($changed.Count -ne 1 -or $changed[0] -ne 'src/main/java/com/feequote/core/Pricing.java') {
    throw 'setup-demo.ps1: could not prepare demo-checks'
}
Invoke-Git commit -q -am 'refactor: tidy domestic fee policy'
Invoke-Git tag demo-checks-base
Invoke-Git checkout -q main

Write-Host 'Demo history created:'
Invoke-Git --no-pager log --oneline --decorate
