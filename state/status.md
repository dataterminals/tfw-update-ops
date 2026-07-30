# Status board — 24097213 → 24479102

**The source of truth for "is this done yet."** Not memory, not the individual repo's WORKLOG.

Legend: ⬜ not started · 🟨 in progress · 🟦 blocked · 🟩 verified · 🟥 confirmed broken · ⬛ n/a this patch

Last updated: 2026-07-30 17:55 EDT — **patch applied 17:34.** Gates 0, 1a, 1b, 3 and 3b all
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
| 2 | Re-decode + filelist diff | 🟨 | Filelist diff **done** — see [`stage2-findings.md`](stage2-findings.md). Force re-decode still outstanding; the catalog is stale (`tables.json` still stamps `24097213`). |
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
| `HeavyRifleRebalanceFix` | 🟥 | **DEAD — needs redesign, not a rebase.** 11 of its 13 override targets are gone (`build_fix.sh` names them). The 6 `DA_WPN_*_v2` are renamed → rebasable; but all 5 `FC_*_Damage` curves are **deleted**, and the curve layer is gone game-wide (`FC_*_Damage` 44→0; float curves under `FW/Weapons` 226→11). Per the mod's own `docs/diagnosis.md`, the **curve** is the real damage lever and the DA scalar is "cosmetic" — so a pure rebase would look rebuilt and do nothing. Hypothesis to test: `WeaponDamage` on `DA_WPN_PLAYER_*` is now authoritative. **Verify before building.** |
| `TFWCharModelSelFramework` | 🟨 | **All 5 core deps survive** with identical counts: `DT_SkinUIData`, `ST_FW_UI_Skins`, `GA_Player_ChangeSkin`, `SK_SCV_FL` (7), `BP_Player_*` (6). Only case-only renames touch its territory. Structurally intact — still **verify frozen slot paths** at smoke test, since those are the third-party contract. |
| `UnkillablesRebalanceFix` | 🟨 | **All 8 override targets survive** with identical counts (`build_fix.sh`): the 6 boss BPs (`MeatMan`, `OrgaMech`, `ShieldOfficer`, `Mech_Toothy`, `MotherCourage`, `Opal`), `AIDEF_Euruska_Stalker` ×4, `BPC_IncomingDamageMod`. Path diff clean — but BP *contents* change without the path moving, and this mod silently reverts upstream BP edits, so this still needs a dump diff to clear. |
| `AllWeaponsUnlockableFix` | 🟨 | **All 6 `EarlyAccess_*_Root` skill trees survive**, as do `WeaponPartStatsData` / `ItemDetailsData`. Structurally intact. Trees variant is the deployed one. |
| `ScavgirlCarryPerks` | ⬜ | **Not enabled** — all 5 variants disabled in MO2. Lower urgency. Skill scaling was reworked (non-linear); check whether perk tables moved. |
| `TFWQuestGiverPortraitPatch` | 🟨 | **Enabled.** Its whole source dir `FW/UI/MainMenu/Textures/Quest` survives — **122 textures, count unchanged**. Structurally intact. Still assumes a 2:1 button brush; the one removed UI texture (`T_Box_SkillsIcon_Small_Red`) is a different family. |
| `forever-winter-skin-mods` | ⬛ | **Not deployed — registry was wrong.** Builds `SCVGIRL_UMP9_*` / `SHM_UMP45_*`; none in the MO2 store. The 4 enabled skins (`101`–`104`) are **third-party**, not ours. Not our fix, but they sit in the smoke-test loadout. |

## Class C — Datamine + data products

| Repo | Status | Finding |
|---|---|---|
| `forever-winter-datamine` | 🟥 | **Weapon dumps invalid.** `DA_WPN_RFL01_v2` and `FC_RFL00_Stability` no longer exist. Re-decode against the new `DA_WPN_PLAYER_*` / `DA_WPN_AI_*` layout; `assets.py` logical names need updating. Upstream of everything below. |
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

| Repo | Version bumped | Both layouts packaged | Nexus updated |
|---|---|---|---|
| *(fill as Class A/B clear)* | | | |
