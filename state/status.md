# Status board — 24097213 → 24479102

**The source of truth for "is this done yet."** Not memory, not the individual repo's WORKLOG.

Legend: ⬜ not started · 🟨 in progress · 🟦 blocked · 🟩 verified · 🟥 confirmed broken · ⬛ n/a this patch

---

> ## 🔺 NEW BUILD 24501089 — hotfix, measured 2026-08-01
>
> Released Friday 2026-07-31; auto-applied on SylG5 2026-08-01 06:42. Full analysis in
> [`hotfix-24501089-findings.md`](hotfix-24501089-findings.md).
>
> **Within the weapon set it is a damage buff and nothing else** — `WeaponDamage` on 32
> `DA_WPN_PLAYER_*` is the only field changed there. Filelist identical (76,309 entries,
> 0 added / 0 removed / 0 renamed), AES key still valid, AI weapons untouched.
>
> A full re-decode of all **722** tracked dumps found **72** differing from live, not 32 —
> also `bosses` 18, `ai_sensors` 15, `enemies` 5, `items` 1, `factions` 1. **Only the weapons
> are attributable to this build**: 24479102 promoted weapons alone, so every other subdir's
> diff spans two patches. The `ai_sensors` block is provably older — it is the
> `Pawn.Player.HoldingPistol` accumulator already documented as a 24479102 finding.
> Notable: **Pistol Ammo 23,000 → 46,000**, extraction XP 200 → 400.
>
> - **`AllWeaponsUnlockableFix` is CLEAR on this build** — verified directly, not inferred:
>   both variants decoded in a full live mount, **381 / 383 references checked, 0 dangling**.
>   `WeaponsDetailsData` is byte-identical to base. **The upload hold is lifted.**
> - **The HRF hypothesis gained real evidence.** Fun Dog retuned damage by editing
>   `WeaponDamage` on `DA_WPN_PLAYER_*` and nothing else — the exact field the board flagged as
>   "may now be authoritative, verify before building". Redesign targets moved: HRF01 → 300.0,
>   HRF02 → 1800.0, HRF05 → 10000.0.
> - **The almanac needs a damage refresh** on top of its existing Stability rework. Published
>   figures are low by ~11%, and `HRF02` / `HMG01` are wrong by half.
> - **Gates 3 and 3b revert to unknown** — the shipping exe changed (same size, different
>   SHA256). 3b is Signature Bypass, AWU's only declared dependency. Both need a launch.
> - **Rollback key captured: `6443337773729671953`** ([`build-history.md`](build-history.md)).
> - **`AutoUpdateBehavior` is `0`** ("always keep updated"); it was `1` through the last cycle,
>   which is what held that patch open for a baseline capture. SylDesk is reported paused.
> - **The tooling is single-machine.** `H:` is SylDesk's NVMe and does not exist on SylG5, so
>   every hardcoded path fails here — `tools/steam_state.ps1` throws rather than reports. The
>   fix is per-machine resolution, **not** a find-and-replace, which would just break SylDesk.
>   Path table in [`build-history.md`](build-history.md).
>
> The `post-24479102` baseline is complete and served as the "before" side, so no capture
> window was lost. Everything below this line is still stamped to `24479102` — treat 🟩 marks
> on the **pak** mods as provisional until re-checked against this build.
>
> ### ⚠ The full-game `zzz_` staging trick does not work — measured 2026-08-01
>
> Every verify wrapper we had stages the whole live game as hardlinks and drops the mod in
> renamed `zzz_` "so it wins the FPackageId collision". **It does not.** CUE4Parse resolves
> each colliding path independently and **non-deterministically**; both copies export to the
> same filename and the last write wins, so which copy you grade depends on mount iteration
> order. Nine mounts of `CMSF_Core_9_P` returned the mod's copy for **0, 3, 4 or 7** of its 7
> overridden packages across runs. Renaming the container `000_` / `aaa_` / `zzz_` changed
> nothing. A CMSF port following the precedent literally reported *"OK, 791 references, 0
> dangling"* on a `DT_SkinUIData` that was an **md5 match for the base game** — it graded
> vanilla and passed.
>
> **The fix is a mount-provenance gate, and which mount to use depends on the mod:**
> - **Override paks → mount in isolation** (the mod's trio + `global.utoc`/`global.ucas`).
>   No base copy present, so no collision is possible and the bytes are certainly the mod's.
>   Soft paths are strings and survive isolation, so `AssetPathName` coverage is unaffected.
> - **Mods whose exposure is *hard imports* → isolation is the wrong tool.** An unresolvable
>   sub-object serialises as null, so the references you want to check vanish. `ScavgirlCarryPerks`
>   is exactly this case: isolated, it yields **1** reference per variant instead of its real
>   surface. Those need the full mount **plus** a provenance gate asserting the dump differs
>   from base.
>
> **This hit our own work.** The AWU clearance earlier today used the full-mount trick and
> produced **7 dumps for a variant that ships 5 assets** — two were base copies. Re-run with an
> isolated mount it is **still clean and now provably the mod's content**: regular 5/5 dumps
> differ from base, 268 refs, 0 dangling; Trees 6/6 differ, 269 refs, 0 dangling. The
> conclusion held, but by luck of the draw rather than by method. **The upload advice stands.**

---

Last updated: 2026-07-31 (3) — **permission gate closed by clean-room rebuild** (`5ed467c`):
#110 author is **LassyMorphee**, page grants no permissions, so the regular Fix was rebuilt from
current vanilla (5 assets, zero upstream bytes, A/B-identical). **Both AWU variants cleared to
upload.** Good `.ucas` sizes: regular **75,174 B**, Trees **79,239 B** — everything else in the
lineage (110,000 / 110,008 / 112,133 / 81,372) is superseded or broken. Community reports parsed
(`community-reports.md`); replies owed to `4ce0fspades` + `Southperry88`.
Earlier (2): AWU regular regression caught & fixed pre-Nexus (`d12007d`); build now strips +
asserts graft sets.
Earlier today: `ScavgirlCarryPerks` verified clean (🟩, no rebuild); `verify_softrefs.py`
ported to it with a new reversion check; AWU permission gate recorded in the Ship table;
`TFWQuestGiverPortraitPatch` "Enabled" corrected to disabled.
Previously 2026-07-30 17:55 EDT — **patch applied 17:34.** Gates 0, 1a, 1b, 3 and 3b all
cleared; filelist diff complete. Findings: [`stage2-findings.md`](stage2-findings.md).

**Where the logs actually live.** MO2 deploys RE-UE4SS and Signature Bypass via Root Builder,
which *physically copies* them into the game `Binaries\Win64` for the session (USVFS cannot
virtualize DLLs the OS loader pulls in before its hooks install). So during a session the logs
are at the **real** game path, not MO2's overwrite:

- `…\Binaries\Win64\ue4ss\UE4SS.log`
- `…\Binaries\Win64\bitfix.txt` (append-only across sessions — filter by date)

They land in `MO2Instance_ModData\ForeverWinter\overwrite\…` only after cleanup on exit. Reading
the overwrite copy while the game is running gets you the **previous** session's log. Verified
the deployed binaries are byte-identical to the MO2 mod's, so this tests the right build.

---

## Gates

These block whole classes. Nothing below them means anything until they're resolved.

| # | Gate | Status | Notes |
|---|---|---|---|
| 0 | Baseline captured | 🟩 | Both sides captured, 0 warnings. `pre-24479102` (76,589 entries) + `post-24479102` (76,309). Datamine tagged `baseline-24097213` @ `36b068b8`. New rollback key `6430523508700280691`. |
| 1a | AES key still valid | 🟩 | **Cleared.** Decoder mounted 76,309 files from the new paks with the key hardcoded at `decoder/Program.cs:28`. The IoStore index is AES-encrypted, so the mount *is* the test. No AESDumpster run needed. |
| 1b | usmap valid (or regenerated) | 🟩 | **Resolved by regeneration 18:15.** Was found stale for `FWWeaponDefinition` (shifted values under wrong names). Dumped a fresh map via UE4SS `Ctrl+Numpad6` → `ForeverWinter-5.4.2-24479102.usmap`; re-decode is clean and round-trips against the old dump. Old map archived to `mappings/archive/`. |
| 2 | Re-decode + filelist diff | 🟩 | **Complete.** Filelist diff + force re-decode + catalog rebuild from fresh dumps (stamp `24479102`, data to match). Real deltas found that the stale-vs-stale diff had missed: `WeaponsDetailsData` 56→53, `DT_TagToRowHandle` 1176→1173 (rows `RFL01_Red/Blue/Green` cut). Nine non-taxonomy dump subdirs not re-decoded — verified 0 stale, flagged as cleanup. |
| 3 | RE-UE4SS attaches to new exe | 🟩 | **Cleared 2026-07-30 17:50.** Clean attach against the new exe (`169584128 B` confirmed in-log). PS scan finished 627 ms, `EngineVersion 5.4`, all symbols resolved, `PS scan successful`, `Event loop start`. The lone `FUObjectHashTables::Get()` miss is **pre-existing** — byte-for-byte the same line appears in the 2026-07-27 old-build log. **Class B is unblocked.** |
| 3b | Signature Bypass matches new exe | 🟩 | **Cleared 2026-07-30 17:50:55.** bitfix AOB scan hit on the new exe (`scan results: [[7FF6E9560600, 7FF6E9560950]]`) and applied the patch (`writing C3`). Same shape as the 07-27 run at shifted addresses. |
| 5a | TFWWorkbench reads new paks | ⬜ | Gates all of Class A rebuilds. |

## Class B — Lua (do first; cheap intel)

**Gates 3 and 3b cleared, and all three deployed Class B mods ran on the new build 2026-07-30
17:57.** No class, Blueprint, widget or function any of them resolves has moved. Zero Lua errors
in the session log.

The hoped-for side benefit did not materialise — Class B failures were supposed to name the paths
that moved and thereby sharpen Class A. Nothing failed, so there is no such intel. That is a good
outcome, just not a useful one for Class A.

| Repo | Status | Finding |
|---|---|---|
| `TFWLootAll` | 🟨 | **Loads clean** — v0.1.0 PROBE, both keybinds bound, no errors. `W_LootUI.uasset` survives the patch. **Not functionally tested** — needs Ctrl+L at a real container to confirm the transfer path. |
| `TFWQuestHUDToggle` | 🟨 | **Loads clean** — v0.1.1, both keybinds bound, no errors. **Not functionally tested** — needs Ctrl+Shift+Q in a quest HUD context. |
| `TFWStaggerControl` | 🟩 | **Not broken by the patch.** Both hook targets survive (`GA_Player_HitReaction.uasset`, `BP_PlayerBase.uasset`) and both hooks **registered successfully in-game** at player restart (`hook (8,8)` / `(9,9)`); probes found a live `GA_Player_HitReaction_C`. The startup "FAILED to hook" lines are the mod's own deferred-retry design, not a regression. Separately: the mod is **incomplete by design state** and is developed/tested on another client — that is dev status, not patch damage, and must not be scored against this patch. |
| `TFWQuestItemTag` | ⬜ | **Not in the MO2 store at all**, so untestable here. Manifest must be regenerated after the re-decode regardless. |

## Class A — Paks (expensive; diff-driven)

| Repo | Status | Finding |
|---|---|---|
| `HeavyRifleRebalanceFix` | 🟥 | **DEAD — confirmed on `24501089` with a named hit list** (`c38fd06`). **`verify_softrefs` is structurally blind to this mod's death** and that is worth understanding: it follows references pointing *outward*, and the mod still ships its own copies of the renamed assets, so on mount those packages exist and all 9 outbound refs resolve — a clean, meaningless pass. The mod is dead because the game no longer **loads** those packages. So the wrapper adds a **target-presence check** against the live filelist, which is what catches it. **11 of 13 gone.** Renamed `DA_WPN_<code>_v2` → `DA_WPN_PLAYER_<code>` at the same folder paths: `HRF01`–`HRF05`, `RFL29`. Deleted with no replacement: `FC_HRF01/02/03/04_Damage`, `FC_RFL29_Damage`. Surviving: `DT_CaliberToHeadshotMulti`, `MI_WPN_HRF03_UPP_01_RTC`. **Curve tree confirmed gone game-wide**: zero `UpgradeTuning` paths and zero `DA_WPN_*_v2` in the 76,309-entry filelist; 20 `FC_*` survive but none are per-weapon damage curves (input modifiers, sway, spray, stamina, animation). **A 12th dead override found** outside this wrapper's scope: the loose-files pak `191` ships 18 packages, 17 survive, `T_Portrait_Manufacturing_Optics` is **GONE**. Redesign targets moved with the hotfix — HRF01 → **300.0**, HRF02 → **1800.0**, HRF05 → **10000.0**; the worklog's numbers are stale. |
| `TFWCharModelSelFramework` | 🟩 | **Verified on `24501089`** (`cb6f944`) — **401 dumps, 1591 references, 0 dangling** across framework, `release-v0.2.0` and the octogirl author pak, using a deterministic isolated mount. Filter coverage proven 100% by mounting each pak alone (framework = exactly 199 packages; octogirl = 3). **Frozen contract handled:** `/Game/CMSF/` is `--ignore`d, and removing the ignore surfaces 576 dangling of which **every one is inside `/Game/CMSF/` and none outside** — so it suppresses exactly the ABI. The **inverted assertion is wired to fail the run**: the live filelist carries **0** entries under `ForeverWinter/Content/CMSF/`, which is the required state — the devs have not collided with the namespace. 100 of the surviving refs point into 54 distinct live base packages (vanilla meshes, `T_Menu_PickCharacter_Portrait_*`), which is exactly the surface a dev rename would break; all resolve. This repo is where the **non-deterministic mount** finding came from — see the banner. |
| `UnkillablesRebalanceFix` | 🟥 | **REVERTS THE 24501089 HOTFIX — needs a rebuild before it ships** (`a9c59da`). The dump diff the board has been asking for is now done, and it found the thing the path diff structurally could not: the shipped `BPC_IncomingDamageMod` drops **13 property shapes** the live build has (live base 43 exports / 41 FuncMap entries; the override 40 / 38). Missing are the functions **Noisy Player**, **Modify Attack Add**, **Big boi Sniper Rifles**, the property **Attack Add**, and `ChildProperties[].Inner.MetaClass`. `dist/` was built **2026-07-20**, so its Option-B extraction predates the hotfix — installing this pak as-is **silently un-does the weapon damage buff**. Fix is a plain rebuild: `build_fix.sh` step `[3/6]` re-extracts `BASEPATCH` from the current game paks. Soft references are clean (17 dumps, **4507 refs, 0 dangling**) and the other 10 packages drop no shapes. **Both checks are structural** — BP graph / Kismet bytecode changes move neither path nor property shape, so this does **not** clear the Option-A Stalker AIDEFs (frozen at 0.9.2.2) for graph drift. Verification ported + wrapper added; override surface confirmed by mounting the pak alone (11 packages), not inferred. |
| `AllWeaponsUnlockableFix` | 🟩 | **Regression found & fixed 2026-07-31** (`d12007d`): the patch-rebase rebuild **resurrected the two Session-2 carry grafts** on ScavGirl's root (13 children again — `Shaman_PackMule_v1` + `OldMan_RIG01_AllowUse`, duplicate "Equip Runner" and all). Cause: Session 2 fixed the *artifact*, `build_fix.sh` kept pulling roots from `upstream/`; first end-to-end rebuild since brought the defect back, and `verify_softrefs` is blind to it — the grafts dangle nothing. Caught **before Nexus** via the SCP-interop question. Now the build *strips* the grafts (step 3) and *asserts* every root's graft set against `tools/fix_expected_grafts.json` (step 8, `verify_grafts.py`, negative-tested). Rebuilt 13→11, redeployed to MO2 hash-verified. **Good `.ucas` = 110,000 B; the regressed one is 110,008** — 8 bytes apart, check exactly. Trees unaffected. Earlier history: **BOTH VARIANTS FIXED** (`fe522fb`). User-confirmed break: every `WeaponsDetailsData` row pinned `DataAsset` → `DA_WPN_<code>_v2`, all renamed to `DA_WPN_PLAYER_<code>` by the patch, so every weapon lost its definition pointer. Measured in a full mount — deployed Trees **56/56 dangling**, regular **56/56 dangling**; **both rebuilds now 0/53** ✅. Root cause + ruled-out alternatives: [`rootcause-awu-customization-ui.md`](rootcause-awu-customization-ui.md). **Deployed to MO2 2026-07-30** (both variants, hash-verified; previous paks backed up). **Not yet released on Nexus** — users are still served the broken paks. Both mods are currently **disabled** in the profile, so re-enable before testing. **Class-level fix added** (`b4b01e4`): `tools/verify_softrefs.py` asserts every `AssetPathName`/`ObjectPath` in a decoded pak resolves against a freshly-regenerated live filelist, and now gates **both** builds. Proved against the real defect — flags **63 dangling** on the broken 07-20 pak, **0** on both rebuilds. `build_fix.sh` previously had *no* content verification at all. **Portable to every other pak mod we own.** |
| `ScavgirlCarryPerks` | 🟨 | **Its clearance needs re-measuring — the method was unsound** (`bd7c87d`). `verify_build.sh` uses the full-game `zzz_` staging trick, now measured to be non-deterministic (see banner), and **every SCP variant overrides a base asset** — exactly the shape that can grade vanilla and report clean. Its `verify_softrefs.py` copy also predated today's fix, so it would have passed an empty scan; now synced to canonical. An isolated re-run on `24501089` cleared all four variants with provenance proven (1 dump each, all differing from base, 0 dangling) — but **only 1 reference each**, because SCP's real exposure is *hard imports* into other characters' packages and those null out under isolation. **Isolation is the wrong tool for this mod**; it needs the full mount plus a provenance gate. Structurally it is safe on this build regardless: the filelist is **identical** across `24479102` → `24501089`, so nothing it points at can have moved. Prior finding, method caveat aside: **Survives unchanged — verified 2026-07-31 (`5007c18`), no rebuild needed.** Override surface is **one asset**: `retoc list` shows all four variants shipping a single package, id `e2129fe5f6accc68` = `SD_Skill_EarlyAccess_ScavGirl_ROOT` (the Combined variants merge AWU's weapon grafts into that same ROOT rather than shipping a second asset). **No `WeaponsDetailsData` override**, so it is structurally immune to the stale-`DataAsset` break that hit AWU. Its actual exposure is a whole-asset ROOT override *referencing* nodes in other characters' packages — checked both ways: **0 dangling refs** and **0 native children dropped**, all four variants, against a filelist regenerated from the live game. Near-miss: the patch renamed `ActiveCharacters/OldMan/` → `Oldman/` (27 assets) and our paks have the old casing baked in — **it binds anyway**, proven by 0 null `ChildSkills` / 0 `UnknownPackage` in a full mount, not merely by the case-insensitive checker passing. `verify_softrefs.py` **ported** + new `tools/verify_build.sh` (reversion check negative-tested). Still ⬜ **in-game on 24479102**; all 5 variants remain disabled in MO2. **Interop addendum 07-31 (corrected):** **SCP is RELEASED on Nexus** — the repo's unchecked "Nexus upload" box was stale. That kills the first theory about the "SCP needs an update for newest AWU" reports: the AWU carry-graft regression **never left this machine**, so Nexus users can't be hitting it. Likely causes, in order: (1) the **base-game Carry Capacity bug** (`docs/carry-capacity.md` — effect drops on location entry; page warning still unposted), (2) the **ScavGirl-ROOT collision** if AWU's pak wins mount order (launch-gated), (3) pre-patch AWU's dead-pointer table making the combo look broken. SCP-Combined's 4 weapon grafts still match both AWU variants' design. **Not recorded anywhere: SCP + AWU Nexus page numbers, report wording, reporters' variant.** |
| `TFWQuestGiverPortraitPatch` | 🟩 | **Verified on `24501089`** (`19214cb`). **The override surface is 3 textures, not 122** — 122 is the vanilla `Quest/` folder population; `build_patch.sh` keeps only the `mapping.tsv` targets. Confirmed by mounting the pak alone: 6 files (3 `.uasset` + 3 `.ubulk`) = Kane / Luca / Slade `_ButtonFramed`. The softref check is **legitimately vacuous** here — cooked `Texture2D` exports hold no `AssetPathName`/`ObjectPath` at all — so `--allow-empty` was **established by running without it first** (exit 2) and inspecting the dumps, and the wrapper asserts what actually matters instead: **baked** (mod pixels ≠ vanilla), **landed** (mount resolves to the mod's bytes), **geometry** (1024x512 `PF_DXT1` mip0 = 262144). All 3/3, negative control fails correctly. Still not enabled in `modlist.txt:28`; still assumes a 2:1 button brush. |
| `forever-winter-skin-mods` | ⬛ | **Not deployed — registry was wrong.** Builds `SCVGIRL_UMP9_*` / `SHM_UMP45_*`; none in the MO2 store. The 4 enabled skins (`101`–`104`) are **third-party**, not ours. Not our fix, but they sit in the smoke-test loadout. |

## Class C — Datamine + data products

| Repo | Status | Finding |
|---|---|---|
| `forever-winter-datamine` | 🟩 | **Re-decoded and current at `24501089`** (`c56bb36`). All **722** tracked dumps re-decoded from the live game, **72 promoted**, catalog rebuilt and stamped `24501089`; `lootobjects` held at its curated 151-of-437. The staleness gap is closed: the 9 non-taxonomy subdirs are now current for the first time since before 24479102. **Added `tools/redecode_check.py`** — decodes by committed basename rather than by filter, so curation is preserved by construction and no subdir can silently widen; re-running it after promotion reports 0 changed across all 13 subdirs. `FALLBACK_BUILD` bumped. Earlier at `24479102`: usmap regenerated, 14 dumps of deleted assets removed, 74 weapon dumps promoted — **weapons only**, which is what cost the attribution on the other 40 this cycle. |
| `forever-winter-almanac` | 🟥 | **Rework, not restamp.** The published Stability analysis (dispersion curves, the Stability 0→1 numbers) documents a system that was deleted. Restamping would make it *confidently wrong*. Gunsmith section likewise. |
| `forever-winter-maps` | ⬜ | |
| `NewStefanMap` | ⬜ | |
| `fwact` | ⬛ | Can't build/test on this desktop (Rust toolchain can't link). |

