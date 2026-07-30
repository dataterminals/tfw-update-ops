# Status board — 24097213 → 24479102

**The source of truth for "is this done yet."** Not memory, not the individual repo's WORKLOG.

Legend: ⬜ not started · 🟨 in progress · 🟦 blocked · 🟩 verified · 🟥 confirmed broken · ⬛ n/a this patch

Last updated: 2026-07-30 17:40 EDT — **patch applied 17:34**, both baselines captured, Gate 1a
cleared, filelist diff complete. Findings: [`stage2-findings.md`](stage2-findings.md).

---

## Gates

These block whole classes. Nothing below them means anything until they're resolved.

| # | Gate | Status | Notes |
|---|---|---|---|
| 0 | Baseline captured | 🟩 | Both sides captured, 0 warnings. `pre-24479102` (76,589 entries) + `post-24479102` (76,309). Datamine tagged `baseline-24097213` @ `36b068b8`. New rollback key `6430523508700280691`. |
| 1a | AES key still valid | 🟩 | **Cleared.** Decoder mounted 76,309 files from the new paks with the key hardcoded at `decoder/Program.cs:28`. The IoStore index is AES-encrypted, so the mount *is* the test. No AESDumpster run needed. |
| 1b | usmap valid (or regenerated) | 🟩 | **Cleared.** Dumped all 43 `AIDEF_Sensor_*` (43 ok / 0 fail); **28 byte-identical** to the committed pre-patch dumps, 15 differing coherently. A stale usmap yields garbage, not 28 exact matches. **Do not regenerate.** No UE4SS needed. |
| 2 | Re-decode + filelist diff | 🟨 | Filelist diff **done** — see [`stage2-findings.md`](stage2-findings.md). Force re-decode still outstanding; the catalog is stale (`tables.json` still stamps `24097213`). |
| 3 | RE-UE4SS attaches to new exe | ⬜ | Gates all of Class B. Exe changed +70,144 B on 169 MB (0.04%) — a code patch, not an engine bump. Encouraging for AOB signatures; not proof. |
| 3b | Signature Bypass matches new exe | ⬜ | Same exe change applies. |
| 5a | TFWWorkbench reads new paks | ⬜ | Gates all of Class A rebuilds. |

## Class B — Lua (do first; cheap intel)

All of Class B is **blocked on Gate 3** (does RE-UE4SS attach to the new exe). Do not triage
individually until that clears.

| Repo | Status | Finding |
|---|---|---|
| `TFWStaggerControl` | 🟦 | Blocked on Gate 3. Was never game-verified on the old build — verify fresh, don't assume regression. |
| `TFWLootAll` | 🟦 | Blocked on Gate 3. Re-check `W_LootUI_C` still resolves — a UI crash fix shipped in this patch. |
| `TFWQuestHUDToggle` | 🟦 | Blocked on Gate 3. |
| `TFWQuestItemTag` | 🟦 | Blocked on Gate 3. Manifest must be regenerated after the re-decode regardless. |

## Class A — Paks (expensive; diff-driven)

| Repo | Status | Finding |
|---|---|---|
| `HeavyRifleRebalanceFix` | 🟥 | **DEAD — confirmed by diff.** Every target renamed or deleted: `DA_WPN_HRF*_v2` → `DA_WPN_PLAYER_HRF*`, all `FC_HRF*` curves and the `*_UpgradeTuning/` tree **deleted**. Fails silently. Needs a design decision before a rebuild — the curve-editing technique may no longer exist. |
| `TFWCharModelSelFramework` | 🟨 | Only **case-only** renames touch its territory (`BagMan`→`BAGMAN` etc.). Package IDs are case-insensitive in UE5, so likely fine — **verify frozen slot paths explicitly** at smoke test. |
| `UnkillablesRebalanceFix` | 🟨 | No boss BP appears in the real-removal list, but BP *contents* change without the path moving, and this mod silently reverts upstream BP edits. Path diff cannot clear it; needs a dump diff. |
| `AllWeaponsUnlockableFix` | 🟨 | Its DataTable targets survived (`WeaponPartStatsData`, `ItemDetailsData` intact). Probably OK — confirm exact targets. Trees variant is the deployed one. |
| `ScavgirlCarryPerks` | ⬜ | **Not enabled** — all 5 variants disabled in MO2. Lower urgency. Skill scaling was reworked (non-linear); check whether perk tables moved. |
| `TFWQuestGiverPortraitPatch` | ⬜ | **Enabled.** Assumes 2:1 button brush + stable texture families. One UI texture removed (`T_Box_SkillsIcon_Small_Red`) — different family, but check. |
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
