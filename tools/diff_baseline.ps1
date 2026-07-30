<#
.SYNOPSIS
    Diff two captured baselines and produce the Stage 2 intelligence product.

.DESCRIPTION
    Compares two directories under state/baselines/ and reports what the game update
    actually changed: build/manifest IDs, shipping binary hashes, pak-level churn,
    added/removed assets from the decoder filelist, and DataTable schema/row-count
    deltas from the fwdata catalog.

    The filelist delta is the headline output -- it answers "which assets moved" which
    is exactly what Class A pak mods are baked against. Cross-reference the result
    against state/asset-dependencies.md to route at specific mods.

    Read-only with respect to everything except state/diffs/.

.PARAMETER Before
    Label of the pre-patch baseline directory, e.g. pre-24479102.

.PARAMETER After
    Label of the post-patch baseline directory, e.g. post-24479102.

.PARAMETER Top
    How many entries to inline into REPORT.md per section. Full lists always go to
    their own files. Default 40.

.EXAMPLE
    powershell -File tools/diff_baseline.ps1 -Before pre-24479102 -After post-24479102

.NOTES
    Windows PowerShell 5.1 compatible. ASCII only (5.1 reads UTF-8 without BOM as ANSI).
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Before,
    [Parameter(Mandatory = $true)][string]$After,
    [int]$Top = 40
)

$ErrorActionPreference = 'Stop'

$RepoRoot     = Split-Path -Parent $PSScriptRoot
$BaselineRoot = Join-Path $RepoRoot 'state\baselines'
$BeforeDir    = Join-Path $BaselineRoot $Before
$AfterDir     = Join-Path $BaselineRoot $After

foreach ($d in @($BeforeDir, $AfterDir)) {
    if (-not (Test-Path $d)) { throw "Baseline not found: $d" }
}

$OutDir = Join-Path $RepoRoot ("state\diffs\{0}__vs__{1}" -f $Before, $After)
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null

$warnings = New-Object System.Collections.ArrayList
$report   = New-Object System.Collections.ArrayList
function Add-Line { param([string]$Text = '') ; [void]$report.Add($Text) }
function Add-Warn { param([string]$Text) ; [void]$warnings.Add($Text) }

Write-Host ""
Write-Host ("  Diffing {0} -> {1}" -f $Before, $After)
Write-Host ("  Output: {0}" -f $OutDir)
Write-Host ""

Add-Line ("# Baseline diff: {0} -> {1}" -f $Before, $After)
Add-Line ""
Add-Line ("Generated: {0}" -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss zzz'))
Add-Line ""
Add-Line "The Stage 2 intelligence product. Cross-reference the asset churn below against"
Add-Line "``state/asset-dependencies.md`` to route at the mods that actually care."
Add-Line ""

# ---------------------------------------------------------------- Steam state

Write-Host "[1/6] Steam state"
Add-Line "## Build identity"
Add-Line ""

function Get-AcfField {
    param([string]$Path, [string]$Field)
    if (-not (Test-Path $Path)) { return $null }
    $raw = Get-Content $Path -Raw
    if ($raw -match ('"{0}"\s+"([^"]*)"' -f [regex]::Escape($Field))) { return $matches[1] }
    return $null
}

function Get-AcfManifest {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return $null }
    $raw = Get-Content $Path -Raw
    if ($raw -match '"2828861"\s*\{[^}]*?"manifest"\s+"(\d+)"') { return $matches[1] }
    return $null
}

$acfB = Join-Path $BeforeDir 'appmanifest.acf'
$acfA = Join-Path $AfterDir  'appmanifest.acf'

$buildB = Get-AcfField -Path $acfB -Field 'buildid'
$buildA = Get-AcfField -Path $acfA -Field 'buildid'
$manB   = Get-AcfManifest -Path $acfB
$manA   = Get-AcfManifest -Path $acfA
$sizeB  = Get-AcfField -Path $acfB -Field 'SizeOnDisk'
$sizeA  = Get-AcfField -Path $acfA -Field 'SizeOnDisk'

Add-Line "| Field | $Before | $After |"
Add-Line "|---|---|---|"
Add-Line ("| Build ID | ``{0}`` | ``{1}`` |" -f $buildB, $buildA)
Add-Line ("| Depot manifest (rollback key) | ``{0}`` | ``{1}`` |" -f $manB, $manA)
Add-Line ("| Size on disk | {0} | {1} |" -f $sizeB, $sizeA)
Add-Line ""

