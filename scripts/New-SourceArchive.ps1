# SPDX-License-Identifier: GPL-3.0-only

[CmdletBinding()]
param([string]$OutputDirectory)

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
    $OutputDirectory = Join-Path $projectRoot 'dist'
}
$outputRoot = [System.IO.Path]::GetFullPath($OutputDirectory).TrimEnd('\')
[void][System.IO.Directory]::CreateDirectory($outputRoot)

& (Join-Path $PSScriptRoot 'Test-Licensing.ps1')

$gitRoot = (& git -C $projectRoot rev-parse --show-toplevel)
if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace([string]$gitRoot)) {
    throw 'Unable to resolve the Git repository root.'
}
$gitRoot = [System.IO.Path]::GetFullPath(([string]$gitRoot).Trim()).TrimEnd('\')
if ($gitRoot -cne [System.IO.Path]::GetFullPath($projectRoot).TrimEnd('\')) {
    throw "Unexpected Git root: $gitRoot"
}

$dirty = @(& git -C $gitRoot status --porcelain)
if ($LASTEXITCODE -ne 0) { throw 'Unable to inspect Git worktree status.' }
if ($dirty.Count -gt 0) {
    throw 'Source archives must be built from a committed, clean worktree.'
}

$commit = ([string](& git -C $gitRoot rev-parse HEAD)).Trim()
$shortCommit = ([string](& git -C $gitRoot rev-parse --short=12 HEAD)).Trim()
if ($LASTEXITCODE -ne 0 -or $commit -notmatch '^[0-9a-f]{40}$' -or $shortCommit -notmatch '^[0-9a-f]{12}$') {
    throw 'Unable to resolve the source commit.'
}
$manifest = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $projectRoot 'manifest.json') | ConvertFrom-Json
$targetVersion = [string]$manifest.target.version
$archiveName = "GitHubDesktop-zh-CN-QiZhang-source-$targetVersion-$shortCommit.zip"
$archivePath = Join-Path $outputRoot $archiveName
$temporaryPath = Join-Path $outputRoot ('.' + $archiveName + '.' + [Guid]::NewGuid().ToString('N') + '.tmp')

try {
    & git -C $gitRoot archive --format=zip "--output=$temporaryPath" HEAD
    if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $temporaryPath -PathType Leaf)) {
        throw 'git archive failed.'
    }

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $zip = [System.IO.Compression.ZipFile]::OpenRead($temporaryPath)
    try {
        $entries = @($zip.Entries | ForEach-Object { $_.FullName })
        $required = @(
            'LICENSE',
            'LICENSE_POLICY.md',
            'ASSET_LICENSES.md',
            'THIRD_PARTY_NOTICES.md',
            'CONTRIBUTING.md',
            'LICENSES/CC-BY-SA-4.0.txt',
            'LICENSES/LGPL-3.0-or-later.txt',
            'LICENSES/LicenseRef-EeryFrank-Assets-Permission-Required.txt',
            'LICENSES/MIT-GitHub-Desktop.txt',
            'LICENSES/MIT-legacy-project.txt'
        )
        foreach ($requiredEntry in $required) {
            if ($entries -cnotcontains $requiredEntry) {
                throw "Source archive is missing a required legal file: $requiredEntry"
            }
        }
        $forbidden = @($entries | Where-Object {
            $_ -match '(?i)\.(asar|nupkg|exe|dll|node|pak|map)$' -or
            $_ -match '(?i)(^|/)(backups|originals|resources/app)/'
        })
        if ($forbidden.Count -gt 0) {
            throw "Source archive contains forbidden upstream application material: $($forbidden -join ', ')"
        }
        $entryCount = $entries.Count
    }
    finally {
        $zip.Dispose()
    }

    if (Test-Path -LiteralPath $archivePath) {
        $newHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $temporaryPath).Hash
        $existingHash = (Get-FileHash -Algorithm SHA256 -LiteralPath $archivePath).Hash
        if ($newHash -cne $existingHash) {
            throw "An archive with the same commit name already exists with different content: $archivePath"
        }
        Remove-Item -Force -LiteralPath $temporaryPath
    }
    else {
        Move-Item -LiteralPath $temporaryPath -Destination $archivePath
    }

    [pscustomobject]@{
        Result = 'PASS'
        Commit = $commit
        Archive = $archivePath
        Entries = $entryCount
        Sha256 = (Get-FileHash -Algorithm SHA256 -LiteralPath $archivePath).Hash
    } | Format-List
    Write-Host 'SOURCE_ARCHIVE_VERIFY=PASS'
}
finally {
    if (Test-Path -LiteralPath $temporaryPath) {
        $resolvedTemporary = [System.IO.Path]::GetFullPath($temporaryPath)
        if (-not $resolvedTemporary.StartsWith($outputRoot + '\', [StringComparison]::OrdinalIgnoreCase) -or
            (Split-Path -Leaf $resolvedTemporary) -notlike ('.' + $archiveName + '.*.tmp')) {
            throw "Refusing to remove a temporary file outside the verified output directory: $resolvedTemporary"
        }
        Remove-Item -Force -LiteralPath $resolvedTemporary
    }
}
