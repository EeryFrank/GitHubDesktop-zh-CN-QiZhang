Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$script:ProjectRoot = Split-Path -Parent $PSScriptRoot
$script:Utf8NoBom = New-Object System.Text.UTF8Encoding($false)

function Get-ProjectManifest {
    $path = Join-Path $script:ProjectRoot 'manifest.json'
    return (Get-Content -Raw -Encoding UTF8 -LiteralPath $path | ConvertFrom-Json)
}

function Get-TranslationData {
    $path = Join-Path $script:ProjectRoot 'translations.zh-CN.json'
    return (Get-Content -Raw -Encoding UTF8 -LiteralPath $path | ConvertFrom-Json)
}

function Get-Sha256 {
    param([Parameter(Mandatory = $true)][string]$LiteralPath)

    $stream = [System.IO.File]::OpenRead($LiteralPath)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        $bytes = $sha.ComputeHash($stream)
        return (($bytes | ForEach-Object { $_.ToString('x2') }) -join '').ToUpperInvariant()
    }
    finally {
        $sha.Dispose()
        $stream.Dispose()
    }
}

function Get-TargetVersion {
    param([Parameter(Mandatory = $true)]$Manifest)

    $targetVersion = [string]$Manifest.target.version
    if ([string]::IsNullOrWhiteSpace($targetVersion) -or $targetVersion -notmatch '^\d+\.\d+\.\d+$') {
        throw "Manifest target.version is missing or invalid: $targetVersion"
    }
    return $targetVersion
}

function Get-DefaultInstallRoot {
    param([Parameter(Mandatory = $true)]$Manifest)

    $localAppData = [Environment]::GetFolderPath('LocalApplicationData')
    $targetVersion = Get-TargetVersion -Manifest $Manifest
    return (Join-Path $localAppData "GitHubDesktop\app-$targetVersion")
}

function Get-DefaultStateRoot {
    $localAppData = [Environment]::GetFolderPath('LocalApplicationData')
    return (Join-Path $localAppData 'GitHubDesktop-zh-CN-patch')
}

