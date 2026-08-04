# Baseline diff: pre-24536482 -> post-24536482

Generated: 2026-08-03 20:24:01 -04:00

The Stage 2 intelligence product. Cross-reference the asset churn below against
`state/asset-dependencies.md` to route at the mods that actually care.

## Build identity

| Field | pre-24536482 | post-24536482 |
|---|---|---|
| Build ID | `24501089` | `24536482` |
| Depot manifest (rollback key) | `6443337773729671953` | `7134816348397298387` |
| Size on disk | 50812092213 | 50813198796 |

**Record `7134816348397298387` in `state/build-history.md` -- it is the rollback key for the NEXT patch.**

## Shipping binaries

Drives expectations for Signature Bypass and RE-UE4SS. A changed shipping exe is normal
and expected; it does not by itself mean UE4SS is dead, but it does mean signatures must
be re-verified before trusting Class B.

1 binary file(s) changed. Full detail: `binaries-changed.csv`

| Binary | State | Bytes before | Bytes after |
|---|---|---|---|
| `ForeverWinter-Win64-Shipping.exe` | CHANGED | 169584128 | 169641472 |

**Shipping exe CHANGED** (169584128 -> 169641472 bytes). Re-run AESDumpster against it (Gate 1a)
and expect to re-verify Signature Bypass + RE-UE4SS (Gates 3 / 3b).

## Pak churn

Pak count: 119 -> 119. Total bytes: 48572725793 -> 48573775032 (delta 1049239).

33 pak file(s) changed. Full detail: `paks-changed.csv`

| Pak | State | Bytes before | Bytes after |
|---|---|---|---|
| `FWPakManifest.json` | CHANGED | 19502 | 19502 |
| `global.ucas` | CHANGED | 3014224 | 3014592 |
| `global.utoc` | CHANGED | 1615 | 1615 |
| `pakchunk0_s1-Windows.ucas` | CHANGED | 1762946512 | 1763995088 |
| `pakchunk0_s1-Windows.utoc` | CHANGED | 1286347 | 1286347 |
| `pakchunk0-Windows.pak` | CHANGED | 56211535 | 56211535 |
| `pakchunk0-Windows.sig` | CHANGED | 3960 | 3960 |
| `pakchunk0-Windows.ucas` | CHANGED | 2425709264 | 2425709264 |
| `pakchunk0-Windows.utoc` | CHANGED | 2168023 | 2168023 |
| `pakchunk20_s10-Windows.ucas` | CHANGED | 3144197440 | 3144197440 |
| `pakchunk20_s10-Windows.utoc` | CHANGED | 992196 | 992196 |
| `pakchunk20_s11-Windows.ucas` | CHANGED | 1567297376 | 1567297376 |
| `pakchunk20_s11-Windows.utoc` | CHANGED | 867326 | 867326 |
| `pakchunk20_s12-Windows.ucas` | CHANGED | 2274727664 | 2274727808 |
| `pakchunk20_s12-Windows.utoc` | CHANGED | 1204733 | 1204868 |
| `pakchunk20_s13-Windows.ucas` | CHANGED | 2627875712 | 2627875712 |
| `pakchunk20_s13-Windows.utoc` | CHANGED | 925230 | 925230 |
| `pakchunk20_s16-Windows.ucas` | CHANGED | 1950437808 | 1950437808 |
| `pakchunk20_s16-Windows.utoc` | CHANGED | 1221572 | 1221572 |
| `pakchunk20_s17-Windows.ucas` | CHANGED | 1358580272 | 1358580272 |
| `pakchunk20_s17-Windows.utoc` | CHANGED | 741217 | 741217 |
| `pakchunk20_s1-Windows.ucas` | CHANGED | 3064565136 | 3064565136 |
| `pakchunk20_s1-Windows.utoc` | CHANGED | 1004305 | 1004305 |
| `pakchunk20_s6-Windows.ucas` | CHANGED | 2473935408 | 2473935408 |
| `pakchunk20_s6-Windows.utoc` | CHANGED | 838135 | 838135 |
| `pakchunk20_s7-Windows.ucas` | CHANGED | 2758472192 | 2758472192 |
| `pakchunk20_s7-Windows.utoc` | CHANGED | 838590 | 838590 |
| `pakchunk20_s8-Windows.ucas` | CHANGED | 2033965920 | 2033965920 |
| `pakchunk20_s8-Windows.utoc` | CHANGED | 840881 | 840881 |
| `pakchunk20_s9-Windows.ucas` | CHANGED | 1947081248 | 1947081264 |
| `pakchunk20_s9-Windows.utoc` | CHANGED | 686346 | 686346 |
| `pakchunk51-Windows.ucas` | CHANGED | 96237920 | 96237920 |
| `pakchunk51-Windows.utoc` | CHANGED | 32574 | 32574 |

## Asset churn (filelist)

Entries: 76309 -> 76310. **109 added, 108 removed.**

Full lists: `filelist-added.txt` / `filelist-removed.txt`

### Added, grouped by directory

| Count | Directory |
|---|---|
| 59 | `ForeverWinter/Content/FW/` |
| 50 | `ForeverWinter/Content/LevelDesign/` |

### Removed, grouped by directory

**Removals are the dangerous ones for Class A** -- a removed path means any mod
overlaying it now overlays nothing, silently.

| Count | Directory |
|---|---|
| 58 | `ForeverWinter/Content/FW/` |
| 50 | `ForeverWinter/Content/LevelDesign/` |

## DataTable catalog

A changed `RowStruct` is a direct pointer at a Class A mod that is now writing into the
wrong shape. A changed row count means content moved under a mod that indexes into it.

Catalog build stamp: `24501089` -> `24501089`. Table count: 32 -> 32.

No table added, removed, restructured, or resized.

Caveat worth stating plainly: this compares **schema and row counts only**. A weapons
tuning pass that rewrites values in place changes neither. Do not read this as
'weapon data unchanged' -- that requires diffing the decoded dumps themselves.

## MO2 deployment

Load order and enabled/disabled state are unchanged, as expected -- the MO2 mod store
lives outside the game directory and Steam does not touch it.

## What to do next

1. Record the new depot manifest in `state/build-history.md` (rollback key for the next patch).
2. Gate 1a -- re-run AESDumpster against the new shipping exe if it changed.
3. Gate 1b -- decode a known asset and eyeball the values before trusting anything here.
4. Intersect `filelist-added.txt` / `filelist-removed.txt` against `state/asset-dependencies.md`
   to get the per-mod hit list, then work `state/status.md` in gate order.

## Warnings

- Catalog build stamp did not change -- the post-patch catalog may be stale (re-decode with --force, then rebuild).

