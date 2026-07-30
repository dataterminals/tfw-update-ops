# tfw-update-ops

**Command post for The Forever Winter game updates**, as they affect everything we ship.

TFW patches break things in predictable ways, but our work is spread across 25+ repos, a
private datamine toolkit, two PWAs, and a live MO2 instance. Without a centre, a patch turns
into 25 independent panics and something always gets missed. This repo is the centre.

It holds **no mod code**. It holds the *registry*, the *procedure*, and the *state*.

## The hierarchy

```
registry/     WHAT we own, and what each thing is exposed to
  repos.md      human-readable inventory, grouped by exposure class
  repos.json    the same, machine-readable — scripts and agents read this

docs/         HOW an update is handled (the doctrine — stable across patches)
  exposure-model.md    the five classes, and what kind of patch breaks each
  baseline-capture.md  what to snapshot BEFORE the update lands, and why
  triage-pipeline.md   the ordered post-update sequence
  rollback.md          the escape hatch — Steam depot downgrade

state/        WHERE WE ARE (the live, per-patch stuff — this churns)
  build-history.md   ledger of build IDs + depot manifest IDs over time
  status.md          the board: per-repo status for the in-flight update

tools/        the small scripts the procedure calls
  steam_state.ps1       read live Steam build / target / depot / schedule
  capture_baseline.ps1  take the pre-update snapshot
```

## Rules of engagement

1. **`state/status.md` is the single source of truth** for "is this mod done yet." Not memory,
   not the individual repo's WORKLOG. If it isn't green on the board, it isn't done.
2. **Nothing ships until the datamine is re-decoded.** `forever-winter-datamine` is upstream of
   the almanac, maps, fwact, and half the mods. Fixing a mod against stale dumps wastes the fix.
3. **Baseline before you patch.** Once Steam applies the update the old build is gone from disk;
   recovering it means a depot downgrade (see `docs/rollback.md`). Cheap now, expensive later.
4. **One repo, one owner-session.** Fixes land in the mod's own repo. This repo only tracks that
   they happened.

## Current situation

See [`state/build-history.md`](state/build-history.md) — as of 2026-07-30 the game is on build
`24097213` with build `24479102` (~820 MB) queued and **held pending go-ahead**. Baseline capture
has not been run.

Start any new session from [`HANDOFF.md`](HANDOFF.md).
