<#
.SYNOPSIS
Builds the demo git history for FeeQuote from the files on disk.

.DESCRIPTION
Produces five conventional commits, tags v0.1.0 and v0.2.0, and a demo-start
branch at the baseline commit (before any Copilot customization files or
release-notes scripts exist; the scripts arrive with the skill commit).
Refuses to touch an existing .git directory unless -Force is given, and -Force
only runs on a clean main checkout at v0.2.0 with no extra worktrees, because the
history is rebuilt from the files on disk.
Works on Windows PowerShell 5.1 and PowerShell 7.

Also creates a demo-checks branch, tagged demo-checks-base: v0.2.0 plus one
commit, "refactor: tidy transfer service usings", whose defect the tests and the
build do not catch (usings out of order and no final newline in
src/FeeQuote/Services/TransferService.cs) but dotnet format does. To restore the
branch after an experiment: git branch -f demo-checks demo-checks-base

Works on ../../csharp-feequote next to this demo-kit folder (~/demos/csharp-feequote),
so it can be run from anywhere.

The presenter's files (DEMO_SCRIPT.md, prompts.txt, RUN_COMPARISON.md, tier-check/,
run-stats.py and these scripts) live in demo-kit, outside the repository, so agents
working in the repository or its worktrees never read the expected answers.

On macOS and Linux use bash ~/demos/demo-kit/csharp-feequote/setup-demo.sh instead;
both scripts build the same history.

.EXAMPLE
~/demos/demo-kit/csharp-feequote/setup-demo.ps1
.EXAMPLE
~/demos/demo-kit/csharp-feequote/setup-demo.ps1 -Force
#>
[CmdletBinding()]
param(
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
$repo = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) "csharp-feequote"
if (-not (Test-Path -LiteralPath $repo -PathType Container)) {
    [Console]::Error.WriteLine("setup-demo.ps1: $repo not found. Keep demo-kit and csharp-feequote side by side under ~/demos.")
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

# Files that arrive after the baseline commit, in the order they are committed.
$customizationFiles = @(
    '.github/copilot-instructions.md', '.github/instructions', 'AGENTS.md',
    '.github/agents',
    '.github/skills', 'scripts',
    '.vscode/mcp.json'
)

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
    if ($branch -ne 'main' -or $dirty -or $worktrees -gt 1 -or -not $release -or $head -ne $release) {
        if (-not $branch) { $branch = 'detached' }
        $atRelease = if (-not $release) { 'no v0.2.0 tag' } elseif ($head -eq $release) { 'yes' } else { 'no' }
        [Console]::Error.WriteLine("setup-demo.ps1: -Force only runs on a clean main checkout at v0.2.0 with no extra worktrees (current branch: $branch, worktrees: $worktrees, HEAD at v0.2.0: $atRelease).")
        [Console]::Error.WriteLine('  Close VS Code and every Copilot CLI session first, then run the full rehearsal reset from DEMO_SCRIPT.md, then git checkout -q main, and try again.')
        [Console]::Error.WriteLine('  To restore only demo-checks: git branch -f demo-checks demo-checks-base')
        exit 1
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

# 1. Baseline: everything except the customization files and the release-notes scripts.
Invoke-Git add -A . ':!.github' ':!AGENTS.md' ':!.vscode' ':!scripts'
Invoke-Git commit -q -m 'feat: add FeeQuote domain, pricing, transfer service and CLI'
Invoke-Git tag v0.1.0
Invoke-Git branch demo-start

# 2. Repository instructions.
Invoke-Git add .github/copilot-instructions.md .github/instructions AGENTS.md
Invoke-Git commit -q -m 'chore: add repository instructions and AGENTS.md'

# 3. Custom agent.
Invoke-Git add .github/agents
Invoke-Git commit -q -m 'feat: add reviewer custom agent'

# 4. Skill and the release-notes scripts it runs. The shell script is committed
#    executable, so it runs on macOS and Linux checkouts of the demo history.
$shellScripts = @(Get-ChildItem -LiteralPath 'scripts' -Filter '*.sh' | ForEach-Object { "scripts/$($_.Name)" })
if ($PSVersionTable.PSEdition -eq 'Core' -and -not $IsWindows) {
    foreach ($shellScript in $shellScripts) { & chmod +x $shellScript }
}
Invoke-Git add .github/skills scripts
foreach ($shellScript in $shellScripts) { Invoke-Git update-index --chmod=+x $shellScript }
Invoke-Git commit -q -m 'feat: add release-notes skill'

# 5. MCP configuration.
Invoke-Git add .vscode/mcp.json
Invoke-Git commit -q -m 'chore: add MCP server configuration'
Invoke-Git tag v0.2.0

# 6. Checks demo branch: dotnet test and the build stay green, dotnet format fails
#    (IMPORTS: usings out of order; FINALNEWLINE: no newline at end of file).
#    Tolerates LF or CRLF files and stops loudly if the file no longer matches.
#    The file is written with LF endings, so the commit is byte-identical to the one
#    setup-demo.sh makes on macOS and Linux.
Invoke-Git checkout -q -b demo-checks
$servicePath = Join-Path $repo 'src/FeeQuote/Services/TransferService.cs'
$service = [System.IO.File]::ReadAllText($servicePath).Replace("`r`n", "`n")
$newline = "`n"
$modelsUsing = "using FeeQuote.Models;$newline"
$clientsUsing = "using FeeQuote.Clients;$newline"
if (-not $service.StartsWith($clientsUsing) -or -not $service.Contains($modelsUsing)) {
    throw "setup-demo.ps1: could not prepare demo-checks; $servicePath no longer matches the expected usings."
}
$service = $service.Replace($modelsUsing, '')
$service = $modelsUsing + $service
$service = $service.TrimEnd([char[]]"`r`n")
# Both defects must be in place: Models above Clients, and no newline after the last brace.
if (-not $service.StartsWith($modelsUsing + $clientsUsing) -or -not $service.EndsWith('}')) {
    throw "setup-demo.ps1: could not prepare demo-checks; $servicePath does not have the expected usings and closing brace."
}
[System.IO.File]::WriteAllText($servicePath, $service, (New-Object System.Text.UTF8Encoding $false))
Invoke-Git commit -q -am 'refactor: tidy transfer service usings'
Invoke-Git tag demo-checks-base
Invoke-Git checkout -q main

$leftover = & git status --porcelain
if ($leftover) {
    [Console]::Error.WriteLine('setup-demo.ps1: warning, some files were left uncommitted:')
    & git status --short
}

Write-Host 'Demo history created:'
Invoke-Git --no-pager log --oneline --decorate
