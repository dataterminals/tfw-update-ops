# Baseline diff: pre-24479102 -> post-24479102

Generated: 2026-07-30 17:36:23 -04:00

The Stage 2 intelligence product. Cross-reference the asset churn below against
`state/asset-dependencies.md` to route at the mods that actually care.

## Build identity

| Field | pre-24479102 | post-24479102 |
|---|---|---|
| Build ID | `24097213` | `24479102` |
| Depot manifest (rollback key) | `7600230730618885177` | `6430523508700280691` |
| Size on disk | 50779543727 | 50815237941 |

**Record `6430523508700280691` in `state/build-history.md` -- it is the rollback key for the NEXT patch.**

## Shipping binaries

Drives expectations for Signature Bypass and RE-UE4SS. A changed shipping exe is normal
and expected; it does not by itself mean UE4SS is dead, but it does mean signatures must
be re-verified before trusting Class B.

1 binary file(s) changed. Full detail: `binaries-changed.csv`

| Binary | State | Bytes before | Bytes after |
|---|---|---|---|
| `ForeverWinter-Win64-Shipping.exe` | CHANGED | 169513984 | 169584128 |

**Shipping exe CHANGED** (169513984 -> 169584128 bytes). Re-run AESDumpster against it (Gate 1a)
and expect to re-verify Signature Bypass + RE-UE4SS (Gates 3 / 3b).

## Pak churn

Pak count: 118 -> 119. Total bytes: 48540247963 -> 48575871521 (delta 35623558).

39 pak file(s) changed. Full detail: `paks-changed.csv`

| Pak | State | Bytes before | Bytes after |
|---|---|---|---|
| `FWPakManifest.json` | ADDED |  | 19502 |
| `global.ucas` | CHANGED | 3012304 | 3014224 |
| `global.utoc` | CHANGED | 1615 | 1615 |
| `pakchunk0_s1-Windows.ucas` | CHANGED | 1769239392 | 1763995056 |
| `pakchunk0_s1-Windows.utoc` | CHANGED | 1293135 | 1286347 |
| `pakchunk0-Windows.pak` | CHANGED | 56211535 | 56211535 |
| `pakchunk0-Windows.sig` | CHANGED | 3960 | 3960 |
| `pakchunk0-Windows.ucas` | CHANGED | 2425709264 | 2425709264 |
| `pakchunk0-Windows.utoc` | CHANGED | 2168190 | 2168023 |
| `pakchunk20_s10-Windows.ucas` | CHANGED | 3144197456 | 3144197440 |
| `pakchunk20_s10-Windows.utoc` | CHANGED | 992196 | 992196 |
| `pakchunk20_s11-Windows.ucas` | CHANGED | 1567297408 | 1567297376 |
| `pakchunk20_s11-Windows.utoc` | CHANGED | 867326 | 867326 |
| `pakchunk20_s12-Windows.ucas` | CHANGED | 2274740480 | 2274727680 |
| `pakchunk20_s12-Windows.utoc` | CHANGED | 1246955 | 1204733 |
| `pakchunk20_s13-Windows.ucas` | CHANGED | 2627875712 | 2627875712 |
| `pakchunk20_s13-Windows.utoc` | CHANGED | 925230 | 925230 |
| `pakchunk20_s15-Windows.ucas` | CHANGED | 3219203888 | 3219203904 |
| `pakchunk20_s15-Windows.utoc` | CHANGED | 1037778 | 1037885 |
| `pakchunk20_s16-Windows.ucas` | CHANGED | 1943098096 | 1950437808 |
| `pakchunk20_s16-Windows.utoc` | CHANGED | 1226083 | 1221572 |
| `pakchunk20_s17-Windows.ucas` | CHANGED | 1327122144 | 1360677424 |
| `pakchunk20_s17-Windows.utoc` | CHANGED | 722548 | 741217 |
| `pakchunk20_s1-Windows.ucas` | CHANGED | 3064565136 | 3064565136 |
| `pakchunk20_s1-Windows.utoc` | CHANGED | 1004305 | 1004305 |
| `pakchunk20_s2-Windows.ucas` | CHANGED | 3007291760 | 3007291616 |
| `pakchunk20_s2-Windows.utoc` | CHANGED | 1186741 | 1186328 |
| `pakchunk20_s5-Windows.ucas` | CHANGED | 2916882608 | 2916882560 |
| `pakchunk20_s5-Windows.utoc` | CHANGED | 2276113 | 2275990 |
| `pakchunk20_s6-Windows.ucas` | CHANGED | 2473935408 | 2473935408 |
| `pakchunk20_s6-Windows.utoc` | CHANGED | 838135 | 838135 |
| `pakchunk20_s7-Windows.ucas` | CHANGED | 2758472192 | 2758472192 |
| `pakchunk20_s7-Windows.utoc` | CHANGED | 838590 | 838590 |
| `pakchunk20_s8-Windows.ucas` | CHANGED | 2033965984 | 2033965920 |
| `pakchunk20_s8-Windows.utoc` | CHANGED | 840881 | 840881 |
| `pakchunk20_s9-Windows.ucas` | CHANGED | 1947081248 | 1947081264 |
| `pakchunk20_s9-Windows.utoc` | CHANGED | 686346 | 686346 |
| `pakchunk20-Windows.ucas` | CHANGED | 2455359392 | 2455359392 |
| `pakchunk20-Windows.utoc` | CHANGED | 1314463 | 1314463 |

