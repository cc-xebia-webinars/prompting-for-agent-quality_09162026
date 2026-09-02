<#
.SYNOPSIS
Builds the demo git history for the FeeQuote Python repository from the files on disk.

.DESCRIPTION
Works on ../../python-feequote next to this demo-kit folder (~/demos/python-feequote), so it can be
run from anywhere. Refuses to run if a .git directory already
exists unless -Force is given, in which case .git is deleted and rebuilt. -Force
only runs on a clean main checkout with no extra worktrees, because the history is
rebuilt from the files on disk.

Resulting history (oldest first):
  feat: add FeeQuote domain, pricing, transfer service and CLI   tag v0.1.0, branch demo-start
  chore: add repository instructions and AGENTS.md
  feat: add reviewer custom agent
  feat: add release-notes skill
  chore: add MCP server configuration                            tag v0.2.0
  refactor: tidy domestic fee policy                              branch demo-checks, tag demo-checks-base

demo-checks carries one extra commit whose defect the test suite does not
catch (a float cap and an unused import) but ruff and mypy do. To restore it
after an experiment: git branch -f demo-checks demo-checks-base

The presenter's files (DEMO_SCRIPT.md, prompts.txt, RUN_COMPARISON.md, tier-check/,
run-stats.py and these scripts) live in demo-kit, outside the repository, so agents
working in the repository or its worktrees never read the expected answers.

.PARAMETER Force
Delete an existing .git directory and rebuild the history.

.EXAMPLE
~/demos/demo-kit/python-feequote/setup-demo.ps1

.EXAMPLE
~/demos/demo-kit/python-feequote/setup-demo.ps1 -Force
#>
[CmdletBinding()]
param(
    [switch]$Force
)

$ErrorActionPreference = "Stop"
$repo = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) "python-feequote"
if (-not (Test-Path -LiteralPath $repo -PathType Container)) {
    [Console]::Error.WriteLine("setup-demo.ps1: $repo not found. Keep demo-kit and python-feequote side by side under ~/demos.")
    exit 1
}
Set-Location -LiteralPath $repo

function Invoke-Git {
    param([Parameter(Mandatory = $true)][string[]]$GitArgs)
    & git @GitArgs
    if ($LASTEXITCODE -ne 0) {
        throw "git $($GitArgs -join ' ') exited with code $LASTEXITCODE"
    }
}

# Files that arrive after the baseline commit, in the order they are committed.
$instructionFiles = @(".github/copilot-instructions.md", ".github/instructions", "AGENTS.md")
$agentFiles = @(".github/agents")
$skillFiles = @(".github/skills", "scripts/release_notes.py")
$mcpFiles = @(".vscode/mcp.json")
$customizationFiles = $instructionFiles + $agentFiles + $skillFiles + $mcpFiles

foreach ($path in $customizationFiles) {
    if (-not (Test-Path -LiteralPath $path)) {
        [Console]::Error.WriteLine("setup-demo.ps1: $path is missing. Run this from a complete copy of the repository on main.")
        exit 1
    }
}

if (Test-Path -LiteralPath ".git") {
    if (-not $Force) {
        [Console]::Error.WriteLine("setup-demo.ps1: .git already exists. Re-run with -Force to delete it and rebuild.")
        exit 1
    }
    # The history is rebuilt from the files on disk, so they must be the full main state.
    $branch = & git symbolic-ref --short -q HEAD
    $dirty = & git status --porcelain
    $worktrees = @(& git worktree list --porcelain | Where-Object { $_ -like "worktree *" }).Count
    $head = & git rev-parse -q --verify HEAD
    $release = & git rev-parse -q --verify "v0.2.0^{commit}"
    if ($branch -ne "main" -or $dirty -or $worktrees -gt 1 -or -not $head -or $head -ne $release) {
        [Console]::Error.WriteLine("setup-demo.ps1: -Force only runs on a clean main checkout at v0.2.0 with no extra worktrees (current branch: $branch, worktrees: $worktrees).")
        [Console]::Error.WriteLine("  Close VS Code and every Copilot CLI session, run the full rehearsal reset, then git checkout -q main.")
        [Console]::Error.WriteLine("  To restore only demo-checks: git branch -f demo-checks demo-checks-base")
        exit 1
    }
    Remove-Item -LiteralPath ".git" -Recurse -Force
}

Invoke-Git @("init", "-q")
Invoke-Git @("symbolic-ref", "HEAD", "refs/heads/main")
Invoke-Git @("config", "user.name", "FeeQuote Demo")
Invoke-Git @("config", "user.email", "demo@example.com")
Invoke-Git @("config", "commit.gpgsign", "false")
Invoke-Git @("config", "tag.gpgsign", "false")
Invoke-Git @("config", "core.autocrlf", "false")

# Baseline: everything on disk except the customization files.
Invoke-Git @("add", "-A")
Invoke-Git (@("reset", "-q", "--") + $customizationFiles)
Invoke-Git @("commit", "-q", "-m", "feat: add FeeQuote domain, pricing, transfer service and CLI")
Invoke-Git @("tag", "-a", "v0.1.0", "-m", "FeeQuote 0.1.0")
Invoke-Git @("branch", "demo-start")

Invoke-Git (@("add", "-A", "--") + $instructionFiles)
Invoke-Git @("commit", "-q", "-m", "chore: add repository instructions and AGENTS.md")

Invoke-Git (@("add", "-A", "--") + $agentFiles)
Invoke-Git @("commit", "-q", "-m", "feat: add reviewer custom agent")

Invoke-Git (@("add", "-A", "--") + $skillFiles)
Invoke-Git @("commit", "-q", "-m", "feat: add release-notes skill")

Invoke-Git (@("add", "-A", "--") + $mcpFiles)
Invoke-Git @("commit", "-q", "-m", "chore: add MCP server configuration")
Invoke-Git @("tag", "-a", "v0.2.0", "-m", "FeeQuote 0.2.0")

# Checks demo branch: tests stay green, ruff (F401) and mypy (arg-type) fail.
Invoke-Git @("checkout", "-q", "-b", "demo-checks")
$pricingPath = Join-Path $repo "feequote/core/pricing.py"
$pricing = [System.IO.File]::ReadAllText($pricingPath)
$newline = if ($pricing.Contains("`r`n")) { "`r`n" } else { "`n" }
$pricing = $pricing.Replace("from dataclasses import dataclass$newline", "import math${newline}from dataclasses import dataclass$newline")
$pricing = $pricing.Replace("cap_cents=2500)", "cap_cents=2500.0)")
if (-not $pricing.Contains("import math") -or -not $pricing.Contains("cap_cents=2500.0)")) { throw "setup-demo.ps1: could not prepare demo-checks" }
[System.IO.File]::WriteAllText($pricingPath, $pricing, [System.Text.UTF8Encoding]::new($false))
Invoke-Git @("commit", "-q", "-am", "refactor: tidy domestic fee policy")
Invoke-Git @("tag", "demo-checks-base")
Invoke-Git @("checkout", "-q", "main")

$leftover = & git status --porcelain
if ($leftover) {
    [Console]::Error.WriteLine("setup-demo.ps1: warning, some files were left uncommitted:")
    & git status --short
}

Write-Host "Demo history created on branch main:"
& git log --oneline --decorate
