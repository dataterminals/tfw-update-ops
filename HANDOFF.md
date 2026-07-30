# HANDOFF — start here

**Written:** 2026-07-30, updated the same day as the patch was applied.
**State:** baseline **captured and verified**. Patch **applied** (or applying) — Sylvia launched
the game on 2026-07-30 after the baseline was confirmed safe.

---

## The situation in four lines

- Baseline `pre-24479102` is captured, verified, committed and pushed. **The window was not missed.**
- The patch to build `24479102` was deliberately triggered afterwards by launching TFW from Steam.
- Patch notes are known: a **content patch** — comprehensive weapons-systems overhaul. No engine bump.
- 25 TFW repos are in scope, of which 12 mods are actively deployed in MO2.

## The single most important thing

**Do not launch through MO2 until Gate 3.** The old-build loadout against a patched game either
crashes or, worse, silently muddies triage. The first MO2 launch should carry **only RE-UE4SS +
Signature Bypass** — that run is simultaneously the UE4SS gate test and the smoke test that MO2
support still works on the new build.

## Where to pick up

Follow [`docs/triage-pipeline.md`](docs/triage-pipeline.md) from **Stage 0**.

1. **Stage 0 — record the landing.** `powershell -File tools/steam_state.ps1`, then append the new
   row to `state/build-history.md`. **The new depot manifest is the rollback key for the *next*
   patch** — capture it while it is in front of you; Steam overwrites it on the following update.

2. **Capture the post baseline and diff it.** Both steps, in order:
   ```bash
   powershell -File tools/capture_baseline.ps1 -Label post-24479102 -RunDecoderList
   powershell -File tools/diff_baseline.ps1 -Before pre-24479102 -After post-24479102
   ```
   The report lands in `state/diffs/pre-24479102__vs__post-24479102/REPORT.md`.

3. **Gate 1a / 1b — AES key and usmap.** If the diff says the shipping exe is byte-identical, the
   AES key cannot have rotated and the UE4SS/Signature-Bypass signatures still match; the report
   says so explicitly. Otherwise re-run AESDumpster. Then decode a known asset and check the
   values are plausible before trusting anything downstream.

4. **Route the diff at the mods.** Intersect the asset churn against
   [`state/asset-dependencies.md`](state/asset-dependencies.md) — it maps every Class A/B mod to
   the exact asset paths, DataTables, classes and gameplay tags it depends on. That intersection
   is the Stage 5 work list. Update `state/status.md` as each row resolves.

5. **Then Gate 3** — the RE-UE4SS-only MO2 launch described above.

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
- **All three tools are tested and working.** `steam_state.ps1` and `capture_baseline.ps1` both ran
  clean on real data. `diff_baseline.ps1` was verified against a synthetic patched baseline that
  exercised every branch (binary add/change/remove, pak churn, filelist add/remove, and all four
  DataTable states) — not just the no-op self-diff.
- **The decoder prerequisite is satisfied.** Both .NET SDK `8.0.420` and **`10.0.301`** are
  installed. The stale datamine README claim about SDK 8 has been **corrected** (`5570d5d`), and
  `Microsoft.Bcl.Memory` was bumped to `10.0.10` to clear a high-severity advisory — verified
  non-disruptive: the regenerated filelist was byte-identical to the captured baseline.
- **Patch notes are known and archived** in [`state/patch-notes-24479102.md`](state/patch-notes-24479102.md),
  with a per-mod blast-radius read. Headline: weapons-systems overhaul, no engine bump.

## Known unknowns

- **Whether the usmap survives.** Unknowable until we decode against the new build. The absence of
  an engine bump in the notes is encouraging but not proof.
- **Whether the AES key rotated.** Constant across every patch so far, but "so far" is load-bearing.
  If the shipping exe turns out byte-identical, this is settled for free.
- **Whether a compatible experimental RE-UE4SS build exists** for the new build. If not,
  Class B is blocked on upstream and should be parked, not stalled on.
- **Whether weapon DataTables were retuned in place.** Near-certain from the patch notes, and
  *invisible* to the catalog diff (same RowStruct, same row count). Requires a dump-value diff.

## What was deliberately not done

- No mod code was touched. Only this repo and `forever-winter-datamine` were modified.
- No Steam settings were changed — Sylvia set the update hold herself, and triggered the patch
  herself by launching from Steam once the baseline was confirmed safe.
- The game has **not** been launched through MO2. Do not, until Gate 3.
