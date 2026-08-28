# SPDX-License-Identifier: LGPL-3.0-or-later

[CmdletBinding()]
param(
    [string]$SourceInstallRoot,
    [switch]$KeepFixture
)

. (Join-Path $PSScriptRoot 'Common.ps1')

$manifest = Get-ProjectManifest
if ([string]::IsNullOrWhiteSpace($SourceInstallRoot)) {
    $SourceInstallRoot = Get-DefaultInstallRoot -Manifest $manifest
}

$sourcePaths = Assert-TargetIdentity -InstallRoot $SourceInstallRoot -Manifest $manifest
$sourceHash = Get-Sha256 -LiteralPath $sourcePaths.Renderer
if ($sourceHash -cne [string]$manifest.target.originalRendererSha256) {
    throw "Isolated testing requires the manifest's original renderer.js. Actual: $sourceHash"
}

$fixtureParent = Join-Path ([System.IO.Path]::GetTempPath()) ('GitHubDesktop-zh-CN-test-' + [Guid]::NewGuid().ToString('N'))
$fixtureRoot = Join-Path $fixtureParent ('app-' + (Get-TargetVersion -Manifest $manifest))
$fixtureApp = Join-Path $fixtureRoot 'resources\app'
$stateRoot = Join-Path $fixtureParent 'state'
[void][System.IO.Directory]::CreateDirectory($fixtureApp)

function Invoke-IsolatedPatchCommand {
    param(
        [Parameter(Mandatory = $true)][string]$ScriptName,
        [Parameter(Mandatory = $true)][string]$ActionName
    )

    try {
        & (Join-Path $PSScriptRoot $ScriptName) -InstallRoot $fixtureRoot -StateRoot $stateRoot
    }
    catch {
        throw "$ActionName failed: $($_.Exception.Message)"
    }
}

function Assert-IsolatedPatchFailure {
    param(
        [Parameter(Mandatory = $true)][string]$ScriptName,
        [Parameter(Mandatory = $true)][string]$ActionName,
        [Parameter(Mandatory = $true)][string]$ExpectedMessagePattern
    )

    $caught = $null
    try {
        & (Join-Path $PSScriptRoot $ScriptName) -InstallRoot $fixtureRoot -StateRoot $stateRoot
    }
    catch {
        $caught = $_
    }

    if ($null -eq $caught) {
        throw "$ActionName unexpectedly succeeded."
    }
    if ([string]$caught.Exception.Message -notmatch $ExpectedMessagePattern) {
        throw "$ActionName failed for an unexpected reason: $($caught.Exception.Message)"
    }
    Write-Host "$ActionName refused as expected: $($caught.Exception.Message)"
}

