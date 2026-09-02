<#
.SYNOPSIS
Builds the demo git history for this repository from the files on disk.

.DESCRIPTION
Creates five conventional commits, tags v0.1.0 and v0.2.0, and a demo-start
branch at the baseline commit. Refuses to run if .git already exists unless
-Force is given, in which case the existing .git is deleted and rebuilt. -Force
only runs on a clean main checkout at v0.2.0 with no extra worktrees, because the
history is rebuilt from the files on disk.

Resulting history (oldest first):
  1. feat: add FeeQuote domain, pricing, transfer service and web app   (tag v0.1.0, branch demo-start)
  2. chore: add repository instructions and AGENTS.md
  3. feat: add reviewer custom agent
  4. feat: add release-notes skill
  5. chore: add MCP server configuration                                (tag v0.2.0)
  6. refactor: tidy quote form submit handler                           (branch demo-checks, tag demo-checks-base)

demo-checks carries one extra commit whose defect the test suites do not
catch (an unused import and a console.log in ClientApp/src/App.tsx) but
eslint and tsc do. To restore it after an experiment:
git branch -f demo-checks demo-checks-base

Works on ../../aspnet-react-feequote next to this demo-kit folder
(~/demos/aspnet-react-feequote), so it can be run from anywhere.

The presenter's files (DEMO_SCRIPT.md, prompts.txt, RUN_COMPARISON.md, tier-check/,
run-stats.py and these scripts) live in demo-kit, outside the repository, so agents
working in the repository or its worktrees never read the expected answers.

.EXAMPLE
~/demos/demo-kit/aspnet-react-feequote/setup-demo.ps1
~/demos/demo-kit/aspnet-react-feequote/setup-demo.ps1 -Force
#>
[CmdletBinding()]
param(
    [switch]$Force
)

$ErrorActionPreference = "Stop"
# Exit codes of git are checked explicitly in Invoke-Git.
$PSNativeCommandUseErrorActionPreference = $false
$repo = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) "aspnet-react-feequote"
if (-not (Test-Path -LiteralPath $repo -PathType Container)) {
    [Console]::Error.WriteLine("setup-demo.ps1: $repo not found. Keep demo-kit and aspnet-react-feequote side by side under ~/demos.")
    exit 1
}
Set-Location -LiteralPath $repo

# Runs one git command and stops the script if it fails. Native commands do
# not raise PowerShell errors on a non-zero exit, so the check is explicit.
function Invoke-Git {
    param([scriptblock]$Command)
    & $Command
    if ($LASTEXITCODE -ne 0) {
        throw "git command failed with exit code ${LASTEXITCODE}: $Command"
    }
}

function Add-Commit {
    param([string]$Message)
    Invoke-Git { git commit -q -m $Message }
    Write-Host "committed: $Message"
}

# Files that arrive after the baseline commit. They must all exist before
# anything runs, or the history would be built without them.
$customizationFiles = @(
    ".github/copilot-instructions.md", ".github/instructions", "AGENTS.md",
    ".github/agents",
    ".github/skills", "scripts",
    ".vscode/mcp.json"
)

foreach ($path in $customizationFiles) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "$path is missing. Run this from a complete copy of the repository on main."
    }
}

if (Test-Path -LiteralPath ".git") {
    if (-not $Force) {
        throw ".git already exists. Re-run with -Force to rebuild the demo history."
    }
    # The history is rebuilt from the files on disk, so they must be the full main state.
    $branch = & git symbolic-ref --short -q HEAD
    $dirty = & git status --porcelain
    $worktrees = @(& git worktree list --porcelain | Where-Object { $_ -like "worktree *" }).Count
    $head = & git rev-parse -q --verify HEAD
    $release = & git rev-parse -q --verify "v0.2.0^{commit}"
    if ($branch -ne "main" -or $dirty -or $worktrees -gt 1 -or -not $release -or $head -ne $release) {
        if (-not $branch) { $branch = "detached" }
        throw ("-Force only runs on a clean main checkout at v0.2.0 with no extra worktrees " +
            "(current branch: $branch, worktrees: $worktrees).`n" +
            "  Close VS Code and every Copilot CLI session first, run the full rehearsal reset`n" +
            "  from DEMO_SCRIPT.md, then git checkout -q main and try again.`n" +
            "  To restore only demo-checks: git branch -f demo-checks demo-checks-base")
    }
    Remove-Item -LiteralPath ".git" -Recurse -Force
}

