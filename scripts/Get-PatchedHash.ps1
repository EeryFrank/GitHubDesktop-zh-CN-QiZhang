# SPDX-License-Identifier: LGPL-3.0-or-later

[CmdletBinding()]
param([string]$SourceInstallRoot)

. (Join-Path $PSScriptRoot 'Common.ps1')

$manifest = Get-ProjectManifest
if ([string]::IsNullOrWhiteSpace($SourceInstallRoot)) {
    $SourceInstallRoot = Get-DefaultInstallRoot -Manifest $manifest
}

$paths = Get-TargetPaths -InstallRoot $SourceInstallRoot -Manifest $manifest
$sourceHash = Get-Sha256 -LiteralPath $paths.Renderer
if ($sourceHash -cne [string]$manifest.target.originalRendererSha256) {
    throw "Source renderer.js hash mismatch: $sourceHash"
}

$sourceText = [System.IO.File]::ReadAllText($paths.Renderer, [System.Text.Encoding]::UTF8)
$result = Invoke-Translations -SourceText $sourceText -TranslationData (Get-TranslationData)
$temporaryPath = Join-Path ([System.IO.Path]::GetTempPath()) ('GitHubDesktop-zh-CN-hash-' + [Guid]::NewGuid().ToString('N') + '.js')
try {
    [System.IO.File]::WriteAllText($temporaryPath, $result.Text, $script:Utf8NoBom)
    [pscustomobject]@{
        Entries = $result.EntryCount
        Replacements = $result.ReplacementCount
        PatchedLength = (Get-Item -LiteralPath $temporaryPath).Length
        PatchedSha256 = Get-Sha256 -LiteralPath $temporaryPath
    } | Format-List
}
finally {
    if (Test-Path -LiteralPath $temporaryPath) {
        Remove-Item -Force -LiteralPath $temporaryPath
    }
}
