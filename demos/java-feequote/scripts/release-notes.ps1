<#
.SYNOPSIS
Prints the commits between two refs grouped by conventional-commit type.

.DESCRIPTION
Reads the git log from FromTag to ToTag and buckets each subject line into
Features, Fixes, Chores or Other. Works on Windows PowerShell 5.1 and PowerShell 7.

.EXAMPLE
pwsh scripts/release-notes.ps1 v0.1.0 v0.2.0
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$FromTag,

    [Parameter(Mandatory = $true, Position = 1)]
    [string]$ToTag
)

$ErrorActionPreference = 'Stop'

& git rev-parse --show-toplevel | Out-Null
if ($LASTEXITCODE -ne 0) {
    throw 'Not inside a git repository.'
}

foreach ($ref in @($FromTag, $ToTag)) {
    # -q keeps git silent on a miss, so there is no stderr to redirect (which would
    # surface as an error record on Windows PowerShell 5.1).
    & git rev-parse -q --verify "${ref}^{commit}" | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "unknown ref '$ref'"
    }
}

$features = New-Object System.Collections.Generic.List[string]
$fixes = New-Object System.Collections.Generic.List[string]
$chores = New-Object System.Collections.Generic.List[string]
$other = New-Object System.Collections.Generic.List[string]
$choreTypes = @('chore', 'docs', 'refactor', 'test', 'ci', 'build', 'perf', 'style')

$subjects = @(& git log --no-merges --reverse --format=%s "${FromTag}..${ToTag}")
if ($LASTEXITCODE -ne 0) {
    throw "git log failed for ${FromTag}..${ToTag}"
}

foreach ($subject in $subjects) {
    if ([string]::IsNullOrWhiteSpace($subject)) { continue }

    # type, optional (scope), optional ! for breaking changes, then ": description"
    if ($subject -match '^(?<type>[a-z]+)(\([^)]*\))?!?:\s*(?<description>.+)$') {
        $type = $Matches['type']
        $description = $Matches['description']
        if ($type -eq 'feat') { $features.Add($description) }
        elseif ($type -eq 'fix') { $fixes.Add($description) }
        elseif ($choreTypes -contains $type) { $chores.Add($description) }
        else { $other.Add($subject) }
    }
    else {
        $other.Add($subject)
    }
}

function Write-Group {
    param(
        [string]$Title,
        [System.Collections.Generic.List[string]]$Lines
    )
    Write-Output "### $Title"
    if ($Lines.Count -eq 0) {
        Write-Output '- (none)'
    }
    else {
        foreach ($line in $Lines) { Write-Output "- $line" }
    }
    Write-Output ''
}

Write-Output "## FeeQuote $ToTag"
Write-Output "Commits $FromTag..$ToTag"
Write-Output ''
Write-Group -Title 'Features' -Lines $features
Write-Group -Title 'Fixes' -Lines $fixes
Write-Group -Title 'Chores' -Lines $chores
Write-Group -Title 'Other (not conventional-commit formatted)' -Lines $other