Invoke-Git { git init -q -b main }
Invoke-Git { git config user.name "FeeQuote Demo" }
Invoke-Git { git config user.email "demo@example.com" }
Invoke-Git { git config commit.gpgsign false }
Invoke-Git { git config tag.gpgsign false }
Invoke-Git { git config core.autocrlf false }

# 1. Baseline: everything except the customization files.
Invoke-Git { git add -A -- . ":(exclude).github" ":(exclude)AGENTS.md" ":(exclude).vscode" ":(exclude)scripts" }
Add-Commit "feat: add FeeQuote domain, pricing, transfer service and web app"
Invoke-Git { git tag v0.1.0 }
Invoke-Git { git branch demo-start }

# 2. Repository instructions.
Invoke-Git { git add .github/copilot-instructions.md .github/instructions AGENTS.md }
Add-Commit "chore: add repository instructions and AGENTS.md"

# 3. Reviewer agent.
Invoke-Git { git add .github/agents }
Add-Commit "feat: add reviewer custom agent"

# 4. Release-notes skill and its script. Shell scripts are committed as
#    executable (mode 100755) so they run on macOS and Linux checkouts;
#    Windows file systems have no execute bit, so it is set in the index.
Invoke-Git { git add .github/skills scripts }
foreach ($shellScript in Get-ChildItem -LiteralPath "scripts" -Filter "*.sh") {
    Invoke-Git { git update-index --chmod=+x "scripts/$($shellScript.Name)" }
}
Add-Commit "feat: add release-notes skill"

# 5. MCP configuration.
Invoke-Git { git add .vscode/mcp.json }
Add-Commit "chore: add MCP server configuration"
Invoke-Git { git tag v0.2.0 }

# 6. Checks demo branch: vitest stays green, eslint (no-unused-vars,
#    no-console) and tsc (TS6133) fail. Tolerates LF or CRLF on disk.
Invoke-Git { git checkout -q -b demo-checks }
$appFile = "src/FeeQuote.Web/ClientApp/src/App.tsx"
$appPath = Join-Path $repo $appFile
$app = [System.IO.File]::ReadAllText($appPath)
$newline = if ($app.Contains("`r`n")) { "`r`n" } else { "`n" }
$importLine = 'import { useState } from "react";'
$amountLine = '    const amountCents = parseAmountToCents(form.amount);'
$app = $app.Replace($importLine + $newline, 'import { useEffect, useState } from "react";' + $newline)
$app = $app.Replace($amountLine + $newline, $amountLine + $newline + '    console.log("quote request", amountCents);' + $newline)
if (-not ($app.Contains('import { useEffect, useState } from "react";') -and $app.Contains('console.log("quote request", amountCents);'))) {
    throw "could not prepare demo-checks; $appFile did not match the expected text."
}
[System.IO.File]::WriteAllText($appPath, $app, [System.Text.UTF8Encoding]::new($false))
Invoke-Git { git add $appFile }
Add-Commit "refactor: tidy quote form submit handler"
Invoke-Git { git tag demo-checks-base }
Invoke-Git { git checkout -q main }

$leftover = & git status --porcelain
if ($leftover) {
    [Console]::Error.WriteLine("warning: some files were left uncommitted:")
    & git status --short
}

Write-Host ""
Invoke-Git { git log --oneline --graph --decorate --all }
Write-Host ""
Write-Host "Ready. 'git checkout demo-start' resets to the baseline; 'git checkout main' restores everything;"
Write-Host "'git checkout demo-checks' has the defect for the guardrails demo; 'git branch -f demo-checks demo-checks-base' restores it."