function Get-NormalizedPath {
    param([Parameter(Mandatory = $true)][string]$LiteralPath)

    return [System.IO.Path]::GetFullPath($LiteralPath).TrimEnd('\')
}

function Assert-NoReparsePoint {
    param([Parameter(Mandatory = $true)][string]$LiteralPath)

    $item = Get-Item -Force -LiteralPath $LiteralPath
    if (($item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
        throw "Safety check failed: reparse points are not allowed: $LiteralPath"
    }
}

function Get-TargetPaths {
    param(
        [Parameter(Mandatory = $true)][string]$InstallRoot,
        [Parameter(Mandatory = $true)]$Manifest
    )

    $root = Get-NormalizedPath -LiteralPath $InstallRoot
    $expectedLeaf = 'app-' + (Get-TargetVersion -Manifest $Manifest)
    if ((Split-Path -Leaf $root) -cne $expectedLeaf) {
        throw "The install directory name must be ${expectedLeaf}: $root"
    }

    return [pscustomobject]@{
        Root = $root
        Exe = Join-Path $root 'GitHubDesktop.exe'
        Package = Join-Path $root 'resources\app\package.json'
        Renderer = Join-Path $root 'resources\app\renderer.js'
    }
}

function Assert-TargetIdentity {
    param(
        [Parameter(Mandatory = $true)][string]$InstallRoot,
        [Parameter(Mandatory = $true)]$Manifest
    )

    $paths = Get-TargetPaths -InstallRoot $InstallRoot -Manifest $Manifest
    foreach ($path in @($paths.Root, $paths.Exe, $paths.Package, $paths.Renderer)) {
        if (-not (Test-Path -LiteralPath $path)) {
            throw "Required target does not exist: $path"
        }
        Assert-NoReparsePoint -LiteralPath $path
    }

    $package = Get-Content -Raw -Encoding UTF8 -LiteralPath $paths.Package | ConvertFrom-Json
    if ([string]$package.version -cne [string]$Manifest.target.version) {
        throw "Version mismatch: package.json=$($package.version), patch=$($Manifest.target.version)"
    }

    $versionInfo = (Get-Item -LiteralPath $paths.Exe).VersionInfo
    if ([string]$versionInfo.ProductVersion -cne [string]$Manifest.target.version) {
        throw "Version mismatch: GitHubDesktop.exe=$($versionInfo.ProductVersion), patch=$($Manifest.target.version)"
    }

    $exeHash = Get-Sha256 -LiteralPath $paths.Exe
    if ($exeHash -cne [string]$Manifest.target.executableSha256) {
        throw "GitHubDesktop.exe hash mismatch; refusing to modify. Actual: $exeHash"
    }

    $packageHash = Get-Sha256 -LiteralPath $paths.Package
    if ($packageHash -cne [string]$Manifest.target.packageJsonSha256) {
        throw "package.json hash mismatch; refusing to modify. Actual: $packageHash"
    }

    $signature = Get-AuthenticodeSignature -FilePath $paths.Exe
    if ([string]$signature.Status -cne 'Valid') {
        throw "GitHubDesktop.exe Authenticode signature is invalid: $($signature.Status)"
    }
    if ($null -eq $signature.SignerCertificate -or
        [string]$signature.SignerCertificate.Thumbprint -cne [string]$Manifest.target.signerThumbprint) {
        throw 'GitHubDesktop.exe signer certificate thumbprint mismatch.'
    }

    return $paths
}

function Assert-GitHubDesktopStopped {
    param([Parameter(Mandatory = $true)][string]$InstallRoot)

    $normalizedRoot = Get-NormalizedPath -LiteralPath $InstallRoot
    $rootPrefix = $normalizedRoot + '\'
    $productPrefix = (Split-Path -Parent $normalizedRoot).TrimEnd('\') + '\'
    $blocking = @()
    foreach ($process in @(Get-Process -Name @('GitHubDesktop', 'Update', 'squirrel') -ErrorAction SilentlyContinue)) {
        try {
            $processPath = $process.Path
            $isDesktopInTarget = $process.ProcessName -ieq 'GitHubDesktop' -and
                $processPath -and $processPath.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)
            $isUpdaterInProduct = ($process.ProcessName -ieq 'Update' -or $process.ProcessName -ieq 'squirrel') -and
                $processPath -and $processPath.StartsWith($productPrefix, [StringComparison]::OrdinalIgnoreCase)
            if ($isDesktopInTarget -or $isUpdaterInProduct) {
                $blocking += $process
            }
        }
        catch {
            throw "Cannot safely inspect a GitHub Desktop process path. Exit the app first. PID: $($process.Id)"
        }
    }

    if ($blocking.Count -gt 0) {
        $details = ($blocking | ForEach-Object { '{0}:{1}' -f $_.ProcessName, $_.Id }) -join ', '
        throw "GitHub Desktop or its updater is still running ($details). Exit the tray app and wait for updates; this script never terminates processes."
    }
}

function Assert-JavaScriptSyntax {
    param(
        [Parameter(Mandatory = $true)][string]$ElectronPath,
        [Parameter(Mandatory = $true)][string]$JavaScriptPath
    )

    # GitHubDesktop.exe is an Electron executable. ELECTRON_RUN_AS_NODE makes
    # the already hash- and signature-verified executable expose its bundled
    # Node parser, so no downloaded or PATH-resolved third-party binary runs.
    $hadOldValue = Test-Path Env:ELECTRON_RUN_AS_NODE
    $oldValue = $env:ELECTRON_RUN_AS_NODE
    $stdoutPath = Join-Path ([System.IO.Path]::GetTempPath()) ('ghd-zh-node-check-' + [Guid]::NewGuid().ToString('N') + '.stdout.log')
    $stderrPath = Join-Path ([System.IO.Path]::GetTempPath()) ('ghd-zh-node-check-' + [Guid]::NewGuid().ToString('N') + '.stderr.log')
    $exitCode = -1
    $output = @()
    try {
        $env:ELECTRON_RUN_AS_NODE = '1'
        $quotedJavaScriptPath = '"' + $JavaScriptPath.Replace('"', '\"') + '"'
        $process = Start-Process -FilePath $ElectronPath -ArgumentList @('--check', $quotedJavaScriptPath) -Wait -PassThru -WindowStyle Hidden -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath
        $exitCode = $process.ExitCode
        if (Test-Path -LiteralPath $stdoutPath) {
            $output += @(Get-Content -Encoding UTF8 -LiteralPath $stdoutPath)
        }
        if (Test-Path -LiteralPath $stderrPath) {
            $output += @(Get-Content -Encoding UTF8 -LiteralPath $stderrPath)
        }
    }
    finally {
        if ($hadOldValue) {
            $env:ELECTRON_RUN_AS_NODE = $oldValue
        }
        else {
            Remove-Item Env:ELECTRON_RUN_AS_NODE -ErrorAction SilentlyContinue
        }
        foreach ($logPath in @($stdoutPath, $stderrPath)) {
            if (Test-Path -LiteralPath $logPath) {
                Remove-Item -Force -LiteralPath $logPath
            }
        }
    }

    if ($exitCode -ne 0) {
        throw "Node syntax check failed (exit $exitCode): $($output -join [Environment]::NewLine)"
    }
}

function Get-OrdinalOccurrenceCount {
    param(
        [Parameter(Mandatory = $true)][string]$Text,
        [Parameter(Mandatory = $true)][string]$Needle
    )

    if ($Needle.Length -eq 0) {
        throw 'A translation search value cannot be empty.'
    }

    $count = 0
    $start = 0
    while ($start -le $Text.Length - $Needle.Length) {
        $index = $Text.IndexOf($Needle, $start, [StringComparison]::Ordinal)
        if ($index -lt 0) {
            break
        }
        $count++
        $start = $index + $Needle.Length
    }
    return $count
}

function ConvertTo-JsonStringToken {
    param([Parameter(Mandatory = $true)][string]$Value)

    # Windows PowerShell 5.1's ConvertTo-Json escapes apostrophes as \u0027,
    # while webpack emits them literally inside double-quoted strings. Build
    # the JSON/JavaScript token explicitly so matching is byte-deterministic.
    $escaped = $Value.Replace('\', '\\')
    $escaped = $escaped.Replace('"', '\"')
    $escaped = $escaped.Replace("`b", '\b')
    $escaped = $escaped.Replace("`f", '\f')
    $escaped = $escaped.Replace("`n", '\n')
    $escaped = $escaped.Replace("`r", '\r')
    $escaped = $escaped.Replace("`t", '\t')
    return '"' + $escaped + '"'
}

function Invoke-Translations {
    param(
        [Parameter(Mandatory = $true)][string]$SourceText,
        [Parameter(Mandatory = $true)]$TranslationData
    )

    $text = $SourceText
    $replacementCount = 0
    $entryCount = 0

    $excludedPrefixes = @($TranslationData.excludedIdPrefixes)
    foreach ($entry in $TranslationData.entries) {
        $excluded = $false
        foreach ($prefix in $excludedPrefixes) {
            if ([string]$entry.id -like ([string]$prefix + '*')) {
                $excluded = $true
                break
            }
        }
        if ($excluded) {
            continue
        }
        $entryCount++
        $mode = [string]$entry.mode
        if ($mode -ceq 'json-string') {
            $find = ConvertTo-JsonStringToken -Value ([string]$entry.original)
            $replace = ConvertTo-JsonStringToken -Value ([string]$entry.translation)
        }
        elseif ($mode -ceq 'literal-fragment') {
            $find = [string]$entry.original
            $replace = [string]$entry.translation
        }
        else {
            throw "Unknown translation mode: $mode (entry $($entry.id))"
        }

        $actual = Get-OrdinalOccurrenceCount -Text $text -Needle $find
        $expected = [int]$entry.expectedOccurrences
        if ($actual -ne $expected) {
            throw "Translation count mismatch for $($entry.id): expected $expected, actual $actual. No target file was written."
        }

        $text = $text.Replace($find, $replace)
        $replacementCount += $actual
    }

    return [pscustomobject]@{
        Text = $text
        EntryCount = $entryCount
        ReplacementCount = $replacementCount
    }
}

function New-PatchContext {
    param(
        [Parameter(Mandatory = $true)][string]$StateRoot,
        [Parameter(Mandatory = $true)][string]$Action,
        [Parameter(Mandatory = $true)]$Manifest
    )

    $root = Get-NormalizedPath -LiteralPath $StateRoot
    $logDirectory = Join-Path $root 'logs'
    $backupRoot = Join-Path $root 'backups'
    $backupDirectory = Join-Path $backupRoot (Get-TargetVersion -Manifest $Manifest)
    [void][System.IO.Directory]::CreateDirectory($logDirectory)
    [void][System.IO.Directory]::CreateDirectory($backupDirectory)
    $stamp = [DateTime]::UtcNow.ToString('yyyyMMddTHHmmssfffZ')
    $logPath = Join-Path $logDirectory "$stamp-$Action-$PID.log"

    return [pscustomobject]@{
        StateRoot = $root
        BackupDirectory = $backupDirectory
        LogPath = $logPath
    }
}

function Write-PatchLog {
    param(
        [Parameter(Mandatory = $true)]$Context,
        [Parameter(Mandatory = $true)][string]$Message
    )

    $line = '[{0}] {1}' -f [DateTime]::UtcNow.ToString('o'), $Message
    Write-Host $line
    [System.IO.File]::AppendAllText($Context.LogPath, $line + [Environment]::NewLine, $script:Utf8NoBom)
}

function Write-JsonUtf8NoBom {
    param(
        [Parameter(Mandatory = $true)][string]$LiteralPath,
        [Parameter(Mandatory = $true)]$Value
    )

    $json = $Value | ConvertTo-Json -Depth 8
    [System.IO.File]::WriteAllText($LiteralPath, $json + [Environment]::NewLine, $script:Utf8NoBom)
}

function Invoke-AtomicReplacement {
    param(
        [Parameter(Mandatory = $true)][string]$TargetPath,
        [Parameter(Mandatory = $true)][string]$ReplacementPath,
        [Parameter(Mandatory = $true)][string]$ExpectedHash,
        [Parameter(Mandatory = $true)][string]$RollbackHash
    )

    $rollbackPath = "$TargetPath.zh-cn-emergency-$PID-$([Guid]::NewGuid().ToString('N')).bak"
    try {
        [System.IO.File]::Replace($ReplacementPath, $TargetPath, $rollbackPath, $true)
        $actualHash = Get-Sha256 -LiteralPath $TargetPath
        if ($actualHash -cne $ExpectedHash) {
            throw "Hash mismatch after atomic replacement: $actualHash"
        }
        if ((Get-Sha256 -LiteralPath $rollbackPath) -cne $RollbackHash) {
            throw 'Emergency rollback copy hash mismatch.'
        }
        Remove-Item -Force -LiteralPath $rollbackPath
    }
    catch {
        if (Test-Path -LiteralPath $rollbackPath) {
            try {
                $currentHash = Get-Sha256 -LiteralPath $TargetPath
                if ($currentHash -cne $RollbackHash) {
                    $failedPath = "$TargetPath.zh-cn-failed-$PID-$([Guid]::NewGuid().ToString('N')).tmp"
                    [System.IO.File]::Replace($rollbackPath, $TargetPath, $failedPath, $true)
                }
            }
            catch {
                throw "Atomic replacement and automatic rollback both failed. Preserve the install directory and recover from the independent backup. Details: $($_.Exception.Message)"
            }
        }
        throw
    }
    finally {
        if (Test-Path -LiteralPath $ReplacementPath) {
            Remove-Item -Force -LiteralPath $ReplacementPath
        }
    }
}
