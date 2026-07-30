<#
.SYNOPSIS
    Snapshot everything cheap-but-irreplaceable about the current game build, before a
    Steam update overwrites it.

.DESCRIPTION
    Captures Steam state, pak inventory + hashes, shipping-exe hash, the MO2 deployment
    (mod store listing + load order), and the fwdata catalog. Deliberately does NOT copy
    the paks themselves (~50 GB) -- the depot manifest ID in the Steam state is the
    insurance policy for that.

    Read-only with respect to the game, Steam, and MO2. Writes only under state/baselines/.

.PARAMETER Label
    Directory name under state/baselines/. Convention: pre-<target build id>.

.EXAMPLE
    powershell -File tools/capture_baseline.ps1 -Label pre-24479102

.NOTES
    Windows PowerShell 5.1 compatible. ASCII only (5.1 reads UTF-8 without BOM as ANSI).
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Label,

    [string]$GamePath  = 'H:\SteamLibrary\steamapps\common\The Forever Winter',
    [string]$AcfPath   = 'H:\SteamLibrary\steamapps\appmanifest_2828860.acf',
    [string]$Mo2Base   = 'H:\MO2Instance_ModData\ForeverWinter',
    [string]$Mo2Profile = 'Default',
    [string]$DatamineRepo = 'H:\Github Repositories\forever-winter-datamine',

    # Hashing ~50 GB of paks takes a while. Skip to capture sizes + names only.
    [switch]$SkipPakHashes,

    # Run the CUE4Parse decoder to produce filelist.txt. Needs the .NET 10 SDK.
    [switch]$RunDecoderList
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$outDir   = Join-Path $repoRoot "state\baselines\$Label"

if (Test-Path $outDir) {
    Write-Warning "Baseline '$Label' already exists at $outDir -- existing files will be overwritten."
}
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$warnings = @()
function Add-Warn { param([string]$m) ; $script:warnings += $m ; Write-Warning $m }

Write-Output "Capturing baseline '$Label' -> $outDir"
Write-Output ''

# ---------------------------------------------------------------- 1. Steam state
Write-Output '[1/6] Steam state'
if (Test-Path $AcfPath) {
    Copy-Item $AcfPath (Join-Path $outDir 'appmanifest.acf') -Force
    & (Join-Path $PSScriptRoot 'steam_state.ps1') |
        Out-File (Join-Path $outDir 'steam-state.txt') -Encoding utf8
    Write-Output '      appmanifest.acf + steam-state.txt'
} else {
    Add-Warn "Steam manifest not found at $AcfPath -- the ROLLBACK KEY was not captured."
}

