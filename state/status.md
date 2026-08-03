# Status board — 24097213 → 24479102

**The source of truth for "is this done yet."** Not memory, not the individual repo's WORKLOG.

Legend: ⬜ not started · 🟨 in progress · 🟦 blocked · 🟩 verified · 🟥 confirmed broken · ⬛ n/a this patch

---

> ## 🖥 SylDesk caught up to 24501089 — 2026-08-03 11:36:51 EDT
>
> The desktop had been sitting on `24479102` with the hotfix pending since 2026-08-01
> (`AutoUpdateBehavior` is **`1`** here, not the `0` read on SylG5). Pushed through on request,
> **without launching the game** — via the Steam client's Downloads page, not `steam://install`,
> which Steam silently ignores. Verified: `StateFlags 4`, size on disk and shipping-exe SHA256
> both **exact matches** for the figures recorded from the laptop, rollback key
> `6443337773729671953` identical. Full sequence in [`build-history.md`](build-history.md).
>
> **Consequence for the board: the "never launch while an update is pending" hazard is gone on
> this machine.** A launch is now an ordinary launch. That unblocks, in one sitting, everything
> the board has been holding: the HRF damage number (780 vs 300), Gates 3/3b re-clear against the
> new exe, Gate 5a, and the two Class B functional tests.
>
> ### ⚠ BLOCKER BEFORE ANY IN-GAME MEASUREMENT — the executable reverts itself
>
> Measured before the update, the game-dir exe was the **`24097213`** binary (169,513,984 B,
> mtime 2026-07-07, matching `baselines/pre-24479102/binaries-win64.csv`) — while Steam's
> manifest had read `24479102` for four days. The real `24479102` exe is **hash-proven to be
> sitting in MO2's overwrite** at
> `overwrite\Root\Windows\ForeverWinter\Binaries\Win64\ForeverWinter-Win64-Shipping.exe`
> (`58EE4F8D…`, mtime 2026-07-30 17:22:43). Root Builder displaced the patched exe into overwrite
> and restored its stale pre-patch backup over it, on exit from the Gate 3/3b session.
>
> **`overwrite\` deploys at the highest priority, so the next session copies that `24479102` exe
> over the `24501089` one Steam just wrote.** Any measurement taken then is against the wrong
> binary and is worthless — silently, with nothing in any log naming it. **Clear it first**, and
> clear the `GameData.json` cache with it: removing the backup alone leaves the cache
> authoritative. Not done here — MO2 was running.
>
> This also scopes the Gate 3/3b greens: they were taken *during* that session, so they did test
> the correct `24479102` binary. They are still unknown against `24501089`.

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
> ~~Notable: **Pistol Ammo 23,000 → 46,000**, extraction XP 200 → 400.~~
> **Correction (2026-08-01, almanac cycle):** that item is **Thermite**, not Pistol Ammo.
> The `items` diff across both patches is two lines in `ValueV2_RareLoot.json` — Thermite
> `Value` 23,000 → 46,000 and `ExtractionExperienceValue` 200 → 400, which moves it from
> the *valuable* tier to *prime* (11,787 → 23,575 cr). Pistol ammo is unchanged: the
> generic row is `Value` 12 / XP 1, and `ValueV2_AMMO` has no pistol row at those numbers.
> There is no economy leg to the "pistols had a good two patches" story — the pistol
> damage buffs are just the near-global ×10/9 restoration, and 5 of 9 pistols got nothing.
>
> - **`AllWeaponsUnlockableFix` is CLEAR on this build** — verified directly, not inferred:
>   both variants decoded in a full live mount, **381 / 383 references checked, 0 dangling**.
>   `WeaponsDetailsData` is byte-identical to base. **The upload hold is lifted** — and the upload
>   happened the night of 2026-07-31 (regular 1.2.1 / Trees 1.1.1).
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
>
> **Addendum 2026-08-01 — it is not a CUE4Parse quirk, and it reaches the BUILD scripts.**
> `retoc` behaves the same way: asked for an asset from a `zzz_`-staged mount it extracts **both**
> colliding copies onto the same output path, so last-write-wins decides which one you ship.
> Measured while rebuilding `UnkillablesRebalanceFix` (`retoc to-legacy -f AIDEF_Euruska_Stalker`
> reports `Extracted 8` for 4 packages). So **the gate belongs in the build scripts too, not only in
> verify** — a lost race there bakes base-game content into the shipped pak with no error anywhere.
> URF's build now asserts the extract carries the mod's known scalar *and* differs from base, and
> reads the finished pak back from an **isolated** mount. **Still owed the same treatment:**
> `AllWeaponsUnlockableFix/tools/build_fix.sh` — the last build that pulls mod-side assets out of a
> `zzz_`-staged mount, and the one that is released and matters.
> ~~`HeavyRifleRebalanceFix/tools/build_fix.sh`~~ — **closed 2026-08-01, by removing the exposure
> rather than gating it.** The HRF redesign extracts every package from the **base game only**
> (no mod staged, so no collision can occur) and patches values into it, so the build has no race
> left to lose. Its *verify* wrapper still uses a full mount — necessary, since the pak must be read
> as the engine sees it — and that is where its provenance gate lives: every target must differ
> from a no-mod decode of the same asset, or the run fails.
>
> **Also: the false claim was written down.** `UnkillablesRebalanceFix/tools/verify_build.sh` stated
> that where the package path is byte-identical "the mod wins the lookup", and its exact-case pairing
> logic only ever rescued the case-*differing* packages. Corrected and negative-tested (it now fails
> on a swapped-in base dump where it previously reported a clean `276/276 (+0)`). Grepped the fleet:
> the sentence itself appears **only** in URF, but four other ported copies stage a full `zzz_` mount
> and so carry the same hazard un-gated — ~~`HeavyRifleRebalanceFix`~~ (**gated 2026-08-01**),
> `ScavgirlCarryPerks`, `TFWCharModelSelFramework`, `TFWQuestGiverPortraitPatch`. **Each needs
> auditing for a provenance
> gate**; the last three are currently 🟩/🟨 on the strength of runs made without one. (CMSF and
> TFWQGPP already assert provenance by other means — CMSF mounts each pak alone, TFWQGPP asserts
> "mount resolves to the mod's bytes" — so they are likely fine; SCP's clearance explicitly needs a
> full mount plus a gate and is the real open item.)

---

Last updated: 2026-08-03 — **SylDesk applied `24501089`** (11:36:51 EDT), verified against the
laptop's figures; and the stale-executable blocker above was found in the process. No mod status
changed today — nothing was rebuilt, deployed or launched.
Earlier 2026-08-01 — **`HeavyRifleRebalanceFix` v2.0 is live on Nexus #123 as `2.0.0`**
(Sylvia reported; upload time not captured, not yet verified by re-download). That
closes the release gap for every mod we own — nothing we ship is still broken on `24501089`.
**It went out ahead of its one in-game measurement**, which is a deliberate trade, not an
oversight: what it replaced was inert *and* actively breaking the six heavy rifles via a dead
`DataAsset` pointer, so v2.0 is an improvement under every outcome. The open question is narrow —
whether `WeaponDamage` is the per-shot damage field. The DataAsset is certainly loaded, so mag
sizes, fire rate, recoil and the headshot table apply regardless; only the damage figures are at
risk, and the failure mode is a partial mod plus a page correction. **The check is one number:
HRF01 deals ~780 or ~300.**
Earlier 2026-08-01 — **`HeavyRifleRebalanceFix` redesigned and rebuilt as v2.0**, clearing the
board's only remaining 🟥. It was dead **four** ways, not two: the two renames/deletions already on the
hit list, plus **an `FWWeaponDefinition` schema shift** (two properties inserted at index 44, shifting
52 more) that makes any rebase *worse than inert* — the mod's own cook now decodes with 30 of 57
properties and a denormal `BurstFireRate` — plus **a JSON-side break no check covered**, where all six
`WeaponsDetailsData` rows pinned the renamed-away `DA_WPN_*_v2` and `Add` overwrote the live row, so the
mod broke the six rifles rather than merely failing. Rebuilt from the live cook, 13 packages → 8, zero
0.9.2 bytes. **Two board claims corrected by measurement:** the "12th dead override"
(`T_Portrait_Manufacturing_Optics`) is a mod **addition**, not an override — the 191 pak is healthy at
18/18 — and `DT_CaliberToHeadshotMulti` was alive but silently reverting a vanilla row. **Damage
re-derived**; only RFL29 moved (vanilla tripled the Vykhlop past the mod's target, so the old 375 would
now be a nerf → 650). Verify gained a provenance gate, a value check against a shared spec file, and a
**TFWWorkbench JSON pointer check** that found a dangling mesh reference dating to 0.9.2 on its first
run. **Still 🟨, not 🟩:** the design rests on `WeaponDamage` being the damage lever, which is strong
inference and zero measurement. One launch settles it.
Earlier 2026-08-01 — **`UnkillablesRebalanceFix` rebuilt and verified on `24501089`**
(`895fa8d`), clearing the only 🟥 raised by this build: the hotfix revert is fixed, `BPC` back to
276/276 (+0), 4519 refs / 0 dangling, deployed to MO2 hash-verified and left disabled. Two
class-level findings came out of it. **(1) The banner's non-determinism is not CUE4Parse-specific
— `retoc` has it too**, extracting *both* colliding copies onto one output path; any build script
that pulls a mod's asset out of a `zzz_`-staged mount needs a provenance gate, not just the verify
wrappers. **(2) That repo's `verify_build.sh` contained the false claim in writing** ("the mod wins
the lookup" where paths are byte-identical) and has been corrected + negative-tested. **The other
ported wrappers should be checked for the same sentence.** `build_fix.sh` also made machine-portable
(it hardcoded `H:` and could not run on SylG5); the same fix is still owed to `tools/steam_state.ps1`
and any other single-machine tooling.
Earlier 2026-07-31 (3) — **permission gate closed by clean-room rebuild** (`5ed467c`):
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
| `HeavyRifleRebalanceFix` | 🟨 | **REDESIGNED AND REBUILT as v2.0 on `24501089`** — every static check green, but the whole design rests on one **unmeasured hypothesis** and that is why this is 🟨 not 🟩: nothing on disk proves `WeaponDamage` is the field the game reads for damage now. **The launch gate is one number** — HRF01 must deal ~780, not ~300. If it deals 300 the approach is wrong at the root and needs re-deriving, not tuning. **A third death was found that was not on the hit list, and it is the reason a rebase was never viable:** `FWWeaponDefinition` gained two properties at schema index 44 (`ScaleADSCameraBlendSpeed`, `ScaleADSExitCameraBlendSpeed`), shifting all 52 later properties by +2. UE5 unversioned serialization writes values in class order with no names, so the mod's 0.9.2 cook now misreads from there on — measured, `DA_WPN_HRF02_v2` yields **30 of 57 properties**, loses `MaxAmmo`/all recoil/all aim-lag/every montage, and reads `BurstFireRate` as the denormal **5.385e-42**. retoc never re-serializes property blobs, so renaming the packages would have bound them correctly and then fed the game garbage — **worse than inert**. Also **a fourth death on the JSON side that no check covered**: all six `WeaponsDetailsData` rows pinned `DataAsset` → `DA_WPN_<code>_v2` and TFWWorkbench `Add` overwrites the live row, so the mod *broke* the six rifles rather than merely failing — the identical break AWU hit on `24479102`, same field. **Two board claims corrected by measurement.** (1) **The "12th dead override" is not one.** `T_Portrait_Manufacturing_Optics` is an asset the mod **adds**, not overrides — the base game has never shipped it (July's two hits were the mod's own `BagmanTest/Content/` copies), its FPackageId hashes to a `/Game/ArtAssets/…` path the base leaves free, and it is the icon its `HeavyOptics` crafting group points at. It works *because* the base lacks it. The `191` pak is healthy: **18/18 packages bind** (CityHash64 recomputed per package name against the pak's chunk ids), meshes/textures deserialize clean. The bug was in the *check* — a basename-vs-filelist test is right for an override and exactly wrong for an addition; the two are now declared in `tools/pak191.conf` and tested in opposite directions. (2) **`DT_CaliberToHeadshotMulti` was alive but stale** — it was silently reverting vanilla's `Item.Ammo.9mm` 1.5 → 1.333333. **Build: 13 packages → 8, zero 0.9.2-cooked bytes** — every package extracted from the live cook and value-patched. New `tools/patch_props.py` resolves offsets from serialization order (on HRF01, `0.1` is both `FireRate` and `RecoilArmAngle`) and **aborts rather than guessing**; it did, twice, in development. `tools/rebalance.conf` is the single source of truth for the numbers — build applies it, verify checks against it, so they cannot drift. **Damage re-derived**: absolutes kept except **RFL29**, where vanilla overtook the mod (175 → **600**, past the mod's 375), so 375 would now be a **37.5% nerf** — re-derived to **650**. RFL29 is the **Vykhlop**; the SVD is **RFL20** and got its own buff (7.62×54R headshot 1.5 → 3.0). `RecoilWristPitch` dropped — vanilla zeroed it game-wide. **Verify rebuilt**: provenance gate + value check + opposite-direction presence + **TFWWorkbench JSON pointers** (new; nothing covered the JSON before). All 7 pass. **JSON check found a bug on its first run** — item `WPN_RFL29_MAG_130_02` pointed at `SM_WPN_RFL29_MAG_130_02`, **a mesh that has never existed in any build or in the mod's own pak**; an original-mod slip from 0.9.2, repointed to `_01`. Still ⬜ **in-game**; mod left **disabled** in MO2 as found. |
| `TFWCharModelSelFramework` | 🟩 | **Verified on `24501089`** (`cb6f944`) — **401 dumps, 1591 references, 0 dangling** across framework, `release-v0.2.0` and the octogirl author pak, using a deterministic isolated mount. Filter coverage proven 100% by mounting each pak alone (framework = exactly 199 packages; octogirl = 3). **Frozen contract handled:** `/Game/CMSF/` is `--ignore`d, and removing the ignore surfaces 576 dangling of which **every one is inside `/Game/CMSF/` and none outside** — so it suppresses exactly the ABI. The **inverted assertion is wired to fail the run**: the live filelist carries **0** entries under `ForeverWinter/Content/CMSF/`, which is the required state — the devs have not collided with the namespace. 100 of the surviving refs point into 54 distinct live base packages (vanilla meshes, `T_Menu_PickCharacter_Portrait_*`), which is exactly the surface a dev rename would break; all resolve. This repo is where the **non-deterministic mount** finding came from — see the banner. |
| `UnkillablesRebalanceFix` | 🟩 | **REBUILT AND VERIFIED ON `24501089`** (`895fa8d`) — the hotfix revert is fixed. `BPC_IncomingDamageMod` now **276 base / 276 ship (+0)**, was dropping 13; **11 shipped packages, 17 dumps, 0 uncovered · 4519 refs, 0 dangling · 0 properties dropped**. `.ucas` **526,684 → 542,979 B** (`.pak` unchanged) — good size, check exactly. The finding was first reproduced *without* the decoder, by string-searching the `to-legacy` output: live base carries `Attack Add` x3 / `Modify Attack Add` / `Big boi Sniper Rifles` / `Noisy Player`, the stale pak **x0 of each**. Provenance proven **by value, not just by hash** — all 11 dumps carry the mod's numbers and **none** of the base numbers (boss HP x2 each with `1E+09` absent, Stalkers `1000` x2, BPC `61870`x4 `108700`x7 `86870`x2 `128000`x3 `43000`x2 `72000`x1 = the 19 patched doubles). **This repo's wrapper carried the false claim the banner warns about** — `verify_build.sh` asserted that where the package path is byte-identical "the mod wins the lookup". It does not; both copies write to the same filename and the last write wins, and exact-case pairing cannot help because there is only ever one file. Replaced with a real provenance gate (shipped dump must differ from base), **negative-tested**: it FAILS on a swapped-in base BPC dump where the old logic reported `OK BPC 276/276 (+0)`. Same hazard found in **retoc**, not just CUE4Parse — it extracts *both* colliding copies onto one output path, so `build_fix.sh` gained a gate asserting the Stalker extract carries the mod's `1000.0f` x2. **`build_fix.sh` is now machine-portable** (env → candidates, `D:` before `H:`); it previously hardcoded `H:` and could not run on SylG5 at all. **`upstream/` is not on this machine** — the pristine Nexus pak's cooked binaries are gitignored, so Option A fell back to the previously shipped `dist/`; proven lossless because all 4 rebuilt AIDEF payloads came out **byte-identical** to the shipped ones. New `tools/expected_package_ids.txt` pins the 11 FPackageIds (a moved id = a silent no-op override; also pins the `Euruska/Toothy` casing the live build spells `TOOTHY`) — 11/11 match. **Deployed to MO2 hash-verified, left disabled as found.** Still ⬜ **in-game** — never launched (`AutoUpdateBehavior 0`). **Both checks remain structural**, so this does **not** clear the 4 Option-A Stalker AIDEFs (frozen at the 0.9.2.2 cook) for BP graph drift; that risk is unchanged and unresolved. Nexus #124 needs the v1.2 zip once a launch is green. |
| `AllWeaponsUnlockableFix` | 🟩 | **Regression found & fixed 2026-07-31** (`d12007d`): the patch-rebase rebuild **resurrected the two Session-2 carry grafts** on ScavGirl's root (13 children again — `Shaman_PackMule_v1` + `OldMan_RIG01_AllowUse`, duplicate "Equip Runner" and all). Cause: Session 2 fixed the *artifact*, `build_fix.sh` kept pulling roots from `upstream/`; first end-to-end rebuild since brought the defect back, and `verify_softrefs` is blind to it — the grafts dangle nothing. Caught **before Nexus** via the SCP-interop question. Now the build *strips* the grafts (step 3) and *asserts* every root's graft set against `tools/fix_expected_grafts.json` (step 8, `verify_grafts.py`, negative-tested). Rebuilt 13→11, redeployed to MO2 hash-verified. **Good `.ucas` = 110,000 B; the regressed one is 110,008** — 8 bytes apart, check exactly. Trees unaffected. Earlier history: **BOTH VARIANTS FIXED** (`fe522fb`). User-confirmed break: every `WeaponsDetailsData` row pinned `DataAsset` → `DA_WPN_<code>_v2`, all renamed to `DA_WPN_PLAYER_<code>` by the patch, so every weapon lost its definition pointer. Measured in a full mount — deployed Trees **56/56 dangling**, regular **56/56 dangling**; **both rebuilds now 0/53** ✅. Root cause + ruled-out alternatives: [`rootcause-awu-customization-ui.md`](rootcause-awu-customization-ui.md). **Deployed to MO2 2026-07-30** (both variants, hash-verified; previous paks backed up). **Not yet released on Nexus** — users are still served the broken paks. Both mods are currently **disabled** in the profile, so re-enable before testing. **Class-level fix added** (`b4b01e4`): `tools/verify_softrefs.py` asserts every `AssetPathName`/`ObjectPath` in a decoded pak resolves against a freshly-regenerated live filelist, and now gates **both** builds. Proved against the real defect — flags **63 dangling** on the broken 07-20 pak, **0** on both rebuilds. `build_fix.sh` previously had *no* content verification at all. **Portable to every other pak mod we own.** |
| `ScavgirlCarryPerks` | 🟨 | **Its clearance needs re-measuring — the method was unsound** (`bd7c87d`). `verify_build.sh` uses the full-game `zzz_` staging trick, now measured to be non-deterministic (see banner), and **every SCP variant overrides a base asset** — exactly the shape that can grade vanilla and report clean. Its `verify_softrefs.py` copy also predated today's fix, so it would have passed an empty scan; now synced to canonical. An isolated re-run on `24501089` cleared all four variants with provenance proven (1 dump each, all differing from base, 0 dangling) — but **only 1 reference each**, because SCP's real exposure is *hard imports* into other characters' packages and those null out under isolation. **Isolation is the wrong tool for this mod**; it needs the full mount plus a provenance gate. Structurally it is safe on this build regardless: the filelist is **identical** across `24479102` → `24501089`, so nothing it points at can have moved. Prior finding, method caveat aside: **Survives unchanged — verified 2026-07-31 (`5007c18`), no rebuild needed.** Override surface is **one asset**: `retoc list` shows all four variants shipping a single package, id `e2129fe5f6accc68` = `SD_Skill_EarlyAccess_ScavGirl_ROOT` (the Combined variants merge AWU's weapon grafts into that same ROOT rather than shipping a second asset). **No `WeaponsDetailsData` override**, so it is structurally immune to the stale-`DataAsset` break that hit AWU. Its actual exposure is a whole-asset ROOT override *referencing* nodes in other characters' packages — checked both ways: **0 dangling refs** and **0 native children dropped**, all four variants, against a filelist regenerated from the live game. Near-miss: the patch renamed `ActiveCharacters/OldMan/` → `Oldman/` (27 assets) and our paks have the old casing baked in — **it binds anyway**, proven by 0 null `ChildSkills` / 0 `UnknownPackage` in a full mount, not merely by the case-insensitive checker passing. `verify_softrefs.py` **ported** + new `tools/verify_build.sh` (reversion check negative-tested). Still ⬜ **in-game on 24479102**; all 5 variants remain disabled in MO2. **Interop addendum 07-31 (corrected):** **SCP is RELEASED on Nexus** — the repo's unchecked "Nexus upload" box was stale. That kills the first theory about the "SCP needs an update for newest AWU" reports: the AWU carry-graft regression **never left this machine**, so Nexus users can't be hitting it. Likely causes, in order: (1) the **base-game Carry Capacity bug** (`docs/carry-capacity.md` — effect drops on location entry; page warning still unposted), (2) the **ScavGirl-ROOT collision** if AWU's pak wins mount order (launch-gated), (3) pre-patch AWU's dead-pointer table making the combo look broken. SCP-Combined's 4 weapon grafts still match both AWU variants' design. **Not recorded anywhere: SCP + AWU Nexus page numbers, report wording, reporters' variant.** |
| `TFWQuestGiverPortraitPatch` | 🟩 | **Verified on `24501089`** (`19214cb`). **The override surface is 3 textures, not 122** — 122 is the vanilla `Quest/` folder population; `build_patch.sh` keeps only the `mapping.tsv` targets. Confirmed by mounting the pak alone: 6 files (3 `.uasset` + 3 `.ubulk`) = Kane / Luca / Slade `_ButtonFramed`. The softref check is **legitimately vacuous** here — cooked `Texture2D` exports hold no `AssetPathName`/`ObjectPath` at all — so `--allow-empty` was **established by running without it first** (exit 2) and inspecting the dumps, and the wrapper asserts what actually matters instead: **baked** (mod pixels ≠ vanilla), **landed** (mount resolves to the mod's bytes), **geometry** (1024x512 `PF_DXT1` mip0 = 262144). All 3/3, negative control fails correctly. Still not enabled in `modlist.txt:28`; still assumes a 2:1 button brush. |
| `forever-winter-skin-mods` | ⬛ | **Not deployed — registry was wrong.** Builds `SCVGIRL_UMP9_*` / `SHM_UMP45_*`; none in the MO2 store. The 4 enabled skins (`101`–`104`) are **third-party**, not ours. Not our fix, but they sit in the smoke-test loadout. |

## Class C — Datamine + data products

| Repo | Status | Finding |
|---|---|---|
| `forever-winter-datamine` | 🟩 | **Re-decoded and current at `24501089`** (`c56bb36`). All **722** tracked dumps re-decoded from the live game, **72 promoted**, catalog rebuilt and stamped `24501089`; `lootobjects` held at its curated 151-of-437. The staleness gap is closed: the 9 non-taxonomy subdirs are now current for the first time since before 24479102. **Added `tools/redecode_check.py`** — decodes by committed basename rather than by filter, so curation is preserved by construction and no subdir can silently widen; re-running it after promotion reports 0 changed across all 13 subdirs. `FALLBACK_BUILD` bumped. Earlier at `24479102`: usmap regenerated, 14 dumps of deleted assets removed, 74 weapon dumps promoted — **weapons only**, which is what cost the attribution on the other 40 this cycle. |
| `forever-winter-almanac` | 🟩 | **Current at `24501089`** (`a47659e`, `51beb91`, `d89021e`). The Stability rework landed as a rework, not a restamp: the published dispersion analysis is **retired**, replaced by the evidence that the system was removed — 0 of 76,309 live files match `*Stability*`, 0 `UpgradeTuning`, 0 player `DA_WPN_PLAYER_*_v2`, and the 20 surviving `FC_*` are all global. The stat still exists on attachments (`WeaponPartStatsData`, 324 of 633 rows non-zero, byte-identical to the previous build), so the page states that the input survives and the transfer function is gone, with the caveat that this only disproves the *data-driven* path — the logic may have moved to compiled C++. **Root cause of the drift was not staleness:** `weapons.json` was a wiki scrape, so it is now generated from `DA_WPN_PLAYER_*` + `WeaponsDetailsData` + `ValueV2_WEAPONS`, wiki kept only for name/class/accuracy/recoil/stability. That found **more than the damage refresh** — 17 of 51 damage wrong *and* **44 of 51 XP wrong**, plus 3 magazines, 3 rates of fire, 2 values. Shotguns were a units mismatch, not an 11% drift: damage is stored **per pellet** with `NumberOfBuckshots` 20, so the app now shows per-pellet, pellet count and spread total. Detection gained the `HoldingPistol` modifier (1.2/0.8 on all 15 sensors with a modifier table — identical to a Stealth Rig), recorded without a build claim since it spans two patches. **Two board corrections:** there is no Gunsmith section in this repo (`grep -ri gunsmith` is empty), and see the Pistol Ammo/Thermite correction above. Also disarmed `tools/fetch_items.py`, which still rebuilt the datamined `economy.json` from the wiki. **Mod overlays fixed too** (`2d26e46`, `578a61f`, `8de506e`): `unkillables.json` picked up `24501089` once `URF 0cc0a19` + `datamine 2bc6b35` removed the hardcoded fallback; **the Heavy Rifles overlay was describing Meganiikko's upstream 0.9.2, which this build disabled** — 11 of 13 packages binding to nothing, so the tab published numbers the game never applies. Repointed at the v2.0 rebuild and now **read from `HeavyRifleRebalanceFix/tools/rebalance.conf`** rather than transcribed, which caught three stale values: HRF01 730→**780**, HRF02 28000→**27000**, RFL29 375→**650**. That last one is the one that bit: vanilla tripled the Vykhlop 175→600 past the mod's 375, so with the overlay on the site showed it hitting **37.5% weaker than vanilla** while its own note promised buffs — invisible until `weapons.json` was corrected to 600. VKS magazines were also renamed A/B→**B/C** to match the shipped mod. Attribution was half-and-half (credited Meganiikko, **#76**, while linking the community fix, **#123**); both are recorded now, plus a rendered `meta.status` because **v2.0 is built and statically verified but NOT released** — #123 still hosts the disabled v1.1. `crafting.json` gained a real `build` field after separating the vanilla decode build from the mod's target build, which had briefly been one constant. **Attachments/parts audited clean:** 279 entries joined to `WeaponPartStatsData` by display name via `ItemDetailsData`, **0 differing values** — the wiki transcribed the raw floats exactly, so those stay wiki-sourced on evidence rather than assumption. **`detection.json` is now generated** (`d06f066` / datamine `d19d32c`): `parse_detection.py` only ever *printed* an analysis for someone to transcribe, which is why the `HoldingPistol` modifier had to be added by hand this cycle. It now writes the file and **aborts** if the dumps contain a sensor, stealth tag or noise event no row claims (all five abort paths tested, 6/6 with a passing baseline), so the next patch that adds one breaks the build instead of publishing a hole. Found in passing: the old noise reader only checked `TravelDistance`, so every event defining only `PathTravelDistance` read as "(none)" — including `Player_Sprinting` (750 → 7.5 m). Also adds the **AT-43 railgun noise event at 10,000 m**, the loudest in the game by 10×, previously unpublished. **`drops-model.json` is generated too** (`cf14997` / datamine `parse_crate_types.py` → `parse_drops.py`), which closes the last hand-maintained dataset. That one had drifted furthest: **the wreck table listed 8 pools and the game has 16** — both Eurasian and Water Thief drones (24-item pools, identical to the Europan one that *was* listed), both vehicle cores, both med-mech weapon arms, the Red Baron quest Exo and the Assault HK corpse were all absent. It also **stated three times that every wreck can come up empty, which is false**: five pools guarantee a payout, from 6,771 cr (vehicle core) to **100,000 cr (Assault HK)**. That sentence is now computed from the rows, and the table gained a Floor column. Seven abort paths tested, 7/7 with a passing baseline. **Nothing in the almanac's `data/` is hand-maintained any more.** One follow-up for the datamine, not the almanac: `parse_loot.py` publishes no source for `Quest_Grabber_Sac` (the Grabber's sac, an 18-item pool), so the Drops panel excludes it rather than link to a dead end — that looks like a gap in `parse_loot`, not a decision. |
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
| `AllWeaponsUnlockableFix` (regular) | 🟩 `5ed467c` — **clean-room rebuild from vanilla** (5 assets, zero upstream bytes), A/B-identical, graft sets asserted. **Re-verified on `24501089` 2026-08-01: 381 refs checked, 0 dangling** | 🟩 2026-07-31 (clean-room deployed) | 🟩 **CLEARED by rebuild** — ships nothing of LassyMorphee's; design credited. DM still owed (their carry-slip bug relay) | 🟩 **SHIPPED 2026-07-31 17:25Z as `1.2.1`** (from 1.1.0), on page **133**. **Verified 2026-08-01** by re-downloading from the live page: all 4 zip entries byte-identical to `dist/`, inner `.ucas` = 75,174 B |
| `AllWeaponsUnlockableFix` (Trees) | 🟩 `3dafbc5`, ALL CHECKS PASSED. **Re-verified on `24501089` 2026-08-01: 383 refs checked, 0 dangling** | 🟩 2026-07-30 | 🟩 n/a — inherits no #110 content | 🟨 **SHIPPED 2026-07-31 17:25Z as `1.1.1`** (from 1.0.0), on page **133** alongside Regular. Pak verified 2026-08-01: 3 container entries byte-identical to `dist/`, `.ucas` = 79,239 B. **But the shipped `readme.txt` is the 07-20 copy** — `build_trees.sh` never re-run after `3808a4d`/`591a233`, so it names the pre-rename pak in the uninstall step and omits LassyMorphee. Fixed in `dist/`; **re-upload owed** |
| `HeavyRifleRebalanceFix` | 🟨 **v2.0 redesigned and rebuilt** — 8 packages, zero 0.9.2 bytes, 7/7 static checks green. **The one in-game number is still unrecorded** (HRF01 = 780 vs 300) | ⬜ not deployed — left disabled in MO2 as found | 🟨 **raised and accepted by Sylvia 2026-08-01** — the position is knowingly held, not overlooked. Original mod by *Meganiikko* (#76); the `191` mesh pak ships their cooked content verbatim, so unlike AWU-regular this one was **not** cleared by a clean-room rebuild. Reopen only if the author objects | 🟨 **SHIPPED 2026-08-01 as `2.0.0`**, Sylvia reported — on page **123**, superseding the v1.1 build that was inert and breaking the six rifles. Upload time not captured; **not yet verified by re-download** (AWU's uploads were byte-compared against `dist/` from the live page — worth doing here too, since this one replaces an actively harmful build). **Build-compatibility note on the page: Sylvia confirmed handled 2026-08-01** — not independently checked from here |

~~**Release is the remaining user-facing gap.**~~ **All three are now released** — AWU regular
1.2.1 / Trees 1.1.1 on 2026-07-31 night, `HeavyRifleRebalanceFix` v2.0 on 2026-08-01. **No mod we
own is still serving a build that is broken on `24501089`.** Plain-language substance for the
pages, if any prose is still owed, is in
[`rootcause-awu-customization-ui.md`](rootcause-awu-customization-ui.md).

Two upload-side items remain open, neither of them a broken pak: AWU-Trees ships a stale
`readme.txt` (re-upload owed), and HRF shipped **before** its damage lever was measured in-game —
so if that check comes back wrong, the page needs a correction rather than a rebuild-and-hope.

**Record-keeping note:** these repos do not observe Nexus. This table's "Nexus updated" column is
only ever as fresh as the last time Sylvia said something — on 2026-08-01 it read ⬜ for both AWU
variants that had already been live for a day. Ask before asserting publication state.

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
