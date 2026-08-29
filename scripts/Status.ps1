# SPDX-License-Identifier: GPL-3.0-only

[CmdletBinding()]
param([string]$InstallRoot)

. (Join-Path $PSScriptRoot 'Common.ps1')

$manifest = Get-ProjectManifest
if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
    $InstallRoot = Get-DefaultInstallRoot -Manifest $manifest
}

try {
    $paths = Assert-TargetIdentity -InstallRoot $InstallRoot -Manifest $manifest
    $hash = Get-Sha256 -LiteralPath $paths.Renderer
    $state = if ($hash -ceq [string]$manifest.target.originalRendererSha256) {
        'ORIGINAL'
    }
    elseif ($hash -ceq [string]$manifest.target.patchedRendererSha256) {
        'PATCHED'
    }
    else {
        'UNKNOWN_REFUSED'
    }

    [pscustomobject]@{
        State = $state
        Version = [string]$manifest.target.version
        InstallRoot = $paths.Root
        RendererSha256 = $hash
    } | Format-List

    if ($state -ceq 'UNKNOWN_REFUSED') {
        exit 2
    }
}
catch {
    Write-Error $_
    exit 1
}