## Class D — Tooling (smoke test)

| Repo | Status | Finding |
|---|---|---|
| `ForeverWinterMO2Support` | ⬜ | |
| `TFWWorkbenchMO2Patcher` | ⬜ | |
| `TFWWorkbenchMO2Fix` | ⬜ | |
| `TFWModdingAssistant` | ⬜ | |
| `ForeverWinterModSetup` | ⬜ | Update if install layout moved. |

## Class E — Research

⬛ this patch. Re-verify only if a downstream fix leans on a finding.

## Ship

| Repo | Rebuilt + verified | Deployed to MO2 | Permission to redistribute | Nexus updated |
|---|---|---|---|---|
| `AllWeaponsUnlockableFix` (regular) | 🟩 `5ed467c` — **clean-room rebuild from vanilla** (5 assets, zero upstream bytes), A/B-identical, graft sets asserted. **Re-verified on `24501089` 2026-08-01: 381 refs checked, 0 dangling** | 🟩 2026-07-31 (clean-room deployed) | 🟩 **CLEARED by rebuild** — ships nothing of LassyMorphee's; design credited. DM still owed (their carry-slip bug relay) | ⬜ **users still on the broken pak — CLEARED ON THE CURRENT BUILD, upload when ready** |
| `AllWeaponsUnlockableFix` (Trees) | 🟩 `3dafbc5`, ALL CHECKS PASSED. **Re-verified on `24501089` 2026-08-01: 383 refs checked, 0 dangling** | 🟩 2026-07-30 | 🟩 n/a — inherits no #110 content | ⬜ **users still on the broken pak — CLEARED ON THE CURRENT BUILD** |
| `HeavyRifleRebalanceFix` | ⬜ needs redesign — curve layer deleted | ⬜ | ⬜ | ⬜ |