# ------------------------------------------------------- 2. Pak inventory + hashes
Write-Output '[2/6] Pak inventory'
$paksPath = Join-Path $GamePath 'Windows\ForeverWinter\Content\Paks'
if (Test-Path $paksPath) {
    $paks = Get-ChildItem $paksPath -Recurse -File
    $rows = foreach ($p in $paks) {
        $hash = ''
        if (-not $SkipPakHashes) {
            $hash = (Get-FileHash $p.FullName -Algorithm SHA256).Hash
        }
        [pscustomobject]@{
            Name          = $p.FullName.Substring($paksPath.Length).TrimStart('\')
            Bytes         = $p.Length
            LastWriteUtc  = $p.LastWriteTimeUtc.ToString('o')
            Sha256        = $hash
        }
    }
    $rows | Sort-Object Name | Export-Csv (Join-Path $outDir 'paks-inventory.csv') -NoTypeInformation -Encoding UTF8
    $total = ($rows | Measure-Object Bytes -Sum).Sum
    Write-Output "      $($rows.Count) files, $total bytes -> paks-inventory.csv"
    if ($SkipPakHashes) { Add-Warn 'Pak hashes SKIPPED (-SkipPakHashes) -- inventory records names+sizes only.' }
} else {
    Add-Warn "Paks folder not found at $paksPath"
}

# ------------------------------------------------------------ 3. Shipping exe hash
Write-Output '[3/6] Shipping binaries'
$binDir = Join-Path $GamePath 'Windows\ForeverWinter\Binaries\Win64'
if (Test-Path $binDir) {
    Get-ChildItem $binDir -File |
        ForEach-Object {
            [pscustomobject]@{
                Name         = $_.Name
                Bytes        = $_.Length
                LastWriteUtc = $_.LastWriteTimeUtc.ToString('o')
                Sha256       = (Get-FileHash $_.FullName -Algorithm SHA256).Hash
            }
        } |
        Export-Csv (Join-Path $outDir 'binaries-win64.csv') -NoTypeInformation -Encoding UTF8
    Write-Output '      binaries-win64.csv (exe hash drives Signature Bypass / UE4SS expectations)'
} else {
    Add-Warn "Win64 binaries folder not found at $binDir"
}

# ------------------------------------------------------------- 4. MO2 deployment
Write-Output '[4/6] MO2 deployment'
$modsDir  = Join-Path $Mo2Base 'mods'
$modlist  = Join-Path $Mo2Base "profiles\$Mo2Profile\modlist.txt"
if (Test-Path $modsDir) {
    Get-ChildItem $modsDir -Directory |
        Select-Object -ExpandProperty Name |
        Out-File (Join-Path $outDir 'mo2-mods.txt') -Encoding utf8
    Write-Output '      mo2-mods.txt'
} else {
    Add-Warn "MO2 mod store not found at $modsDir"
}
if (Test-Path $modlist) {
    Copy-Item $modlist (Join-Path $outDir 'mo2-modlist.txt') -Force
    Write-Output '      mo2-modlist.txt (load order + enabled/disabled state)'
} else {
    Add-Warn "MO2 modlist not found at $modlist"
}

# ---------------------------------------------------------- 5. fwdata catalog copy
Write-Output '[5/6] fwdata catalog'
$catalogDir = Join-Path $DatamineRepo 'datamine\catalog'
if (Test-Path $catalogDir) {
    $dest = Join-Path $outDir 'catalog'
    New-Item -ItemType Directory -Force -Path $dest | Out-Null
    Copy-Item (Join-Path $catalogDir '*.json') $dest -Force
    Write-Output '      catalog/*.json (items, widgets, tables -- the diffable summary)'
} else {
    Add-Warn "fwdata catalog not found at $catalogDir -- run 'python -m fwdata build all' first."
}

# git state of the datamine repo: the dumps live there, so record the exact commit
if (Test-Path (Join-Path $DatamineRepo '.git')) {
    $sha    = (& git -C $DatamineRepo rev-parse HEAD)
    $status = (& git -C $DatamineRepo status --porcelain)
    $lines = @("datamine HEAD: $sha", '', 'working tree:')
    if ([string]::IsNullOrWhiteSpace($status)) {
        $lines += '  (clean)'
    } else {
        $lines += ($status -split "`n" | ForEach-Object { "  $_" })
        Add-Warn 'forever-winter-datamine has uncommitted changes -- commit before tagging the baseline.'
    }
    $lines | Out-File (Join-Path $outDir 'datamine-git-state.txt') -Encoding utf8
    Write-Output "      datamine-git-state.txt (HEAD $($sha.Substring(0,8)))"
}

# ------------------------------------------------------------ 6. decoder filelist
Write-Output '[6/6] Decoder filelist'
$decoderDir = Join-Path $DatamineRepo 'datamine\decoder'
if ($RunDecoderList) {
    if (Test-Path $decoderDir) {
        $env:FW_PAKS = $paksPath
        Push-Location $decoderDir
        try {
            & dotnet run -c Release -- list
            $fl = Join-Path $decoderDir 'out\filelist.txt'
            if (Test-Path $fl) {
                Copy-Item $fl (Join-Path $outDir 'filelist.txt') -Force
                $n = (Get-Content $fl | Measure-Object -Line).Lines
                Write-Output "      filelist.txt ($n entries) -- THE key diff input"
            } else {
                Add-Warn 'Decoder ran but out/filelist.txt was not produced.'
            }
        } catch {
            Add-Warn "Decoder failed: $($_.Exception.Message). Needs the .NET 10 SDK."
        } finally {
            Pop-Location
        }
    } else {
        Add-Warn "Decoder not found at $decoderDir"
    }
} else {
    Add-Warn 'filelist.txt NOT captured (-RunDecoderList not set). This is the single most useful diff input -- capture it before patching.'
}

# ----------------------------------------------------------------------- summary
$summary = @()
$summary += "# Baseline: $Label"
$summary += ''
$summary += "Captured: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz')"
$summary += "Game path: $GamePath"
$summary += ''
$summary += '## Files'
Get-ChildItem $outDir -Recurse -File | ForEach-Object {
    $summary += "- $($_.FullName.Substring($outDir.Length).TrimStart('\')) ($($_.Length) bytes)"
}
$summary += ''
if ($warnings.Count -gt 0) {
    $summary += '## Warnings'
    foreach ($w in $warnings) { $summary += "- $w" }
} else {
    $summary += '## Warnings'
    $summary += '- none'
}
$summary | Out-File (Join-Path $outDir 'SUMMARY.md') -Encoding utf8

Write-Output ''
Write-Output "Done. $($warnings.Count) warning(s). See $outDir\SUMMARY.md"
if ($warnings.Count -gt 0) {
    Write-Output ''
    Write-Output 'Review the warnings before giving Steam the go-ahead -- an incomplete baseline is decorative.'
}
