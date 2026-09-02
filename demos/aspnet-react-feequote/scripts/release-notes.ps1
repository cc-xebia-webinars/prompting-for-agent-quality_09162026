<#
.SYNOPSIS
Prints the commits between two tags grouped by conventional-commit type.

.EXAMPLE
.\scripts\release-notes.ps1 v0.1.0 v0.2.0
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$FromTag,

    [Parameter(Mandatory = $true, Position = 1)]
    [string]$ToTag
)

$ErrorActionPreference = "Stop"
# Exit codes of git are checked explicitly below.
$PSNativeCommandUseErrorActionPreference = $false

foreach ($tag in @($FromTag, $ToTag)) {
    git rev-parse --verify --quiet "refs/tags/$tag" | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "tag '$tag' not found"
    }
}

$subjects = @(git log --no-merges --reverse --format=%s "$FromTag..$ToTag")
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

$groups = [ordered]@{
    Features = New-Object System.Collections.Generic.List[string]
    Fixes    = New-Object System.Collections.Generic.List[string]
    Chores   = New-Object System.Collections.Generic.List[string]
}
$other = New-Object System.Collections.Generic.List[string]

foreach ($subject in $subjects) {
    if ([string]::IsNullOrWhiteSpace($subject)) { continue }

    if ($subject -match '^(?<type>[a-z]+)(\([^)]*\))?!?:\s*(?<rest>.+)$') {
        $type = $Matches['type']
        $rest = $Matches['rest']
        switch ($type) {
            'feat' { $groups['Features'].Add($rest) }
            'fix' { $groups['Fixes'].Add($rest) }
            { $_ -in 'chore', 'build', 'ci', 'docs', 'refactor', 'test' } { $groups['Chores'].Add($rest) }
            default { $other.Add($subject) }
        }
    }
    else {
        $other.Add($subject)
    }
}

function Write-Group {
    param([string]$Title, [System.Collections.Generic.List[string]]$Lines)

    Write-Output $Title
    if ($Lines.Count -eq 0) {
        Write-Output "- (none)"
    }
    else {
        foreach ($line in $Lines) {
            Write-Output "- $line"
        }
    }
    Write-Output ""
}

Write-Output "Commits $FromTag..$ToTag"
Write-Output ""
foreach ($name in $groups.Keys) {
    Write-Group -Title $name -Lines $groups[$name]
}
if ($other.Count -gt 0) {
    Write-Group -Title "Unclassified" -Lines $other
}
