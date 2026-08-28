# SPDX-License-Identifier: LGPL-3.0-or-later

[CmdletBinding()]
param(
    [string]$InstallRoot,
    [string]$StateRoot,
    [string]$BackupPath
)

. (Join-Path $PSScriptRoot 'Common.ps1')

$manifest = Get-ProjectManifest
if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
    $InstallRoot = Get-DefaultInstallRoot -Manifest $manifest
}
if ([string]::IsNullOrWhiteSpace($StateRoot)) {
    $StateRoot = Get-DefaultStateRoot
}

$context = New-PatchContext -StateRoot $StateRoot -Action 'restore' -Manifest $manifest
try {
    Write-PatchLog -Context $context -Message "Starting patch restore: $($manifest.patchId)"
    Write-PatchLog -Context $context -Message "Target: $(Get-NormalizedPath -LiteralPath $InstallRoot)"

    $paths = Assert-TargetIdentity -InstallRoot $InstallRoot -Manifest $manifest
    Assert-GitHubDesktopStopped -InstallRoot $paths.Root

    $currentHash = Get-Sha256 -LiteralPath $paths.Renderer
    if ($currentHash -ceq [string]$manifest.target.originalRendererSha256) {
        Write-PatchLog -Context $context -Message 'State: already original; no write needed.'
        return
    }
    if ($currentHash -cne [string]$manifest.target.patchedRendererSha256) {
        throw "renderer.js is not this patch; refusing to overwrite it from backup. Actual hash: $currentHash"
    }

    if ([string]::IsNullOrWhiteSpace($BackupPath)) {
        $matching = @()
        foreach ($metadataPath in @(Get-ChildItem -File -LiteralPath $context.BackupDirectory -Filter '*.json' | Sort-Object LastWriteTimeUtc -Descending)) {
            try {
                $metadata = Get-Content -Raw -Encoding UTF8 -LiteralPath $metadataPath.FullName | ConvertFrom-Json
                $candidate = Join-Path $context.BackupDirectory ([string]$metadata.backupFile)
                if ([string]$metadata.installRoot -ceq $paths.Root -and
                    [string]$metadata.patchId -ceq [string]$manifest.patchId -and
                    [string]$metadata.sha256 -ceq [string]$manifest.target.originalRendererSha256 -and
                    (Test-Path -LiteralPath $candidate)) {
                    $matching += $candidate
                }
            }
            catch {
                # Ignore malformed unrelated metadata and continue looking for a verified backup.
            }
        }
        if ($matching.Count -eq 0) {
            throw 'No verified original backup matches this install root. Use -BackupPath to select the renderer.js backup created at install time.'
        }
        $BackupPath = $matching[0]
    }

    $BackupPath = Get-NormalizedPath -LiteralPath $BackupPath
    if (-not (Test-Path -LiteralPath $BackupPath)) {
        throw "Backup does not exist: $BackupPath"
    }
    Assert-NoReparsePoint -LiteralPath $BackupPath
    $backupHash = Get-Sha256 -LiteralPath $BackupPath
    if ($backupHash -cne [string]$manifest.target.originalRendererSha256) {
        throw "Backup hash mismatch; refusing to restore: $backupHash"
    }

    $temporaryPath = "$($paths.Renderer).zh-cn-restore-$PID-$([Guid]::NewGuid().ToString('N')).tmp.js"
    [System.IO.File]::Copy($BackupPath, $temporaryPath, $false)
    if ((Get-Sha256 -LiteralPath $temporaryPath) -cne [string]$manifest.target.originalRendererSha256) {
        throw 'Restore temporary file hash verification failed.'
    }
    Assert-JavaScriptSyntax -ElectronPath $paths.Exe -JavaScriptPath $temporaryPath
    Write-PatchLog -Context $context -Message 'Node --check passed using the verified GitHubDesktop.exe Electron Node mode.'

    Invoke-AtomicReplacement -TargetPath $paths.Renderer -ReplacementPath $temporaryPath -ExpectedHash ([string]$manifest.target.originalRendererSha256) -RollbackHash ([string]$manifest.target.patchedRendererSha256)
    Write-PatchLog -Context $context -Message "Restore succeeded using backup: $BackupPath"
    Write-PatchLog -Context $context -Message "Original SHA-256: $backupHash"
    Write-PatchLog -Context $context -Message "Log: $($context.LogPath)"
}
catch {
    Write-PatchLog -Context $context -Message "FAILED: $($_.Exception.Message)"
    throw
}
