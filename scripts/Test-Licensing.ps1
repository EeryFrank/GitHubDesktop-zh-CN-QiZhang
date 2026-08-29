# SPDX-License-Identifier: GPL-3.0-only

[CmdletBinding()]
param()

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$expectedSpdx = 'GPL-3.0-only'
$expectedAssetLicense = 'LicenseRef-EeryFrank-Assets-Permission-Required'
$expectedScriptHeader = '# SPDX-License-Identifier: GPL-3.0-only'
$expectedMarkdownHeader = '<!-- SPDX-License-Identifier: GPL-3.0-only -->'

function Get-FileSha256 {
    param([Parameter(Mandatory = $true)][string]$LiteralPath)

    $stream = [System.IO.File]::OpenRead($LiteralPath)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    try {
        return (($sha.ComputeHash($stream) | ForEach-Object { $_.ToString('x2') }) -join '').ToUpperInvariant()
    }
    finally {
        $sha.Dispose()
        $stream.Dispose()
    }
}

function Assert-ExactHash {
    param(
        [Parameter(Mandatory = $true)][string]$RelativePath,
        [Parameter(Mandatory = $true)][string]$ExpectedHash
    )

    $path = Join-Path $projectRoot $RelativePath
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Required license file is missing: $RelativePath"
    }
    $actual = Get-FileSha256 -LiteralPath $path
    if ($actual -cne $ExpectedHash) {
        throw "License file hash mismatch: $RelativePath actual=$actual expected=$ExpectedHash"
    }
}

function Assert-FirstLine {
    param(
        [Parameter(Mandatory = $true)][string]$RelativePath,
        [Parameter(Mandatory = $true)][string]$ExpectedLine
    )

    $path = Join-Path $projectRoot $RelativePath
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Licensed project file is missing: $RelativePath"
    }
    $firstLine = Get-Content -Encoding UTF8 -LiteralPath $path -TotalCount 1
    if ([string]$firstLine -cne $ExpectedLine) {
        throw "SPDX header mismatch: $RelativePath"
    }
}

$licenseHashes = [ordered]@{
    'LICENSE' = 'FB981668C18A279E285FC4D83FBA1E836CC84DD4DAA73C9697D3CFD2D8ACA6E0'
    'LICENSES\CC-BY-SA-4.0.txt' = 'CDE7883B9050A1104F4AC19A1572AAFD6E5D7323B68351AAF51FBF4BEBA54966'
    'LICENSES\LGPL-3.0-or-later.txt' = '996AF0513DF21F7496288951C41428A03C174E9E4A9D63665C57D670F845CCB1'
    'LICENSES\LicenseRef-EeryFrank-Assets-Permission-Required.txt' = 'A929DBAC5C7201B3E43BF186B097710B651F8B1D351BFAB39CD8308D92503CF0'
    'LICENSES\MIT-legacy-project.txt' = '41360965C11D27CB694A1ADA48A3A5165FE8A984B589728A8311E03272CF2571'
    'LICENSES\MIT-GitHub-Desktop.txt' = '891D678CD6AA67C0712F663B5FEE690F24D11D360795300814F7BF2EB91BA530'
}
foreach ($entry in $licenseHashes.GetEnumerator()) {
    Assert-ExactHash -RelativePath $entry.Key -ExpectedHash $entry.Value
}

$scriptFiles = @(Get-ChildItem -File -LiteralPath (Join-Path $projectRoot 'scripts') -Filter '*.ps1')
foreach ($file in $scriptFiles) {
    Assert-FirstLine -RelativePath ('scripts\' + $file.Name) -ExpectedLine $expectedScriptHeader
}

$markdownFiles = @(
    'README.md',
    'SECURITY.md',
    'CONTRIBUTING.md',
    'LICENSE_POLICY.md',
    'ASSET_LICENSES.md',
    'THIRD_PARTY_NOTICES.md'
)
$markdownFiles += @(Get-ChildItem -File -LiteralPath (Join-Path $projectRoot 'docs') -Filter '*.md' | ForEach-Object { 'docs\' + $_.Name })
foreach ($relativePath in $markdownFiles | Sort-Object -Unique) {
    Assert-FirstLine -RelativePath $relativePath -ExpectedLine $expectedMarkdownHeader
}

Assert-FirstLine -RelativePath '.github\workflows\audit.yml' -ExpectedLine $expectedScriptHeader
Assert-FirstLine -RelativePath '.gitattributes' -ExpectedLine $expectedScriptHeader
Assert-FirstLine -RelativePath '.gitignore' -ExpectedLine $expectedScriptHeader

$manifest = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $projectRoot 'manifest.json') | ConvertFrom-Json
if ([string]$manifest.projectContentLicense -cne $expectedSpdx -or
    [string]$manifest.futureProjectAssetLicense -cne $expectedAssetLicense -or
    [string]$manifest.assetInventory -cne 'ASSET_LICENSES.md' -or
    [string]$manifest.licensePolicy -cne 'LICENSE_POLICY.md') {
    throw 'manifest.json license metadata is missing or incorrect.'
}

$translations = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $projectRoot 'translations.zh-CN.json') | ConvertFrom-Json
if ([string]$translations.projectContentLicense -cne $expectedSpdx -or
    [string]$translations.upstreamOriginalStringsLicense -cne 'MIT' -or
    [string]$translations.upstreamLicenseFile -cne 'LICENSES/MIT-GitHub-Desktop.txt' -or
    [string]$translations.licensePolicy -cne 'LICENSE_POLICY.md') {
    throw 'translations.zh-CN.json mixed-license metadata is missing or incorrect.'
}
foreach ($translation in @($translations.entries)) {
    if ($null -eq $translation.PSObject.Properties['original'] -or $null -eq $translation.PSObject.Properties['translation']) {
        throw "Translation entry does not preserve the upstream/project field boundary: $($translation.id)"
    }
}

$policyText = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $projectRoot 'LICENSE_POLICY.md')
foreach ($requiredText in @('GPL-3.0-only', 'LicenseRef-EeryFrank-Assets-Permission-Required', 'LGPL-3.0-or-later.txt', 'CC-BY-SA-4.0.txt', 'MIT-legacy-project.txt', 'MIT-GitHub-Desktop.txt', 'existing-MIT-and-LGPL-grants-not-revoked', 'c4069d88b2fdce86d5b825a48b739aa5067c4ff2', 'ASSET_LICENSES.md', 'unmodified-only-inside-unmodified-official-package', 'separate-use-requires-prior-written-permission')) {
    if ($policyText.IndexOf($requiredText, [StringComparison]::OrdinalIgnoreCase) -lt 0) {
        throw "LICENSE_POLICY.md is missing a required boundary: $requiredText"
    }
}

