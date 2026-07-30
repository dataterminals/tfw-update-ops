# Stage 2 findings — 24097213 -> 24479102

Derived from [`diffs/pre-24479102__vs__post-24479102/REPORT.md`](diffs/pre-24479102__vs__post-24479102/REPORT.md)
plus the rename analysis below. Written 2026-07-30, ~25 minutes after the patch landed.

**Headline: the weapons data architecture was restructured, not just retuned.
`HeavyRifleRebalanceFix` is almost certainly dead, and the datamine's weapon dumps are invalid.**

---

## Gate 1a — AES key: CLEARED

The decoder mounted **76,309 files** from the new paks using the key hardcoded at
`decoder/Program.cs:28`. The IoStore index is AES-encrypted, so a successful mount *is* the test:
**the key did not rotate.** No AESDumpster run needed.

Note this does **not** clear Gate 1b. `list` needs the key, not the `.usmap` — property decoding
is untested until something is actually dumped.

## Gate 1b — usmap: CLEARED

Dumped all 43 `AIDEF_Sensor_*` assets against the existing
`ForeverWinter-5.4.2.usmap`: **43 ok, 0 fail**, and — the part that actually proves it —
**28 of the 43 are byte-identical to the committed pre-patch dumps**, with the other 15
differing *coherently* rather than randomly.

That distinction is the whole test. A stale usmap does not fail loudly; it yields plausible
garbage. Twenty-eight exact matches plus fifteen semantically meaningful, internally consistent
changes is not what a broken type layout produces. **The usmap survived; do not regenerate it.**

### Free intel from the Gate 1b probe

All 15 differing files are `AIDEF_Sensor_Vision_*`, and every one gained exactly the same new
entry — one new gameplay tag, nothing removed:

```
Pawn.Player.HoldingPistol   AccumulationMultiplier 1.2   DecayMultiplier 0.8
```

Per `tools/parse_detection.py:87`, the multiplier applies to accumulation **time**, so
`>1 = stealthier` and `decay <1 = stealthier`. Holding a pistol therefore makes you **~20%
slower to be detected and your accumulated awareness fade ~20% faster**, across all 15 enemy
vision profiles.

That is the datamined confirmation of the patch note "smaller firearms draw less agro than
bigger ones; agro accrued with these smaller weapons disperses more quickly" — and it is a
**publishable almanac Detection-tab update** that costs nothing extra to ship.

Worth stating: read the multiplier direction off the parser, not off intuition. The naive
reading of "accumulation 1.2" is *faster* detection, which is backwards.

## The raw churn, and why the headline number is misleading

The report says 1,013 added / 1,293 removed. Most of that is noise:

| Category | Count | Meaning |
|---|---|---|
| **Case-only renames** | 924 | Same path ignoring case. `BagMan` -> `BAGMAN`, `Exo` -> `EXO`, `GunUP` -> `GunUp`, `Submixes` -> `SubMixes`, `OldMan` -> `Oldman` |
| **Real removals** | 369 | Asset genuinely gone. **358 of them under `FW/Weapons/`** |
| **Real additions** | 89 | 64 under `FW/Weapons/`, 23 new HMG art assets |

Split lists are written alongside the report as `filelist-case-only-renames.txt`,
`filelist-real-removed.txt`, and `filelist-real-added.txt`.

### The case renames are probably harmless — but verify

UE5 computes `FPackageId` by lowercasing the package name before hashing it, so a case-only
rename produces the **same package ID and the same IoStore chunk ID**. A pak mod overlaying
`.../BagMan/MI_SCV_BGM_head` should still resolve against `.../BAGMAN/...`.

**Confidence: high, but not verified.** This is worth a deliberate check at smoke test because
120 of the renamed paths are under `Character/Scavengers/` — skin-mod territory. Deployed skins
(Slade, Luca, Kane) show **zero** renamed paths and Bunco-chan shows one, so exposure looks
small either way.

## What actually happened to weapons

The player/AI weapon split is the whole story:

```
DA_WPN_HRF01_v2   ->   DA_WPN_PLAYER_HRF01   +   DA_WPN_AI_HRF01a / b / c
DA_WPN_CRW01      ->   DA_WPN_PLAYER_CRW01
```

The `_v2` suffix is dropped and each weapon is now split into a **PLAYER** and one or more **AI**
data assets. This matches the patch notes exactly: the overhaul was scoped to "player handheld
weaponry," and they gave player weapons their own namespace to do it.

