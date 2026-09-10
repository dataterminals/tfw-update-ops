# HANDOFF — the `25071553` cycle

> **Written 2026-09-10.** Per-cycle document — check that date before trusting a word of it.
> [`state/status.md`](state/status.md) is the source of truth for progress; this file is the
> orientation. If you are writing the next cycle's handoff, **replace this file rather than
> appending to it** — a stale "start here" is worse than none.

---

## The situation in six lines

- **Build `25071553` landed 2026-09-03, unattended.** `AutoUpdateBehavior` is `0` on SylG5, so it
  applied itself. **No `pre-25071553` capture exists and none can**; `post-24536482` is the
  "before" side. Rollback key **`4492887131597018203`**.
- It folds in **four announced versions**, `0.9.5.0` (08-28) through the `0.9.5.3` hotfix (09-02).
  The three intermediate depot manifests are gone, so **rollback granularity this cycle is one
  step, not four.**
- **Gate 1b is RED** — the usmap is stale, `FWWeaponDefinition` decodes 30 properties where
  provenance records 57. **Every value-level decode is void.**
- **Gate 3 is UNATTEMPTED** — no `UE4SS.log` exists. All of Class B is unknown.
- **Root Builder is ARMED.** No MO2 launch since 2026-08-04, so its cache has had no chance to
  rebuild against this build.
- **A previously-unknown mod-detection subsystem is in the live cook** and in no patch note. See
  [`state/scriptobjects-25071553.md`](state/scriptobjects-25071553.md).

## One sitting clears most of it

In this order. Steps 1 and 2 are preconditions — doing 3 without them produces numbers off a
part-July install with a mod that crashes.

1. **Delete Root Builder's `GameData.json` AND its sibling `Backup\` — together.** Removing only
   the cache leaves ~47 GB of July files ready to restore; removing only the backup leaves the
   cache asserting the game looks like July. On SylG5 they live under
   `C:\Modding\MO2\plugins\data\RootBuilder\DSteamLibrarysteamappscommonThe_Forever_Winter\5_4_2_0\`.
   The key is the **engine** version, which has not changed since July — that is why it never
   self-corrects.
2. **Disable `CMSF v0.2.1 dev` in the profile.** It holds a Jul 25 pak and will crash at launch.
   Consider also disabling `+UnkillablesRebalanceFix` — it is enabled and carrying a two-build-stale
   v1.2 pak, which makes it a smoke-test contaminant.
3. **Launch → `DumpUSMAP()` → exit.** Experimental UE4SS into `Binaries\Win64`, a Lua mod calling
   `DumpUSMAP()`, then remove UE4SS again. Archive the outgoing `24536482` map under
   `mappings/archive/` with its build in the filename and update `provenance.json` **in the same
   commit**.

Gate 3, gate 3b and gate 5a all fall out of the same launch for free. **Gate 1b clearing is what
un-voids the collection** — no Class A pak may be rebuilt against a stale map.

⚠ **Gate 3 clearing does not clear Class B.** All four Class B mods are *absent* from SylG5's mod
store, not merely disabled. The runtime host (`RE-UE4SS`, `Signature Bypass`) is enabled and ready;
there is nothing for it to load. Deploy them first — they are loose Lua.

## 🖥 Picking this up on SylDesk

> **✅ Remediated on SylDesk, 2026-09-10, measured on the machine itself.** The table below is kept
> because its *method* still applies to the next cycle, but its SylDesk column is now history. What
> was actually found is in the rows marked **was / now**. The patch was applied in the same
> sitting and **verified**: SylDesk's shipping exe now hashes `D87AE674…`, byte-identical to the
> `post-25071553` baseline captured on SylG5, and its `FWPakManifest.json` hashes `5362C74E…`,
> also identical to that baseline. The two machines are provably on the same cook.

| | SylG5 | SylDesk — was | SylDesk — now |
|---|---|---|---|
| Build | `25071553` | `24501089`, two cycles back | patched to `25071553` |
| `AutoUpdateBehavior` | `0` (self-applies) | `1` (waits) | `1`, unchanged |
| Root Builder cache + backup | ✅ cleared 2026-08-04, but **re-armed** since | ❌ never done, armed | ✅ **cleared, both together** |
| Displaced exe in `overwrite\Root` | ✅ deleted | ❌ still armed | ✅ **moved out** |
| Last written to git | current | 2026-08-03 11:40 | current |

**Two board figures were wrong and are corrected by measurement:**

- **Root Builder's `Backup\` was 2,240,296,629 bytes — 2.1 GB, not "~47 GB".** 154 files, all stock
  (the `.pak`s in it are Chromium/CEF locale paks, not UE content). Nothing in it was unique.
- **The displaced exe was not a copy of the live one.** Same 169,584,128 bytes, but SHA256
  `58EE4F8D…` against the live `E4E76D0E…` — it is the **bitfix-patched** exe (`bitfix.txt` records
  `writing C3 to 7FF7D6770290`). `CrashReportClient.exe` differed too, and the exe *inside*
  `Backup\` was **169,513,984** bytes, older still than 24501089. The hazard was real: an MO2 launch
  would have laid a patched two-builds-old binary over whatever Steam had just written.

The standing pre-session exe check **passed before any of this**: SylDesk's live exe hashed
`E4E76D0E…`, exactly the `pre-24536482` baseline, so the machine was genuinely on 24501089 and not
silently running a foreign build. All 7 game binaries matched that baseline; the two "missing"
rows against it are `dsound.dll` and `bitfix.txt`, which are MO2-deployed rather than game files.

Preserved at `H:\MO2Instance_ModData\_preserved-syldesk-2026-09-10\` with a `HASHES.txt` recording
everything before removal: both displaced exes, and SylDesk's own `bitfix.txt` and `UE4SS.log`,
which are genuinely unique — they differ from the `post-24536482` copies. The overwrite usmap was
**not** preserved: it is byte-identical to `mappings/archive/ForeverWinter-5.4.2-build24479102.usmap`.

**No pre-patch baseline was captured, deliberately.** `pre-24536482` *is* a 24501089 baseline and
its exe hash matches this machine's to the byte, and the rollback key `6443337773729671953` was
already in `build-history.md`. There was nothing left to capture.

### Two corrections to what the board believes about SylDesk

1. **Class B is not absent here.** SylDesk's store holds `TFWLootAll`, `TFWQuestHUDToggle` and
   `TFWStaggerControl`, and the preserved 2026-07-30 log shows all three loading from `enabled.txt`
   and running. "There is no Class B loadout" is true of SylG5 and was never measured here.
2. **The usmap dump does not need a Lua mod.** Step 3 of "One sitting clears most of it" says to
   write one that calls `DumpUSMAP()`. SylDesk already did this on 2026-07-30 using UE4SS's
   built-in **Mappings Generator by OutTheShade** from the GUI console (`GuiConsoleEnabled = 1` in
   `UE4SS-settings.ini`); the log records `Mappings Generation Completed Successfully!` and
   `Output file: ForeverWinter-5.4.2-0+UE5-2172883.usmap`. UE4SS here is
   `v3.0.1 Beta #0 - Git SHA #2172883`, which is the experimental build `CMSFUnlock` targets.

