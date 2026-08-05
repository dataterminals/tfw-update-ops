# Registry — everything TFW we own

27 tracked repos + 1 empty stub. All remotes are `github.com/dataterminals/<name>`.
Classes are defined in [`../docs/exposure-model.md`](../docs/exposure-model.md).

**Local root is per-machine** — resolve from `repos.json` → `roots.<hostname>`, never a hardcoded
drive. SylG5: `D:\Github Repositories\`. SylDesk: `H:\Github Repositories\` (`H:\` does not exist
on SylG5, and joining it throws `DriveNotFound` rather than reporting nothing found).

Added 2026-08-05, previously absent from both halves of the registry:
- **`forever-winter-attachments`** (Class C) — a second full TFW almanac PWA sharing the almanac's
  root commit, its own remote, data stamped `24097213`. Almost certainly the retired predecessor.
  **Open:** confirm whether its GitHub Pages deployment is still live; if it is, it serves
  three-build-old economy and drop numbers under the same branding as the live almanac.
- **`TombstoneAlways`** (Class B) — pre-implementation research whose open item is a runtime
  instrumentation session, so it should be routed into the next launch window.

Deliberately **excluded**: `CleanUIRecipeTooltipFix` (Project Zomboid B42 mod — `42/media/lua/client/`,
not TFW; the name misleads).

---

## Class A — Pak / asset mods

Baked against specific game assets at specific paths. **Highest risk**: a patch that touches the
source `.uasset` silently invalidates the mod, or the game refuses to load the pak at all.

| Repo | What it is | Notes |
|---|---|---|
| `TFWCharModelSelFramework` | Skin-append framework, v0.2.x | Author owns name/portrait/mesh at **frozen slot paths** — those paths are the whole contract. Highest-risk item we own. |
| `AllWeaponsUnlockableFix` | Weapon unlock data mod (+ Trees variant) | Trees variant is the one deployed. |
| `UnkillablesRebalanceFix` | 6 boss BPs rebuilt (Option B) | BP rebuilds are the most patch-fragile technique we use. |
| `HeavyRifleRebalanceFix` | Weapon rebalance | Built via TFWWorkbench; `upstream/` + `work/` staging. |
| `ScavgirlCarryPerks` | Carry-capacity perks, 4 variants + UE4SS variant | |
| `TFWQuestGiverPortraitPatch` | Rebaked BC1 button textures + mip splice | Depends on the button brush staying 2:1 and the texture families staying put. |
| `forever-winter-skin-mods` | Skin pak collection | |

## Class B — UE4SS / Lua runtime mods

Resolve BP paths, class names and widget trees **at runtime**. Fail loudly (log errors) rather
than silently, which makes them easier to triage — but they die outright if UE4SS itself doesn't
survive the engine build.

| Repo | What it is | Notes |
|---|---|---|
| `TFWStaggerControl` | Stagger disable-by-damage-type + resistance skill tree | Pivots on the ungranted `Ability.HitReactionBlocked` tag. Public, **not yet game-verified** — verify against the new build, not the old one. |
| `TFWLootAll` | Loot-all hotkey | Open item: the per-item transfer call. Wired to decoded `W_LootUI_C`. |
| `TFWQuestHUDToggle` | Quest HUD toggle, v0.1.1 | Shipped. |
| `TFWQuestItemTag` | Quest-item tagging, v0.1.2 | Manifest generated from `fwdata.query.quest_items()` — **regenerate after re-decode**. |

## Class C — Datamine + data products

`forever-winter-datamine` is upstream of everything else in this class. Re-decode first; every
other row here is downstream of that one.

| Repo | What it is | Notes |
|---|---|---|
| `forever-winter-datamine` | **The source.** usmap + CUE4Parse decoder + dumps + `parse_*.py` + `fwdata` | usmap may need regeneration (see doctrine). `GAME_BUILD` auto-reads Steam. |
| `forever-winter-almanac` | Installable offline PWA — maps, gunsmith, datamined systems, loot economy | Data currently stamped to build `24097213`. |
| `forever-winter-maps` | Offline maps PWA (GitHub Pages) | Updated via `tools/fetch_maps.py`. |
| `NewStefanMap` | Map work | |
| `fwact` | Rust tool, v0.1.0 | Cannot be built/tested on this desktop — toolchain can't link (no `as.exe`, no MSVC). |

## Class D — Tooling / infra

Usually survives a content patch. Needs a smoke test, not a rebuild — *unless* the patch moves
the exe or changes the install layout.

| Repo | What it is |
|---|---|
| `ForeverWinterMO2Support` | MO2 support for TFW, v0.2.1 |
| `TFWWorkbenchMO2Patcher` | v1.0.0 patcher + .bat wrapper |
| `TFWWorkbenchMO2Fix` | Load-order fix + evidence |
| `TFWModdingAssistant` | C# menu-driven doctor for UE4SS/Workbench problems, v0.2.0 |
| `ForeverWinterModSetup` | Setup docs + MO2 state changelog |

## Class E — Research (reference only)

No ship surface. Findings may be *invalidated* by a patch; nothing breaks for users.
Re-verify only if a downstream fix leans on a finding.

| Repo | Subject |
|---|---|
| `tfw-weapon-modding-research` | Weapon modding |
| `tfw-imgui-research` | ImGui / live-config (concluded: C++-only, separate-window D3D12) |
| `tfworkbench-compat-research` | Workbench compatibility |
| `FWBehaviorLab` | NPC behavior |

## Stub

| Repo | State |
|---|---|
| `TFW_CyborgNerfFix` | **Empty** — `.git` only, zero commits, no working tree. Decide: build it or archive it. |

---

## Third-party dependencies (not ours, but we break when they break)

These are deployed in the MO2 instance and are hard blockers — no amount of fixing our mods
helps if these don't come back up on the new build.

| Dependency | Why it blocks |
|---|---|
| **RE-UE4SS** | Every Class B mod is dead without it. Note: *stable v3.0.1 fails on this exe* — we run the **experimental** build (fixed 5.4 AOB signatures). A new engine build may need a newer experimental. |
| **Signature Bypass** | Must match the new shipping exe. |
| **TFWWorkbench** | Build tool for Class A pak mods. If it doesn't read the new paks, Class A can't be rebuilt at all. |

## Deployment reality

The game directory is **clean by design** — mods live in the MO2 instance, never the game folder.

- MO2 instance ini: `C:\Users\sylvi\AppData\Local\ModOrganizer\The Forever Winter\ModOrganizer.ini`
**SylG5** (the machine on `24536482`, doing the work):
- Mod store: `D:\MO2_InstanceData\TheForeverWinter\mods\` (**18** folders)
- Load order: `D:\MO2_InstanceData\TheForeverWinter\profiles\Default\modlist.txt`
- Game: `D:\SteamLibrary\steamapps\common\The Forever Winter`

**SylDesk** (still on `24501089`, not measurable from SylG5):
- Mod store: `H:\MO2Instance_ModData\ForeverWinter\mods\` (39 folders)
- Load order: `H:\MO2Instance_ModData\ForeverWinter\profiles\Default\modlist.txt`
- Game: `H:\SteamLibrary\steamapps\common\The Forever Winter`

⚠ The counts differ because these are **different loadouts**, not a stale reading — the three
Class B mods the board wants functionally tested are in SylDesk's store, not SylG5's.

**Enabled as of 2026-07-30** — 12 of 39, but **only 5 of them are ours.** Corrected after reading
the actual pak filenames in the mod store; the earlier version of this section misattributed the
four skins.

| Enabled mod | Pak | Ours? |
|---|---|---|
| `CMSF v0.2 Framework` | — | **Yes** — `TFWCharModelSelFramework` |
| `QuestGiver Portrait Patch` | `110_QuestGiverPortraitPatch_P` | **Yes** — `TFWQuestGiverPortraitPatch` |
| `HeavyRifleRebalanceFix` | — | **Yes** |
| `UnkillablesRebalanceFix` | — | **Yes** |
| `AllWeaponsUnlockableTrees` | — | **Yes** — `AllWeaponsUnlockableFix`, Trees variant |
| `Bunco-chan Texture Swap` | `101-Bunko-Chan_P` | No — third-party |
| `Augmented Kane` | `102-kane_P` | No — third-party |
| `Naughty Luca` | `103-Luca_P` | No — third-party |
| `Recruiter Slade` | `104-Slade_P` | No — third-party |
| `TFWWorkbench`, `RE-UE4SS`, `Signature Bypass` | — | No — third-party blockers |

That enabled set is the **smoke-test loadout** — first thing to bring back up after a patch.

Two corrections worth carrying forward, both of which change triage priority:

- **`forever-winter-skin-mods` is NOT deployed.** It builds `SCVGIRL_UMP9_*_P` and `SHM_UMP45_*_P`
  paks; none of those is in the store, and nothing in the repo references the `101`–`104` names.
  The four enabled skins are somebody else's work. We are not on the hook to fix them, but they
  are in the loadout, so they can still break a smoke test.
- **No Class B mod is currently enabled.** `TFWLootAll`, `TFWStaggerControl` and
  `TFWQuestHUDToggle` are all disabled, `TFWQuestItemTag` is not in the store at all, and all five
  `ScavgirlCarryPerks` variants are disabled. "5 deployed variants" meant five *present*, not five
  *enabled*. Nobody is running these right now, which lowers their user-facing urgency relative to
  the five enabled Class A mods.