$assetInventoryText = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $projectRoot 'ASSET_LICENSES.md')
foreach ($requiredText in @('Current-Project-Media-Assets: none', 'LicenseRef-EeryFrank-Assets-Permission-Required', 'unmodified-only-inside-unmodified-official-package', 'separate-use-requires-prior-written-permission', 'original', 'MIT')) {
    if ($assetInventoryText.IndexOf($requiredText, [StringComparison]::OrdinalIgnoreCase) -lt 0) {
        throw "ASSET_LICENSES.md is missing a required boundary: $requiredText"
    }
}

$mediaExtensions = @('.png', '.jpg', '.jpeg', '.gif', '.webp', '.svg', '.ico', '.wav', '.mp3', '.ogg', '.flac', '.m4a', '.ttf', '.otf', '.woff', '.woff2')
$mediaFiles = @(Get-ChildItem -Recurse -File -LiteralPath $projectRoot | Where-Object {
    $mediaExtensions -contains $_.Extension.ToLowerInvariant() -and
    $_.FullName -notmatch '[\\/](\.git|dist)[\\/]'
})
foreach ($mediaFile in $mediaFiles) {
    $relativeMediaPath = $mediaFile.FullName.Substring($projectRoot.Length).TrimStart('\').Replace('\', '/')
    if ($assetInventoryText.IndexOf($relativeMediaPath, [StringComparison]::OrdinalIgnoreCase) -lt 0) {
        throw "Media asset is not explicitly inventoried in ASSET_LICENSES.md: $relativeMediaPath"
    }
}

$noticeText = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $projectRoot 'THIRD_PARTY_NOTICES.md')
foreach ($requiredText in @('release-3.6.4', 'MIT-GitHub-Desktop.txt', 'actions/checkout', 'no-trademark-rights-granted')) {
    if ($noticeText.IndexOf($requiredText, [StringComparison]::OrdinalIgnoreCase) -lt 0) {
        throw "THIRD_PARTY_NOTICES.md is missing a required notice: $requiredText"
    }
}

$archiveScriptText = Get-Content -Raw -Encoding UTF8 -LiteralPath (Join-Path $projectRoot 'scripts\New-SourceArchive.ps1')
foreach ($requiredText in @('LICENSE_POLICY.md', 'ASSET_LICENSES.md', 'THIRD_PARTY_NOTICES.md', 'LICENSES/CC-BY-SA-4.0.txt', 'LICENSES/LGPL-3.0-or-later.txt', 'LICENSES/LicenseRef-EeryFrank-Assets-Permission-Required.txt', 'LICENSES/MIT-GitHub-Desktop.txt', 'LICENSES/MIT-legacy-project.txt')) {
    if ($archiveScriptText.IndexOf($requiredText, [StringComparison]::Ordinal) -lt 0) {
        throw "New-SourceArchive.ps1 is missing a required legal entry: $requiredText"
    }
}

[pscustomobject]@{
    Result = 'PASS'
    ProjectLicense = $expectedSpdx
    VerifiedLicenseFiles = $licenseHashes.Count
    VerifiedPowerShellFiles = $scriptFiles.Count
    VerifiedMarkdownFiles = @($markdownFiles | Sort-Object -Unique).Count
    TranslationEntries = @($translations.entries).Count
    UpstreamOriginalStringsLicense = [string]$translations.upstreamOriginalStringsLicense
    FutureProjectAssetLicense = [string]$manifest.futureProjectAssetLicense
    InventoriedMediaFiles = $mediaFiles.Count
    VerifiedArchiveLegalEntries = 8
} | Format-List
Write-Host 'LICENSE_AUDIT=PASS'
