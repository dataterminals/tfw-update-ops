<#
.SYNOPSIS
    Read the live Steam state for The Forever Winter: installed build, pending build,
    depot manifest ID (the rollback key), and any scheduled auto-update.

.NOTES
    Read-only. Never writes to the .acf -- Steam owns that file.
    Windows PowerShell 5.1 compatible.
#>
[CmdletBinding()]
param(
    [string]$AppId = '2828860',
    [string[]]$LibraryRoots = @(
        'H:\SteamLibrary\steamapps',
        'C:\Program Files (x86)\Steam\steamapps',
        'D:\SteamLibrary\steamapps'
    )
)

$ErrorActionPreference = 'Stop'

function Get-AcfValue {
    param([string]$Text, [string]$Key)
    $m = [regex]::Match($Text, '"' + [regex]::Escape($Key) + '"\s+"([^"]*)"')
    if ($m.Success) { return $m.Groups[1].Value }
    return $null
}

function Format-Epoch {
    param([string]$Seconds)
    if ([string]::IsNullOrWhiteSpace($Seconds) -or $Seconds -eq '0') { return '(none)' }
    return ([datetimeoffset]::FromUnixTimeSeconds([int64]$Seconds)).ToLocalTime().ToString('yyyy-MM-dd HH:mm:ss zzz')
}

$manifestPath = $null
foreach ($root in $LibraryRoots) {
    # Build the candidate as a plain string. Join-Path resolves the drive qualifier and throws
    # DriveNotFound on an absent drive, which killed the whole loop on the machine that lacks H:
    # before it could reach the roots that do exist. Test-Path is drive-safe; Join-Path is not.
    $candidate = $root.TrimEnd('\') + '\' + "appmanifest_$AppId.acf"
    if (Test-Path $candidate) { $manifestPath = $candidate; break }
}
if (-not $manifestPath) {
    throw "No appmanifest_$AppId.acf found in: $($LibraryRoots -join '; ')"
}

$acf = Get-Content $manifestPath -Raw

$buildId      = Get-AcfValue $acf 'buildid'
$targetBuild  = Get-AcfValue $acf 'TargetBuildID'
$stateFlags   = Get-AcfValue $acf 'StateFlags'
$toDownload   = Get-AcfValue $acf 'BytesToDownload'
$downloaded   = Get-AcfValue $acf 'BytesDownloaded'
$autoUpdate   = Get-AcfValue $acf 'AutoUpdateBehavior'
$scheduled    = Get-AcfValue $acf 'ScheduledAutoUpdate'
$lastUpdated  = Get-AcfValue $acf 'LastUpdated'
$sizeOnDisk   = Get-AcfValue $acf 'SizeOnDisk'
$installDir   = Get-AcfValue $acf 'installdir'

# Depot manifest IDs live in the InstalledDepots block.
$depots = @()
$di = $acf.IndexOf('"InstalledDepots"')
if ($di -ge 0) {
    $block = $acf.Substring($di, [Math]::Min(2000, $acf.Length - $di))
    foreach ($m in [regex]::Matches($block, '"(\d+)"\s*\{\s*"manifest"\s+"(\d+)"')) {
        $depots += [pscustomobject]@{ Depot = $m.Groups[1].Value; Manifest = $m.Groups[2].Value }
    }
}

$flagNames = @()
if ($stateFlags) {
    $f = [int]$stateFlags
    if ($f -band 1)   { $flagNames += 'Uninstalled' }
    if ($f -band 2)   { $flagNames += 'UpdateRequired' }
    if ($f -band 4)   { $flagNames += 'FullyInstalled' }
    if ($f -band 8)   { $flagNames += 'Encrypted' }
    if ($f -band 16)  { $flagNames += 'Locked' }
    if ($f -band 32)  { $flagNames += 'FilesMissing' }
    if ($f -band 64)  { $flagNames += 'AppRunning' }
    if ($f -band 1024){ $flagNames += 'UpdateRunning' }
}

$autoUpdateText = switch ($autoUpdate) {
    '0'     { '0 = always keep this game updated' }
    '1'     { '1 = only update when I launch it' }
    '2'     { '2 = high priority' }
    default { "$autoUpdate = (unrecognized)" }
}

$updatePending = ($targetBuild -and $targetBuild -ne '0' -and $targetBuild -ne $buildId)

Write-Output ''
Write-Output "  Steam state -- app $AppId ($installDir)"
Write-Output "  manifest file:   $manifestPath"
Write-Output ''
Write-Output "  Installed build: $buildId"
Write-Output "  Target build:    $(if ($targetBuild) { $targetBuild } else { '(none)' })"
Write-Output "  StateFlags:      $stateFlags  [$($flagNames -join ' | ')]"
Write-Output "  Last updated:    $(Format-Epoch $lastUpdated)"
Write-Output "  Size on disk:    $sizeOnDisk bytes"
Write-Output ''
Write-Output "  Auto-update:     $autoUpdateText"
Write-Output "  Scheduled at:    $(Format-Epoch $scheduled)"
Write-Output "  To download:     $toDownload bytes (downloaded so far: $downloaded)"
Write-Output ''
Write-Output '  Depot manifests (THE ROLLBACK KEYS -- record these in state/build-history.md):'
foreach ($d in $depots) {
    Write-Output "    depot $($d.Depot)  manifest $($d.Manifest)"
    Write-Output "      download_depot $AppId $($d.Depot) $($d.Manifest)"
}
Write-Output ''

if ($updatePending) {
    Write-Output "  >> UPDATE PENDING: $buildId -> $targetBuild"
    Write-Output "  >> The old build is still on disk. Baseline capture is still possible."
    Write-Output "  >> See docs/baseline-capture.md"
} else {
    Write-Output "  >> No update pending. Installed build is current."
}
Write-Output ''