**Release is the remaining user-facing gap.** The Nexus pages still serve the pre-patch paks, so
every downloader still hits the customization-UI break. Nexus prose + upload are Sylvia's; the
plain-language substance is in [`rootcause-awu-customization-ui.md`](rootcause-awu-customization-ui.md).

### New blocker found 2026-07-31: the two variants differ on permission

Provenance was audited and written up in
[`AllWeaponsUnlockableFix/CREDITS.md`](../../AllWeaponsUnlockableFix/CREDITS.md) (`8ae8a17`).
The finding is that **one repo holds two different copyright positions**:

- **Regular Fix ships #110's work.** `build_fix.sh:42` stages the author's `AllSkills_P` pak and
  `:44` `to-legacy`s **6 skill roots out of it**; `tools/mod_allowtags.json` is their AllowTags
  edits "vendored from the mod decode". Redistributing this build depends on their permission.
- **Trees ships none of it.** Built from current vanilla, inherits only the concept
  (`AllWeaponsUnlockableFix/WORKLOG.md:305`), which is not protectable. Free to upload.

**Two facts are needed and are not recorded anywhere:** the #110 author's *username*, and their
page's *Permissions and credits* block. Both are one page-load from
<https://www.nexusmods.com/theforeverwinter/mods/110>. Automated fetches get Cloudflare 403 /
bot-check — this needs a logged-in browser, i.e. Sylvia. Three WORKLOG entries carry an unchecked
"(optional) confirm original-author permission" box; it was fair while local-only, and stops being
optional at upload.

**Trees is not blocked by this.** If the permission answer is slow or unfavourable, Trees can ship
alone — and it is the variant `disxmfk` was running when they hit the break.

`AllWeaponsUnlockableFix` also gained a scoped MIT `LICENSE` (same text as CMSF/LootAll/
QuestHUDToggle, but carved out so it does not appear to license Fun Dog assets, #110's content, or
the built paks). The four other derivative pak repos still have no licence file at all.

Version numbers were **not** bumped — do that at upload time rather than guessing a scheme here.
Both layouts (manual-install default + MO2-compatible) are produced by the build scripts as
`dist/<name>/` plus the `.zip`; the zip already nests paks under `Mods/` so it satisfies both.