if ($buildB -eq $buildA) {
    Add-Warn "Build ID is IDENTICAL in both baselines -- did the update actually apply?"
    Add-Line "> **Build ID did not change.** Either the update has not applied yet, or the wrong"
    Add-Line "> baseline was captured. Everything below is probably meaningless."
    Add-Line ""
}
if ($manA) {
    Add-Line ("**Record ``{0}`` in ``state/build-history.md`` -- it is the rollback key for the NEXT patch.**" -f $manA)
    Add-Line ""
}

# ------------------------------------------------------------ Shipping binaries

Write-Host "[2/6] Shipping binaries"
Add-Line "## Shipping binaries"
Add-Line ""
Add-Line "Drives expectations for Signature Bypass and RE-UE4SS. A changed shipping exe is normal"
Add-Line "and expected; it does not by itself mean UE4SS is dead, but it does mean signatures must"
Add-Line "be re-verified before trusting Class B."
Add-Line ""

function Import-Inventory {
    param([string]$Path)
    $map = @{}
    if (-not (Test-Path $Path)) { return $null }
    foreach ($row in (Import-Csv $Path)) { $map[$row.Name] = $row }
    return $map
}

$binB = Import-Inventory (Join-Path $BeforeDir 'binaries-win64.csv')
$binA = Import-Inventory (Join-Path $AfterDir  'binaries-win64.csv')

if ($null -eq $binB -or $null -eq $binA) {
    Add-Warn "binaries-win64.csv missing from one or both baselines -- binary section skipped."
    Add-Line "*Skipped: binaries-win64.csv missing from one or both baselines.*"
    Add-Line ""
} else {
    $binRows = New-Object System.Collections.ArrayList
    foreach ($name in ($binB.Keys + $binA.Keys | Sort-Object -Unique)) {
        $b = $binB[$name]; $a = $binA[$name]
        if     ($null -eq $a) { $state = 'REMOVED' }
        elseif ($null -eq $b) { $state = 'ADDED' }
        elseif ($b.Sha256 -ne $a.Sha256) { $state = 'CHANGED' }
        else { continue }
        [void]$binRows.Add([pscustomobject]@{
            Name       = $name
            State      = $state
            BytesBefore= if ($b) { $b.Bytes } else { '' }
            BytesAfter = if ($a) { $a.Bytes } else { '' }
            Sha256Before = if ($b) { $b.Sha256 } else { '' }
            Sha256After  = if ($a) { $a.Sha256 } else { '' }
        })
    }

    if ($binRows.Count -eq 0) {
        Add-Line "No shipping binary changed. Notable -- Signature Bypass and UE4SS signatures very"
        Add-Line "likely still apply."
    } else {
        $binRows | Export-Csv (Join-Path $OutDir 'binaries-changed.csv') -NoTypeInformation -Encoding ASCII
        Add-Line ("{0} binary file(s) changed. Full detail: ``binaries-changed.csv``" -f $binRows.Count)
        Add-Line ""
        Add-Line "| Binary | State | Bytes before | Bytes after |"
        Add-Line "|---|---|---|---|"
        foreach ($r in $binRows) {
            Add-Line ("| ``{0}`` | {1} | {2} | {3} |" -f $r.Name, $r.State, $r.BytesBefore, $r.BytesAfter)
        }
    }
    Add-Line ""

    $exe = 'ForeverWinter-Win64-Shipping.exe'
    if ($binB.ContainsKey($exe) -and $binA.ContainsKey($exe)) {
        if ($binB[$exe].Sha256 -ne $binA[$exe].Sha256) {
            Add-Line ("**Shipping exe CHANGED** ({0} -> {1} bytes). Re-run AESDumpster against it (Gate 1a)" -f $binB[$exe].Bytes, $binA[$exe].Bytes)
            Add-Line "and expect to re-verify Signature Bypass + RE-UE4SS (Gates 3 / 3b)."
        } else {
            Add-Line "**Shipping exe is byte-identical.** The AES key cannot have rotated, and UE4SS/Signature"
            Add-Line "Bypass signatures still match. Gates 1a, 3 and 3b are effectively pre-cleared."
        }
        Add-Line ""
    }
}

# ------------------------------------------------------------------- Pak churn