Also note SylDesk's profile needs no mod disabling before a smoke test: **every CMSF and rebalance
mod is already `-` in `modlist.txt`**, with only `RE-UE4SS` and `Signature Bypass` enabled.

### Do these in order on SylDesk

> **All of 1–5 were done on 2026-09-10** and their findings are recorded above. **6 was skipped
> deliberately** — `pre-24536482` already *is* a 24501089 baseline whose exe hash matches this
> machine to the byte, and the rollback key was already recorded, so there was nothing left to
> capture and the pre-patch window cost nothing to spend. The steps stay here as the method for
> next cycle.
>
> ⚠ **Step 5's completion criterion is misleading and should be read as `StateFlags 4` alone.**
> Watched live through this patch, `BytesDownloaded == BytesToDownload` went true *early*, with the
> apply phase still to come; `BytesStaged == BytesToStage` then also went true (38,256,399,262 B)
> while `StateFlags` was still `1030` `[UpdateRequired | FullyInstalled | UpdateRunning]`. Both byte
> equalities are reached before the update is finished. **Only the `StateFlags` transition to `4`
> means done.**
>
> Also worth knowing for next time: Steam's cached `TargetBuildID` was a month stale and read
> `24536482` until the client refreshed, at which point it re-targeted to `25071553` and the
> download grew from 413 MB to 1,495,072,128 B. Do not size the job off the pre-refresh figure.

1. **`powershell -File tools/steam_state.ps1`** — read the actual state. Do not trust the table
   above; it is a month old and was never measurable from here.
2. **Compare the shipping exe's SHA256 against the baseline before anything else.** This is the
   standing pre-session rule and it exists *because of SylDesk* — it was running the previous
   build's executable for four days with nothing in any log naming it. The baselines have always
   captured the hash; nothing was ever reading it.
3. **Clear `GameData.json` and `Backup\` together**, under SylDesk's `H:`-keyed plugin directory.
   Until this is done, any measurement taken on that machine is suspect.
4. **Delete the displaced exe from `overwrite\Root`.** `overwrite\` deploys at the highest
   priority, so the next session copies a stale exe over whatever Steam wrote. Preserve anything
   unique first (`UE4SS.log`, `bitfix.txt`, a usmap) — hash-compare before removing, do not assume.
5. **Only then** apply the pending patch, **from the Steam client's Downloads page**.
   `steam://install/<appid>` is silently ignored. Completion is
   `BytesDownloaded == BytesToDownload` **and** `StateFlags 4`; `BytesToDownload` is an estimate,
   not a contract.
