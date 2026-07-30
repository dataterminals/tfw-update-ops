# Asset dependency map - Class A/B routing table

**What this is.** A reverse index from *game asset* to *our mods*. Given a path out of a filelist
diff, it answers "who cares?" in seconds, and says what kind of breakage to expect.

**Built against** the `pre-24479102` baseline (`state/baselines/pre-24479102/`, installed build
`24097213`, filelist 76,589 entries). Every path below was checked against that filelist by the
per-repo extraction pass. Line numbers cited as `filelist.txt:NNNNN` are pre-patch line numbers -
useful for locating a path, useless as identity after a re-decode.

**How to use it.**

- **Stage 2 (filelist diff).** Take `state/diffs/<before>__vs__<after>/filelist-added.txt` and
  `filelist-removed.txt`, run the [Grep these first](#grep-these-first) list against them, and any
  hit routes to the named repo. That intersection *is* the Stage 5 work list.
- **Stage 5 (Class A triage).** Open the per-repo section, confirm which of that mod's identifiers
  moved, and read the failure-mode note to decide *rebuild* vs *likely-clean*. Most of this class
  fails silently, so "the game launched" is not evidence.
- **Before anything else**, read [FROZEN CONTRACT identifiers](#frozen-contract-identifiers).
  Those break other people's mods, not just ours.

**What it deliberately does not cover.** Classes C, D and E have no per-asset dependency surface of
this kind. Coverage gaps and confidence caveats are recorded honestly in
[Coverage and confidence](#coverage-and-confidence) - read that before treating a clean intersection
as a clean bill of health.

---

## Grep these first

Deduped and flattened. Grouped by **what breaks if they move**, because the group determines the
fix procedure. Each line is a substring safe to grep against the new `filelist.txt` (or against the
added/removed diffs).

### Group 1 - Whole-asset overrides: the game's change gets silently deleted

We ship a complete copy of these. If the devs edit one and we do not rebuild, **our pak reverts
their edit for every user** and nothing anywhere reports it. A hit here means *rebuild*, not
*investigate*. This is the "staleness inversion" and it triggers even when the diff line looks
unrelated to what the mod does.

```
FW/Player/Data/DT_SkinUIData.uasset                     -> TFWCharModelSelFramework
FW/Player/Class/BP_Player_                              -> TFWCharModelSelFramework  (6 assets)
Blueprints/Data/WeaponsDetailsData.uasset               -> AllWeaponsUnlockableFix (whole table)
FW/Player/Skills/EarlyAccessTrees/                      -> AllWeaponsUnlockableFix (5 of 7)
EarlyAccessTrees/ScavGirl/SD_Skill_EarlyAccess_ScavGirl_ROOT  -> AllWeaponsUnlockableFix + ScavgirlCarryPerks (contested)
Euruska/MeatMan/BP_AI_Euruska_MeatMan.uasset            -> UnkillablesRebalanceFix
Euruska/OrgaMech/BP_AI_Euruska_OrgaMech.uasset          -> UnkillablesRebalanceFix
Euruska/ShieldOfficer/BP_AI_Euruska_ShieldOfficer.uasset-> UnkillablesRebalanceFix
Euruska/TOOTHY/BP_Mech_Toothy.uasset                    -> UnkillablesRebalanceFix  (dir is UPPERCASE)
Eurasia/MotherCourage/BP_AI_Eurasia_MotherCourage.uasset-> UnkillablesRebalanceFix
Eurasia/Opal/BP_AI_Eurasia_Opal.uasset                  -> UnkillablesRebalanceFix
FW/AI/Characters/Shared/BPC_IncomingDamageMod.uasset    -> UnkillablesRebalanceFix
```

### Group 2 - Override targets: mod detaches and goes inert, silently

Bound by `FPackageId` = CityHash64 of the lowercased package name. A rename or move means our pak
overlays nothing. Game looks normal, mod does nothing, no log line anywhere.

```
Euruska/Stalker/AIDEF_Euruska_Stalker                   -> UnkillablesRebalanceFix (4 variants)
HRF_HeavyRifles/HRF0[1-5]/DA_WPN_HRF0                   -> HeavyRifleRebalanceFix
RFL_Rifles/RFL29/DA_WPN_RFL29_v2.uasset                 -> HeavyRifleRebalanceFix
HRF0[1-4]_UpgradeTuning/FC_HRF0                         -> HeavyRifleRebalanceFix
RFL29_UpgradeTuning/FC_RFL29_Damage.uasset              -> HeavyRifleRebalanceFix (most fragile item we own)
Weapon_V2/DT_CaliberToHeadshotMulti.uasset              -> HeavyRifleRebalanceFix
MI_WPN_HRF03_UPP_01_RTC                                 -> HeavyRifleRebalanceFix
ATT_Attachments/PIC_Picatinny/SCP_Scopes/               -> HeavyRifleRebalanceFix (191 pak, 7 entries)
WPN_Weapons/RFL_Rifles/RFL29/SM_WPN_RFL29_              -> HeavyRifleRebalanceFix (191 pak)
WPN_Weapons/RFL_Rifles/RFL20/SM_WPN_RFL20_UPP_0         -> HeavyRifleRebalanceFix (191 pak)
Quest/T_QuestGiver_Kane_ButtonFramed                    -> TFWQuestGiverPortraitPatch
Quest/T_QuestGiver_Luca_ButtonFramed                    -> TFWQuestGiverPortraitPatch
Quest/T_QuestGiver_Slade_ButtonFramed                   -> TFWQuestGiverPortraitPatch
Scavengers/Shaman/SK_SCV_SHM                            -> forever-winter-skin-mods
Scavengers/Shaman/Skins/{Dogmask,DWK,DSQ,MAY}/SK_       -> forever-winter-skin-mods
Scavengers/Female/Skins/{SPT,DEC,DSQ,MAY}/SK_           -> forever-winter-skin-mods
```

### Group 3 - Referenced but not shipped: dangling import, null child, or hard crash

We name these inside a shipped package without owning them. A rename produces either a `null` in an
array (silent, mod half-works) or an `ObjectSerializationError` on load (loud crash - this is what
shipped to players once already, see `UnkillablesRebalanceFix/WORKLOG.md:113-129`).

```
ActiveCharacters/*/SkillData/*_ALLOWUSE                 -> AllWeaponsUnlockableFix + ScavgirlCarryPerks (11 in baseline)
GlobalSkills/Weapon_*_Expert/GE_Skill_Global_*_ALLOWUSE -> AllWeaponsUnlockableFix (5)
GlobalSkills/Rigs/GE_Skill_Global_RIG_                  -> ScavgirlCarryPerks
OldMan/SkillData/Rigs/SD_Skill_OldMan_RIG0              -> ScavgirlCarryPerks + AllWeaponsUnlockableFix
Shaman/SkillData/PackMule/SD_Skill_Shaman_PackMule_v    -> ScavgirlCarryPerks + AllWeaponsUnlockableFix
Bagman/SkillData/PackMule/GE_Skill_BagMan_PackMule_v    -> ScavgirlCarryPerks (unshipped closure build)
GlobalSkills/Stamina/{SD,GE}_Skill_Global_Stamina_Lvl_01-> TFWStaggerControl (clone templates, unbuilt half)
Animations/GenericHumanoid/*/Rifle/                     -> HeavyRifleRebalanceFix (98 montages in the DA import closure)
Animations/GenericBipedalMechanical/Grabber/            -> UnkillablesRebalanceFix (Stalker AIDEF imports)
FW/Player/AnimationLayers/                              -> HeavyRifleRebalanceFix (5 ABP layers)
Weapon_V2/HRF_HeavyRifles/GE_WPN_Passive_HRF            -> HeavyRifleRebalanceFix
Weapon_V2/RFL_Rifles/GE_WPN_Passive_RFL                 -> HeavyRifleRebalanceFix
```

### Group 4 - Runtime resolution: Class B, fails loudly in UE4SS.log

Never a crash. The mod logs a resolution failure and no-ops. One tester log answers the whole class.

```
Widgets/Inventory/W_LootUI.uasset                       -> TFWLootAll (critical)
Widgets/Inventory/W_LootItem.uasset                     -> TFWLootAll (critical)
Widgets/Inventory/W_Loot{InRange,FailReason}.uasset     -> TFWLootAll (cosmetic)
FW/UI/HUD/Quests/WBP_Quests.uasset                      -> TFWQuestHUDToggle (single point of failure)
FW/UI/HUD/WBP_ItemTooltips.uasset                       -> TFWQuestItemTag (critical)
FW/UI/HUD/WBP_BaseTooltip.uasset                        -> TFWQuestItemTag (holds the written TextBlock)
FW/UI/HUD/BPFL_Tooltips.uasset                          -> TFWQuestItemTag (fallback hook)
FW/Player/GameplayAbilities/GA_Player_HitReaction.uasset-> TFWStaggerControl (the whole mod)
FW/Player/BP_PlayerBase.uasset                          -> TFWStaggerControl (fails dangerously, not loudly)
MainMenu/UMG/Panels/WBP_SkinSelection.uasset            -> TFWCharModelSelFramework
MainMenu/UMG/Buttons/WBP_SkinButton.uasset              -> TFWCharModelSelFramework
MainMenu/UMG/Widgets/WBP_PlayerStatusWidget.uasset      -> TFWCharModelSelFramework
MainMenu/UMG/WBP_{MenuMaster,ReadyRoom}.uasset          -> TFWCharModelSelFramework
MainMenu/UMG/SkillTree/WBP_Skill{Panel,_Button}.uasset  -> ScavgirlCarryPerks (layout premise)
FW/LootObjects/Containers/General/BP_{Random,}LootContainer -> TFWLootAll (DISCOVER only)
FW/LootObjects/FromCorpses/BP_RandomLoot_{Corpse,Vehicle}   -> TFWLootAll (DISCOVER only)
```

### Group 5 - Build inputs: mod is unbuildable, or bakes wrong output

Not override targets. These feed a build step. Damage here surfaces at rebuild time (good) or as a
wrong-looking output (bad).

```
Widgets/UIMockup/images/VendorPortraits/REFRAMED/       -> TFWQuestGiverPortraitPatch (bake source, 3 of 18)
Female/Skins/OCT/SK_SCV_FL_OCT{,_Skeleton}.uasset       -> TFWCharModelSelFramework (mesh clone source)
T_Menu_PickCharacter_Portrait_{DLC04_Scavgirl,ScavGirl,LockedV2} -> TFWCharModelSelFramework (icon sources)
FW/UI/StringTables/ST_FW_UI_Skins.uasset                -> TFWCharModelSelFramework (stgen clone template)
Blueprints/Data/ItemDetailsData.uasset                  -> TFWQuestItemTag (manifest source) + HeavyRifleRebalanceFix
Blueprints/Data/Value/ValueV2_WEAPONS{,_PARTS}.uasset   -> HeavyRifleRebalanceFix + AllWeaponsUnlockableFix
FW/UI/Manufactoring/Data/DT_Manufactoring{Groups,Recipies} -> HeavyRifleRebalanceFix
FW/Weapons/Customizer/WeaponPartStatsData.uasset        -> HeavyRifleRebalanceFix
FW/Quests/DT_QuestGiverData.uasset                      -> TFWQuestGiverPortraitPatch (row must still point at our targets)
MainMenu/UMG/Buttons/WBP_QuestGiverButton.uasset        -> TFWQuestGiverPortraitPatch (2:1 brush premise)
GenericHumanoid/GenericHumanoid_Skeleton{,_MainCharacters} -> forever-winter-skin-mods (rename = T-pose, still "loads")
Character/Master_Materials/M_FW_Char.uasset             -> forever-winter-skin-mods
Audio/SFX/VO/OLMA/                                      -> forever-winter-skin-mods (4 subtrees, 2 casings)
```

### Group 6 - Must stay ABSENT

```
grep -c "^ForeverWinter/Content/CMSF/" filelist.txt    # pre-patch: 0. MUST STAY 0.
```

A non-zero count means the developers have collided with the CMSF framework's public namespace and
**every claimed third-party slot in the wild breaks at once**. See
[FROZEN CONTRACT identifiers](#frozen-contract-identifiers).

---

## Per-repo dependencies

`Baseline` column: `exact` = verbatim filelist match. `case` = differs only in directory-name case;
benign, because UE lowercases the package name before hashing `FPackageId` - **do not treat a
casing change as a break unless the lowercased path also changed**. `runtime` = never appears in a
filelist by construction (native class, UFunction, property, gameplay tag). `row` = DataTable row
key. `absent` = not in the baseline; see [Not found in baseline](#not-found-in-baseline).

### TFWCharModelSelFramework (Class A + B hybrid)

Rebuilds from the **live cook** every time, so it always overrides whatever the current game ships.
That is what makes Group 1 lethal here: a patch that adds a skin row and no rebuild means our pak
deletes the devs' new content for every CMSF user.

| Identifier | Kind | Baseline | Evidence |
|---|---|---|---|
| `FW/Player/Data/DT_SkinUIData.uasset` | datatable | exact | `tools/cmsf_framework.py:47` |
| `FW/Player/Class/BP_Player_{BagMan,Girl,Gunhead,MaskMan,OldMan,Shaman}.uasset` | blueprint | exact (6) | `tools/cmsf_framework.py:44,46,129`; `tools/cmsf_build.py:46-51` |
| `FW/UI/StringTables/ST_FW_UI_Skins.uasset` | uasset | exact | `tools/cmsf_framework.py:48` |
| `MainMenu/UMG/Panels/WBP_SkinSelection.uasset` (`WBP_SkinSelection_C`) | widget | exact | `runtime/CMSFUnlock/Scripts/main.lua:148,523` |
| `MainMenu/UMG/Buttons/WBP_SkinButton.uasset` | widget | exact | `main.lua:162,171,252` |
| `MainMenu/UMG/Widgets/WBP_PlayerStatusWidget.uasset` | widget | exact | `main.lua:62,120,494` |
| `MainMenu/UMG/WBP_MenuMaster.uasset`, `WBP_ReadyRoom.uasset` | widget | exact | `docs/09-stutter.md:150,213` |
| `FW/Player/GameplayAbilities/GA_Player_ChangeSkin.uasset` | blueprint | exact | `docs/00-findings.md:209` |
| `FW/Player/Data/DT_Entitlements.uasset`, `DT_EntitlementTags.uasset` | datatable | exact | `docs/00-findings.md:185-187` |
| `Female/Skins/OCT/SK_SCV_FL_OCT.uasset` + `_Skeleton.uasset` | mesh | exact | `skins/octogirl/skin.json:5`; `tools/mshgen/Program.cs:98-100` |
| `Female/SK_SCV_FL.uasset` | mesh | exact | `docs/00-findings.md:58,104` |
| `T_Menu_PickCharacter_Portrait_{DLC04_Scavgirl,ScavGirl,LockedV2}` | texture | exact (3) | `examples/example-skin/skin.json:7`; `tools/cmsf_build.py:106,157` |
| DT_SkinUIData row `ScavGirl0` (addst clone template) | row | **unverifiable** | `tools/skinpatch/Program.cs:331-345` - hard abort if missing |
| DT_SkinUIData row `Skin.Girl.MAY` (v0.1 add template) | row | **unverifiable** | `tools/skinpatch/Program.cs:235-237` - hard abort |
| `FWSkinChangeComponent` / `SkinChoices` / `LockedSkinChoices` | runtime | runtime | `skinpatch/Program.cs:117-132`; `docs/00-findings.md:91-99` |
| `SelectLockedSkinsOnly`, `Init()`, `SkinOptions`, `SkinRow.RowName` | runtime | runtime | `main.lua:434,461,422,299` |
| `SkinIcon.Brush.ResourceObject` -> `GetFullName()` | runtime | runtime | `main.lua:268-276` - **the entire claim signal** |
| `/Game/CMSF/**` (21 slot-path identifiers) | frozen | **absent by design** | see frozen section |

**Failure modes.** (1) Group 1 staleness inversion - rebuild unconditionally after every patch,
even if nothing skin-related is in the diff. (2) Runtime claim signal fails *open*: if `SkinIcon`,
`SkinRow`, `SkinOptions` or the brush chain is renamed, `deriveVerdict` returns nil and roughly 192
placeholder tiles appear rather than a crash. (3) `Init()` renamed = menu silently stops
repopulating. All pcall-wrapped; none logs a rename as an error. Fastest field check is the
`cmsfunlock` console line "selector lists N skin(s)" - vanilla unfiltered Scav Girl is 7,
framework-loaded is 39.

### UnkillablesRebalanceFix (Class A)

Two risk tiers that must be routed differently. Ships exactly 11 packages, verified from the `.utoc`
directory index.

**Option B - 7 packages, shipped bytes ARE the current base cook with scalars overwritten.** If the
patch touches any of these at all, the shipped copy is instantly a stale cook and reintroduces the
`ObjectSerializationError` that already shipped to players once. Highest-priority diff targets in
the whole collection.

| Identifier | Kind | Baseline | Evidence |
|---|---|---|---|
| `Euruska/MeatMan/BP_AI_Euruska_MeatMan` | blueprint | exact (`:49019`) | `tools/build_fix.sh:56`; `tools/patch_drifted.py:69` |
| `Euruska/OrgaMech/BP_AI_Euruska_OrgaMech` | blueprint | exact (`:49029`) | `build_fix.sh:56`; `patch_drifted.py:70` |
| `Euruska/ShieldOfficer/BP_AI_Euruska_ShieldOfficer` | blueprint | exact (`:49041`) | `build_fix.sh:57`; `patch_drifted.py:71` |
| `Euruska/TOOTHY/BP_Mech_Toothy` | blueprint | **case** (`:49103`) | `build_fix.sh:57` writes `Toothy/`; game is `TOOTHY/` |
| `Eurasia/MotherCourage/BP_AI_Eurasia_MotherCourage` | blueprint | exact (`:48864`) | `build_fix.sh:58`; `patch_drifted.py:74` |
| `Eurasia/Opal/BP_AI_Eurasia_Opal` | blueprint | exact (`:48877`) | `build_fix.sh:58`; `patch_drifted.py:75` |
| `Shared/BPC_IncomingDamageMod` | blueprint | exact (`:49270`) | `build_fix.sh:59`; `patch_drifted.py:76` |

**Option A - 4 Stalker DataAssets, shipped bytes frozen at the mod's 0.9.2.2 cook.**

| Identifier | Kind | Baseline | Evidence |
|---|---|---|---|
| `Euruska/Stalker/AIDEF_Euruska_Stalker` | uasset | exact (`:49068`) | `build_fix.sh:29,49` |
| `..._Stalker_HK` / `_Pregnant_Quest` / `_Underground` | uasset | exact (`:49065-67`) | `build_fix.sh:49-50` |
| Import closure: `AM_GRAB_Stun`, `AM_GRAB_Melee`, `LS_GRAB_SyncKill_Smash`, `BB_Stalker`, `BT_Patrol_Stalker`, `BT_Stalker_Main{,_Underground}`, `DD_AI_AbilitySet_Stalker`, `BPC_AI_HitReactManager`, `BPC_HighValueEnemyDamageMod`, `BP_AC_DropWeaponLogic`, `BP_AI_Euruska_Stalker{,_Pregnant_Quest,_Underground}` | uasset | exact (14) | import strings in `work/legacy-A/*.uasset` |
| `FWAIPawnDefinition` (`DamageToStagger`, `SyncKillMaxPlayerHealth`) | class | runtime | `work/decode-out-modclean/.../AIDEF_Euruska_Stalker.json:3-6` |

**Values, not paths.** The build is gated on scalar values and `patch_drifted.py` hard-aborts if
they move: exactly two `float32 1e9` per uexp in MeatMan/OrgaMech/ShieldOfficer/MotherCourage/Opal,
exactly two `9e8` in Toothy, and a 19-double sequence in `BPC_IncomingDamageMod.uexp` in exact
file-offset order. **A balance pass that retunes boss HP moves zero filelist lines and still breaks
the rebuild.** Routing this repo requires a re-decode of the 7 Option-B assets, not a path diff.
Note the patcher is not idempotent-safe: it writes each file as it goes, so an abort on the BPC step
leaves the 6 boss BPs already patched in the work tree.

**Cross-mod.** `BPC_IncomingDamageMod` is genuinely shared - its import table names the Stalker,
Opal, OrgaMech, ShieldOfficer, MeatMan, Toothy and their `_HK` variants, StiltWalker, RatKing,
MedMech, `GA_Stunned` and `BP_WPN_HRF05`. Any other repo overriding it collides at the same
`FPackageId`. `HeavyRifleRebalanceFix` is cleared for AI assets but does ship `BP_WPN_HRF05`.

### AllWeaponsUnlockableFix (Class A)

**Trees is the deployed variant** (`+AllWeaponsUnlockableTrees` / `-AllWeaponsUnlockableFix` in
`mo2-modlist.txt`). Route Trees first; Fix is a dormant second build in the same repo.

| Identifier | Kind | Baseline | Evidence |
|---|---|---|---|
| `Blueprints/Data/WeaponsDetailsData.uasset` (**whole-table override**) | datatable | exact | `tools/build_trees.sh:44`; `tools/build_fix.sh:46` |
| `EarlyAccessTrees/{Bagman,MaskMan,OldMan,ScavGirl,Shaman}/SD_Skill_EarlyAccess_*_Root` | uasset | exact (5) | `tools/trees_grafts.json:54-58` |
| `EarlyAccessTrees/GunHead/SD_Skill_EarlyAccess_Gunhead_Root` + `GA_Skill_...` | uasset | exact (2) | `build_fix.sh:30` - **Fix variant only** |
| Graft heads: `MaskMan_{GRL,HRF,LMG}_ALLOWUSE`, `BagMan_HMG_ALLOWUSE`, `Shaman_SMG_ALLOWUSE` | uasset | exact / case | `tools/trees_grafts.json:32-49` |
| `GE_Skill_Global_{GRL,HMG,HRF,LMG,SMG}_ALLOWUSE` | uasset | exact (5) | `docs/trees-notes.md:58`; `WORKLOG.md:294` |
| 25 inherited `ChildSkills` baked into the shipped roots | uasset | exact (25) | `work/decode-out/dump/base/SD_Skill_EarlyAccess_*.json` |
| 272 baked object refs inside the table override (56 weapon BPs, 56 DataAssets, 112 textures, 51 unlock tables, 2 value tables) | mixed | exact (272/272) | `work/decode-out/dump/base/WeaponsDetailsData.json` |
| `InventoryDangly` row struct; `AllowTags`, `RequiredGameplayTags` | runtime | runtime | `tools/tablepatch/Program.cs:24,39,61` |
| `Pawn.Player.*` (6) and `PlayerSkill.Global.*.AllowUse` (7) tags | tag | runtime | `tools/trees_allowtags.json`; `tools/verify_trees.py:181-184` |

**Failure modes.** A new weapon row in `WeaponsDetailsData` is **silently deleted** while the mod is
installed - the exact defect this repo exists to fix, and it returns the moment the table moves.
`tools/verify_trees.py` is hardcoded to the current shape and will hard-fail the build (line 158
asserts exactly 56 rows, 176 asserts 31 widened, 178 asserts AllowTags equality) - a loud failure,
which is the good case. **But its inputs are stale**: `verify_trees.py:23-25` reads
`work/decode-out/base-list/filelist.txt` and `work/decode-out/dump/base/*.json`, captured against
build `24097213`, and `build_trees.sh` does not regenerate them. Regenerate both before trusting a
post-patch verification, or the verifier passes while validating nothing. `work/` is gitignored, so
these exist only on this machine.

### HeavyRifleRebalanceFix (Class A + TFWWorkbench JSON)

Two paks plus five runtime DataTable JSON overlays. Only one shipped layout
(`dist/HeavyRifleRebalanceFix_Loosefiles/`), contrary to the usual both-layouts convention.

| Identifier | Kind | Baseline | Evidence |
|---|---|---|---|
| `HRF_HeavyRifles/HRF0{1..5}/DA_WPN_HRF0*_v2` | uasset | exact (5) | `tools/build_fix.sh:30,70-74` |
| `RFL_Rifles/RFL29/DA_WPN_RFL29_v2` | uasset | exact | `build_fix.sh:31,75` |
| `HRF0{1..4}_UpgradeTuning/FC_HRF0*_Damage` | uasset | exact (4) | `build_fix.sh:31,76-79` |
| `RFL29_UpgradeTuning/FC_RFL29_Damage` | uasset | exact | `build_fix.sh:49,94` - **most fragile item in the repo** |
| `Weapon_V2/DT_CaliberToHeadshotMulti` + `STRUCT_CaliberToHeadshotMulti` | datatable | exact (2) | `build_fix.sh:32,80` |
| `WPN_Weapons/HRF_HeavyRifles/HRF03/MI_WPN_HRF03_UPP_01_RTC` | material | exact | `build_fix.sh:32,81` |
| 18 x `191_HeavyRifleRebalance_P` override targets (scope meshes, RFL29/RFL20 parts, scope textures) | mesh/texture | exact (17) + 1 absent | `191_*.utoc` directory index |
| Import closure of the 6 DA assets: 98 anim montages/sequences, 5 ABP layers, 5 tuning-curve DAs, 2 `GE_WPN_Passive_*`, `M_WPN_MagnifiedScope_Master` | uasset | 82 exact + 43 case = 125/125 | import tables in `work/legacy-repath/` |
| Workbench targets: `ItemDetailsData`, `WeaponsDetailsData`, `WeaponPartStatsData`, `DT_ManufactoringGroups`, `DT_ManufactoringRecipies` | datatable | exact (5) | vendored `TFWWorkbench/Scripts/Settings.lua:10-19` |
| `BP_WPN_HRF05` (`BP_WPN_HRF05_C`) | blueprint | exact | `WeaponDetailsData.json:265` - **the historical crash asset**, check first |
| `Quest.HRF05.UnlockManufacture`, `Item.Ammo.{127,54R,50PST,50cal}`, `Scope.Weapon.*` | tag | runtime | `005_HeavyRifleRebalance_Recipe.json`; `docs/diagnosis.md:110` |

**Failure modes.** `FC_RFL29_Damage` is extracted from the current base and byte-patched, asserting
exactly one `float32 175.0` and one `350.0` in the uexp (`build_fix.sh:56-60`). A vanilla retune
aborts the rebuild loudly - but the **shipped** pak keeps silently applying 375 flat. Same exposure
for the other 12 packages: `build_fix.sh:27` re-extracts them from `dist/`, so `dist/` is
load-bearing *input*, not just output. Two struct-level risks are documented and unfixed and are
invisible to a filelist diff: `InventoryDangly` gained 8 fields the mod's JSON omits and Workbench's
Add path rewrites a fresh struct (harmless only while those 6 rows hold defaults), and Workbench
hardcodes `RecipyCraftTime` at `ManufactoringRecipies` struct offset `0x68` while the struct has
already gained `AccelerationTags`. Build prereq worth knowing: `build_fix.sh:25` points `RETOC` at
a **sibling repo's** checkout (`UnkillablesRebalanceFix/tools/retoc/retoc.exe`).

### ScavgirlCarryPerks (Class A x4 + Class B x1)

All five variants are **currently disabled** in MO2. Every pak overrides exactly one asset.

| Identifier | Kind | Baseline | Evidence |
|---|---|---|---|
| `EarlyAccessTrees/ScavGirl/SD_Skill_EarlyAccess_ScavGirl_ROOT` | uasset | exact (`:57167`) | `tools/build_root.sh:20-21` - **the only shipped override** |
| `OldMan/SkillData/Rigs/SD_Skill_OldMan_RIG03_AllowUse` | uasset | exact (`:57125`) | `build_root.sh:22`; `main.lua:29` |
| `OldMan/SkillData/Rigs/SD_Skill_OldMan_RIG04_AllowUse` | uasset | exact (`:57126`) | `main.lua:33`; `tools/build_unbfix.sh:36` |
| `Shaman/SkillData/PackMule/SD_Skill_Shaman_PackMule_v{1..4}` | uasset | exact (4) | `build_root.sh:23`; `tools/build_closure.sh:68-73` |
| `ScavGirl/SkillData/Rigs/SD_Skill_ScavGirl_RIG04_AllowUse` | uasset | exact (`:57130`) | `main.lua:24-25` - UE4SS live graft target |
| `Bagman/SkillData/PackMule/GE_Skill_BagMan_PackMule_v{1..4}` | uasset | **case** (`:56921-25`) | `build_closure.sh:42` hardcodes `BagMan/` |
| `GlobalSkills/Rigs/GE_Skill_Global_RIG_{PackMule,PackMuleGunRunner}_AllowUse` | uasset | exact | `docs/design-notes.md:12` (repo records a glob only) |
| `MainMenu/UMG/SkillTree/WBP_Skill{Panel,_Button}` | widget | exact | `docs/ue4ss-plan.md:19-21` |
| `Blueprints/Data/{BackpackRigDataV2,InventoryContainerData}` | datatable | exact | `WORKLOG.md:216-219` |
| `PlayerSkill.Global.Rig.*` tags; `FWPlayerAttributeSet_SkillTree` | tag/class | runtime | `docs/design-notes.md:7-12`; `docs/carry-capacity.md:20-28` |

**Failure modes.** All four paks ship a hand-edited copy of the pre-patch ROOT - Group 1. The
grafted nodes are referenced-only, so a rename gives a branch that just does not draw (Class A
silent). Worst case: a patch that de-globalises a rig tag leaves the branch rendering while granting
nothing. **Ordering dependency**: the two Combined variants extract their base ROOT from a mount of
base + `AllWeaponsUnlockableFix`, so AWU must be fixed first, then Combined rebuilt on top.
`tools/skillpatch` inserts `ChildSkills` at a **schema slot** (before `ValueOfXP`, else
`SkillEffects`); if the new usmap reorders `FWSkillDefinition`, `add` silently writes at the wrong
offset - this repo is hard-gated on the usmap, not just on AES. All five build scripts hardcode
`D:\` paths and will not run on this machine without edits.

### TFWQuestGiverPortraitPatch (Class A, texture rebake)

| Identifier | Kind | Baseline | Evidence |
|---|---|---|---|
| `Quest/T_QuestGiver_{Kane,Luca,Slade}_ButtonFramed` `.uasset`+`.ubulk` | texture | exact (`:58481-86`) | `tools/mapping.tsv:26-28` |
| `VendorPortraits/REFRAMED/{Eurasia,Europa}_Quest_Giver_REFRAMED_samesized`, `Vendor_01_b_REFRAMED_samesized` | texture | exact (3) | `tools/mapping.tsv:26-28` col 3 - bake sources |
| `FW/Quests/DT_QuestGiverData.uasset` + rows Kane/Luca/Slade -> `QuestGiverImage` | datatable | exact / **rows unverifiable** | `docs/diagnosis.md:8-17` |
| `MainMenu/UMG/Buttons/WBP_QuestGiverButton.uasset` (Brush.ImageSize 512x256) | widget | exact | `docs/diagnosis.md:41-52` |
| `MainMenu/UMG/Panels/WBP_Border.uasset` | widget | exact | `docs/diagnosis.md:75-79` |
| `Quest/T_QuestGiver_Bundleton_ButtonFramed`, `Quest/BUNCO_flag_250323_copy` | texture | exact | `build_patch.sh:77-82` - pulled by the filter, then deleted |
| Cooked layout contract: 1024x512, PF_DXT1, 11 mips, MipBytes `[262144,65536,16384,4096,1024,256,64,16,8,8,8]` | other | runtime | `tools/splice_texture.py:38-45` hard-asserts equality |

**Failure modes.** The mip-layout contract is the real fragility and is **invisible to a filelist
diff** - dims/format/mip-count changes abort the build while the three paths still read "present".
Post-patch, re-run `fwextract mips` on the three targets and compare against `work/bake/*.bc1.json`.
`MIP_COUNT=11` and `TARGET_W/H` are hardcoded constants in `bake_buttons.py:24-26`. Also: the four
vendor mods (101-104) are **build-time inputs** - `build_patch.sh:48-53` mounts every `.utoc` under
the MO2 store, so if the vendor paks break, this rebuild inherits it. The tracked `dist/` binary was
force-added despite `.gitignore` and is a stale machine-specific artifact from 2026-07-21; it must
be rebuilt, not re-verified.

### forever-winter-skin-mods (Class A)

**Not deployed.** None of the 8 shipped variants appear in the MO2 store or `modlist.txt` - they are
Nexus-facing deliverables. See the correction in [Coverage and confidence](#coverage-and-confidence)
regarding `status.md`'s "4 skins deployed" line.

| Identifier | Kind | Baseline | Evidence |
|---|---|---|---|
| `Scavengers/Shaman/Skins/{Dogmask/SK_SCV_SHM_Doghead, DWK/SK_SCV_SHM_DWK, DSQ/SK_SCV_SHM_DSQ, MAY/SK_SCV_SHM_MAY}` | mesh | exact (4) | `docs/shaman-skin-map.md:12-15` |
| `Scavengers/Female/Skins/{SPT/SK_SCV_FL_SPT, DEC/SK_FL_SCV_DEC, DSQ/SK_SCV_FL_DSQ, MAY/SK_SCV_FL_May}` | mesh | exact (4) | `docs/scavgirl-skin-map.md:16-19` |
| `Shaman/SK_SCV_SHM{,_PhysicsAsset}`, `Female/SK_SCV_FL{,_PhysicsAsset}` | mesh | exact (4) | `build_shaman_dlc_variants.sh:30,48-52` |
| `GenericHumanoid/GenericHumanoid_Skeleton{,_MainCharacters}` | uasset | exact (2) | `docs/shaman-skin-map.md:5`; `docs/scavgirl-skin-map.md:3-4` |
| `Character/Master_Materials/M_FW_Char` | material | exact | `README.md:45` |
| `FW/Player/Data/DT_SkinUIData` + rows `Shaman0`, `ShamanDogHead`, `ShamanDec2025`, `Skin.Shaman.{DSQ,May}`, `ScavGirl0`, `ScavGirlSPT`, `ScavGirlDec2025`, `Skin.Girl.{DSQ,MAY}` | datatable | exact / **rows unverifiable** | `docs/*-skin-map.md:3,11-19` |
| `Audio/SFX/VO/OLMA/{Shaman,SHAMAN,ScavGirl,}/` VO packages | other | exact (4 subtrees) | `build_*_dlc_variants.sh:54-60`; shipped `.utoc` indexes |

**Failure modes.** Ranked: mesh rename kills one variant silently; **skeleton rename gives a T-pose
on every variant, which still "loads" and looks working in a screenshot**; `M_FW_Char` rename drops
all materials to default; VO tree reorg kills voice while the model keeps working (so it gets
misdiagnosed). Note the game ships **both** `.../OLMA/SHAMAN/` (all caps, 262 files) and
`.../OLMA/Shaman/` (mixed, 112 files) - a casing consolidation would break half the bundled voice.
The real contract is the **DT_SkinUIData row -> `Skin.AssetPathName` mapping**, which a filelist
diff cannot see: if a row is repointed while the old mesh stays in the paks, the diff reads clean
and the mod silently stops appearing. The skin maps were written against build `24045295` and have
never been re-verified - already two builds of drift before this patch.

### Class B - runtime resolution (4 repos)

All four fail into `UE4SS.log`. One tester run with the four enabled answers the whole class.

| Repo | Critical identifier(s) | Baseline | Failure signature |
|---|---|---|---|
| `TFWStaggerControl` | `FW/Player/GameplayAbilities/GA_Player_HitReaction` (`main.lua:161`) | exact | logs "FAILED to hook" forever; mod is a logged no-op |
| | `FW/Player/BP_PlayerBase` -> `ReceiveAnyDamage` (`main.lua:186`) | exact | **dangerous**: selective mode loses classification, every stagger is *allowed*, only a "pending hit-react expired unresolved" line explains it |
| | ~25 `BP_WPN_*` / `BP_AI_*` / damage-type BPs matched by substring needle (`config.lua:54-70`) | exact (25) | new enemy weapon degrades to family "other", unticked - silently leaks a stagger |
| | `Ability.HitReactionBlocked`, `Event.HitReaction.Player.Weapon` | runtime | invisible to filelist; needs a re-decode of the ability |
| `TFWLootAll` | `Widgets/Inventory/W_LootUI` (+ `_C:ItemLooted` hook, `LootItem`, `LootingAll`, `LootWidgets`) | exact | panel-missing logs a DISCOVER hint; a **bound-event rename is invisible** and degrades route A -> route B quietly |
| | `Widgets/Inventory/W_LootItem` (+ `ItemFits`) | exact | as above |
| | `W_LootInRange`, `W_LootFailReason`, 4 `BP_*LootContainer*` | exact (6) | DISCOVER-only; churn here is informational |
| `TFWQuestHUDToggle` | `FW/UI/HUD/Quests/WBP_Quests` (`WBP_Quests_C`, `main.lua:46`) | exact (`:58139`) | logs "N widget(s) affected" - **N=0 is the dead-mod alarm** |
| | fallbacks `FWQuestHUD`, `WBP_QuestStatus_C` | runtime / **no backing asset** | neither will absorb a rename; effectively single-point-of-failure |
| `TFWQuestItemTag` | `FW/UI/HUD/WBP_ItemTooltips` (`WBP_ItemTooltips_C`) | exact (`:58148`) | FindAllOf returns nil, loop no-ops, **only the startup banner logs** |
| | `FW/UI/HUD/WBP_BaseTooltip` -> `ItemDescription` TextBlock | exact (`:58140`) | the write target; verified in `catalog/widgets.json:17-23` |
| | `FW/UI/HUD/BPFL_Tooltips` (`CreateTooltips`) | exact (`:58132`) | documented fallback hook |
| | `Blueprints/Data/ItemDetailsData` + 43 `Quest_`-prefixed rows | exact / rows in `catalog/items.json` | **manifest must be regenerated after re-decode** |

**Two things to know before triaging Class B.** (1) `TFWStaggerControl`, `TFWLootAll` and
`TFWQuestItemTag` were **never confirmed working in-game even pre-patch**. A post-patch "does
nothing" report cannot be attributed to the patch without a pre-patch reference. (2)
`TFWQuestItemTag`'s `Scripts/quest_items.lua` is a generated build product of the decode - it is
stale until Stage 2 finishes and `tools/gen_manifest.py` is re-run against the sibling
`forever-winter-datamine` checkout.

### Deployed but unowned - third-party vendor paks

Enabled in MO2, no repo, no source in the collection. They have a dependency surface and
`TFWQuestGiverPortraitPatch` consumes them as build input, so they need routing too. Targets read
from their `.utoc` directory indexes and verified against the baseline:

| Pak | Targets | Baseline |
|---|---|---|
| `101-Bunko-Chan_P` | `Quest/BUNCO_flag_250323_copy` | exact |
| `102-kane_P` | `EconV2/Textures/T_KanePortrait`, `Vendors/T_Vendors_*`, REFRAMED portraits | exact |
| `103-Luca_P` | `EconV2/Textures/T_LucaPortrait`, REFRAMED portraits | exact |
| `104-Slade_P` | `VendorPortraits/REFRAMED/Vendor_01_b_REFRAMED_samesized` | exact |

Each also carries a bare `Kane.uasset` / `Luca.uasset` / `Slade.uasset` / `Bunko.uasset` with no
baseline counterpart - additions, not overrides. Each ships an inert override under
`Quest/{Bunko,Kane,Luca,Slade}` that resolves to nothing (verified: zero baseline matches); those
never loaded and are irrelevant to routing.

---

## FROZEN CONTRACT identifiers

> **Read this before touching `TFWCharModelSelFramework`.** These strings are **public ABI**.
> Third-party skin paks are cooked *against* them. Changing one is not a rename - it is a forced
> rebuild for every author who has ever shipped a CMSF skin, and their existing paks break in the
> wild with no warning and no way for us to fix them. **Append-only. Never renumber.**

Only `TFWCharModelSelFramework` publishes frozen contracts. No other repo does.

| Frozen identifier | Shape | Baseline | Why it is frozen |
|---|---|---|---|
| `/Game/CMSF/<Char>/<NN>/SK_CMSF_<Char>_<NN>` | mesh slot | **absent (required)** | authors cook their mesh to this exact path |
| `/Game/CMSF/<Char>/<NN>/T_CMSF_<Char>_<NN>` | texture slot | **absent (required)** | also the claim signal `CMSFUnlock` derives from the row name |
| `/Game/CMSF/<Char>/<NN>/ST_CMSF_<Char>_<NN>` | stringtable slot | **absent (required)** | hard reference; needs a synthesised import chain |
| `ForeverWinter/Content/CMSF/<Char>/<NN>/` | pak staging dir | **absent (required)** | build FAILS if a pak ships anything outside it |
| `CMSF.<Char>.<NN>` | DT row name **and** ST namespace | row | both must agree; parsed at runtime, `main.lua:215` |
| `Name` / `Desc` | string-table keys | runtime | an override only lands if namespace + both keys agree |
| `CMSF%.%a+%.%d%d` | Lua match pattern | runtime | freezes slot numbers at **exactly two digits**; pool hard cap 100 |
| `<Char>` token set: `BagMan`, `Girl`, `Gunhead`, `MaskMan`, `OldMan`, `Shaman` | identifier | runtime | 6 characters x 32 shipped slots = 192 |
| `DT_SkinUIData` + the 6 `BP_Player_*` | override targets | exact | the surface the whole contract is expressed through |
| `WBP_SkinButton_C.SkinIcon.Brush.ResourceObject` -> `GetFullName()` | claim signal | runtime | the chain every author's slot claim is validated by |
| Load-order tokens `CMSF_Core_9_P` / `CMSF_<Char><NN>_<id>_11_P` | filename | n/a | third-party paks bake the `_11_P` token |

**The check that matters most.** `grep -c "^ForeverWinter/Content/CMSF/" filelist.txt` must return
**0** (pre-patch: confirmed 0). That vacancy is *required*, not a defect. A real
`ForeverWinter/Content/CMSF/` entry in the new filelist means the developers have collided with the
framework's namespace and every claimed slot in the wild breaks simultaneously.

**Registered claims.** Exactly one public slot is registered: `Girl/00` = Octogirl
(`docs/slots.md:27`). Slots 28-31 are the unpoliced private range; the shipped example skin sits at
`Girl/28`. So the *known* third-party breakage surface is one claim plus whatever is unregistered in
the wild - but "unregistered" is not "none", and we cannot enumerate it.

**Secondary contract risk.** The string-table override only lands if namespace `CMSF.<Char>.<NN>`
**and** keys `Name`/`Desc` all agree. Changing any of the three breaks author paks **without
breaking our build** - the quietest possible failure.

---

## Not found in baseline

Every dependency the extraction pass recorded as `not_found`, with a verdict on whether it means
*already-broken* or *mis-recorded identifier*. **All of these need resolution regardless of what the
patch did** - they are pre-existing state, not patch damage.

| Identifier | Repo | Verdict | Resolution needed |
|---|---|---|---|
| `/Game/CMSF/**` - 21 entries (6 char slot families, the 3 Octogirl `Girl/00` packages, the `Girl/28` example, the staging dir) | `TFWCharModelSelFramework` | **Mis-recorded by schema, not broken.** This is the mod's own namespace. Absence is the *required* state, not a miss. | Reclassify, do not investigate. The correct assertion is an inverted one: assert the count stays 0. Tracked above under [FROZEN CONTRACT](#frozen-contract-identifiers). |
| `/Game/WPN_Weapons/RFL_Rifles/RFL29/SM_WPN_RFL29_MAG_130_02` | `HeavyRifleRebalanceFix` | **Genuinely already-broken - upstream authoring bug.** Absent from the baseline *and* from the mod's own 191 pak (`_01` is present, `_02` is not; zero hits for "130_02" across all three 191 files). Corroborating tell: both mag items carry the identical `ItemName` "VKS Magazine B" with differing descriptions - the author copy-pasted the `_01` row and bumped the mesh suffix without ever cooking a `_02` mesh. | Cosmetic only (the 19-round mag renders with no mesh). Inherited from Nexus #76, not introduced by our fix. Fix or drop the row; **do not route a patch diff at it**. |
| `/Game/ArtAssets/UI/Inventory/Textures/ItemPortraits/Manufacturing/T_Portrait_Manufacturing_Optics` | `HeavyRifleRebalanceFix` | **Mis-recorded as a game dependency.** The mod *ships* this asset itself inside `191_HeavyRifleRebalance_P`. It is a mod addition at a `/Game/` path the base game does not have. | Reclassify as mod output. A naive filelist diff **will** flag it as new/missing - ignore it. |

**Adjacent gap, not a `not_found`.** `TFWQuestHUDToggle` lists `WBP_QuestStatus_C` as a fallback
resolution candidate. The class name exists in the usmap but **no standalone `WBP_QuestStatus.uasset`
exists in the baseline** - only `WBP_QuestStatusPanel.uasset` (a Debrief panel) and
`WBP_PlayerQuestStatusWidget.uasset`. Either it is a nested sub-object or a stale usmap entry;
either way it is a different widget from the in-mission HUD and **will not absorb a rename of
`WBP_Quests_C`**. That mod should be treated as having a single point of failure, and the same
repo's docs claim (`docs/DESIGN.md:67`, `README.md:30`) that the usmap "lists WBP_Quests" is wrong -
it does not; the confirmation comes from the pak filelist.

---

## How to use this after the re-decode

Concretely, once Stage 2 has produced a new `filelist.txt`:

**1. Produce the changed-path set.**

```bash
powershell -File tools/diff_baseline.ps1 -Before pre-24479102 -After post-24479102
cd state/diffs/pre-24479102__vs__post-24479102
cat filelist-added.txt filelist-removed.txt > /tmp/changed.txt
```

A rename shows as one line in each file. Treat added+removed as one set; do not try to pair them up
by hand.

**2. Intersect against this map.** Run the [Grep these first](#grep-these-first) patterns over
`changed.txt`. Anything that hits routes to the named repo in the same line.

```bash
grep -Ef <(patterns from Group 1..5) /tmp/changed.txt
```

**3. Apply the matching rules before declaring a break.**

- **Case-only differences are not breaks.** `TOOTHY`/`Toothy`, `Bagman`/`BagMan`,
  `GunHead`/`Gunhead`, `Gunplay`/`GunPlay`, `GUNS`/`Guns` all appear in the collection. UE
  lowercases the package name before hashing `FPackageId`. Compare lowercased paths; only a change
  that survives lowercasing is real.
- **The `.ubulk` companion matters** for textures. If a target's `.ubulk` disappears while the
  `.uasset` stays, the streaming layout changed - that is a real break for
  `TFWQuestGiverPortraitPatch` even though the "asset is still there".
- **Additions inside our own namespaces are not game changes.** `T_Portrait_Manufacturing_Optics`
  and anything under `ForeverWinter/Content/CMSF/` fall here.

**4. Run the inverted check.**

```bash
grep -c "^ForeverWinter/Content/CMSF/" filelist.txt   # must be 0
```

**5. Route at the named mods**, then update `state/status.md` in the same turn. Zero hits for a repo
means *likely-clean*, which is a smoke-test result, not a verified one.

**6. Then do the work a filelist diff cannot do.** This is the part that gets skipped and should
not be. The intersection above finds moved paths. It finds none of the following, all of which are
live risks in this patch:

| Blind spot | Affected repos | How to actually check |
|---|---|---|
| DataTable **values** retuned in place (same RowStruct, same row count) | `HeavyRifleRebalanceFix`, `AllWeaponsUnlockableFix`, `UnkillablesRebalanceFix` | `python -m fwdata get <table> --force` then diff dump values, not `tables.json` |
| Scalar constants the build asserts on | `UnkillablesRebalanceFix` (2x `1e9`, 2x `9e8`, 19-double sequence), `HeavyRifleRebalanceFix` (`FC_RFL29` 175/350) | attempt the rebuild; it aborts loudly, which *is* the test |
| Texture mip layout (dims / format / mip count / per-mip bytes) | `TFWQuestGiverPortraitPatch` | `fwextract mips` on the 3 targets vs `work/bake/*.bc1.json` |
| Widget member and bound-event renames | `TFWLootAll` (`BndEvt__*` ordinals), `TFWCharModelSelFramework` (`SelectLockedSkinsOnly`, `Init`), `TFWQuestHUDToggle` | re-decode the widget, or read `UE4SS.log` after a Class B pass |
| Gameplay tag renames or de-globalisation | `AllWeaponsUnlockableFix`, `ScavgirlCarryPerks`, `TFWStaggerControl`, `HeavyRifleRebalanceFix` | tags never appear in a filelist; decode the granting assets |
| DT row -> asset repointing while the old asset survives | `forever-winter-skin-mods`, `TFWQuestGiverPortraitPatch`, `TFWCharModelSelFramework` | decode `DT_SkinUIData` and `DT_QuestGiverData` row-by-row |
| Struct field additions | `HeavyRifleRebalanceFix` (`InventoryDangly`, `ManufactoringRecipies` offset `0x68`), `ScavgirlCarryPerks` (`FWSkillDefinition` slot order) | diff the usmap / row struct, not the table asset |

**7. Regenerate the derived artifacts** that are build products of the decode, not of the game:
`TFWQuestItemTag/Scripts/quest_items.lua` (via `tools/gen_manifest.py`) and
`AllWeaponsUnlockableFix`'s `work/decode-out/` verifier inputs. Both are stale the moment Stage 2
finishes and both fail *quietly* if left alone.

---

## Coverage and confidence

Honest limits of this map. It is a routing table, not a certificate.

**Scope.** Covers all 7 Class A and all 4 Class B repos, plus the 4 deployed third-party vendor
paks. Classes C, D and E are out of scope by design - they have no per-asset dependency surface of
this kind.

**What the baseline could not verify.**

- `catalog/tables.json` indexes only **32** tables. It does **not** include `DT_SkinUIData`,
  `DT_QuestGiverData`, `BackpackRigDataV2`, `InventoryContainerData` or `DT_PlayerSkillTags`. So
  four repos have row-level dependencies that this baseline literally cannot check:
  `TFWCharModelSelFramework` (the `ScavGirl0` and `Skin.Girl.MAY` clone templates - both hard build
  aborts), `forever-winter-skin-mods` (the entire row->mesh mapping, which *is* its contract),
  `TFWQuestGiverPortraitPatch` (whether Kane/Luca/Slade still point at our targets), and
  `ScavgirlCarryPerks` (rig capacity rows). **Recommend adding these tables to the decoder's dump
  list before the post-patch capture** - it is a small change that closes a real hole.
- `catalog/widgets.json` covers the **tooltip family only** (9 widgets). Member names were
  verifiable for `TFWQuestItemTag` and nothing else. CMSF's `WBP_SkinSelection` members and
  TFWLootAll's `W_LootUI` members rest on repo-side decodes, not on this baseline.
- **Gameplay tags never appear in a filelist at all.** Roughly 60 tag dependencies across the
  collection are unverifiable from a path diff by construction.

**Where evidence is fragile.** Several repos' strongest evidence lives in **gitignored `work/`
trees that exist only on this machine**: `HeavyRifleRebalanceFix/work/legacy-repath/` (the source of
its 125-path import closure), `UnkillablesRebalanceFix/work/` (481 extracted refs),
`AllWeaponsUnlockableFix/work/decode-out/`. If those are cleaned, the closure evidence is gone and
only the much thinner `KEEPERS` lists in the build scripts survive.

**Where confidence in the mods themselves is low, independent of this map.**

- `TFWStaggerControl`, `TFWLootAll`, `TFWQuestItemTag` were **never confirmed working in-game**.
  `TFWCharModelSelFramework` v0.2.4 is documented as unverified in-game. For these four, a
  post-patch failure cannot be separated from a pre-existing one. A post-patch field test is
  confirming two things at once.
- `TFWQuestGiverPortraitPatch`'s committed `dist/` binary is a stale, machine-specific artifact and
  is not reproducible from the repo alone.
- `TFWStaggerControl`'s pak half **does not exist** - `build.sh` steps 3-5 are stubs. Its skill-tree
  identifiers are dependencies of an unbuilt artifact.

**One correction to the board.** `state/status.md:44` records `forever-winter-skin-mods` as
"4 skins deployed (Slade, Luca, Bunco-chan, Kane)". That is a mismatch. Those four are third-party
numbered vendor paks (`101-Bunko-Chan_P`, `102-kane_P`, `103-Luca_P`, `104-Slade_P`) with no source
in any repo, and they are **UI portrait texture swaps, not character skins**. None of
`forever-winter-skin-mods`' 8 shipped variants (4 Shaman, 4 Scav Girl) is deployed in MO2 at all.
Routing that row at the skin repo will send work to the wrong place. Left uncorrected here because
this file is the only one in scope for this pass.

**Extraction confidence.** All 11 per-repo passes self-reported `high`. That reflects thoroughness
of the source reading, not certainty about the patch. Treat every "likely-clean" verdict this map
produces as a hypothesis to smoke-test, not a result.
