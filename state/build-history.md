# Build history

Ledger of TFW builds and their depot manifest IDs. **The manifest ID is the rollback key** —
record it while the build is installed, because Steam overwrites it on patch.

App `2828860` · Depot `2828861` · Install `H:\SteamLibrary\steamapps\common\The Forever Winter`

| Build ID | Depot manifest | Steam `LastUpdated` | Size on disk | Notes |
|---|---|---|---|---|
| `24097213` | `7600230730618885177` | 2026-07-07 16:55 EDT | 50,779,543,727 B | Previous baseline. Almanac data stamped to this build. usmap `ForeverWinter-5.4.2.usmap` corresponds to it. Datamine tagged `baseline-24097213`. |
| `24479102` | `6430523508700280691` | 2026-07-30 17:34 EDT | 50,815,237,941 B | **Current.** Applied 2026-07-30 17:34 EDT. 819,642,192 B download; install grew 35,694,214 B. Weapons-systems overhaul — see [`patch-notes-24479102.md`](patch-notes-24479102.md). |

## 24097213 → 24479102 — landed 2026-07-30 17:34 EDT

**The window was not missed.** Baseline `pre-24479102` was captured, verified (0 warnings,
76,589-entry filelist) and pushed *before* the patch was triggered; the datamine repo is tagged
`baseline-24097213` at `36b068b8`. Sylvia then launched TFW from Steam deliberately to apply it.

Sequence of record:

- Hold mechanism: `AutoUpdateBehavior` `1` (only update when I launch it) neutralized the
  scheduled 2026-07-31 05:26 EDT slot, so the patch landed only on deliberate launch. Confirmed
  working — the build sat at `24097213` for the whole capture.
- Applied 17:34:02 EDT; `StateFlags` settled to `4` (FullyInstalled, nothing pending).
- Download 819,642,192 B. Install grew 50,779,543,727 → 50,815,237,941 B (**+35,694,214 B**), which
  is a small net delta for an 820 MB patch — consistent with rewriting existing assets rather than
  adding bulk content.
- **New rollback key `6430523508700280691`** captured immediately, before anything could overwrite
  it. This is the key that recovers `24479102` after the *next* patch.

**Patch notes reviewed 2026-07-30** (Discord announcement, archived with a blast-radius read in
[`patch-notes-24479102.md`](patch-notes-24479102.md)). Characterization: **content patch** —
comprehensive weapons-systems overhaul (recoil/bloom/ADS/sway, mod effects, non-linear skill
scaling, DPM tuning pass on all weapons) + AI fixes + networking reliability + crash fixes. No
engine-version bump mentioned; ~820 MB fits a data patch. Weapon/skill DataTables near-certainly
changed → `HeavyRifleRebalanceFix`, `AllWeaponsUnlockableFix`, almanac gunsmith are the expected
hot spots; AI BP fixes raise the prior on the `UnkillablesRebalanceFix` boss BPs. Still unknown
until decode: AES key, usmap survival.

## Post-patch close-outs

*(one dated section per completed update — see triage-pipeline Stage 9)*
