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

## Gate 1b — RESOLVED (usmap regenerated 2026-07-30 18:15)

Regenerated via the built-in UE4SS `DumpUSMAP` keybind (Ctrl+Numpad6, already bound in the
`Keybinds` mod — no custom Lua mod was needed, contrary to the datamine README procedure).
New map is `ForeverWinter-5.4.2-24479102.usmap`, 2,154,699 B (old: 2,152,882 B, delta +1,817).
Old map archived to `mappings/archive/` and still reachable via the `baseline-24097213` tag.

Re-decoding `DA_WPN_PLAYER_HRF01` with it fixes everything:

| Property | Stale usmap | Regenerated | Old build |
|---|---|---|---|
| `ADSMovementSpeed` | `1.14637E-40` | `250.0` | `250.0` |
| `OTAMovementSpeed` | `5.3264E-34` | `250.0` | `250.0` |
| `MaxAimLagYaw` | `Y: 1.1709359E+17` | `{-75.0, 75.0}` | — |
| `AimLagSpringStiffness` | `0.5` | `2000.0` | `2000.0` |
| `AimLagSpringMass` | `2000.0` | `55.0` | `55.0` |
| `NumberOfBurstShots` | `16288` | *(not a real property)* | — |
| `NumberOfBuckshots` | *(absent)* | `1` | `1` |

The full `CharacterWeaponAnimationSets` block also returns — six pawn entries (Girl, Gunhead,
OldMan, Shaman, BagMan, MaskMan) with complete montage/anim-layer references. That is what the
missing 20 KB was.

### The HeavyRifle question — ANSWERED: needs a redesign, not a rebase

An earlier draft of this section guessed "rebuildable, provided it edited the weapon DataAsset."
Checking the repo settled it, and the answer is the unfavourable branch of that conditional.

`tools/build_fix.sh` names the 152 pak's override set exactly. **11 of its 13 targets are gone:**

| Target | Fate |
|---|---|
| `DA_WPN_HRF01..05_v2`, `DA_WPN_RFL29_v2` | **GONE** — renamed to `DA_WPN_PLAYER_*` (rebasable) |
| `FC_HRF01..04_Damage`, `FC_RFL29_Damage` | **GONE — deleted, not renamed** |
| `DT_CaliberToHeadshotMulti`, `MI_WPN_HRF03_UPP_01_RTC` | Survive |

And the curve layer is gone **game-wide**, not relocated:

- `FC_*_Damage` curves: **44 → 0**. Not one survives anywhere in the build.
- Float curves under `FW/Weapons/`: **226 → 11** (~95% removed).

This matters because of what the mod's own `docs/diagnosis.md:11` establishes: *"a heavy rifle's
real per-shot damage comes from its `FC_*_Damage` **curve**, not the DA `WeaponDamage` scalar
(vanilla `FC_HRF01` ramps 300→500 → the mod flattens it to 780 = the actual damage; the DA's 730
is cosmetic)."* That was hard-won knowledge — v1.1 exists specifically because the Vykhlop didn't
change until a flattened `FC_RFL29_Damage` was added.

**So the mod's primary damage mechanism no longer has anything to act on.** Rebasing the DataAsset
overrides onto the new `DA_WPN_PLAYER_*` names is mechanical, but on its own it would produce a mod
that changes only the value the mod's own docs call *cosmetic* — i.e. it would look rebuilt and do
nothing. That is the silent-failure trap again, one layer up.

**The likely new design, stated as a hypothesis to test, not a conclusion:** with the curve layer
deleted, `WeaponDamage` in `DA_WPN_PLAYER_HRF01` (now `270.0`) is probably authoritative — the devs
appear to have replaced per-weapon damage curves with a scalar plus the reworked mod/customization
system. If so the rebuild is *simpler* than the original technique. **Verify before building:**
change `WeaponDamage` on one weapon, confirm in-game damage actually moves. Do not assume.

### Real HRF01 changes (now trustworthy)

| Property | Old | New |
|---|---|---|
| `WeaponDamage` | 300.0 | **270.0** (-10%) |
| `DistanceToSphere` | 200.0 | **1000.0** (5x) |
| `ScaleADSCameraBlendSpeed` | *(absent)* | **1.25** |
| `ScaleADSExitCameraBlendSpeed` | *(absent)* | **1.125** |

The two new properties are the patch note "each weapon now has its own appropriate enter / exit
ADS speed", visible directly in the data. Dispersion values are **unchanged** (`3.0` / `0.333333`
/ `0.175`) — the accuracy rework happened elsewhere, not in the base weapon stats.