Deleted outright, by family:

| Family | Count | What it was |
|---|---|---|
| `FC_*` | 216 | Per-weapon float curves -- the entire `*_UpgradeTuning/` tree (recoil clamps, spray patterns, settle, weight-movement, damage) |
| `DA_*` | 108 | Per-weapon data assets under the old `_v2` naming |
| `VC_*` | 27 | |
| `BP_* / BPC_*` | 5 | Includes `BPC_PlayerWeaponADSAccuracy`, `BPC_SustainedFire` |

Also gone, and telling: `FC_MovementBloom`, `FC_SustainedFire`, and the gameplay effects
`GE_ADSAccuracy_LongArm`, `GE_ADSAccuracy_Pistol`, `GE_ADSAccuracy_Shotgun`, `GE_SustainedFire_01`.
The old accuracy/bloom system was removed as a unit, not adjusted.

**The per-weapon curve tree is not renamed. It is deleted.** Any mod whose technique was "edit
this weapon's tuning curves" has lost the thing it edits.

## Named-asset probe

| Asset | Before | After | Verdict |
|---|---|---|---|
| `DA_WPN_RFL01_v2` | 4 | 0 | **GONE** -- datamine's primary weapon dump source |
| `FC_RFL00_Stability` | 3 | 0 | **GONE** -- backs the almanac's Stability analysis |
| `FC_HRF*` | 6 | 0 | **GONE** |
| `DA_WPN_HRF*` | 11 | 2 | Restructured to `DA_WPN_PLAYER_HRF01..05` |
| `WeaponPartStatsData` | 1 | 1 | Survives |
| `WeaponsDetailsData` | 1 | 1 | Survives |
| `ItemDetailsData` | 2 | 2 | Survives |

The **DataTables survived**; the **per-weapon DataAssets and curves did not**. That distinction
routes the triage: mods keyed on DataTables are probably fine, mods keyed on per-weapon assets
are not.

## Routing

| Repo | Verdict | Why |
|---|---|---|
| `HeavyRifleRebalanceFix` | **Dead — rebuild** | Every overlay target (`DA_WPN_HRF*_v2`, `FC_HRF*`, the HRF upgrade-tuning tree) is renamed or deleted. Fails **silently**. Worse than a rebuild: the curve-based technique itself may no longer exist, so this needs a design decision before a build. |
| `forever-winter-datamine` | **Dumps invalid** | `DA_WPN_RFL01_v2` and `FC_RFL00_Stability` no longer exist. Weapon dumps describe a deleted system. Re-decode against the new `DA_WPN_PLAYER_*` layout; `assets.py` logical names need updating. |
| `forever-winter-almanac` | **Rework, not restamp** | The published Stability analysis (dispersion curves, Stability 0->1 numbers) documents a system that is gone. Restamping it to `24479102` would make it *confidently wrong*. Gunsmith section likewise. |
| `AllWeaponsUnlockableFix` | **Probably OK — verify** | Its DataTable targets survived. Confirm exact targets before clearing. |
| `UnkillablesRebalanceFix` | **Unresolved** | No boss BPs in the real-removal list, but BP *contents* can change without the path moving, and this mod silently reverts upstream BP edits. Needs a dump diff, not a path diff. |
| Skins + `TFWCharModelSelFramework` | **Probably OK — verify** | Only case-only renames touch their territory. See the caveat above. |
| Class B (all) | **Blocked on Gate 3** | Exe changed (+70,144 B on 169 MB, 0.04%) -- a code patch, not an engine bump. Signatures still need re-verification. |

## What the diff could NOT tell us

Stated plainly so nobody over-reads a clean row:

1. **Value changes are invisible.** The catalog diff compares RowStruct and row count only. The
   patch notes promise a DPM tuning pass on every weapon; `WeaponPartStatsData` kept its 633 rows
   and its struct, and that tells us **nothing** about whether the numbers inside changed. They
   almost certainly did.
2. **The post-patch catalog is stale.** The diff warned about this correctly -- `tables.json` still
   stamps `24097213` because it was built from committed dumps, not a re-decode. Force-decode
   before trusting any catalog comparison.
3. **BP graph contents are invisible.** Relevant to `UnkillablesRebalanceFix` specifically.
