# HANDOFF — start here

**Written:** 2026-07-30, end of the session that created this repo.
**State:** repo scaffolded and pushed. Update **not applied**. Baseline **not captured**.

---

## The situation in four lines

- TFW is on build `24097213`. Build `24479102` (~820 MB) is downloaded-pending, **not applied**.
- Steam is set to **"only update when I launch it"** — so the patch lands the moment the game is
  launched, and not before. **Do not launch TFW.**
- Nothing has been captured yet. The old build is still on disk; that window is open until launch.
- 25 TFW repos are in scope, of which 12 mods are actively deployed in MO2.

## The single most important thing

**Capture the baseline before the game is launched.** Everything about this update gets easier or
harder based on whether we have a pre-patch snapshot to diff against. Class A (pak) mods fail
*silently* — without a baseline you cannot tell a working mod from a dead one without manually
re-verifying every value in-game.

```bash
pwsh -File "H:/Github Repositories/tfw-update-ops/tools/capture_baseline.ps1" -Label pre-24479102 -RunDecoderList
```

Read `docs/baseline-capture.md` first — particularly the "what NOT to capture" section, so nobody
tries to back up 48.5 GB of paks.

## First five actions for the next session

1. **Verify the window is still open.**
   `pwsh -File tools/steam_state.ps1` — confirm `Installed build: 24097213`. If it already reads
   `24479102`, we're past the window: skip to `docs/rollback.md` and decide whether a depot
   downgrade is worth it.

2. **Run the capture** — the decoder prerequisite is already confirmed (see below), so go straight
   to it with `-RunDecoderList`. Then check `state/baselines/pre-24479102/SUMMARY.md` — it prints its own
   warnings. An incomplete baseline is decorative; fix the warnings before moving on.

3. **Sanity-check `filelist.txt`** — it should be tens of thousands of lines. If it's empty or
   tiny, the decode failed silently and the baseline's most valuable piece is missing.

4. **Tag the datamine repo.** `git -C "H:/Github Repositories/forever-winter-datamine" tag baseline-24097213`
   and push the tag. The dumps live there; this makes the pre-patch state addressable by name.
   (Working tree was **clean** at HEAD `36b068b8` when checked.)

5. **Then, and only then, tell Sylvia the baseline is safe** and let her launch the game to apply
   the patch. From there, follow `docs/triage-pipeline.md` from Stage 0.

## Things established this session (don't re-derive)

- **Rollback key:** app `2828860`, depot `2828861`, manifest `7600230730618885177` for build
  `24097213`. Recorded in `state/build-history.md`. This is what makes the old build recoverable.
- **Deployment is MO2**, base `H:\MO2Instance_ModData\ForeverWinter`. 39 mod folders, **12 enabled**
  — that enabled set is the smoke-test loadout, listed in `registry/repos.md`.
- **Three third-party blockers** gate large chunks of work: RE-UE4SS (all of Class B), Signature
  Bypass, and TFWWorkbench (all Class A rebuilds). Test these before triaging our own mods.
- **`CleanUIRecipeTooltipFix` is a Project Zomboid mod**, not TFW. The name misleads. Excluded from
  the registry.
- **`TFW_CyborgNerfFix` is an empty repo** — `.git` only, zero commits, no working tree. Needs a
  decision: build it or archive it.
- **Pak set:** 118 files, 48,540,247,963 bytes. Not worth backing up; the manifest ID covers it.
- **Both tools are tested and working.** `steam_state.ps1` ran clean; `capture_baseline.ps1` ran
  clean end-to-end as a smoke test (~442 KB output, since deleted).
- **The decoder prerequisite is satisfied.** Both .NET SDK `8.0.420` and **`10.0.301`** are
  installed, and `datamine/decoder/bin/Release/net10.0/fwextract.exe` exists (built 2026-07-27).
  So `-RunDecoderList` should work. **The datamine README is stale on this point** — it says only
  SDK 8 is installed, which is why `fwdata` shells out to the prebuilt exe instead of
  `dotnet run`. Worth correcting there at some point; harmless either way.

## Known unknowns

- **What's actually in the patch.** No patch notes reviewed. Worth 5 minutes before Stage 1 — a
  content patch and an engine bump are very different days.
- **Whether the usmap survives.** Unknowable until we decode against the new build.
- **Whether the AES key rotated.** Constant across every patch so far, but "so far" is load-bearing.
- **Whether a compatible experimental RE-UE4SS build exists** for the new engine build. If not,
  Class B is blocked on upstream and should be parked, not stalled on.

## What was deliberately not done

- No mod code was touched. No repo other than this one was modified.
- No Steam settings were changed — Sylvia set the update hold herself.
- The game was not launched.
- `state/status.md` was created but every row is ⬜. It is a plan, not a record.