---

## How the staleness was found (kept for doctrine)

**Correcting an earlier call in this same document.** Gate 1b was marked cleared on the strength
of the AI-sensor probe below. That evidence was real but the conclusion was over-generalised: a
`.usmap` is a **per-struct** type map, so "it decoded one family correctly" says nothing about a
family the patch actually restructured.

Decoding `DA_WPN_PLAYER_HRF01` exposed it. The struct type name is unchanged
(`FWWeaponDefinition`), it reports 57 properties, and the leading properties are perfect —
`MaxDispersionRate 3.0`, `DispersionCoolDownStart 0.333333`, `DispersionCoolDownRate 0.175`,
matching the documented pre-patch values exactly. Then it derails:

```
NumberOfBurstShots   16288           <- a 16,288-round burst
ADSMovementSpeed     1.14637E-40     <- denormalized float
OTAMovementSpeed     5.3264E-34      <- denormalized float
MaxAimLagYaw.Y       1.1709359E+17
```

Comparing shared properties against the committed `DA_WPN_HRF01_v2.json` proves what happened —
**the same distinctive values are present, bound to the wrong names:**

| Old property | Value | New property now holding it |
|---|---|---|
| `AimLagSpringStiffness` | 2000.0 | `AimLagSpringMass` |
| `AimLagSpringDamping` | 0.85 | `AimLagTurnSpeedContributionScalar` |
| `AimLagSpringMass` | 55.0 | `AimLagIdleScale` |
| `AimLagTurnSpeedContributionScalar` | 0.5 | `AimLagIdleStabilizeADSTime` |

A spring with stiffness `0.5` and mass `2000.0` is physically absurd; stiffness `2000.0` with
mass `55.0` is sensible. The **old** labelling is the correct one, so it is the new decode that
is shifted — UE5 unversioned properties are positional, the real struct's property order changed,
and the stale usmap maps the byte stream onto stale names.

**Consequences, and they are serious:**

1. **Every weapon value decoded with the current usmap is untrustworthy** — including the
   `WeaponDamage 300 -> 270` "change" reported earlier in this document. That may be a real
   nerf or may be a shift artifact; it cannot be distinguished until the usmap is regenerated.
2. **The added/removed property lists are also artifacts.** `bUseSpreadShot`, `NumberOfBurstShots`
   et al. are the stale map's guesses, not evidence about the real struct.
3. This is precisely the failure mode the exposure model warns about — *"garbage that still
   parses"*. It does not error. It produces confident, plausible, wrong numbers, which is exactly
   what would have been published to the almanac.

**Required before any weapons work:** regenerate the usmap with the experimental UE4SS
`DumpUSMAP()` (datamine README procedure), then re-decode. This is now unblocked — Gate 3 proved
UE4SS attaches to the patched exe. Remember UE4SS emits usmap **v4**, needing CUE4Parse
`1.2.2.202607`, already pinned.

**What is still safe:** structs the patch did not touch. The AI-sensor evidence below stands on
its own — those 28 byte-identical dumps are genuinely valid, and the pistol-stealth finding is
real. Treat per-family validity as something to be demonstrated, not assumed.

## The AI-sensor probe (valid, and the basis of the original 1b call)

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

## Stage 2 complete — re-decode done, and it changed the answer

The catalog is now genuinely rebuilt from freshly decoded data (build stamp `24097213` →
`24479102`, and this time the *data* moved with the stamp).

### The `--force` → `build all` workflow has a gap

`fwdata get <asset> --force` re-decodes into the **build-namespaced cache**
(`decoder/out/cache/24479102/dump/…`). `fwdata build all` globs **`datamine/dumps/`**. Nothing
promotes cache → dumps, so running the documented sequence back-to-back produces a catalog stamped
with the new build and populated from the old dumps — exactly the failure the datamine README
warns about, reached by following the README's own remedy.

Fixed here by promoting explicitly before rebuilding. **Worth a `fwdata` change** so the documented
workflow is correct on its own rather than depending on someone knowing this.

Promotion was not a blind copy:
- **weapons** — deleted 14 dumps of now-nonexistent assets (`DA_WPN_HRF01–05_v2`, `DA_WPN_RFL01_v2`
  + 3 variants, `DA_WPN_RFL29_v2`, 3× `FC_RFL00_Stability*`, `DA_WPN_RFL01_BaseTuning_..._Curves`),
  promoted 74 fresh → **75 files**.
