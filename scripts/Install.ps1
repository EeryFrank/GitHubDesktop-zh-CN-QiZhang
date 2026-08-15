[CmdletBinding()]
param(
    [string]$InstallRoot,
    [string]$StateRoot
)

. (Join-Path $PSScriptRoot 'Common.ps1')

$manifest = Get-ProjectManifest
if ([string]::IsNullOrWhiteSpace($InstallRoot)) {
    $InstallRoot = Get-DefaultInstallRoot -Manifest $manifest
}
if ([string]::IsNullOrWhiteSpace($StateRoot)) {
    $StateRoot = Get-DefaultStateRoot
}

$context = New-PatchContext -StateRoot $StateRoot -Action 'install' -Manifest $manifest
try {
    $translations = Get-TranslationData
    Write-PatchLog -Context $context -Message "Starting patch install: $($manifest.patchId)"
    Write-PatchLog -Context $context -Message "Target: $(Get-NormalizedPath -LiteralPath $InstallRoot)"

    $paths = Assert-TargetIdentity -InstallRoot $InstallRoot -Manifest $manifest
    Assert-GitHubDesktopStopped -InstallRoot $paths.Root

    $currentHash = Get-Sha256 -LiteralPath $paths.Renderer
    if ($currentHash -ceq [string]$manifest.target.patchedRendererSha256) {
        Write-PatchLog -Context $context -Message 'State: already patched; no write needed.'
        return
    }
    if ($currentHash -cne [string]$manifest.target.originalRendererSha256) {
        throw "renderer.js is neither the supported original nor this patch. Actual hash: $currentHash"
    }

    $backupStamp = [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfffZ') + '-' + [Guid]::NewGuid().ToString('N').Substring(0, 8)
    $backupPath = Join-Path $context.BackupDirectory "$backupStamp-renderer.js"
    [System.IO.File]::Copy($paths.Renderer, $backupPath, $false)
    $backupHash = Get-Sha256 -LiteralPath $backupPath
    if ($backupHash -cne [string]$manifest.target.originalRendererSha256) {
        throw "Independent backup verification failed: $backupPath"
    }

    $backupMetadata = [ordered]@{
        schemaVersion = 1
        createdUtc = [DateTime]::UtcNow.ToString('o')
        patchId = [string]$manifest.patchId
        installRoot = $paths.Root
        targetRelativePath = 'resources\app\renderer.js'
        backupFile = [System.IO.Path]::GetFileName($backupPath)
        sha256 = $backupHash
    }
    Write-JsonUtf8NoBom -LiteralPath ($backupPath + '.json') -Value $backupMetadata
    Write-PatchLog -Context $context -Message "Independent backup created: $backupPath"

    $sourceText = [System.IO.File]::ReadAllText($paths.Renderer, [System.Text.Encoding]::UTF8)
    $result = Invoke-Translations -SourceText $sourceText -TranslationData $translations
    $temporaryPath = "$($paths.Renderer).zh-cn-$PID-$([Guid]::NewGuid().ToString('N')).tmp.js"
    [System.IO.File]::WriteAllText($temporaryPath, $result.Text, $script:Utf8NoBom)
    $patchedHash = Get-Sha256 -LiteralPath $temporaryPath
    if ($patchedHash -cne [string]$manifest.target.patchedRendererSha256) {
        throw "Generated file hash does not match manifest: $patchedHash"
    }
    Assert-JavaScriptSyntax -ElectronPath $paths.Exe -JavaScriptPath $temporaryPath
    Write-PatchLog -Context $context -Message 'Node --check passed using the verified GitHubDesktop.exe Electron Node mode.'

    Invoke-AtomicReplacement -TargetPath $paths.Renderer -ReplacementPath $temporaryPath -ExpectedHash ([string]$manifest.target.patchedRendererSha256) -RollbackHash ([string]$manifest.target.originalRendererSha256)
    Write-PatchLog -Context $context -Message "Install succeeded: $($result.EntryCount) translation entries, $($result.ReplacementCount) replacements."
    Write-PatchLog -Context $context -Message "Patched SHA-256: $patchedHash"
    Write-PatchLog -Context $context -Message "Log: $($context.LogPath)"
}
catch {
    Write-PatchLog -Context $context -Message "FAILED: $($_.Exception.Message)"
    throw
}