6. **Capture a baseline before the patch downloads a byte.** With `AutoUpdateBehavior 1` the
   pre-patch window is genuinely available on this machine — that is the one advantage SylDesk has
   over SylG5, and it has been wasted every cycle so far. Run a **Steam verify first** so the
   baseline is manifest-validated rather than merely observed.

**Resolve every path from `registry/repos.json` → `roots.<hostname>`.** Never hardcode a drive.
SylDesk's store is `H:\MO2Instance_ModData\ForeverWinter\mods\`; SylG5's is
`D:\MO2_InstanceData\TheForeverWinter\mods\`.

⚠ `capture_baseline.ps1` still hardcodes `H:` defaults and has **not** had the drive-safety
treatment `steam_state.ps1` got. On SylDesk that happens to be correct; it is a trap on SylG5.

## What is actually known this cycle

**Structural findings are sound** — they read no type map. **Everything value-level is void.**

The filelist diff is **153 added / 142 removed and mostly directory-case churn**, which must not be
read as movement (UE lowercases the package name before hashing `FPackageId`). The genuinely new
content is small: Europa behaviour trees `Trees_v2`→`Trees_v3` with new EQS queries and a
danger-close decorator, `BTTask_AI_FindRandomSpotNearKey` removed, Shaman MAY material renames, the
`SM_WPN_SHG05_RCV` receiver split, and a recased `Toothy` AI set.

**A read-only board audit ran 2026-09-10 and completed 7 of 13 repos** before a session limit cut
it off — **the adversarial verification pass never ran on any of them**. Those seven rows are
single-source. `AllWeaponsUnlockableFix`, `TFWStaggerControl`, `TFWQuestGiverPortraitPatch`,
`forever-winter-datamine`, `forever-winter-almanac` and `TombstoneAlways` were never audited and
still carry `24536482`-or-older text. **Re-running that audit is the cheapest next task and it is
not gate-blocked.**

### Three things the audit found that were not on the board

1. **`UnkillablesRebalanceFix` is ENABLED carrying a two-build-stale v1.2 pak** while a verified
   v1.3 sits unshipped in `dist/`. The board said "left disabled as found" — false on both counts.
2. **`HeavyRifleRebalanceFix` v2.1 was built and verified on `24536482`** a day *after* the board's
   last write, and was never uploaded. **Nexus #123 has served the broken 2.0.0 for five weeks.**
   Do not upload v2.1 blind — a `24536482`-targeted pak on a live `25071553` risks a second broken
   release.
3. **There is no Class B loadout on SylG5 at all** — all four mods absent from the store, not
   disabled. Unstated for two cycles.

## ⚠ The finding that may outrank the whole cycle

`FWModIntegritySubsystem` is in the live cook and not in July's: mod detection with **party-wide
replication**, plus a **weapon-damage override gated on `IsStockWeapon`**. It is in no patch note.

The anti-tamper manifest it plausibly consumes — `FWPakManifest.json` — is dated from this repo's
own baselines to **`24479102`, 2026-07-30**, so the surface is six weeks old and the collection has
been running against some of it without symptoms. **That lowers the urgency; it does not close the
question.** Full working, including what is *not* settled, in
[`state/scriptobjects-25071553.md`](state/scriptobjects-25071553.md).

**Blast radius is the weapon mods, not the cosmetics.** If server-side damage normalisation is
real, `HeavyRifleRebalanceFix`'s launch gate ("HRF01 must deal ~780, not ~300") could fail for
reasons that have nothing to do with the pak being correct. **That is a Nexus-page question and
Nexus-facing prose is Sylvia's** — flagged, not drafted.

## What is NOT true, and must not be re-derived

- **Container staleness does not explain the CMSF launch crash.** It was proposed, tested against
  the parsed name sets, and ruled out. The rebuilt CMSF pak is **not a demonstrated fix**.
- **Store *growth* is a non-event.** Only two script objects were ever removed
  (`FWReplicatedAimRecord`, `OnRep_AimReplication`). **Do not tell six repos to rebuild.**
- **A clean filelist diff does not mean a patch is harmless.** It compares schema and row counts; a
  tuning pass that rewrites values in place is invisible to it.
- **A passing check is not a check that tested anything.** This project has shipped vacuous ones.

## Division of work, 2026-09-10

`TFWCharModelSelFramework` is being handled by a parallel session: the mechanism investigation, the
Class A exposure audit, and CMSF itself. **One repo, one owner** — this repo does not touch another
repo's build. Nothing has been pushed to Nexus or Discord, and `modlist.txt` is untouched by both
sessions.

⚠ **"One repo, one owner" protects authorship, not the filesystem.** Sessions share one working
tree per repo, and on 2026-09-10 a `git add -A` here committed another session's uncommitted edit
under the wrong authorship — with a near-miss that would have destroyed it silently instead.
**Never `git add -A` in a shared repo; stage explicit paths, and claim a shared file before editing
it.** Full protocol and the structural fix in
[`docs/multi-session-protocol.md`](docs/multi-session-protocol.md).