- **items / ui_widgets** — straight promote (15 / 9).
- **lootobjects** — refreshed only the **151 tracked** names; skipped 282 untracked. That subdir is a
  deliberate 151-of-437 curation ("only the ones with loot wiring"), and a blind copy would have
  silently tripled it with textures and widgets.

### Real DataTable changes — invisible until now

The earlier catalog diff reported "no table changes." That was wrong, and wrong for an instructive
reason: **both sides were derived from the same stale dumps**, so it was comparing old data to old
data. With a real re-decode:

| Table | Before | After |
|---|---|---|
| `WeaponsDetailsData` | 56 rows | **53** |
| `DT_TagToRowHandle` | 1176 rows | **1173** |

Both lost the same three, and they are named: **`RFL01_Red`, `RFL01_Blue`, `RFL01_Green`** — the
RFL01 colour variants, matching the deleted `DA_WPN_RFL01_v2_VariantA/B/C` assets exactly. Those
weapons were cut from the game.

**Check `AllWeaponsUnlockableFix` for references to those three rows** — its targets all survive,
but a reference to a removed row is a different failure than a missing asset.

`items.json` holds at 792 rows, so the item economy is untouched.

### Still outstanding: dumps outside the taxonomy

`fwdata`'s taxonomy covers 10 logical assets, but `datamine/dumps/` has **13 subdirs**. The nine not
covered — `ai_noise`, `ai_sensors`, `bosses`, `containers`, `crafting`, `enemies`, `factions`,
`hunterkillers`, `loot` — were **not** re-decoded here. Every asset they reference still exists
(verified: 0 stale across all of them), and the AI-sensor family is known-good from the Gate 1b
probe, so they are not suspect. But they were decoded under the old usmap and have not been
re-verified value-by-value. **Adding taxonomy entries for them is the natural next cleanup.**

## Class A sweep — every other mod's targets survive

Same method as the HeavyRifle check: read each mod's build script for its exact override set, then
probe those identifiers against both filelists. **HeavyRifle is the only casualty.**

| Repo | Targets checked | Result |
|---|---|---|
| `UnkillablesRebalanceFix` | 6 boss BPs + `AIDEF_Euruska_Stalker` ×4 + `BPC_IncomingDamageMod` | **8/8 survive**, identical counts |
| `AllWeaponsUnlockableFix` | 6 × `EarlyAccess_*_Root` skill trees | **6/6 survive** |
| `TFWCharModelSelFramework` | `DT_SkinUIData`, `ST_FW_UI_Skins`, `GA_Player_ChangeSkin`, `SK_SCV_FL`, `BP_Player_*` | **5/5 survive** |
| `TFWQuestGiverPortraitPatch` | `FW/UI/MainMenu/Textures/Quest` | **122 textures, count unchanged** |

Caveat that keeps all four at 🟨 rather than 🟩: a surviving *path* is not a surviving *asset*.
Blueprint graph contents and DataTable values change without the path moving, and
`UnkillablesRebalanceFix` in particular silently reverts upstream BP edits. Clearing these needs a
content diff, not a path diff.

## A stable usmap filename is load-bearing

The regenerated map was briefly installed as `ForeverWinter-5.4.2-24479102.usmap`. That broke
**nine build scripts** across four repos which hardcode `ForeverWinter-5.4.2.usmap`
(`AllWeaponsUnlockableFix` ×2, `ScavgirlCarryPerks` ×6, `TFWQuestGiverPortraitPatch` ×1), plus
several READMEs.

Resolved by inverting the convention: **the live map keeps the stable name**, and *archived* maps
carry the build stamp (`mappings/archive/ForeverWinter-5.4.2-build24097213.usmap`). Provenance
lives in the archive filename and git history instead of in the active path. Verified after the
rename — decoder resolves one map and `DA_WPN_PLAYER_HRF01` still decodes clean
(`ADSMovementSpeed 250.0`, `AimLagSpringStiffness 2000.0`).

Worth remembering next patch: renaming the active usmap is a breaking change to every downstream
build script, not a bookkeeping detail.

## Routing

| Repo | Verdict | Why |
|---|---|---|
| `HeavyRifleRebalanceFix` | **Dead — blocked on usmap** | Every overlay target (`DA_WPN_HRF*_v2`, `FC_HRF*`, the HRF upgrade-tuning tree) is renamed or deleted. Fails **silently**. The successor asset `DA_WPN_PLAYER_HRF01` exists and is far smaller (2.9 KB vs 22.7 KB), but **its contents cannot be read correctly until the usmap is regenerated** — so the design question "does an equivalent tuning lever still exist?" is currently unanswerable. Do not attempt a rebuild first. |
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