try {
    [System.IO.File]::Copy($sourcePaths.Exe, (Join-Path $fixtureRoot 'GitHubDesktop.exe'), $false)
    foreach ($runtimeFile in @('icudtl.dat', 'resources.pak', 'snapshot_blob.bin', 'v8_context_snapshot.bin')) {
        $runtimeSource = Join-Path $sourcePaths.Root $runtimeFile
        if (Test-Path -LiteralPath $runtimeSource) {
            [System.IO.File]::Copy($runtimeSource, (Join-Path $fixtureRoot $runtimeFile), $false)
        }
    }
    [System.IO.File]::Copy($sourcePaths.Package, (Join-Path $fixtureApp 'package.json'), $false)
    [System.IO.File]::Copy($sourcePaths.Renderer, (Join-Path $fixtureApp 'renderer.js'), $false)

    Invoke-IsolatedPatchCommand -ScriptName 'Install.ps1' -ActionName 'First isolated install'
    $patchedHash = Get-Sha256 -LiteralPath (Join-Path $fixtureApp 'renderer.js')
    if ($patchedHash -cne [string]$manifest.target.patchedRendererSha256) { throw 'Hash mismatch after first install.' }

    Invoke-IsolatedPatchCommand -ScriptName 'Install.ps1' -ActionName 'Idempotent install'
    if ((Get-Sha256 -LiteralPath (Join-Path $fixtureApp 'renderer.js')) -cne $patchedHash) { throw 'Idempotent install unexpectedly changed the file.' }

    Invoke-IsolatedPatchCommand -ScriptName 'Restore.ps1' -ActionName 'First isolated restore'
    if ((Get-Sha256 -LiteralPath (Join-Path $fixtureApp 'renderer.js')) -cne [string]$manifest.target.originalRendererSha256) { throw 'Hash mismatch after restore.' }

    Invoke-IsolatedPatchCommand -ScriptName 'Restore.ps1' -ActionName 'Idempotent restore'

    $expectedBackupDirectory = Join-Path (Join-Path $stateRoot 'backups') (Get-TargetVersion -Manifest $manifest)
    if (-not (Test-Path -LiteralPath $expectedBackupDirectory)) {
        throw "Version-derived backup directory was not created: $expectedBackupDirectory"
    }

    $fixturePackage = Join-Path $fixtureApp 'package.json'
    $fixtureRenderer = Join-Path $fixtureApp 'renderer.js'
    $packageBytes = [System.IO.File]::ReadAllBytes($fixturePackage)
    try {
        $wrongVersionPackage = Get-Content -Raw -Encoding UTF8 -LiteralPath $fixturePackage | ConvertFrom-Json
        $wrongVersionPackage.version = '0.0.0'
        Write-JsonUtf8NoBom -LiteralPath $fixturePackage -Value $wrongVersionPackage
        $rendererHashBeforeRefusal = Get-Sha256 -LiteralPath $fixtureRenderer
        Assert-IsolatedPatchFailure -ScriptName 'Install.ps1' -ActionName 'Wrong-version install' -ExpectedMessagePattern ([regex]::Escape('Version mismatch: package.json=0.0.0'))
        if ((Get-Sha256 -LiteralPath $fixtureRenderer) -cne $rendererHashBeforeRefusal) {
            throw 'Wrong-version refusal unexpectedly changed renderer.js.'
        }
    }
    finally {
        [System.IO.File]::WriteAllBytes($fixturePackage, $packageBytes)
    }
    if ((Get-Sha256 -LiteralPath $fixturePackage) -cne [string]$manifest.target.packageJsonSha256) {
        throw 'Failed to restore package.json after wrong-version refusal test.'
    }

    $rendererBytes = [System.IO.File]::ReadAllBytes($fixtureRenderer)
    try {
        [System.IO.File]::AppendAllText($fixtureRenderer, [Environment]::NewLine, $script:Utf8NoBom)
        $unexpectedRendererHash = Get-Sha256 -LiteralPath $fixtureRenderer
        if ($unexpectedRendererHash -ceq [string]$manifest.target.originalRendererSha256) {
            throw 'Wrong-hash fixture did not change renderer.js.'
        }
        Assert-IsolatedPatchFailure -ScriptName 'Install.ps1' -ActionName 'Wrong-hash install' -ExpectedMessagePattern ([regex]::Escape('renderer.js is neither the supported original nor this patch.'))
        if ((Get-Sha256 -LiteralPath $fixtureRenderer) -cne $unexpectedRendererHash) {
            throw 'Wrong-hash refusal unexpectedly changed renderer.js.'
        }
    }
    finally {
        [System.IO.File]::WriteAllBytes($fixtureRenderer, $rendererBytes)
    }
    if ((Get-Sha256 -LiteralPath $fixtureRenderer) -cne [string]$manifest.target.originalRendererSha256) {
        throw 'Failed to restore renderer.js after wrong-hash refusal test.'
    }

    if ((Get-Sha256 -LiteralPath $sourcePaths.Renderer) -cne $sourceHash) {
        throw 'The source installation changed during isolated testing.'
    }

    $translations = Get-TranslationData
    $originalText = [System.IO.File]::ReadAllText($sourcePaths.Renderer, [System.Text.Encoding]::UTF8)
    $result = Invoke-Translations -SourceText $originalText -TranslationData $translations
    [pscustomobject]@{
        Result = 'PASS'
        Entries = $result.EntryCount
        Replacements = $result.ReplacementCount
        OriginalSha256 = [string]$manifest.target.originalRendererSha256
        PatchedSha256 = [string]$manifest.target.patchedRendererSha256
        WrongVersionRefusal = 'PASS'
        WrongHashRefusal = 'PASS'
        SourceInstallUnchanged = 'PASS'
        FixtureRoot = $fixtureRoot
    } | Format-List
}
finally {
    if ($KeepFixture) {
        Write-Host "Kept isolated fixture: $fixtureParent"
    }
    elseif (Test-Path -LiteralPath $fixtureParent) {
        $resolvedFixture = Get-NormalizedPath -LiteralPath $fixtureParent
        $resolvedTemp = Get-NormalizedPath -LiteralPath ([System.IO.Path]::GetTempPath())
        if (-not $resolvedFixture.StartsWith($resolvedTemp + '\', [StringComparison]::OrdinalIgnoreCase) -or
            (Split-Path -Leaf $resolvedFixture) -notlike 'GitHubDesktop-zh-CN-test-*') {
            throw "Refusing to clean a fixture outside the verified temp boundary: $resolvedFixture"
        }
        $removed = $false
        for ($attempt = 1; $attempt -le 5; $attempt++) {
            try {
                Remove-Item -Recurse -Force -LiteralPath $resolvedFixture
                $removed = $true
                break
            }
            catch {
                if ($attempt -eq 5) {
                    throw
                }
                Start-Sleep -Milliseconds 200
            }
        }
        if (-not $removed) {
            throw "Failed to clean isolated fixture: $resolvedFixture"
        }
    }
}
