# Status board — 24536482 → 25071553

**The source of truth for "is this done yet."** Not memory, not the individual repo's WORKLOG.

Legend: ⬜ not started · 🟨 in progress · 🟦 blocked · 🟩 verified · 🟥 confirmed broken · ⬛ n/a this patch

---

> ## 🔺 CURRENT CYCLE — build 25071553, landed 2026-09-03, recorded 2026-09-10
>
> **Read this before anything below it.** Everything in the older banners and in the class tables
> was written for `24536482` or earlier. Where a row has been restamped this cycle it says so;
> where it has not, treat it as history, not as state.
>
> **The board was a full cycle stale until today.** `81c6db5` (2026-09-09) captured the
> `post-25071553` baseline and wrote [`build-history.md`](build-history.md), but never touched this
> file — so it carried "all seven gates green" for a week against a build that has two red gates.
> That is the Rule 1 failure this file exists to prevent. **The board is the deliverable, not the
> commit message.**
>
> ### Machine state — checked 2026-09-10, not assumed
>
> | | |
> |---|---|
> | Installed / target build | `25071553`, `StateFlags 4`, **no update pending** |
> | Rollback key | `4492887131597018203` |
> | Shipping exe | `169,740,288 B` / `D87AE674…`, mtime 2026-09-03 11:57 — **matches `post-25071553/binaries-win64.csv`** |
> | Root Builder | ⚠ **ARMED** — no MO2 launch since 2026-08-04, no `UE4SS.log` anywhere under the instance, no `overwrite\Root` |
> | SylDesk | **Two cycles behind** — still `24501089`, cache + ~47 GB backup unremediated, displaced exe still armed |
>
> The standing pre-session exe check **passes**: Steam's own patch write is in place and Root
> Builder has not reverted anything. That is because nothing has launched, not because the
> mechanism is fixed. **Clear `GameData.json` AND its sibling `Backup\` together before the next
> launch.**
>
> ### 🚨 DOCTRINE — this rig cannot test any integrity path, and never could
>
> **The MO2 profile runs `Signature Bypass` (`dsound.dll`) `+`enabled.** Whatever
> `FWModIntegritySubsystem` (below) does about container or manifest validation, **no measurement
> ever taken on SylG5 is a valid control for it.** A clean local launch proves the bypass works —
> not that the mods are undetected, and not that a user without the bypass sees what we see.
>
> This has been true of every measurement this project has made and was never written down. **Add
> it to the pre-launch routine beside the exe-hash check:** before concluding *"mods are fine"* from
> a local session, state which of `Signature Bypass` / `RE-UE4SS` were loaded. Testing the integrity
> path for real means disabling the bypass — a separate, deliberate experiment.
>
> ### Two gates are red, and one action clears both
>
> - **Gate 1b 🟥 — the usmap is stale.** `FWWeaponDefinition` on `DA_WPN_PLAYER_HRF01` decodes
>   **30 properties where `provenance.json` records 57**. No error, plausible values, exit 0 — the
>   documented silent-failure mode verbatim. **Every value-level decode against this build is void.**
>   Structural findings that read no type map (the filelist; raw `retoc to-legacy` byte comparison)
>   are the only things this cycle may act on.
> - **Gate 3 ⬜ — unattempted, not merely unscored.** Nothing has run against this exe. All of
>   Class B is unknown, including the UE4SS `-894` pin against a September binary.
>
> **The single unblocking action is one sitting at the machine:** clear Root Builder → disable
> `CMSF v0.2.1 dev` (Jul 25 pak, will crash) → launch → `DumpUSMAP()` → exit. Gate 3, gate 3b and
> every Class B row fall out of the same launch for free.
>
> ### ⚠ "1b is red so everything is void" is too coarse — and the cycle is not frozen
>
> Full rule in [`docs/gate-1b-partial-validity.md`](../docs/gate-1b-partial-validity.md). The
> distinction is whether a conclusion came from the **type map** or from the package's own **name
> table**:
>
> - **Sound today:** raw `retoc to-legacy` byte comparison (passed no usmap at all — *the gold
>   standard while 1b is red*), filelist and path existence, `FPackageId` binding, DataTable **row
>   keys**, soft-path **strings**, script-object name-set diffs, container structure, and all
>   deployment / load-order / ship-state auditing.
> - **Void:** property counts, property names, every scalar value, "0 properties dropped", and any
>   catalog rebuilt from a decode.
> - **The trap — relative comparison is only half safe.** A detected **difference** is sound. A
>   detected **identity is not**: a stale map *truncates* the read (30 of 57 right now), so anything
>   past the truncation point is never compared and reports as clean. **"Identical" means "identical
>   in the part the map could still reach."** The same mechanism makes a softref check report *0
>   dangling* because it never reached the properties — a false green of exactly the vacuous-check
>   family this project keeps rediscovering.
>
> **Three repos' verifiers were found this cycle to run to completion and exit 0 against the stale
> map** — `UnkillablesRebalanceFix` (`verify_build.sh:97,159`), `HeavyRifleRebalanceFix` (both
> scripts), and `TFWCharModelSelFramework` (checks `[3]`/`[4]`, self-reported). **Nothing may be
> called "fully green" while 1b is red.** Report which checks ran soundly and which are void.
>
> ### 🔍 The script-object store, and an undisclosed mod-detection subsystem
>
> Full working in [`scriptobjects-25071553.md`](scriptobjects-25071553.md). The short version:
>
> - ✅ **Container staleness is REFUTED — the route is closed.** Proposed as CMSF's crash cause,
>   tested three ways, and dead: `FScriptObjectEntry` stores an **explicit 64-bit `GlobalIndex`**,
>   and across the two cooks **zero of 46,497 shared paths changed id while 99.7% changed array
>   position**. Settled by artifact: the actually-crashing July `CMSF_Core_9_P` was unpacked and all
>   **220 ScriptImports across its 199 packages resolve against the live store, zero dangling.**
>   **Measured exposure is zero everywhere. Do not tell any repo to rebuild on this basis** — and
>   the CMSF rebuild is a **null intervention**, 193 of 199 packages byte-identical to the July pak.
> - The durable predicate is **removals, not growth**: a pak is exposed iff its ScriptImport set
>   intersects `{FWReplicatedAimRecord, FWHardpointContainerComponent.OnRep_AimReplication}`.
>   The +5,258 bytes that started this are causally inert.
> - **CMSF's crash remains unexplained.** The better-formed untested candidate is **`PackageImport`
>   public-export-hash staleness** — resolved against the *live cook's* base packages rather than
>   the script store, fatal in shipping when a base package's public export is renamed, and
>   `0.9.5.0` rebuilt the AI subsystem from the ground up. **It generalises further than
>   ScriptImports do.**
> - **`FWModIntegritySubsystem`** appears in the live cook and not in July's: mod detection with
>   party-wide replication (`ServerReportPotentiallyModded`, `IsPartyMemberPotentiallyModded`,
>   `OnRep_PotentiallyModded`) plus a weapon-damage override path gated on `IsStockWeapon`
>   (`GetBaseWeaponDamage` / `SetBaseWeaponDamage` / `ClearWeaponDamageOverride`). **In no patch
>   note.** Blast radius is the weapon mods, not the cosmetics.
> - **✅ Dated exactly: it shipped at `24479102`, 2026-07-30 — six weeks ago, and symptomless
>   since.** Two unrelated artifacts converge. This repo's baselines put `FWPakManifest.json` (the
>   anti-tamper manifest) at that build — absent in `pre-24479102`, present in `post-`, and it is
>   precisely the 118→119 pak-row delta we recorded as a *count* without ever reading what the new
>   row was. The datamine's archived per-build usmaps independently put the
>   `FWModIntegritySubsystem` *type* at the same build. **So it is not a crash candidate for this
>   cycle** — but it stays a real concern for the weapon mods in multiplayer. A usmap dates the
>   type, not the moment behaviour behind it was switched on.
> - **Lesson worth keeping:** a changed row count is a question, not a datum. **Read what the new
>   row is.** This one sat unread in a baseline for six weeks.
>
> ### Restamp status — what this cycle actually knows
>
> A read-only audit was run across the board's rows on 2026-09-10. **It completed 7 of 13 repos and
> was cut off by a session limit before the adversarial-verification pass ran on any of them.**
> The 7 restamped rows below are therefore **single-source and unrefuted** — good evidence, not
> confirmed evidence. They are marked ⚠ *unverified restamp*. The 6 that never ran are unchanged
> and still carry their `24536482`-or-older text: **`AllWeaponsUnlockableFix`, `TFWStaggerControl`,
> `TFWQuestGiverPortraitPatch`, `forever-winter-datamine`, `forever-winter-almanac`,
> `TombstoneAlways`.** `TFWCharModelSelFramework` is owned by a parallel session this cycle and is
> deliberately not restamped here.
>
> **2026-09-22 — two of those six are done:** `forever-winter-datamine` and `forever-winter-almanac` are restamped to `25071553` from a full 722-dump re-decode (gate 2 🟩, 1b corroborated). Both are pushed, and Pages is confirmed serving the almanac at `dfe077c`. See both Class C rows.
>
> **The one thing the audit found that is not gate-blocked:** `UnkillablesRebalanceFix` is
> **ENABLED in the MO2 profile** (`+UnkillablesRebalanceFix`) carrying the **v1.2 pak**, two builds
> stale — while a verified v1.3 sits unshipped in `dist/`. The old board row said "left disabled as
> found". That is now false on both counts, and it makes the profile a smoke-test contaminant.
>
> **2026-09-22 correction:** v1.3 was never unshipped. Nexus lists it as #124's main file since
> 2026-08-24, and on `25071553` it **crashes the game on load** (reproduced to the byte). `dist/` now
> holds v1.4, built and verified, awaiting the in-game test. The MO2 profile still carries v1.2.
> See the `UnkillablesRebalanceFix` row.

---

> ## ⚠ DOCTRINE — Root Builder reverts the install after every patch. Clear cache + backup TOGETHER.
>
> **SylG5 is remediated and safe to launch (2026-08-04); ⚠ SylDesk is NOT — see "Remediation" below.**
> Standing rule this bought: **compare the shipping exe's SHA256 against the current baseline before
> every session.** The baselines have always captured it; nothing ever read it, and that one check
> would have caught this four days earlier on SylDesk. On SylG5 right now the exe is
> `169,641,472 B` / `5D9F12E6…`, an exact match for `baselines/post-24536482/binaries-win64.csv`.
>
> <details><summary>The 2026-08-03 23:05 incident, in full (resolved — kept because the mechanism recurs every patch)</summary>
>
> **Root Builder restored stale pre-patch backups over the patched game on exit.** Same mechanism
> SylDesk found with its executable on 2026-08-03, at far greater scale. Measured immediately
> after the session, with the game closed and the directory stable:
>
> - **The shipping exe is the `24097213` binary** — 169,513,984 B, SHA `CAEFF67E…`. It should be
>   169,641,472 / `5D9F12E6…`. That is a **three-patch** revert.
> - **20 of 118 pak files reverted** to `24097213`-era versions (mtimes 2026-07-04 / 07-07),
>   including `global.ucas`, `pakchunk0_s1-Windows.ucas` and `pakchunk20_s16/s17`.
> - **`FWPakManifest.json` deleted** from the game's `Paks\`.
> - Proof it is a genuine revert and not a mis-measure: the decoder now mounts **76,589** files —
>   exactly the `pre-24479102` count — and matches **zero** `DA_WPN_PLAYER_*`, a naming that only
>   exists from `24479102` onward.
>
> **Nothing is lost.** Every correct `24536482` file is sitting in
> `overwrite\Root\Windows\…` with mtime `2026-08-03 20:19:32` (Steam's patch write), sizes
> matching `post-24536482` exactly — including the correct exe at 169,641,472 B.
>
> ### Root cause: Root Builder's cache is keyed on the ENGINE version, which never changes
>
> `C:\Modding\MO2\plugins\data\RootBuilder\DSteamLibrarysteamappscommonThe_Forever_Winter\`
> **`5_4_2_0`**`\GameData.json` (68,263 B, rewritten 23:05:47 at session start). The key is
> `5_4_2_0` — the UE version — and it has been identical across `24097213` → `24479102` →
> `24501089` → `24536482`. So Root Builder believes its file inventory from a July build still
> describes the current game and "restores" it. **This will recur on every launch after every
> patch until the cache is cleared**, and it explains the SylDesk executable finding as the same
> bug rather than a one-off.
>
> ### The mechanism, proven from the cache file itself
>
> `GameData.json` stores `{Relative, Hash (md5), Modified, Size}` per game file. **Every reverted
> file is recorded at its `24097213` size with a July timestamp** — exe `169513984` @ 2026-07-07
> 22:33, `global.ucas` `3012304` @ 2026-07-04 06:08, `pakchunk0_s1` `1769239392` @ 2026-07-07.
> The file's own mtime was 23:05:47 (session start), so **Root Builder rewrote the file while
> keeping July contents**: it captures each game file's "original" state once and never re-checks
> it against a patch.
>
> The bytes themselves lived in a sibling **`5_4_2_0\Backup\` — 274 files, 50,781,752,235 B
> (47.29 GB), created 2026-07-12**, a full copy of the game root. Its exe hashed to `CAEFF67E…`,
> byte-for-byte what was found in the game directory after the session. Not inferred — measured.
>
> **Why it never self-corrected:** the cache directory is keyed on `5_4_2_0`, the *engine* version,
> which has been identical across `24097213` → `24479102` → `24501089` → `24536482`. Content
> patches never invalidate it.
>
> ### Remediation — DONE on SylG5 2026-08-04
>
> 1. 🟩 **Steam verify** run by Sylvia (`StateFlags 1190`, ~5.9 GB re-downloaded). Restores the
>    exe, the 20 paks and `FWPakManifest.json` authoritatively.
> 2. 🟩 **`GameData.json` and `Backup\` both deleted** — together, which is the point: removing
>    only the cache leaves 47 GB of July files ready to restore, removing only the backup leaves
>    the cache asserting the game looks like July. **46.7 GB reclaimed on `C:`.** Root Builder
>    rebuilds both from the correct install on next launch. The two Cyberpunk instances under the
>    same plugin directory were left untouched.
> 3. 🟩 **`overwrite\Root` deleted** — 47 files / 38.52 GB of displaced game content, reclaimed on
>    `D:`. Everything unique was preserved first: `UE4SS-gate3.log` and `bitfix-gate3b.txt` into
>    `baselines/post-24536482/` (matching the `post-24479102` convention), and the usmap into the
>    datamine repo — hash-compared `E80B0E79…` before removal, not assumed. `overwrite\` retains
>    `LogicMods` and `TFWWorkbench`, which are legitimate mod output and were not touched.
>
> **~85 GB reclaimed in total.** Expect Root Builder to rebuild a fresh cache and ~47 GB backup on
> the next MO2 launch, snapshotting the *correct* install. That is the fix working, not a relapse.
>
> ### 🟩 The repaired install is verified — 119/119 paks + 9/9 binaries by SHA256
>
> Not by size, and not by "the game launched". Every pak and every Win64 binary hash-matches
> `post-24536482`; the shipping exe is back to `5D9F12E6…`. **Functionally proven too:** the
> decoder mounts **76,310** files (76,589 would mean still reverted), `DA_WPN_PLAYER_HRF01`
> decodes a full 57 properties against the regenerated usmap, and `AIDEF_Sensor_Damage_Default`
> round-trips byte-identical to its committed dump.
>
> **One baseline hash was corrected in the process** — `pakchunk20_s8-Windows.ucas`, same byte
> length, different content. Steam's post-verify copy is authoritative (it matches the depot
> manifest; our baseline was an unvalidated filesystem snapshot), so the CSV now carries the
> validated hash and the original is preserved in
> [`CORRECTION-pakchunk20_s8.md`](baselines/post-24536482/CORRECTION-pakchunk20_s8.md). Cause not
> determined — a torn read during a capture started ~30 s after the patch completed, or a patch
> write that differed from the manifest. **Process fix: run a Steam verify *before* capturing a
> post-patch baseline**, which makes the baseline manifest-validated rather than merely observed.
>
> **⚠ SylDesk needs steps 2 and 3** — its cache and backup live under an `H:`-keyed directory,
> almost certainly also ~47 GB, and its displaced exe is still armed. **It has not been done.**
>
> ### Add to the pre-launch routine
>
> **Compare the shipping exe's SHA256 against the current baseline before every session.** The
> baselines have always captured it; nothing ever read it. That single check would have caught
> this on SylDesk four days earlier, and would catch any future recurrence immediately.
>
> ### What this does and does not invalidate
>
> - **Gates 3 and 3b stand.** Both were measured at 23:05:50 from the live session log, while the
>   correct `24536482` exe was still in place; the revert happened at cleanup ~23:12.
> - **The usmap regeneration stands.** It was dumped at 23:12:13 from the running correct build,
>   and both validation runs mounted **76,310** files. Had they hit the reverted set, the AI-sensor
>   controls would have differed rather than matching byte-identically.
> - **Any in-game measurement taken on this machine before tonight is suspect**, because nothing
>   ever compared the exe hash before a session. Add that check to the pre-launch routine — the
>   baselines already capture the hash, nothing was reading it.
> - **The earlier "SylG5 is clean" check in this session was correct but too narrow.** It looked
>   for a displaced *executable* under the MO2 instance and for `GameData.json` under the instance
>   and `%LOCALAPPDATA%`/`%APPDATA%`. The cache actually lives under the **MO2 install directory**
>   (`C:\Modding\MO2\plugins\data\`), which was never searched, and the check never considered
>   *pak* files at all.
>
> </details>

---

> ## 🔺 NEW BUILD 24536482 — APPLIED on SylG5 2026-08-03 20:21:32 EDT
>
> **✅ All seven gates have since been re-run and are 🟩 against this build** (1b/2 closed 08-03/04,
> 3/3b/5a scored 08-05 from the 08-03 23:05 capture). **The Gates table is current. The class
> tables are not** — Class B still means `24479102`-on-SylDesk, and Class C is restamped per row.
>
> **What this patch actually is — characterised 2026-08-05, from the patch notes.** Hotfix
> `0.9.4.2`: *"an improvement was made to ensure all weapons have adjustments for height over
> bore"*, plus a 3rd-person crosshair accuracy fix. That is `bConvergeADSAimToCamera` landing in
> `FWWeaponDefinition` — **a weapon-schema patch, not a value tune.** Every mod that ships a cooked
> `DA_WPN_*` package built against `24501089` reads shifted garbage past the insertion point,
> which is precisely what happened to HRF v2.0. Contrast: `24479102` was a restructure,
> `24501089` a pure value tune. That the earlier "unclassified" note held for two days is the
> gap — **the Discord/Steam patch notes are a Stage 1 input, not an optional extra.**
>
> **Rollback key: `7134816348397298387`** ([`build-history.md`](build-history.md)). The previous
> key (`6443337773729671953` → `24501089`) still matters — **SylDesk is still on `24501089`**, so
> the two machines are diverged as of tonight.
>
> **Both sides of the diff exist for the first time in two cycles.** `pre-24536482` was captured
> **before the patch downloaded a single byte** (0 warnings, 119 paks / 48,572,725,793 B hashed,
> 76,309-entry filelist, exe hash-proven `E4E76D0E…` = `24501089`), and `post-24536482` follows
> immediately. **Gate 0 is green on evidence, not on luck** — contrast `24501089`, which installed
> unattended and had no pre-side of its own.
>
> - Applied **deliberately, without launching the game**, via the Steam client's **Downloads
>   page** — the route established on SylDesk earlier the same day, now confirmed on a second
>   machine. **`steam://install/<appid>` does not work.** This is a genuine amendment to rule 3:
>   launching is *not* the only way to trigger a pending patch, so a pending update no longer
>   forces a choice between patching and testing.
> - `StateFlags` went `6` → `1030` (UpdateRunning) → **`4`**, `UpdateResult 0`. Under three
>   minutes end to end.
> - **Download 414,173,424 B against a predicted 413,369,888.** SylDesk saw the same
>   under-prediction, much larger, on the previous patch. **`BytesToDownload` is an estimate, not
>   a contract** — completion is `BytesDownloaded == BytesToDownload` *and* `StateFlags 4`.
> - Install grew **+1,106,583 B** (~1 MiB on a 394 MiB patch) — the rewrite-in-place signature
>   both prior patches showed. **This says nothing about whether values changed.**
> - **Patch notes still unreviewed**, so this build has no blast-radius characterization and no
>   mod has a prior on it. `24479102` was a restructure, `24501089` a pure value tune; this one is
>   unclassified. The Discord announcement is the missing input.
>
> **The stale-executable blocker is SylDesk-only** — see the checked-not-assumed subsection in the
> banner below. Nothing needs clearing on the laptop before an in-game session.
>
> **`tools/steam_state.ps1` was fixed to make any of this possible** — it threw `DriveNotFound` on
> the absent `H:` before reaching the `D:` root, and `capture_baseline.ps1` calls it as step 1
> under `-ErrorActionPreference Stop`, so that one throw would have taken down the whole capture.
> Now drive-safe; SylDesk unaffected. `capture_baseline.ps1` still needs the same treatment (its
> `H:` defaults were overridden on the command line here).
>
> ### Gate order from here — Stage 1 restarts
>
> AES → usmap → re-decode/diff → UE4SS → Signature Bypass → Class B → Class A.
> Two standing warnings apply to this cycle specifically:
>
> - **Gate 1b is the one that bites.** On `24479102` the usmap was declared clear because AI
>   sensors decoded byte-identically, and `FWWeaponDefinition` was simultaneously decoding to
>   correct values bound to neighbouring property names — no error, entirely plausible. **A usmap
>   is per-struct.** Check a weapon struct explicitly; do not generalise from one struct family.
> - **Gates 3 and 3b were already unknown before this patch** (the exe changed on 08-01 and was
>   never re-tested), so they are owed regardless of what `24536482` did.
>
> ### What the patch did structurally — clean, and that is not the whole story
>
> Diff in [`state/diffs/pre-24536482__vs__post-24536482/`](diffs/pre-24536482__vs__post-24536482/REPORT.md).
> Filelist **76,309 → 76,310**: 109 added / 108 removed, of which **108 are case-only directory
> renames** in map and level-design geometry (`FW/Maps` 58, `LevelDesign/City` 26, `HUB_World` 14,
> `HUB_Intro` 7, `Shanti` 3). Lowercased, they are unchanged — and per
> [`asset-dependencies.md`](asset-dependencies.md) a casing change is not a break, because UE
> lowercases the package name before hashing `FPackageId`.
>
> - **Zero real removals.** Nothing any mod overlays has vanished. That is the failure mode that
>   killed AWU and HRF on `24479102`, and it did not happen here.
> - **One real addition:** `FW/UI/MainMenu/UMG/Panels/WBP_PopUp_Gift_July2026Drone.uasset`.
> - **Zero hits against the routing table** — all 69 Group 1–5 dependency patterns checked against
>   the full 217-path changed set. No Class A or Class B mod is structurally implicated.
> - **Frozen contract intact:** `ForeverWinter/Content/CMSF/` count is **0**, the required state.
> - **33 pak files changed, most with identical byte counts** — content rewritten in place. Plus
>   `pakchunk0_s1-Windows.ucas` +1,048,576 B and `global.ucas` +368 B.
>
> **Do not read the clean structural diff as "this patch is harmless."** The diff compares schema
> and row counts; a tuning pass that rewrites values in place is invisible to it, and the changed
> `.ucas` files with unchanged sizes are exactly where that hides. **More to the point, Gate 1b
> failed** — the weapon type layout moved without a single path moving. A clean filelist diff and a
> broken struct schema are entirely compatible, and this build is the proof.
>
> ### 🟥 `HeavyRifleRebalanceFix` v2.0 IS BROKEN ON THIS BUILD — measured 2026-08-04
>
> **This is no longer a hypothesis.** The shipped `152_HeavyRifleRebalance_P` pak was decoded in an
> **isolated mount** (mod trio + `global` only, 8 files — no base copy present, so the bytes are
> certainly the mod's) and checked field-by-field against `tools/rebalance.conf`. **All 6 weapons
> fail.** Each decodes **30–33 of 54–58 properties**, and `HRF01`'s `BurstFireRate` reads as the
> denormal **5.739719E-39** — the same tell `24479102` produced.
>
> **A/B proves the patch caused it, not a bad build.** The *same pak bytes*, read against the
> **pre-`24536482`** schema (the archived `24479102` usmap), decode to **57 properties with every
> conf value intact**. Read against the new schema they collapse. The mod was built correctly from
> the `24501089` cook; `bConvergeADSAimToCamera` landing in `FWWeaponDefinition` broke it.
>
> **What survives and what does not** — this matters for the page wording, because it is a partial
> failure, not a dead mod:
>
> | | |
> |---|---|
> | **Intact** (before the shift point) | `WeaponDamage` on all 6, `FireRate`, `CrosshairSpreadScalar`, `DistanceToSphere`, `SphereRadius`, `FovSprint` |
> | **Lost** (after it) | all recoil tuning (`RecoilWristYaw`, `RecoilArmAngle`, `RecoilWristRecoveryBlend`, `ScaleRecoilADS`), **`MaxAmmo` on 5 of 6**, `ADSMovementSpeed`/`OTAMovementSpeed`, `AimLagSpringDamping`/`Mass`, `ScaleAimLagPositionInADS`, `StabilizeFireTime`, `BurstFireRate` (denormal) |
>
> So the **damage rebalance — the headline feature — still applies**, while magazine sizes and all
> handling do not.
>
> **Second, independent defect on the same asset: a Group 1 staleness inversion.** The mod ships
> `DA_WPN_PLAYER_HRF02` with `SocketOptic = "Optics"`; the live game now has **`"S_Aim"`**. As a
> whole-asset override, the mod reverts the developers' change for every user, silently. That is
> exactly the failure mode [`asset-dependencies.md`](asset-dependencies.md) Group 1 exists to catch.
>
> **The fix is a rebuild, not a redesign.** `build_fix.sh` already extracts every package from the
> live cook and value-patches it, so re-running it against `24536482` produces correctly-serialized
> assets and picks up `S_Aim` for free. The design is unaffected — `WeaponDamage` is still the
> lever, and the damage figures decoded intact.
>
> ⚠ **It is live on Nexus #123 as `2.0.0`.** Users on `24536482` are being served a pak that
> applies damage but not magazines or handling, and reverts a vanilla socket change. Note also the
> mod is **not deployed on SylG5** (the laptop holds pre-v2.0 paks per the 08-01 audit), so any
> in-game confirmation needs it deployed here first.
>
> **Caveat on method:** this is a static measurement via CUE4Parse's emulation of UE's unversioned
> property serialization. It is strong — the denormal is the signature of a real misread, and the
> A/B controls for everything except the schema — but it is not an in-game observation.

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
>
> ### ✅ Checked on SylG5 2026-08-03 — the laptop does NOT have this problem
>
> **No `ForeverWinter-Win64-Shipping.exe` exists anywhere under
> `D:\MO2_InstanceData\TheForeverWinter`.** A full recursive search of the instance returns
> nothing; `overwrite\Root\Windows\ForeverWinter\Binaries\Win64\` holds only `bitfix.txt` and
> `UE4SS.log`, which are ordinary session logs. There is also **no `GameData.json`** under the
> instance, under `%LOCALAPPDATA%\ModOrganizer` or under `%APPDATA%\ModOrganizer`, so neither
> half of the SylDesk remediation applies. The laptop's game-dir exe is the correct `24501089`
> binary — hash-proven `E4E76D0E…` by the `pre-24536482` capture, not merely size-matched.
> **Nothing needs clearing here before an in-game measurement.** The blocker is SylDesk-only.

---

> ## 🔺 BUILD 24501089 — hotfix, measured 2026-08-01 (installed on BOTH machines as of 2026-08-03)
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

Last updated: 2026-08-05 — **`24536482` is applied on SylG5 and all seven gates are 🟩 against it.**
1b and 2 were closed on 2026-08-03/04 (usmap regenerated, 722 dumps re-decoded, catalog restamped)
but their rows were never carried forward and sat 🟥/🟦 for a day; 3, 3b and 5a were all cleared by
the 23:05–23:06 session and simply never scored. **Every 🟩 in the Gates table now means
`24536482`** — the class tables below do **not**: Class B is stamped `24479102`/SylDesk and Class C
is restamped per row.

Today (2026-08-05), from a datamine-pipeline audit rather than a game session:
- **Patch characterised at last.** Hotfix `0.9.4.2` (2026-08-03) — *"all weapons have adjustments
  for height over bore"* + a 3rd-person crosshair fix. That is `bConvergeADSAimToCamera`, which is
  exactly what shifted `FWWeaponDefinition` and broke HRF v2.0. **This build is a weapon-schema
  patch**, not a value tune — the blast radius the banner said was unclassified.
- Re-decode **re-confirmed**: 722/722 byte-identical to the live paks.
- Four real defects fixed in `forever-winter-datamine` (a decode returned neighbouring assets'
  files; the decoder exited 0 on total failure; `FALLBACK_BUILD` two builds stale; the Steam
  mid-update guard rejected nothing) — see that repo's `99a4616..5e08d51`.
- **The almanac is republished on `24536482`** (`057dd53`), including the Heavy Rifles overlay
  status, which had been telling users for four days that Nexus #123 hosts v1.1.

Prior, 2026-08-03 — two sessions on two machines, merged. Evening, SylG5: `pre-24536482` baseline
captured with 0 warnings before the patch downloaded a single byte, then the patch applied
deliberately via the Steam Downloads page. Also fixed `tools/steam_state.ps1`, which could not run
on SylG5 at all. Morning, SylDesk: **applied `24501089`** (11:36:51 EDT) without launching, and
found the stale-executable blocker in the process.
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

### Current cycle — `25071553`

| # | Gate | Status | Notes |
|---|---|---|---|
| 0 | Baseline captured | 🟨 | **One-sided.** `post-25071553` exists (76,321-entry filelist, 119 paks, exe hash-proven `D87AE674…`); **there is no `pre-25071553`** and there cannot be — `AutoUpdateBehavior` is `0` on SylG5, so the patch applied itself unattended on 2026-09-03. `post-24536482` serves as the "before" side. Two provenance caveats recorded on the capture: `filelist.txt` was added by hand after the fact, and **`catalog/` is carried over from `24536482`** — stamped `build: 24536482`, files dated 08-05. `capture_baseline.ps1` copies the datamine catalog without comparing its build stamp, so an unchanged catalog there means *"not rebuilt"*, never *"nothing changed"*. **That script should warn on the mismatch — it does not.** |
| 1a | AES key still valid | 🟩 | **Cleared on `25071553`.** Decoder mounts **76,321** files (was 76,310 at `24536482`) with the key unchanged at `decoder/Program.cs:28`. The IoStore index is AES-encrypted, so the mount *is* the test. |
| 1b | usmap valid (or regenerated) | 🟩 | **CLEARED 2026-09-10 on SylDesk** — map re-dumped from the live build and installed as datamine `f2526c8` (`provenance.json` records `25071553`; `DA_WPN_PLAYER_HRF01` decodes **57** properties where the stale map gave 30). **Corroborated 2026-09-22 on SylG5 by the re-decode itself:** all 722 dumps came back with plausible values, `DA_WPN_PLAYER_HRF01` among the 618 byte-identical to the committed 57-property decode, and the 104 that changed are patch content, not truncation. *Previous 🟥 text is in git history.* |
| 2 | Re-decode + filelist diff | 🟩 | **COMPLETE 2026-09-22 on SylG5 — both halves.** Filelist: 153 added / 142 removed, mostly case churn (unchanged from the 09-10 read); a fresh `fwextract list` mounts **76,321**. Re-decode: all **722** tracked dumps re-decoded against `25071553` (datamine `e6c75a9`) — **618 byte-identical, 104 changed, 0 gone**: ai_noise 15, ai_sensors 25, enemies 40, bosses 14, weapons 7, hunterkillers 1, items 1, lootobjects 1. The changes read as 0.9.5.0's AI overhaul: noise tiers re-tuned upward (player walk 2.5→6 m, sprint →15 m), `PointBlankVisionRange` 500 on 12 sensors, HearingData re-ordered on all 7, AIDEFs repointed at `Trees_v3`. Weapons: handling retunes on SMG03/PST10, suppressed-fire cues, knockdown flags on AI HRF01a/b/c — **no damage, RoF or magazine field moved**. `tables.json`: no RowStruct or row count moved. Catalog rebuilt and `FALLBACK_BUILD` bumped in the same commit. **Class A read of this:** no `WeaponsDetailsData`, `WeaponPartStatsData` or `DA_WPN_PLAYER_*` damage/ammo field changed, so the weapon mods' value tables are untouched; the two changed player `DA_WPN_*` handling assets are `SMG03` and `PST10`. |
| 3 | RE-UE4SS attaches to new exe | ⬜ | **UNATTEMPTED — not merely unscored.** There is **no `UE4SS.log` anywhere** under `D:\MO2_InstanceData\TheForeverWinter`, so nothing has run against this exe. **All of Class B is unknown**, and the `-894` experimental pin has never been tested against a September binary. |
| 3b | Signature Bypass matches new exe | ⬜ | **Unattempted.** Same launch as gate 3. The AOB pattern has survived every patch so far, but that is a prior, not a measurement. |
| 5a | TFWWorkbench reads new paks | ⬜ | **Unattempted.** Falls out of the same launch. Class A rebuilds stay gated until it and 1b are both green. |

### Previous cycle — `24536482` (kept for evidence; **not current state**)

| # | Gate | Status | Notes |
|---|---|---|---|
| 0 | Baseline captured | 🟩 | **Green for the `24536482` cycle — captured 2026-08-03 before the patch downloaded, and `post-24536482` follows it.** `pre-24536482`: 0 warnings, 119 paks / 48,572,725,793 B hashed, 76,309 entries, datamine `6f76f425`, exe hash confirms it snapshots `24501089`. Prior cycle: `pre-24479102` (76,589) + `post-24479102` (76,309), datamine tagged `baseline-24097213` @ `36b068b8`, rollback key `6430523508700280691`. |
| 1a | AES key still valid | 🟩 | **Cleared on `24536482` 2026-08-03.** Decoder mounted **76,310** files from the new paks with the key hardcoded at `decoder/Program.cs:28`, unchanged. The IoStore index is AES-encrypted, so the mount *is* the test. No AESDumpster run needed. (Previously cleared the same way on `24479102` at 76,309.) |
| 1b | usmap valid (or regenerated) | 🟩 | **CLEARED on `24536482` — regenerated 2026-08-03 23:12:13**, datamine [`f7d7db7`](https://github.com/dataterminals/forever-winter-datamine/commit/f7d7db7) (`ForeverWinter-5.4.2.usmap`, 2,155,180 B, sha256 `e80b0e79…`; the `24479102` map archived alongside it). **Verified against the struct that moved:** `FWWeaponDefinition` now carries `bConvergeADSAimToCamera` at index 46, and `DA_WPN_PLAYER_HRF01` decodes a full **57** properties — it was stopping at 30. **Root cause is now known and matches the patch notes:** hotfix `0.9.4.2` (2026-08-03) states *“improvement … to ensure all weapons have adjustments for height over bore”* — that is the inserted property, and unversioned serialization shifted every later index behind it. **Cross-check that the map is right, not merely different:** the full 722-dump re-decode came back byte-identical on 720 and the 2 real changes are both explicable (`DA_WPN_PLAYER_GRL00` 54→55 props = the new property; `HRF02` `SocketOptic` `"Optics"`→`"S_Aim"`). A wrong map does not produce 720 byte-identical dumps. Provenance is now recorded on disk in `datamine/mappings/provenance.json`, so this is checkable next patch without a launch. *Previous 🟥 analysis retained in git history; evidence files `baselines/post-24536482/DA_WPN_PLAYER_*-STALE-USMAP.json` are the PRE-regeneration reads.* |
| 2 | Re-decode + filelist diff | 🟩 | **COMPLETE on `24536482` — both halves.** Filelist: `pre-`/`post-24536482` diffed, 76,309→76,310, **0 real removals**, 1 real addition (`WBP_PopUp_Gift_July2026Drone`), 108 case-only directory renames, **0 hits against the 69-pattern routing table**. Re-decode: all **722** tracked dumps re-decoded from the live paks and diffed (datamine [`2f604df`](https://github.com/dataterminals/forever-winter-datamine/commit/2f604df)) — **720 byte-identical, 2 changed, 0 no-longer-in-live**, catalog rebuilt and stamped `24536482`. **Re-confirmed 2026-08-05: 722/722 identical, 0 changed.** **The two changes are the whole Class A exposure for this patch:** `DA_WPN_PLAYER_GRL00` gained `bConvergeADSAimToCamera`, and `DA_WPN_PLAYER_HRF02`'s `SocketOptic` moved `"Optics"`→`"S_Aim"` — the latter is a Group 1 staleness inversion any whole-asset override will silently revert. Prior cycle's result below. **Complete on `24479102`:** real deltas the stale-vs-stale diff had missed — `WeaponsDetailsData` 56→53, `DT_TagToRowHandle` 1176→1173 (rows `RFL01_Red/Blue/Green` cut). |
| 3 | RE-UE4SS attaches to new exe | 🟩 | **Re-cleared on `24536482` 2026-08-03 23:05:50** — `baselines/post-24536482/UE4SS-gate3.log`. Clean attach against the **new** exe (`169,641,472 B`, in-log at :16, sha256 `5D9F12E6…` matching `binaries-win64.csv`), `Found EngineVersion: 5.4` (:31), `PS scan successful` (:42), `Event loop start` (:990). The lone `FUObjectHashTables::Get()` miss is **pre-existing** — byte-for-byte the same line appears in the 2026-07-27 old-build log. *Previously cleared 2026-07-30 17:50 on `24479102` at `169,584,128 B`; that run is history, not the current evidence.* **Class B is unblocked.** |
| 3b | Signature Bypass matches new exe | 🟩 | **Re-cleared on `24536482` 2026-08-03 23:05:50** — `baselines/post-24536482/bitfix-gate3b.txt`. AOB scan hit on the new exe (`scan results: [[7FF702860AF0, 7FF702860E40]]`) and applied the patch (`writing C3 to 7FF702860E40`, `done executing`). Same shape as prior runs at shifted addresses — the pattern itself has survived every patch so far. *Previously cleared 2026-07-30 17:50:55 on `24479102` at `[[7FF6E9560600, 7FF6E9560950]]`.* |
| 5a | TFWWorkbench reads new paks | 🟩 | **CLEARED on `24536482` 2026-08-03 23:06:21**, from this repo's own capture — `baselines/post-24536482/UE4SS-gate3.log:999-1022`. Workbench ran `CollectData` over **7** DataTable dirs (`WeaponsDetailsData`, `WeaponPartStatsData`, `VendorData`, `CraftingRecipe`, `CraftingGroup`, `Item`, `ItemValue`) and configured 6 live tables including `WeaponConfigSetup → DT_WPN_Config_Setup` and `InventoryItemDetails → ItemDetailsData`, then wrote 20 dumps. **No error, failure or Lua exception on any Workbench line.** The evidence was already on disk from the gate-3 session; nothing was ever scored from it. **Class A rebuilds are unblocked.** |

## Class B — Lua (do first; cheap intel)

### Restamped for `25071553` — 2026-09-10 ⚠ *unverified: the adversarial pass never ran*

> ## 🟦 There is no Class B loadout on this machine at all.
>
> **Gate 3 is unattempted** — nothing has run against this exe — so every row here is unknown on
> `25071553` for that reason alone. But the deeper problem is the loadout: **`TFWLootAll`,
> `TFWStaggerControl`, `TFWQuestHUDToggle` and `TFWQuestItemTag` are all absent from SylG5's MO2
> store entirely** — not disabled, *absent*, with no line in `modlist.txt` in either the `+` or the
> `-` set. `RE-UE4SS` and `Signature Bypass` **are** `+`enabled, so the runtime host is deployed and
> ready; there is simply nothing for it to load.
>
> **So gate 3 clearing does not clear Class B.** The precondition is either *deploy those four into
> `D:\MO2_InstanceData\TheForeverWinter\mods`* — which is cheap, they are loose Lua — *or* defer
> Class B until SylDesk is remediated and patched. This has been true and unstated for two cycles.

| Repo | Status | Restamped finding |
|---|---|---|
| `TFWLootAll` | ⬜ | **Real stamp `24479102`, and load-only** — four lines in `post-24479102/UE4SS-classB.log` (mod started, both keybinds bound, `v0.1.0 PROBE` loaded). That is the entire runtime record; no DISCOVER output, no transfer ever exercised. **Its identifier contract was only ever decoded at `24097213`** — two builds older than its load test. **Structurally clean at `25071553`:** all four assets it resolves (`W_LootUI`, `W_LootItem`, `W_LootInRange`, `W_LootFailReason`) are present at byte-identical paths. usmap-independent, so **not** 1b-blocked. Not deployed, not released; a `v0.1.0` manual zip exists in `dist/`. |
| `TFWQuestHUDToggle` | ⬜ | **Real stamp `24479102`** — load-only, same session, same limits. Not deployed. usmap-independent. Never functionally tested (needs Ctrl+Shift+Q in a quest HUD context). |
| `TFWQuestItemTag` | 🟦 | **Never confirmed working in-game on ANY build.** The only positive evidence anywhere is `9a1c167`'s note (2026-07-14) that the READ path worked *on a third party's machine*, build unrecorded — and that same message states the `SetText` write path was the unproven piece, which is why v0.1.2 exists. **There is no green here to carry forward or to void.** Structurally the patch is clean: `WBP_ItemTooltips`, `WBP_BaseTooltip`, `BPFL_Tooltips`, `Blueprints/Data/ItemDetailsData` all present and unmoved, with **zero** changes in either directory across the diff. **The one action the board owes it is now blocked, not merely pending:** `tools/gen_manifest.py` reads decoded `ItemDetailsData` through `fwdata`, so regenerating the manifest today would **bake gate-1b-void data and exit 0**. Separately, the shipped manifest was **already 3 items short before this patch** — 43 committed vs 46 from `fwdata.query.quest_items()`, measured at `24536482` — upstream rule drift, not patch damage. The "recommended for release" static-pak vector has **never been built**: no build script, no retoc invocation, no `.pak` anywhere in the repo. |
| `TFWStaggerControl` | ⬜ | **Not restamped — the audit was cut off before it ran.** Row below is `24479102`-era. Flagged as the highest-priority Class B re-test when one is possible: it hooks `GA_Player_HitReaction` and `BP_PlayerBase`, both combat-adjacent, and `0.9.5.0` is a ground-up combat AI rework. |
| `TombstoneAlways` | ⬜ | **Not restamped — audit cut off.** May not be cloned on this machine at all. |

### Previous cycle — `24479102` (**history, not state**)

> ⚠ **Everything in this section is stamped `24479102`, measured on SylDesk 2026-07-30 17:57 — NOT
> `24536482`.** It cannot be re-cleared on SylG5 as things stand: `TFWLootAll`, `TFWStaggerControl`
> and `TFWQuestHUDToggle` are **not in SylG5's 18-mod store** (checked live, not from the snapshot).
> So the precondition is either *deploy those three into
> `D:\MO2_InstanceData\TheForeverWinter\mods`*, or *defer Class B until SylDesk is remediated and
> patched*. Gates 3/3b are green on `24536482`, so the runtime itself is not the blocker — the
> loadout is.

**Gates 3 and 3b cleared, and all three deployed Class B mods ran on `24479102` 2026-07-30
17:57.** No class, Blueprint, widget or function any of them resolves had moved. Zero Lua errors
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

### Restamped for `25071553` — 2026-09-10 ⚠ *unverified: the adversarial pass never ran*

**No Class A row here is 🟩 and none can be**, because `verify_build.sh` in every one of these
repos passes `FW_USMAP` to the decoder, so every property-shape number they report is void under
gate 1b. The useful asymmetry: several **builds** are byte-patch-only and are *not* 1b-blocked —
only the verifies are.

| Repo | Status | Restamped finding |
|---|---|---|
| `UnkillablesRebalanceFix` | 🟨 | **2026-09-22, later: Fenix reports v1.4 works in game** (Sylvia relayed it to `commander`; whether that run covered the repeated-Grabber-shooting check wasn't said). **Still not live:** Nexus #124's MAIN file is v1.3 (file 499, 141,180 B; public API checked twice, the second time just before the almanac push), and `fa91b35` is unpushed. So the almanac toggle correctly keeps "Doesn't work on the current game version yet". **Left for Sylvia:** push `fa91b35` and upload both zips to #124. Then change the README "For players" line, re-run `parse_unkillables.py` alone, and add a dated entry to the almanac's hand-written `data/changelog.json`. **Earlier, 2026-09-22 (`fa91b35`): v1.4 is built and verified on `25071553` and awaits the in-game test. It is not on Nexus, and the live download is broken:** Nexus #124's main file is **v1.3** (uploaded 2026-08-24; no v1.2 was ever listed, so the previous row's "never shipped / #124 still serves v1.2" was wrong on both counts), and on `25071553` v1.3 **crashes the game on load**. **Proven to the byte:** Fenix's 0.9.5.0 report `Default__BP_AI_Euruska_MeatMan_C: Bad import index 1996488703/198` reproduces from v1.3's MeatMan CDO. 0.9.5 inserted `bFaceFocusWhileMoving` (Bool) into `FWGameAICharacter`, so `ThrowingSystem`'s 4-byte reference lands on the 1-byte `bIsGesturing` and the next object read (`SoundLand`) takes `00 00 00 89`, which is import 1996488703 of MeatMan's 198. Their zip was v1.3 (size match); their exe (169,738,240 B) was an intermediate 0.9.5.0/.1 build. v1.4 differs from v1.3 in 20 bytes across the 6 boss packages, every one an unversioned-header skip count, with no values changed. **`verify_build.sh` re-run under the live `25071553` usmap (1b green): 11 packages, 16 dumps, 0 uncovered · 3165 refs / 0 dangling · 0 properties dropped**, identical to 2026-09-11. **Both layouts packaged** by the new `tools/package_release.py`: `dist/UnkillablesRebalanceFix.zip` (manual, the default; sha256 `4cf0b2b9…`, unchanged since 09-11) and `dist/UnkillablesRebalanceFix-MO2.zip` (`Mods\` layout; `78340d26…`). **Almanac:** the toggle links #124, credits #68 by Meganiikko (Nexus's author field; uploaded by warhamer116), and prints the URF README's new "For players" line verbatim: *"Doesn't work on the current game version yet — the current download crashes the game while loading. A fix is on the way."* (almanac `c35234f` + `f29d846`, datamine `4c9ecde`). **SylG5 pre-launch, checked 2026-09-22:** exe SHA256 matches `post-25071553`; all 119 paks match by size; Root Builder `5_4_2_0\` is empty (not armed); the **MO2 profile still has `+UnkillablesRebalanceFix` carrying v1.2 and `+CMSF v0.2.1 dev` enabled**, so install the MO2 zip over the mod and untick CMSF before a local test. Signature Bypass is on, so a local pass cannot speak to the integrity path. **Left for Sylvia:** the in-game test (her or Fenix), the repeated-Grabber-shooting check (still open, no crash log), uploading both zips to #124, then changing the README "For players" line and re-running `parse_unkillables.py` alone. |
| `HeavyRifleRebalanceFix` | 🟦 | **Board was a cycle stale on the fix and accurate on the harm.** **v2.1.0 WAS rebuilt and verified against `24536482`** on 2026-08-05/06 (`9f835cd` — 7/7 checks, 36/36 values, rifles decode 55–58 properties matching vanilla, `HRF02` picked up `SocketOptic` `"S_Aim"` for free). The board's last write (`25255fa`, 08-05) predates that commit by a day, so the 🟥 "BROKEN on `24536482`" half is **superseded**. **Still true and now worse: v2.1 was never uploaded.** Nexus #123 has served **2.0.0 — a `24501089` cook — for five weeks**, and on `25071553` it is at least two schema generations stale. The MO2 store holds an even older **v1.1** pak (2026-07-13, sha `2b5726b7…`), disabled. **State on `25071553` is UNKNOWN and unmeasurable:** both `build_fix.sh` and `verify_build.sh` bind `FW_USMAP`, and `rebalance.conf` is nothing but `FWWeaponDefinition` scalars, so every claim this repo can make is behind gate 1b. **None of the new content touches its 26 owned packages** — the `SM_WPN_SHG05_RCV` split is a *shotgun*; the mod overrides `SM_WPN_HRF05_RCV`, a different weapon in a different directory. **But the asset list is the wrong place to look:** `0.9.5.0` is a client-side shooting rework, `FWWeaponDefinition` has been extended by two consecutive builds, and gate 1b's own datum (HRF01 at 30 of 57) is the *exact fingerprint v2.0 showed when it broke*. **A stale usmap and a third re-shift are indistinguishable from disk.** Do **not** upload v2.1 until 1b clears and verify re-runs — uploading a `24536482`-targeted pak onto a live `25071553` risks shipping a second broken release. See also [`scriptobjects-25071553.md`](scriptobjects-25071553.md) §4: this repo has the **highest exposure** to the weapon-damage-override path, which could make its launch gate fail for reasons unrelated to the pak being correct. |
| `ScavgirlCarryPerks` | 🟦 | **Real stamp `24479102`** (`5007c18`, 2026-07-31) — the last *real* full-mount verification. **Nothing in this repo was ever measured at `24536482`, and nothing at `25071553`.** The later `24501089` artifact is an undocumented, gitignored isolated re-run whose Unbalanced dump shows all 9 `ChildSkills` as literal `null` — **isolation demonstrably proves nothing about this mod's graft**, confirming the board's own "the method was unsound" note rather than resolving it. **Structurally clean:** it owns exactly one package (`SD_Skill_EarlyAccess_ScavGirl_ROOT`, id `e2129fe5f6accc68`) and nothing genuinely-new in `25071553` touches it or its read surface. **Six SCP folders in the store, all six DISABLED.** Released on Nexus; **page number recorded nowhere on disk** — a standing gap the WORKLOG names itself. 1b-blocked for any value-level re-verify. |
| `forever-winter-skin-mods` | 🟦 | **Real stamp `24097213`** — the repo is untouched since 2026-07-09 and its skin maps were read at `24045295`. **Three builds of undetected drift.** **Corrects two stale board claims:** (1) the four skins the old row names (`101`–`104` — Slade, Luca, Bunco-chan, Kane) **left the store before the `24536482` baseline** and are in no smoke-test loadout — that clause was already wrong a cycle ago; (2) the store's one skin mod is **`UMP45`, Nexus #30 — the third-party *upstream source* mod this repo retargets**, files dated 2025-03-26, and `modlist.txt:3` reads `-UMP45`, disabled. None of the 8 built variants is deployed. **The flagged Shaman MAY material renames are a near-miss, examined and cleared:** they land inside `Skins/MAY/Materials/`, and `SHM_UMP45_ShamanMay_P` replaces `SK_SCV_SHM_MAY` wholesale with its own materials, so the renamed base materials are unreferenced once installed. All 8 slot meshes, both skeletons, `M_FW_Char` and the 2,142-file OLMA VO tree survive at identical paths. **🟦 not 🟩 because the contract is the unreadable part:** the `DT_SkinUIData` row→mesh mapping is value-level and void under 1b, and `fwrepath` loads the usmap unconditionally. **Queue `DT_SkinUIData` as the first re-decode consumer once 1b clears — one datatable, not a rebuild.** ⚠ Redistribution permission is unresolved on disk (Nexus #30 records no grant) — same class of blocker that gated AWU and HRF. |
| `TFWCharModelSelFramework` | 🟨 | **Owned by a parallel session this cycle — deliberately not restamped here.** Its pak was rebuilt on the live cook and statically verified three ways that read no usmap (pawn `.uexp` = live_src + exactly 672 B; 199/199 `.uexp` payloads round-trip byte-identical through `retoc to-legacy`; `verify_build.sh` green incl. a new "built on THIS cook" check). **Staged in the store as `CMSF v0.2.5 rebuild 25071553`, correctly absent from `modlist.txt`, release zip deliberately unbuilt.** ⚠ **The currently-ENABLED `CMSF v0.2.1 dev` holds a Jul 25 pak and will crash — disable it before any launch.** **The rebuild is not a demonstrated fix:** container staleness was proposed as the crash cause, tested, and does not explain it — see [`scriptobjects-25071553.md`](scriptobjects-25071553.md) §2. |
| `AllWeaponsUnlockableFix` | ⬜ | **Not restamped — the audit was cut off before it ran.** Row below is `24501089`-era. **It is `+`ENABLED in the profile**, so it is in whatever loadout the next launch uses. Weapon-table mod: see the integrity-subsystem exposure table in [`scriptobjects-25071553.md`](scriptobjects-25071553.md) §4. |
| `TFWQuestGiverPortraitPatch` | ⬜ | **Not restamped — audit cut off.** Texture-only, so plausibly usmap-independent; that was never confirmed. |

### Previous cycle — `24536482` and earlier (**history, not state**)

| Repo | Status | Finding |
|---|---|---|
| `HeavyRifleRebalanceFix` | 🟥 | **BROKEN ON `24536482` — MEASURED 2026-08-04, AND IT IS LIVE ON NEXUS #123.** Isolated-mount decode of the shipped `152` pak (mod trio + `global`, 8 files, no base copy possible) checked field-by-field against `tools/rebalance.conf`: **6 of 6 weapons fail**, each decoding **30–33 of 54–58 properties**, with `HRF01.BurstFireRate` reading as the denormal **5.739719E-39**. **A/B isolates the cause to this patch, not to a bad build:** the *identical pak bytes* read against the archived `24479102` usmap give **57 properties with every conf value intact**. `bConvergeADSAimToCamera` entering `FWWeaponDefinition` shifted the schema, and `retoc` never re-serializes property blobs, so assets cooked from the `24501089` live cook are now misread — the same mechanism that killed the 0.9.2 cook, one patch later. **Partial, not total, and the distinction matters for the page:** `WeaponDamage` on all six **survives** (it precedes the shift point), so the damage rebalance still applies; **`MaxAmmo` on 5 of 6, all recoil tuning, all aim-lag, ADS/OTA movement speeds and `StabilizeFireTime` are lost**. **A second, independent defect on the same asset:** the mod ships `DA_WPN_PLAYER_HRF02` with `SocketOptic = "Optics"` while the live game now has **`"S_Aim"`** — a Group 1 staleness inversion, reverting a vanilla change for every user. **The fix is a rebuild, not a redesign:** `build_fix.sh` already extracts every package from the live cook and value-patches it, so re-running it against `24536482` corrects the serialization and picks up `S_Aim` in one pass; the `WeaponDamage`-is-the-lever design is untouched and its damage figures decoded intact. **Method caveat:** static, via CUE4Parse's emulation of UE unversioned serialization — strong (the denormal is a real-misread signature, and the A/B controls everything but the schema) but not an in-game observation. Prior state, still accurate as history: 🟨 **REDESIGNED AND REBUILT as v2.0 on `24501089`** — every static check green, but the whole design rests on one **unmeasured hypothesis** and that is why this is 🟨 not 🟩: nothing on disk proves `WeaponDamage` is the field the game reads for damage now. **The launch gate is one number** — HRF01 must deal ~780, not ~300. If it deals 300 the approach is wrong at the root and needs re-deriving, not tuning. **A third death was found that was not on the hit list, and it is the reason a rebase was never viable:** `FWWeaponDefinition` gained two properties at schema index 44 (`ScaleADSCameraBlendSpeed`, `ScaleADSExitCameraBlendSpeed`), shifting all 52 later properties by +2. UE5 unversioned serialization writes values in class order with no names, so the mod's 0.9.2 cook now misreads from there on — measured, `DA_WPN_HRF02_v2` yields **30 of 57 properties**, loses `MaxAmmo`/all recoil/all aim-lag/every montage, and reads `BurstFireRate` as the denormal **5.385e-42**. retoc never re-serializes property blobs, so renaming the packages would have bound them correctly and then fed the game garbage — **worse than inert**. Also **a fourth death on the JSON side that no check covered**: all six `WeaponsDetailsData` rows pinned `DataAsset` → `DA_WPN_<code>_v2` and TFWWorkbench `Add` overwrites the live row, so the mod *broke* the six rifles rather than merely failing — the identical break AWU hit on `24479102`, same field. **Two board claims corrected by measurement.** (1) **The "12th dead override" is not one.** `T_Portrait_Manufacturing_Optics` is an asset the mod **adds**, not overrides — the base game has never shipped it (July's two hits were the mod's own `BagmanTest/Content/` copies), its FPackageId hashes to a `/Game/ArtAssets/…` path the base leaves free, and it is the icon its `HeavyOptics` crafting group points at. It works *because* the base lacks it. The `191` pak is healthy: **18/18 packages bind** (CityHash64 recomputed per package name against the pak's chunk ids), meshes/textures deserialize clean. The bug was in the *check* — a basename-vs-filelist test is right for an override and exactly wrong for an addition; the two are now declared in `tools/pak191.conf` and tested in opposite directions. (2) **`DT_CaliberToHeadshotMulti` was alive but stale** — it was silently reverting vanilla's `Item.Ammo.9mm` 1.5 → 1.333333. **Build: 13 packages → 8, zero 0.9.2-cooked bytes** — every package extracted from the live cook and value-patched. New `tools/patch_props.py` resolves offsets from serialization order (on HRF01, `0.1` is both `FireRate` and `RecoilArmAngle`) and **aborts rather than guessing**; it did, twice, in development. `tools/rebalance.conf` is the single source of truth for the numbers — build applies it, verify checks against it, so they cannot drift. **Damage re-derived**: absolutes kept except **RFL29**, where vanilla overtook the mod (175 → **600**, past the mod's 375), so 375 would now be a **37.5% nerf** — re-derived to **650**. RFL29 is the **Vykhlop**; the SVD is **RFL20** and got its own buff (7.62×54R headshot 1.5 → 3.0). `RecoilWristPitch` dropped — vanilla zeroed it game-wide. **Verify rebuilt**: provenance gate + value check + opposite-direction presence + **TFWWorkbench JSON pointers** (new; nothing covered the JSON before). All 7 pass. **JSON check found a bug on its first run** — item `WPN_RFL29_MAG_130_02` pointed at `SM_WPN_RFL29_MAG_130_02`, **a mesh that has never existed in any build or in the mod's own pak**; an original-mod slip from 0.9.2, repointed to `_01`. Still ⬜ **in-game**; mod left **disabled** in MO2 as found. |
| `TFWCharModelSelFramework` | 🟩 | **Verified on `24501089`** (`cb6f944`) — **401 dumps, 1591 references, 0 dangling** across framework, `release-v0.2.0` and the octogirl author pak, using a deterministic isolated mount. Filter coverage proven 100% by mounting each pak alone (framework = exactly 199 packages; octogirl = 3). **Frozen contract handled:** `/Game/CMSF/` is `--ignore`d, and removing the ignore surfaces 576 dangling of which **every one is inside `/Game/CMSF/` and none outside** — so it suppresses exactly the ABI. The **inverted assertion is wired to fail the run**: the live filelist carries **0** entries under `ForeverWinter/Content/CMSF/`, which is the required state — the devs have not collided with the namespace. 100 of the surviving refs point into 54 distinct live base packages (vanilla meshes, `T_Menu_PickCharacter_Portrait_*`), which is exactly the surface a dev rename would break; all resolve. This repo is where the **non-deterministic mount** finding came from — see the banner. |
| `UnkillablesRebalanceFix` | 🟩 | **REBUILT AND VERIFIED ON `24501089`** (`895fa8d`) — the hotfix revert is fixed. `BPC_IncomingDamageMod` now **276 base / 276 ship (+0)**, was dropping 13; **11 shipped packages, 17 dumps, 0 uncovered · 4519 refs, 0 dangling · 0 properties dropped**. `.ucas` **526,684 → 542,979 B** (`.pak` unchanged) — good size, check exactly. The finding was first reproduced *without* the decoder, by string-searching the `to-legacy` output: live base carries `Attack Add` x3 / `Modify Attack Add` / `Big boi Sniper Rifles` / `Noisy Player`, the stale pak **x0 of each**. Provenance proven **by value, not just by hash** — all 11 dumps carry the mod's numbers and **none** of the base numbers (boss HP x2 each with `1E+09` absent, Stalkers `1000` x2, BPC `61870`x4 `108700`x7 `86870`x2 `128000`x3 `43000`x2 `72000`x1 = the 19 patched doubles). **This repo's wrapper carried the false claim the banner warns about** — `verify_build.sh` asserted that where the package path is byte-identical "the mod wins the lookup". It does not; both copies write to the same filename and the last write wins, and exact-case pairing cannot help because there is only ever one file. Replaced with a real provenance gate (shipped dump must differ from base), **negative-tested**: it FAILS on a swapped-in base BPC dump where the old logic reported `OK BPC 276/276 (+0)`. Same hazard found in **retoc**, not just CUE4Parse — it extracts *both* colliding copies onto one output path, so `build_fix.sh` gained a gate asserting the Stalker extract carries the mod's `1000.0f` x2. **`build_fix.sh` is now machine-portable** (env → candidates, `D:` before `H:`); it previously hardcoded `H:` and could not run on SylG5 at all. **`upstream/` is not on this machine** — the pristine Nexus pak's cooked binaries are gitignored, so Option A fell back to the previously shipped `dist/`; proven lossless because all 4 rebuilt AIDEF payloads came out **byte-identical** to the shipped ones. New `tools/expected_package_ids.txt` pins the 11 FPackageIds (a moved id = a silent no-op override; also pins the `Euruska/Toothy` casing the live build spells `TOOTHY`) — 11/11 match. **Deployed to MO2 hash-verified, left disabled as found.** Still ⬜ **in-game** — never launched (`AutoUpdateBehavior 0`). **Both checks remain structural**, so this does **not** clear the 4 Option-A Stalker AIDEFs (frozen at the 0.9.2.2 cook) for BP graph drift; that risk is unchanged and unresolved. Nexus #124 needs the v1.2 zip once a launch is green. |
| `AllWeaponsUnlockableFix` | 🟩 | **Regression found & fixed 2026-07-31** (`d12007d`): the patch-rebase rebuild **resurrected the two Session-2 carry grafts** on ScavGirl's root (13 children again — `Shaman_PackMule_v1` + `OldMan_RIG01_AllowUse`, duplicate "Equip Runner" and all). Cause: Session 2 fixed the *artifact*, `build_fix.sh` kept pulling roots from `upstream/`; first end-to-end rebuild since brought the defect back, and `verify_softrefs` is blind to it — the grafts dangle nothing. Caught **before Nexus** via the SCP-interop question. Now the build *strips* the grafts (step 3) and *asserts* every root's graft set against `tools/fix_expected_grafts.json` (step 8, `verify_grafts.py`, negative-tested). Rebuilt 13→11, redeployed to MO2 hash-verified. **Good `.ucas` = 110,000 B; the regressed one is 110,008** — 8 bytes apart, check exactly. Trees unaffected. Earlier history: **BOTH VARIANTS FIXED** (`fe522fb`). User-confirmed break: every `WeaponsDetailsData` row pinned `DataAsset` → `DA_WPN_<code>_v2`, all renamed to `DA_WPN_PLAYER_<code>` by the patch, so every weapon lost its definition pointer. Measured in a full mount — deployed Trees **56/56 dangling**, regular **56/56 dangling**; **both rebuilds now 0/53** ✅. Root cause + ruled-out alternatives: [`rootcause-awu-customization-ui.md`](rootcause-awu-customization-ui.md). **Deployed to MO2 2026-07-30** (both variants, hash-verified; previous paks backed up). **Not yet released on Nexus** — users are still served the broken paks. Both mods are currently **disabled** in the profile, so re-enable before testing. **Class-level fix added** (`b4b01e4`): `tools/verify_softrefs.py` asserts every `AssetPathName`/`ObjectPath` in a decoded pak resolves against a freshly-regenerated live filelist, and now gates **both** builds. Proved against the real defect — flags **63 dangling** on the broken 07-20 pak, **0** on both rebuilds. `build_fix.sh` previously had *no* content verification at all. **Portable to every other pak mod we own.** |
| `ScavgirlCarryPerks` | 🟨 | **Its clearance needs re-measuring — the method was unsound** (`bd7c87d`). `verify_build.sh` uses the full-game `zzz_` staging trick, now measured to be non-deterministic (see banner), and **every SCP variant overrides a base asset** — exactly the shape that can grade vanilla and report clean. Its `verify_softrefs.py` copy also predated today's fix, so it would have passed an empty scan; now synced to canonical. An isolated re-run on `24501089` cleared all four variants with provenance proven (1 dump each, all differing from base, 0 dangling) — but **only 1 reference each**, because SCP's real exposure is *hard imports* into other characters' packages and those null out under isolation. **Isolation is the wrong tool for this mod**; it needs the full mount plus a provenance gate. Structurally it is safe on this build regardless: the filelist is **identical** across `24479102` → `24501089`, so nothing it points at can have moved. Prior finding, method caveat aside: **Survives unchanged — verified 2026-07-31 (`5007c18`), no rebuild needed.** Override surface is **one asset**: `retoc list` shows all four variants shipping a single package, id `e2129fe5f6accc68` = `SD_Skill_EarlyAccess_ScavGirl_ROOT` (the Combined variants merge AWU's weapon grafts into that same ROOT rather than shipping a second asset). **No `WeaponsDetailsData` override**, so it is structurally immune to the stale-`DataAsset` break that hit AWU. Its actual exposure is a whole-asset ROOT override *referencing* nodes in other characters' packages — checked both ways: **0 dangling refs** and **0 native children dropped**, all four variants, against a filelist regenerated from the live game. Near-miss: the patch renamed `ActiveCharacters/OldMan/` → `Oldman/` (27 assets) and our paks have the old casing baked in — **it binds anyway**, proven by 0 null `ChildSkills` / 0 `UnknownPackage` in a full mount, not merely by the case-insensitive checker passing. `verify_softrefs.py` **ported** + new `tools/verify_build.sh` (reversion check negative-tested). Still ⬜ **in-game on 24479102**; all 5 variants remain disabled in MO2. **Interop addendum 07-31 (corrected):** **SCP is RELEASED on Nexus** — the repo's unchecked "Nexus upload" box was stale. That kills the first theory about the "SCP needs an update for newest AWU" reports: the AWU carry-graft regression **never left this machine**, so Nexus users can't be hitting it. Likely causes, in order: (1) the **base-game Carry Capacity bug** (`docs/carry-capacity.md` — effect drops on location entry; page warning still unposted), (2) the **ScavGirl-ROOT collision** if AWU's pak wins mount order (launch-gated), (3) pre-patch AWU's dead-pointer table making the combo look broken. SCP-Combined's 4 weapon grafts still match both AWU variants' design. **Not recorded anywhere: SCP + AWU Nexus page numbers, report wording, reporters' variant.** |
| `TFWQuestGiverPortraitPatch` | 🟩 | **Verified on `24501089`** (`19214cb`). **The override surface is 3 textures, not 122** — 122 is the vanilla `Quest/` folder population; `build_patch.sh` keeps only the `mapping.tsv` targets. Confirmed by mounting the pak alone: 6 files (3 `.uasset` + 3 `.ubulk`) = Kane / Luca / Slade `_ButtonFramed`. The softref check is **legitimately vacuous** here — cooked `Texture2D` exports hold no `AssetPathName`/`ObjectPath` at all — so `--allow-empty` was **established by running without it first** (exit 2) and inspecting the dumps, and the wrapper asserts what actually matters instead: **baked** (mod pixels ≠ vanilla), **landed** (mount resolves to the mod's bytes), **geometry** (1024x512 `PF_DXT1` mip0 = 262144). All 3/3, negative control fails correctly. Still not enabled in `modlist.txt:28`; still assumes a 2:1 button brush. |
| `forever-winter-skin-mods` | ⬛ | **Not deployed — registry was wrong.** Builds `SCVGIRL_UMP9_*` / `SHM_UMP45_*`; none in the MO2 store. The 4 enabled skins (`101`–`104`) are **third-party**, not ours. Not our fix, but they sit in the smoke-test loadout. |

## Class C — Datamine + data products

| Repo | Status | Finding |
|---|---|---|
| `forever-winter-datamine` | 🟩 | **Facts, not tips, 2026-09-22** (`0118089`, pushed; `origin/main` is `0118089`). The last tip-style prose in `parse_enemies`, `parse_detection`, `parse_drops` and `parse_ammo` is rewritten as plain facts, and every number stays. One correction rode along: the Orgamech and MeatMan descs put the start of their dash at 0.4 m, but `DashRange.X` is 400 cm (4 m), which their cards' Attacks rows already showed. Regenerated with those four parsers only, and they reproduce the almanac's `data/` byte for byte. Senses harness: 50 PASS / 0 FAIL / 1 OBSERVE. **Every enemy's senses now come from its own blueprint, 2026-09-22** (`81390cc`, pushed in the integrated push at `4c9ecde`). `parse_detection` resolves each UNITS row's vision/hearing/ESP up the blueprint chain it names instead of taking hand-named sensors. The sense component's `InputSensorDefinitions` is one array, so the most-derived list decides every family: a family it leaves out is absent, not inherited. Its `Template` names the archetype, which skips undecoded parents. `parse_enemies` keys each card by its pawn definition's `PawnClass` (the `DETECTION_MAP` name map and its silent `except` are gone), held by `check_carriers`, because `PawnClass` is only a default: every Hunter-Killer definition points at its plain counterpart. **What it corrected:** Mech row ESP ×3 → none (no mech a player meets binds ESP); Opal ESP base → none; both turret rows gain hearing 5.75 m / 11.5 m violent; the Exo and Stilt Walker cards stop borrowing the Mech row; 17 cards get senses for the first time (MeatMan: Hunter-Killer ESP, ∞). **Two dumps added**, `BP_AI_TurretBase` and `BP_AI_Scav_Turret_20mm`, decoded at `25071553` after regenerating the filelist (76,321 = mounted); `redecode_check` gives **724/724 identical**. The only `ESP_Mech` binders, `BP_Mech_Europa_MediumMech` and its Eurasia child, are spawned by no row of the encounter table (`DT_ScenarioEncounters_NPCs`, scratch decode, not tracked) and by no HK controller, so a new `UNMET_BLUEPRINTS` table excuses them. Europa's medium-mech row spawns `BP_Mech_MedMech`; Euruska's spawns `BP_Euruska_MedMech`, which has the same sensors. **48 abort paths tested** with OUT in `work/`, each firing from its intended guard. An independent review found four holes, all closed: `PawnClass` trusted blindly, a `Template` pointing at nothing, the "only place" claim unenforced, and unit-specific notes leaking onto other cards. **Open:** `OutputSensorClasses` lists no ESP sensor class on 44 blueprints, including every one behind the Soldier and both sniper rows. Which array the engine builds sensors from is native code, so their "base" ESP is undecided. Spawned follow-ups, each in its own session: the Blind Mother "no vision sensor" prose (`5abd0a6`, that session's), and HP from the same blueprint chain, **now done: HP comes from each card's own blueprint too** (`7bdf3ee`, plus `973088c` for the Rat King note's wording, on `5abd0a6`, pushed at `4c9ecde`). `resolve_health` walks the card's `blueprint` up its `HealthComponent` chain to the first blueprint that stores `DefaultHealth`: each class default object's copy stores only what differs from its `Template`, the same component on the parent's default object. It replaces `HP_BP`, `BODY_BP` and the 23 hand-kept UNITS `bp` fields, and codexKill judges gunfire-vs-DetPack from the same pool with `BODY_BP`'s semantics kept. It aborts on an undecoded blueprint in the way, a `Template` that isn't the class's own parent or misses that parent's export (desynced dumps), a native parent with nothing stored and no `HP_NOTE`, `DefaultMaxHealth` disagreeing, an `HP_NOTE` the data contradicts or that names no card, and two tracked carriers of one AIDEF with different HP (`check_hp_carriers`, `UNMET_BLUEPRINTS` aside). **No number moved at `25071553`:** all 33 cards resolve from tracked dumps, 6 by inheritance (sniper, drone, T-90, Merkava, Blind Mother, Rat King), and every figure the maps published matches. The sniper's and the medium mech's hand-picked blueprints weren't the ones their definitions name, but hold the same 1,250 and 337,400. **One claim was false:** Rat King had "no separate body pool", because `BP_Mech_Scav_RatKing` stores no health of its own; it inherits `BP_Mech_MedMech`'s 337,400. Its codexKill note is corrected; realHp, invincible and method follow its armour and don't move. **25/25 abort paths** tested with OUT in `work/hp/`, and the senses harness gives the same 50 PASS + 1 OBSERVE on the new file. **Open:** the Stilt Walker's body pool is **900,000,000** under 130,900 of armour, Toothy's figure. It's a unit, so no codexKill publishes it and its card shows armour only; by the codexKill semantics gunfire can't kill it, which nobody has checked in game. **Then, at Sylvia's request** (`5e2913d`): 11 card subtitles (`desc`) lose their player tips and keep their facts. codex_kill's method now says how a boss dies whether or not it drops a Codex, which settles Blind Mother's card saying "Kill method unconfirmed" beside a note saying she dies like Mother Courage: she is now detpack, 3 plants, no Codex. **Earlier 2026-09-22:** **Re-decoded and current at `25071553`** (`e6c75a9..8ba0cce`, pushed; `origin/main` is `8ba0cce`). 722 re-decoded, 104 promoted, catalog restamped, `FALLBACK_BUILD` → `25071553` — see gate 2. **Three parser defects found while re-checking the output, all older than this patch:** `parse_detection` read hearing from `HearingData[0]` (the NoiseMaker-decoy entry on most sensors) and ignored every per-target vision override, and three UNITS rows named sensors their blueprints don't bind (`fc8ffba`, with a `bps` binding check and 7/7 abort paths tested); `parse_loot` published a `BP_RareLootManager` list **no function reads** as World Rare-Loot, and `parse_items` published that list's item tags as spawn locations (`0222e10`); `parse_ammo`'s headshot story was a flat multiplier when the blueprint scores a head hit as a share of max health (`3c9f66f`). The last two were established from **Kismet bytecode** — the decoder now takes `FW_SCRIPT=1` for that (`adfac10`, off by default; redecode_check still 722/722 identical with the rebuilt exe). **Earlier at `24536482`:** **Re-decoded and current at `24536482`** (`2f604df`) — 720 of 722 dumps byte-identical, 2 changed, 0 gone; catalog stamped `24536482`. **Re-confirmed 2026-08-05: 722/722 identical.** **Four real defects fixed 2026-08-05** (`99a4616..5e08d51`), none of them patch damage: `decode.py` returned the whole output directory rather than its own decode, so `get("ai_weapons")` handed back 19 files for a 16-file decode with 3 player-weapon defs attached (now one cache leaf per asset); the decoder **exited 0 on every total failure** — empty paks, no match, missing usmap — which `decode.py` cached as "this asset is empty at this build" (now exits 2/3/4/5/64); `FALLBACK_BUILD` was still `24501089` two builds on, so any Steam-less machine restamped backwards; and `steam.build_id`'s mid-update guard rejected nothing (FullyInstalled survives an update, so `1030`/`260` passed). Also: usmap provenance is now on disk (`mappings/provenance.json`), and the README documented a per-asset re-decode route that **cannot reach 470 of 722 dumps**. **Earlier at `24501089`** (`c56bb36`): All **722** tracked dumps re-decoded from the live game, **72 promoted**, catalog rebuilt and stamped `24501089`; `lootobjects` held at its curated 151-of-437. The staleness gap is closed: the 9 non-taxonomy subdirs are now current for the first time since before 24479102. **Added `tools/redecode_check.py`** — decodes by committed basename rather than by filter, so curation is preserved by construction and no subdir can silently widen; re-running it after promotion reports 0 changed across all 13 subdirs. `FALLBACK_BUILD` bumped. Earlier at `24479102`: usmap regenerated, 14 dumps of deleted assets removed, 74 weapon dumps promoted — **weapons only**, which is what cost the attribution on the other 40 this cycle. |
| `forever-winter-almanac` | 🟩 | **Pushed 2026-09-22 by `commander`: Pages confirmed serving `83052ed`** (live `SHELL_REV` `8a97b04e`; `check shell revision` and Pages both green on that commit). `83052ed` drops the Changelog tab's opening callout at Sylvia's request ("we don't need the callout that tells people what the changelog does"). Before it, two commits. `80b161b` finishes the facts-not-tips sweep: the four datasets regenerated from datamine `0118089`, plus app.js prose on the Weapons, Stats, Muzzles, Ammo, Detection, Enemies, Factions, Economy and Drops tabs. `4be1fbf` adds the **Changelog** tab (`#/changelog`). Its `data/changelog.json` is hand-written, the one file in `data/` that no tool generates, and is seeded with today's changes. The 13th tab would have widened the open sideways-scroll bug (721–~915 px became ~1046 px), so the tab strip now scrolls inside itself at every width: checked from 375 to 1280 px, with no page overflow. Checked as one tree before the push: the four changed parsers reproduce `data/` byte for byte; `node --check` and `stamp-sw --check` pass; all 13 tabs and both mod toggles render in the preview. The only console errors are the known `File:Map icon Europan exo.png` 404s. Before that, commander-1 pushed `4de08f1` and `77abdde` (the Stats tab's tips; live `SHELL_REV` `aa6b447a`). **Earlier: integrated push 2026-09-22, Pages confirmed serving `b108166`** (live `SHELL_REV` `8a34bf8b`; both workflows green on that commit). Twelve commits from four sessions went out in one push, with `commander` integrating: senses `055121a`; Blind Mother `b37494f` `5bc361a` `2a694b3`; HP `1eca991` `8f14e44` `297934b` `71051ba`; Unkillables `c35234f` `f29d846`; commander `57d6789` (Heavy Rifles ×5 headshot no longer labelled "baseline"; ".50 PST no row" reworded for players) and `b108166` (restamp). Checked as one tree before the push: every parser at datamine `4c9ecde` reproduces `data/` byte for byte, the senses abort harness reports 50 PASS / 0 FAIL / 1 OBSERVE (R11, by design), and every tab plus both mod toggles render in the preview. Mod credits were checked against Nexus's public API: #68 and #76 list Meganiikko as author, and #124 still serves 1.3. **Senses regenerated from each enemy's own blueprint, 2026-09-22** (`055121a`, data only, from datamine `81390cc`), pushed in that round. Detection: Mech ESP ×3 → none, Opal ESP → none, both turrets gain hearing 5.75 m (11.5 m violent), and the Soldier note "The baseline grunt" becomes "The baseline profile", since it now shows on every card built with those senses. Enemies: the Exo and Stilt Walker lose the borrowed Mech profile (the Exo is built with soldier senses; the Stilt Walker has Mech eyes and soldier hearing); the medium mech, Rat King and Toothy lose ESP; the turret gains hearing; and 17 cards gain a Senses block (MeatMan ∞ ESP). Cards take a Detection row's notes only when built exactly like it, so the 4 that match no row show numbers only. Previewed locally: the Detection table and 13 cards were read back from the DOM, with no console errors. `stamp-sw --check` is green at HEAD. Also on `main` and unpushed: `b37494f`, the Blind Mother session's hidden-cone fix; `5bc361a`, that session's "drop the boss taglines, and stop calling the Blind Mother blind"; and `1eca991` + `8f14e44`, **HP from each card's own blueprint** (data only, from datamine `7bdf3ee` + `973088c`). Neither moves a number. Rat King's How-to-kill note no longer claims "no separate body pool"; it now says Rat King has the same ~337,400 body pool as the Medium Mech. The data file's top-level note, which the page doesn't render, says HP comes from the same blueprint as senses. Previewed locally: the Rat King card renders the new note, with no console errors. Then `297934b` (data, from datamine `5e2913d`): card subtitles without tips, and Blind Mother's How-to-kill gives the DetPack kill instead of "Kill method unconfirmed". And `71051ba` (`app.js`): the "Datamined from each unit's own AI" callout is gone from the top of the Enemies tab. **`sw.js` is stale after `71051ba`** (`SHELL_REV` a8a921f4 → 8a34bf8b), left for the commander's single restamp at integration. Previewed locally, with no console errors. **To close:** push, then confirm Pages serves it. **Earlier:** **Republished at `25071553` 2026-09-22** (`e4fe319`, `dfe077c`) — **Pages confirmed serving `dfe077c`**: live `sw.js` carries `SHELL_REV` `db183afd`, live `ammo.json`/`detection.json` read build `25071553`, and both the `check shell revision` and Pages workflows passed on that commit. Prompted by two #wiki reports (Discord, 09-20/09-21): the 7.62x54mmR headshot (almanac ×3 vs wiki ×1.5 — ×3 is right, it moved at `24479102`) and Economy "Tunnels" items found on surface maps (the tag is read by nothing). All datasets regenerated from the datamine commits above, plus `fetch_weapons.py` (no datamined stat moved; the wiki filled real stability/recoil for 4 guns). **What players will see change:** Detection noise (walk 6 m, sprint 15 m), hearing now the player-facing radius (+ violent radius), vision now the player-facing cone (Mech 15/40 m, not 14/400), point-blank range; Ammo explains headshots as damage × caliber ÷ 450 of the health bar, with a per-caliber "A head hit takes" column; Economy loses the Tunnels/Regions badge for a "drops" link into the Drops tab; Drops gains Map Rare-Loot and a corrected World Rare-Loot. Verified in a local preview first, no console errors. **Earlier at `24536482`:** **Republished at `24536482` 2026-08-05** (`057dd53`, Pages build confirmed serving it). All 11 datasets restamped and the diff is **stamp-only** — the patch's 2 changed dumps touch fields no parser reads. `weapons.json` needed a separate run because its generator lives in the almanac repo, not the datamine, so it is missed by the parser batch by construction. Two claims regeneration could not reach were also fixed: the Stats tab hardcoded `24501089` / `76,309` in prose (now derived; re-measured at `24536482` — still 0 of **76,310** match `*Stability*`), and see the Heavy Rifles correction below. `unkillables.json` deliberately stays at `24501089`: that field is the build the URF pak was **verified** against, not a decode stamp. **Earlier at `24501089`** (`a47659e`, `51beb91`, `d89021e`): The Stability rework landed as a rework, not a restamp: the published dispersion analysis is **retired**, replaced by the evidence that the system was removed — 0 of 76,309 live files match `*Stability*`, 0 `UpgradeTuning`, 0 player `DA_WPN_PLAYER_*_v2`, and the 20 surviving `FC_*` are all global. The stat still exists on attachments (`WeaponPartStatsData`, 324 of 633 rows non-zero, byte-identical to the previous build), so the page states that the input survives and the transfer function is gone, with the caveat that this only disproves the *data-driven* path — the logic may have moved to compiled C++. **Root cause of the drift was not staleness:** `weapons.json` was a wiki scrape, so it is now generated from `DA_WPN_PLAYER_*` + `WeaponsDetailsData` + `ValueV2_WEAPONS`, wiki kept only for name/class/accuracy/recoil/stability. That found **more than the damage refresh** — 17 of 51 damage wrong *and* **44 of 51 XP wrong**, plus 3 magazines, 3 rates of fire, 2 values. Shotguns were a units mismatch, not an 11% drift: damage is stored **per pellet** with `NumberOfBuckshots` 20, so the app now shows per-pellet, pellet count and spread total. Detection gained the `HoldingPistol` modifier (1.2/0.8 on all 15 sensors with a modifier table — identical to a Stealth Rig), recorded without a build claim since it spans two patches. **Two board corrections:** there is no Gunsmith section in this repo (`grep -ri gunsmith` is empty), and see the Pistol Ammo/Thermite correction above. Also disarmed `tools/fetch_items.py`, which still rebuilt the datamined `economy.json` from the wiki. **Mod overlays fixed too** (`2d26e46`, `578a61f`, `8de506e`): `unkillables.json` picked up `24501089` once `URF 0cc0a19` + `datamine 2bc6b35` removed the hardcoded fallback; **the Heavy Rifles overlay was describing Meganiikko's upstream 0.9.2, which this build disabled** — 11 of 13 packages binding to nothing, so the tab published numbers the game never applies. Repointed at the v2.0 rebuild and now **read from `HeavyRifleRebalanceFix/tools/rebalance.conf`** rather than transcribed, which caught three stale values: HRF01 730→**780**, HRF02 28000→**27000**, RFL29 375→**650**. That last one is the one that bit: vanilla tripled the Vykhlop 175→600 past the mod's 375, so with the overlay on the site showed it hitting **37.5% weaker than vanilla** while its own note promised buffs — invisible until `weapons.json` was corrected to 600. VKS magazines were also renamed A/B→**B/C** to match the shipped mod. Attribution was half-and-half (credited Meganiikko, **#76**, while linking the community fix, **#123**); both are recorded now, plus a rendered `meta.status`. ⚠ **That status string was hardcoded in `parse_crafting.py` and went false the day v2.0 shipped** — it told users #123 hosted a disabled v1.1 for four days while #123 served a v2.0 that `24536482` had broken. Fixed 2026-08-05 (datamine `a6c9296`): it now reads the mod repo's own status line and **refuses** if that line is missing, the same stance `mod_target_build()` already took. Release state is not derivable from any file in these repos — do not restate it here. `crafting.json` gained a real `build` field after separating the vanilla decode build from the mod's target build, which had briefly been one constant. **Attachments/parts audited clean:** 279 entries joined to `WeaponPartStatsData` by display name via `ItemDetailsData`, **0 differing values** — the wiki transcribed the raw floats exactly, so those stay wiki-sourced on evidence rather than assumption. **`detection.json` is now generated** (`d06f066` / datamine `d19d32c`): `parse_detection.py` only ever *printed* an analysis for someone to transcribe, which is why the `HoldingPistol` modifier had to be added by hand this cycle. It now writes the file and **aborts** if the dumps contain a sensor, stealth tag or noise event no row claims (all five abort paths tested, 6/6 with a passing baseline), so the next patch that adds one breaks the build instead of publishing a hole. Found in passing: the old noise reader only checked `TravelDistance`, so every event defining only `PathTravelDistance` read as "(none)" — including `Player_Sprinting` (750 → 7.5 m). Also adds the **AT-43 railgun noise event at 10,000 m**, the loudest in the game by 10×, previously unpublished. **`drops-model.json` is generated too** (`cf14997` / datamine `parse_crate_types.py` → `parse_drops.py`), which closes the last hand-maintained dataset. That one had drifted furthest: **the wreck table listed 8 pools and the game has 16** — both Eurasian and Water Thief drones (24-item pools, identical to the Europan one that *was* listed), both vehicle cores, both med-mech weapon arms, the Red Baron quest Exo and the Assault HK corpse were all absent. It also **stated three times that every wreck can come up empty, which is false**: five pools guarantee a payout, from 6,771 cr (vehicle core) to **100,000 cr (Assault HK)**. That sentence is now computed from the rows, and the table gained a Floor column. Seven abort paths tested, 7/7 with a passing baseline. **Nothing in the almanac's `data/` is hand-maintained any more** (since 2026-09-22, with one deliberate exception: the Changelog tab's `changelog.json`, which is editorial and says so in its note). One follow-up for the datamine, not the almanac: `parse_loot.py` publishes no source for `Quest_Grabber_Sac` (the Grabber's sac, an 18-item pool), so the Drops panel excludes it rather than link to a dead end — that looks like a gap in `parse_loot`, not a decision. |
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
