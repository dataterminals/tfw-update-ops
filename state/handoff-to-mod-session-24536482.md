# Handoff to the mod session — build `24536482`

**Written:** 2026-08-05, by the datamine-pipeline session.
**Scope:** what the mod session inherits from upstream. Nothing here was fixed by that session,
and nothing in any mod repo was edited by it.

> **The one-line version.** The datamine is current and correct at `24536482`, all seven gates are
> 🟩, and the almanac is republished. Three things are wrong *in mod repos* because of upstream
> changes, two are wrong because of the patch, and `fwdata`'s contract changed in five ways you
> should read before running any codegen.

---

## What the patch actually did — this is the frame for everything below

Hotfix **`0.9.4.2`** (2026-08-03): *"an improvement was made to ensure all weapons have adjustments
for **height over bore**"*, plus a 3rd-person crosshair accuracy fix.

That is **`bConvergeADSAimToCamera` landing inside `FWWeaponDefinition`**. UE 5.4 serializes
unversioned properties in class order with no names, so one inserted property shifts **every later
index**. This build is a **weapon-schema patch, not a value tune.**

**Consequence:** any mod shipping a cooked `DA_WPN_*` package built against `24501089` reads
correctly up to the insertion point and garbage after it. It does not error — it degrades quietly.

The full re-decode is the control: **720 of 722 dumps byte-identical**, and both real changes are
in weapons — `DA_WPN_PLAYER_GRL00` 54→55 properties (the new one), and `DA_WPN_PLAYER_HRF02`'s
`SocketOptic` `"Optics"` → `"S_Aim"`. **That is the entire Class A exposure for this patch.**

---

## 1. Owed to users right now

### `HeavyRifleRebalanceFix` — a broken pak is live on Nexus

**Nexus #123 hosts `2.0.0`, which `24536482` broke.** Measured: all 6 rifles decode 30–33 of 55–58
properties. `WeaponDamage` is early in the class so **the damage rebalance still applies** — which
is exactly why nobody noticed. Lost: `MaxAmmo` on 5 of 6, all recoil, all aim-lag, every montage,
and `BurstFireRate` reading as the denormal `5.739719e-39`.

**v2.1 is already built and verified for `24536482` locally — 9 uncommitted files — and not
uploaded.** So the work is done; the shipping is not.

Second, independent defect on the same asset: the mod ships `DA_WPN_PLAYER_HRF02` with
`SocketOptic = "Optics"` while the live game now has **`"S_Aim"`**. As a whole-asset override it
**silently reverts the developers' change for every user** — the Group 1 staleness inversion
`asset-dependencies.md` exists to catch. Re-sourcing from the live cook picks it up for free.

### `TFWQuestItemTag` — 3 quest items go untagged, and this one is our fault

The shipped Lua manifest has **43** items. `fwdata.query.quest_items()` returns **46**. Verified by
regenerating into a scratch dir (repo left clean):

```
committed: 43   regenerated: 46
added: DataCache_Quest "Data Cache" · Octogirl_Tools_QuestItem "Octogirl's Tool Set" · TransTower_Quest_Marker "Frequency Tap"
removed: (none)
```

Those three read as ordinary salvage in the tooltip for every user of v0.1.2. **This is upstream
drift, not patch damage** — the datamine widened `is_quest_item` from a `Quest_` *prefix* test to a
`(^|_)Quest` *token* test and the manifest was never regenerated.

**Fix:** `python tools/gen_manifest.py`, commit both outputs. Then correct the four places that
still restate the superseded rule and the 43 count: `tools/gen_manifest.py:17-19`,
`README.md:16,21,33`, `docs/DESIGN.md:15,20,25,66,81,97`.

---

## 2. `fwdata` contract changes — read before running any mod codegen

Five behaviour changes landed today (`99a4616..5e08d51`). Only two repos import `fwdata`
(`forever-winter-almanac/tools/fetch_weapons.py`, `TFWQuestItemTag/tools/gen_manifest.py`) and both
were executed against the new code and run clean — but anything new should know:

| Before | Now |
|---|---|
| `get()` returned **every file in the output dir**, so `get("ai_weapons")` handed back 19 files for a 16-file decode | returns only that asset's own files (one cache leaf per asset) |
| `get()` returned `[]` when a decode produced nothing | **raises `RuntimeError`** — an empty decode is an error, not a result |
| `get("item_details")` returned 2 files (incl. the 6-row legacy `QuestItemDetailsData`) | returns 1 — the 792-row master table |
| `get("loot_objects")` always shelled out to a 433-asset decode | resolves the 151 committed dumps; works with no game installed |
| `paths.usmap()` silently fell through a bad `FW_USMAP` | **raises** on a missing `FW_USMAP`, and on >1 `.usmap` in `mappings/` |

**The decoder now exits non-zero on failure** (`2` nothing mounted, `3` name collision, `4` filter
matched nothing, `5` a decode failed, `64` bad usage). It used to exit `0` on all of these. Any
script that calls `fwextract.exe` and ignores the exit code will now surface failures it previously
swallowed — **expect some scripts to start "failing"; they were failing before, silently.**

### ⚠ New coupling: the almanac reads the HRF repo's working tree

`forever-winter-datamine/tools/parse_crafting.py` now reads **four** things out of
`HeavyRifleRebalanceFix/`:

- `dist/HeavyRifleRebalanceFix_Loosefiles/TFWWorkbench/DataTable`
- `tools/rebalance.conf`
- `docs/fix-notes.md` — needs a `Target build: **<build>**` line
- `README.md` — needs a `> **Status: …**` blockquote ← **new today**