Write-Host "[3/6] Pak inventory"
Add-Line "## Pak churn"
Add-Line ""

$pakB = Import-Inventory (Join-Path $BeforeDir 'paks-inventory.csv')
$pakA = Import-Inventory (Join-Path $AfterDir  'paks-inventory.csv')

if ($null -eq $pakB -or $null -eq $pakA) {
    Add-Warn "paks-inventory.csv missing from one or both baselines -- pak section skipped."
    Add-Line "*Skipped: paks-inventory.csv missing from one or both baselines.*"
    Add-Line ""
} else {
    $pakRows = New-Object System.Collections.ArrayList
    foreach ($name in ($pakB.Keys + $pakA.Keys | Sort-Object -Unique)) {
        $b = $pakB[$name]; $a = $pakA[$name]
        if     ($null -eq $a) { $state = 'REMOVED' }
        elseif ($null -eq $b) { $state = 'ADDED' }
        elseif ($b.Sha256 -ne $a.Sha256) { $state = 'CHANGED' }
        else { continue }
        [void]$pakRows.Add([pscustomobject]@{
            Name = $name; State = $state
            BytesBefore = if ($b) { $b.Bytes } else { '' }
            BytesAfter  = if ($a) { $a.Bytes } else { '' }
            Sha256Before = if ($b) { $b.Sha256 } else { '' }
            Sha256After  = if ($a) { $a.Sha256 } else { '' }
        })
    }

    $totalB = ($pakB.Values | Measure-Object -Property Bytes -Sum).Sum
    $totalA = ($pakA.Values | Measure-Object -Property Bytes -Sum).Sum
    Add-Line ("Pak count: {0} -> {1}. Total bytes: {2} -> {3} (delta {4})." -f `
        $pakB.Count, $pakA.Count, $totalB, $totalA, ($totalA - $totalB))
    Add-Line ""

    if ($pakRows.Count -eq 0) {
        Add-Line "No pak changed. That would be very surprising for a real update."
        Add-Warn "No pak files changed -- verify the correct post-patch baseline was captured."
    } else {
        $pakRows | Export-Csv (Join-Path $OutDir 'paks-changed.csv') -NoTypeInformation -Encoding ASCII
        Add-Line ("{0} pak file(s) changed. Full detail: ``paks-changed.csv``" -f $pakRows.Count)
        Add-Line ""
        Add-Line "| Pak | State | Bytes before | Bytes after |"
        Add-Line "|---|---|---|---|"
        foreach ($r in ($pakRows | Select-Object -First $Top)) {
            Add-Line ("| ``{0}`` | {1} | {2} | {3} |" -f $r.Name, $r.State, $r.BytesBefore, $r.BytesAfter)
        }
        if ($pakRows.Count -gt $Top) {
            Add-Line ("| ... | *{0} more in the CSV* | | |" -f ($pakRows.Count - $Top))
        }
    }
    Add-Line ""
}

# --------------------------------------------------------------- Asset filelist

Write-Host "[4/6] Asset filelist (the headline)"
Add-Line "## Asset churn (filelist)"
Add-Line ""

$flB = Join-Path $BeforeDir 'filelist.txt'
$flA = Join-Path $AfterDir  'filelist.txt'

if (-not (Test-Path $flB) -or -not (Test-Path $flA)) {
    Add-Warn "filelist.txt missing from one or both baselines -- THE key diff input is unavailable."
    Add-Line "*Skipped: ``filelist.txt`` missing from one or both baselines. This is the single most"
    Add-Line "valuable diff input -- re-run the capture with ``-RunDecoderList``.*"
    Add-Line ""
} else {
    $arrB = [string[]](Get-Content $flB)
    $arrA = [string[]](Get-Content $flA)
    $setB = New-Object 'System.Collections.Generic.HashSet[string]'(, $arrB)
    $setA = New-Object 'System.Collections.Generic.HashSet[string]'(, $arrA)

    $added   = @($arrA | Where-Object { -not $setB.Contains($_) })
    $removed = @($arrB | Where-Object { -not $setA.Contains($_) })

    Set-Content -Path (Join-Path $OutDir 'filelist-added.txt')   -Value $added   -Encoding ASCII
    Set-Content -Path (Join-Path $OutDir 'filelist-removed.txt') -Value $removed -Encoding ASCII

    Add-Line ("Entries: {0} -> {1}. **{2} added, {3} removed.**" -f $arrB.Count, $arrA.Count, $added.Count, $removed.Count)
    Add-Line ""
    Add-Line "Full lists: ``filelist-added.txt`` / ``filelist-removed.txt``"
    Add-Line ""

    if ($added.Count -eq 0 -and $removed.Count -eq 0) {
        Add-Line "**No assets were added or removed.** Every asset path survived the patch. That is the"
        Add-Line "good case for Class A: no mod's overlay target vanished. Note this does NOT mean asset"
        Add-Line "*contents* are unchanged -- a DataTable can be rewritten in place. Check the catalog"
        Add-Line "section below and re-decode before declaring anything clean."
        Add-Line ""
    } else {
        # Rollup by directory prefix -- far more readable than thousands of raw paths.
        function Get-Rollup {
            param([string[]]$Paths, [int]$Depth = 3)
            $h = @{}
            foreach ($p in $Paths) {
                $parts = $p -split '/'
                if ($parts.Count -gt $Depth) { $key = ($parts[0..($Depth - 1)] -join '/') + '/' }
                else { $key = $p }
                if ($h.ContainsKey($key)) { $h[$key]++ } else { $h[$key] = 1 }
            }
            return $h.GetEnumerator() | Sort-Object -Property Value -Descending
        }

        if ($added.Count -gt 0) {
            Add-Line "### Added, grouped by directory"
            Add-Line ""
            Add-Line "| Count | Directory |"
            Add-Line "|---|---|"
            foreach ($e in (Get-Rollup -Paths $added | Select-Object -First $Top)) {
                Add-Line ("| {0} | ``{1}`` |" -f $e.Value, $e.Name)
            }
            Add-Line ""
        }
        if ($removed.Count -gt 0) {
            Add-Line "### Removed, grouped by directory"
            Add-Line ""
            Add-Line "**Removals are the dangerous ones for Class A** -- a removed path means any mod"
            Add-Line "overlaying it now overlays nothing, silently."
            Add-Line ""
            Add-Line "| Count | Directory |"
            Add-Line "|---|---|"
            foreach ($e in (Get-Rollup -Paths $removed | Select-Object -First $Top)) {
                Add-Line ("| {0} | ``{1}`` |" -f $e.Value, $e.Name)
            }
            Add-Line ""
        }
    }
}

# ----------------------------------------------------------------- Catalog diff

Write-Host "[5/6] fwdata catalog"
Add-Line "## DataTable catalog"
Add-Line ""
Add-Line "A changed ``RowStruct`` is a direct pointer at a Class A mod that is now writing into the"
Add-Line "wrong shape. A changed row count means content moved under a mod that indexes into it."
Add-Line ""

$tblBPath = Join-Path $BeforeDir 'catalog\tables.json'
$tblAPath = Join-Path $AfterDir  'catalog\tables.json'

if (-not (Test-Path $tblBPath) -or -not (Test-Path $tblAPath)) {
    Add-Warn "catalog/tables.json missing from one or both baselines -- catalog section skipped."
    Add-Line "*Skipped: ``catalog/tables.json`` missing from one or both baselines.*"
    Add-Line ""
} else {
    $tB = (Get-Content $tblBPath -Raw | ConvertFrom-Json)
    $tA = (Get-Content $tblAPath -Raw | ConvertFrom-Json)

    $namesB = @($tB.tables.PSObject.Properties.Name)
    $namesA = @($tA.tables.PSObject.Properties.Name)

    Add-Line ("Catalog build stamp: ``{0}`` -> ``{1}``. Table count: {2} -> {3}." -f `
        $tB.build, $tA.build, $namesB.Count, $namesA.Count)
    Add-Line ""

    if ($tA.build -eq $tB.build) {
        Add-Warn "Catalog build stamp did not change -- the post-patch catalog may be stale (re-decode with --force, then rebuild)."
    }

    $tblRows = New-Object System.Collections.ArrayList
    foreach ($n in ($namesB + $namesA | Sort-Object -Unique)) {
        $b = $tB.tables.$n
        $a = $tA.tables.$n
        if ($null -eq $a)      { $state = 'REMOVED' }
        elseif ($null -eq $b)  { $state = 'ADDED' }
        elseif ($b.row_struct -ne $a.row_struct) { $state = 'ROWSTRUCT CHANGED' }
        elseif ($b.rows -ne $a.rows)             { $state = 'ROWCOUNT CHANGED' }
        else { continue }
        [void]$tblRows.Add([pscustomobject]@{
            Table = $n; State = $state
            StructBefore = if ($b) { $b.row_struct } else { '' }
            StructAfter  = if ($a) { $a.row_struct } else { '' }
            RowsBefore   = if ($b) { $b.rows } else { '' }
            RowsAfter    = if ($a) { $a.rows } else { '' }
        })
    }

    if ($tblRows.Count -eq 0) {
        Add-Line "No table added, removed, restructured, or resized."
        Add-Line ""
        Add-Line "Caveat worth stating plainly: this compares **schema and row counts only**. A weapons"
        Add-Line "tuning pass that rewrites values in place changes neither. Do not read this as"
        Add-Line "'weapon data unchanged' -- that requires diffing the decoded dumps themselves."
    } else {
        $tblRows | Export-Csv (Join-Path $OutDir 'tables-changed.csv') -NoTypeInformation -Encoding ASCII
        Add-Line ("{0} table(s) changed. Full detail: ``tables-changed.csv``" -f $tblRows.Count)
        Add-Line ""
        Add-Line "| Table | State | RowStruct before | RowStruct after | Rows before | Rows after |"
        Add-Line "|---|---|---|---|---|---|"
        foreach ($r in $tblRows) {
            Add-Line ("| ``{0}`` | {1} | ``{2}`` | ``{3}`` | {4} | {5} |" -f `
                $r.Table, $r.State, $r.StructBefore, $r.StructAfter, $r.RowsBefore, $r.RowsAfter)
        }
    }
    Add-Line ""
}

# --------------------------------------------------------------- MO2 deployment

Write-Host "[6/6] MO2 deployment"
Add-Line "## MO2 deployment"
Add-Line ""

$mlB = Join-Path $BeforeDir 'mo2-modlist.txt'
$mlA = Join-Path $AfterDir  'mo2-modlist.txt'
if ((Test-Path $mlB) -and (Test-Path $mlA)) {
    $d = Compare-Object (Get-Content $mlB) (Get-Content $mlA)
    if ($null -eq $d -or $d.Count -eq 0) {
        Add-Line "Load order and enabled/disabled state are unchanged, as expected -- the MO2 mod store"
        Add-Line "lives outside the game directory and Steam does not touch it."
    } else {
        Add-Warn "MO2 modlist CHANGED between baselines -- the deployment moved under us."
        Add-Line "**The MO2 modlist changed between baselines.** That is unexpected for a Steam update."
        Add-Line ""
        Add-Line '```'
        foreach ($x in $d) { Add-Line ("{0} {1}" -f $x.SideIndicator, $x.InputObject) }
        Add-Line '```'
    }
} else {
    Add-Line "*Skipped: mo2-modlist.txt missing from one or both baselines.*"
}
Add-Line ""

# ------------------------------------------------------------------ Next steps

Add-Line "## What to do next"
Add-Line ""
Add-Line "1. Record the new depot manifest in ``state/build-history.md`` (rollback key for the next patch)."
Add-Line "2. Gate 1a -- re-run AESDumpster against the new shipping exe if it changed."
Add-Line "3. Gate 1b -- decode a known asset and eyeball the values before trusting anything here."
Add-Line "4. Intersect ``filelist-added.txt`` / ``filelist-removed.txt`` against ``state/asset-dependencies.md``"
Add-Line "   to get the per-mod hit list, then work ``state/status.md`` in gate order."
Add-Line ""

if ($warnings.Count -gt 0) {
    Add-Line "## Warnings"
    Add-Line ""
    foreach ($w in $warnings) { Add-Line ("- {0}" -f $w) }
    Add-Line ""
}

$reportPath = Join-Path $OutDir 'REPORT.md'
Set-Content -Path $reportPath -Value $report -Encoding ASCII

Write-Host ""
if ($warnings.Count -gt 0) {
    Write-Host ("  Done with {0} warning(s):" -f $warnings.Count)
    foreach ($w in $warnings) { Write-Host ("    ! {0}" -f $w) }
} else {
    Write-Host "  Done. 0 warnings."
}
Write-Host ("  Report: {0}" -f $reportPath)
Write-Host ""