## Asset churn (filelist)

Entries: 76589 -> 76309. **1013 added, 1293 removed.**

Full lists: `filelist-added.txt` / `filelist-removed.txt`

### Added, grouped by directory

| Count | Directory |
|---|---|
| 311 | `ForeverWinter/Content/Animations/` |
| 211 | `ForeverWinter/Content/Audio/` |
| 151 | `ForeverWinter/Content/FW/` |
| 120 | `ForeverWinter/Content/Character/` |
| 81 | `ForeverWinter/Content/BOT_Robots/` |
| 61 | `ForeverWinter/Content/WPN_Weapons/` |
| 42 | `ForeverWinter/Content/LevelDesign/` |
| 24 | `ForeverWinter/Content/Developers/` |
| 5 | `Engine/Content/EngineSounds/` |
| 3 | `ForeverWinter/Content/Weapons/` |
| 3 | `ForeverWinter/Content/Movies/` |
| 1 | `ForeverWinter/Content/AssetPacksStore/` |

### Removed, grouped by directory

**Removals are the dangerous ones for Class A** -- a removed path means any mod
overlaying it now overlays nothing, silently.

| Count | Directory |
|---|---|
| 448 | `ForeverWinter/Content/FW/` |
| 311 | `ForeverWinter/Content/Animations/` |
| 211 | `ForeverWinter/Content/Audio/` |
| 120 | `ForeverWinter/Content/Character/` |
| 82 | `ForeverWinter/Content/BOT_Robots/` |
| 42 | `ForeverWinter/Content/LevelDesign/` |
| 38 | `ForeverWinter/Content/WPN_Weapons/` |
| 24 | `ForeverWinter/Content/Developers/` |
| 5 | `Engine/Content/EngineSounds/` |
| 3 | `ForeverWinter/Content/Movies/` |
| 3 | `ForeverWinter/Content/ArtAssets/` |
| 3 | `ForeverWinter/Content/Weapons/` |
| 2 | `ForeverWinter/Content/AssetPacksStore/` |
| 1 | `ForeverWinter/Content/UI/` |

## DataTable catalog

A changed `RowStruct` is a direct pointer at a Class A mod that is now writing into the
wrong shape. A changed row count means content moved under a mod that indexes into it.

Catalog build stamp: `24097213` -> `24097213`. Table count: 32 -> 32.

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