The status line used to be a hardcoded sentence in `parse_crafting.py`, and it told users for four
days that #123 hosted a v1.1 that had not been there since 08-01. It is now read from the mod repo,
and **`parse_crafting.py` aborts rather than defaulting** if that block is missing — deliberate, same
stance `mod_target_build()` already took. **If you restructure HRF's README, keep that block.**

**After shipping v2.1:** re-run `python tools/parse_crafting.py` in the datamine and republish the
almanac, so the overlay stops saying "not yet uploaded".

---

## 3. Toolchain — 12 scripts can't run on this machine

`H:` is not mounted on SylG5. The game, the repos and the MO2 store are all on `D:`.

**No escape hatch — the source must be edited to build here:**

| Script | Hardcoded |
|---|---|
| `AllWeaponsUnlockableFix/tools/build_fix.sh` | `:33` REPO, `:34` GAME_PAKS, `:37` USMAP (only `DECODER` at `:38` is overridable) |
| `AllWeaponsUnlockableFix/tools/build_trees.sh` | `:32,:33,:36,:93` — all four |
| `TFWStaggerControl/build.sh` | `:12,:13,:14,:16` |
| `FWBehaviorLab/mods/NoESPWallhack/tools/build.sh` | `:11,:12,:14` |

AWU matters most: it is the mod whose `24479102` breakage shipped to users undetected, and it has
**no live-build verification script at all** to catch a repeat.

**Runs only if you hand-set 4–5 env vars every invocation** (`${VAR:-H:/…}`):
`ScavgirlCarryPerks/tools/` — all 7 scripts — and `TFWQuestGiverPortraitPatch/tools/build_patch.sh:16-22`.

**Already correct, copy one of these:** `HeavyRifleRebalanceFix/tools/resolve_paths.sh` (sourceable,
verified resolving under `D:` here), `UnkillablesRebalanceFix/tools/*` (D:-then-H: probe with the
machines named in a comment), `TFWQuestGiverPortraitPatch/tools/verify_build.sh` and
`TFWCharModelSelFramework/tools/verify_build.sh` (`ROOTS="D: H:"` + `pick()`).
Note QGPP's two scripts **disagree with each other in the same directory**.

### `ScavgirlCarryPerks/tools/verify_build.sh` can report a green run that verified nothing

Two independent false-pass channels:

1. `:32` existence-checks `GAME_PAKS`, `DECODER` and `USMAP` but **not `REPO`** — a wrong `REPO`
   falls through to the per-variant `[ -e "$REPO/dist/…" ]` at `:57` and prints
   `SKIP (not built)` for all four variants. Green-looking, verified nothing.
2. `:91-93` — the reversion check does `if base is None or ship is None: print("SKIPPED"); sys.exit(0)`,
   and **both** decoder calls that produce those dumps (`:40`, `:46`) redirect stderr to `/dev/null`
   under `set -uo pipefail` with no `-e`. Any decoder failure yields `SKIPPED` and still passes.

The repo's own `tools/verify_softrefs.py:25-32` names this exact failure — *"a verifier that passes
on an empty input is worse than no verifier, because it launders a non-result into a result"* — and
guards against it at `:162-171`. The reversion check never got the same guard.

### `ForeverWinterModSetup` — stale build pin, warning now fires unconditionally

`Install-ForeverWinterMods.ps1:74` pins `$KNOWN_GOOD_BUILDID = '24097213'` (three builds back);
`TFWModdingAssistant/data/knowledge.json:19` carries the same. The installer's own comment says that
when the pattern doesn't match *"the bypass fails silently and no pak mod loads"* — so this warning
is the only signal users get, and it now fires every time, which trains people to ignore it.

**The pattern itself still matches on `24536482`** (verified against the installed exe, and gate 3b
is green). So this is **just a pin bump**, not a re-derivation.

---

## 4. Explicitly NOT owed — things that look stale and are correct

- **`UnkillablesRebalanceFix` / `unkillables.json` at `24501089`.** `target_game_build` is the build
  the shipped pak was **verified** against — not a decode stamp. Its own schema says the two are
  expected to diverge. Re-verifying URF on `24536482` is optional work; **restamping it without
  re-verifying would assert something untrue.**
- **Class B 🟨 rows** (`TFWLootAll`, `TFWQuestHUDToggle`). They are not "failing" — they are not in
  SylG5's 18-mod store, so they cannot be re-tested here. Gates 3/3b are green, so the runtime is
  fine; the *loadout* is the blocker. Deploy them, or wait for SylDesk.
- **`forever-winter-skin-mods` "deployed".** It is not. The four enabled skins are third-party.
  `repos.json` was corrected today; it had disagreed with `repos.md` since 08-01.

---

## 5. Machine caveat

**⚠ Do not launch MO2 on SylDesk before remediating it.** It is still on `24501089`, its Root
Builder `GameData.json` cache and ~47 GB `Backup\` are unpurged, and its displaced `24479102` exe is
still armed. Launching applies `24536482` and then lets Root Builder restore a July-era backup over
it — the mechanism that reverted SylG5 by three builds on 08-03. Delete the cache **and** the backup
**together**, then patch.

**SylG5 is remediated and safe.** New standing rule, now in `docs/triage-pipeline.md`: compare the
shipping exe's SHA256 against the current baseline **before every session**.

---

## Upstream commits this handoff refers to

| Repo | Range | What |
|---|---|---|
| `forever-winter-datamine` | `99a4616..5e08d51` | 4 real defects fixed, usmap provenance, README rewrite |
| `forever-winter-almanac` | `057dd53` | restamped to `24536482`, published, HRF status derived |
| `tfw-update-ops` | `25255fa` | board carried forward, all 7 gates 🟩, registry made per-machine |
