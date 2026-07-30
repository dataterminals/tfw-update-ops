# Status board — 24097213 → 24479102

**The source of truth for "is this done yet."** Not memory, not the individual repo's WORKLOG.

Legend: ⬜ not started · 🟨 in progress · 🟦 blocked · 🟩 verified · ⬛ n/a this patch

Last updated: 2026-07-30 (repo created; update not yet applied)

---

## Gates

These block whole classes. Nothing below them means anything until they're resolved.

| # | Gate | Status | Notes |
|---|---|---|---|
| 0 | Baseline captured | ⬜ | **Do before giving Steam the go-ahead.** |
| 1a | AES key still valid | ⬜ | Constant across patches so far. Re-verify with AESDumpster. |
| 1b | usmap valid (or regenerated) | ⬜ | Regeneration needs experimental UE4SS + `DumpUSMAP()`. |
| 2 | Re-decode + filelist diff | ⬜ | Force-decode; do **not** trust `fwdata build all` alone. |
| 3 | RE-UE4SS attaches to new exe | ⬜ | Gates all of Class B. |
| 3b | Signature Bypass matches new exe | ⬜ | |
| 5a | TFWWorkbench reads new paks | ⬜ | Gates all of Class A rebuilds. |

## Class B — Lua (do first; cheap intel)

| Repo | Status | Finding |
|---|---|---|
| `TFWStaggerControl` | ⬜ | Was never game-verified on the old build — verify fresh, don't assume regression. |
| `TFWLootAll` | ⬜ | Re-check `W_LootUI_C` still resolves. |
| `TFWQuestHUDToggle` | ⬜ | |
| `TFWQuestItemTag` | ⬜ | Manifest must be regenerated after Stage 2 regardless. |

## Class A — Paks (expensive; diff-driven)

| Repo | Status | Finding |
|---|---|---|
| `TFWCharModelSelFramework` | ⬜ | **Check frozen slot paths first** — third-party skin authors depend on them. |
| `UnkillablesRebalanceFix` | ⬜ | Diff the 6 boss BPs specifically; BP rebuilds silently revert dev edits. |
| `AllWeaponsUnlockableFix` | ⬜ | Trees variant is the deployed one. |
| `HeavyRifleRebalanceFix` | ⬜ | |
| `ScavgirlCarryPerks` | ⬜ | 5 deployed variants. |
| `TFWQuestGiverPortraitPatch` | ⬜ | Assumes 2:1 button brush + stable texture families. |
| `forever-winter-skin-mods` | ⬜ | 4 skins deployed (Slade, Luca, Bunco-chan, Kane). |

## Class C — Datamine + data products

| Repo | Status | Finding |
|---|---|---|
| `forever-winter-datamine` | ⬜ | Upstream of everything below. |
| `forever-winter-almanac` | ⬜ | Restamp only after a real re-decode. |
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
