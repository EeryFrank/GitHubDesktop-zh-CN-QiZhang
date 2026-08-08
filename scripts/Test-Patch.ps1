[CmdletBinding()]
param(
    [string]$SourceInstallRoot,
    [switch]$KeepFixture
)

. (Join-Path $PSScriptRoot 'Common.ps1')

if ([string]::IsNullOrWhiteSpace($SourceInstallRoot)) {
    $SourceInstallRoot = Get-DefaultInstallRoot
}

$manifest = Get-ProjectManifest
$sourcePaths = Assert-TargetIdentity -InstallRoot $SourceInstallRoot -Manifest $manifest
$sourceHash = Get-Sha256 -LiteralPath $sourcePaths.Renderer
if ($sourceHash -cne [string]$manifest.target.originalRendererSha256) {
    throw "Isolated testing requires the manifest's original renderer.js. Actual: $sourceHash"
}

$fixtureParent = Join-Path ([System.IO.Path]::GetTempPath()) ('GitHubDesktop-zh-CN-test-' + [Guid]::NewGuid().ToString('N'))
$fixtureRoot = Join-Path $fixtureParent 'app-3.6.3'
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

    $translations = Get-TranslationData
    $originalText = [System.IO.File]::ReadAllText($sourcePaths.Renderer, [System.Text.Encoding]::UTF8)
    $result = Invoke-Translations -SourceText $originalText -TranslationData $translations
    [pscustomobject]@{
        Result = 'PASS'
        Entries = $result.EntryCount
        Replacements = $result.ReplacementCount
        OriginalSha256 = [string]$manifest.target.originalRendererSha256
        PatchedSha256 = [string]$manifest.target.patchedRendererSha256
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
