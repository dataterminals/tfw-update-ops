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

**SylDesk is two cycles behind and has never been remediated.** Everything below is unverified from
SylG5 — `H:` does not exist here, and joining it throws `DriveNotFound` rather than reporting
nothing, which has already taken down `steam_state.ps1` once. **Measure, do not assume.**

| | SylG5 | SylDesk |
|---|---|---|
| Build | `25071553` | **`24501089`** — two cycles back |
| `AutoUpdateBehavior` | `0` (self-applies) | **`1`** (waits) |
| Root Builder cache + backup | ✅ cleared 2026-08-04, but **re-armed** since | ❌ **never done** — ~47 GB, still armed |
| Displaced exe in `overwrite\Root` | ✅ deleted | ❌ **still armed** |
| Last written to git | current | 2026-08-03 11:40 |

### Do these in order on SylDesk

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
