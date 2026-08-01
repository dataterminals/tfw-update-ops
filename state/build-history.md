# Build history

Ledger of TFW builds and their depot manifest IDs. **The manifest ID is the rollback key** —
record it while the build is installed, because Steam overwrites it on patch.

App `2828860` · Depot `2828861` · Install `D:\SteamLibrary\steamapps\common\The Forever Winter`

> **Install path moved.** Every entry below 2026-08-01 was recorded when the library was on
> `H:\`. That drive is no longer present on this machine; Steam's `libraryfolders.vdf` now lists
> only `C:\Program Files (x86)\Steam` and `D:\SteamLibrary`, and there is exactly one
> `appmanifest_2828860.acf`. See the 24501089 section for the toolchain fallout.

| Build ID | Depot manifest | Steam `LastUpdated` | Size on disk | Notes |
|---|---|---|---|---|
| `24097213` | `7600230730618885177` | 2026-07-07 16:55 EDT | 50,779,543,727 B | Previous baseline. Almanac data stamped to this build. usmap `ForeverWinter-5.4.2.usmap` corresponds to it. Datamine tagged `baseline-24097213`. |
| `24479102` | `6430523508700280691` | 2026-07-30 17:34 EDT | 50,815,237,941 B | Applied 2026-07-30 17:34 EDT. 819,642,192 B download; install grew 35,694,214 B. Weapons-systems overhaul — see [`patch-notes-24479102.md`](patch-notes-24479102.md). All Session-1/2 triage work is stamped to this build. |
| `24501089` | `6443337773729671953` | 2026-08-01 06:42 (file mtime; no `LastUpdated` key in the acf) | 50,812,092,213 B | **Current.** Auto-applied 2026-08-01 06:42. 686,534,560 B download; install **shrank** 3,145,728 B (exactly 3 MiB). Patch notes not yet reviewed. |

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

## 24479102 → 24501089 — landed 2026-08-01 06:42, auto-applied

**The pre-patch window was not missed, but only by luck of prior work.** No `pre-24501089`
capture was taken, because the patch installed unattended. The `post-24479102` baseline
(76,309-entry filelist, catalog, binary hashes, MO2 state) is complete and serves as the
"before" side of this diff. Nothing is lost.

**Rollback key for `24501089`: `6443337773729671953`.** The previous build's key
(`6430523508700280691`, → `24479102`) is in the table above and remains usable.

Facts of record, read from the acf and the installed files:

- `StateFlags 4` (FullyInstalled, nothing pending), `UpdateResult 0`,
  `BytesDownloaded == BytesToDownload == 686,534,560`. The patch completed.
- **`AutoUpdateBehavior` is `0`** — "always keep this game updated". It was `1`
  ("only update when I launch it") through the 24479102 cycle, and that setting is what held
  the previous patch open long enough to capture a baseline. The hold is currently off.
- **The shipping executable changed.** Byte size is identical (`169,584,128`) but the SHA256
  is not:
  - `24479102`: `58EE4F8DFDE093E5C60D25DB7FEC780803EEF75A40062E40C43A03BA2D287875`
  - `24501089`: `E4E76D0E37782EA8E846CF21369BDDEB230BA219999B67A4C03CEBDF55A41C1E`

  Same size with different contents is a recompile that did not move the layout. **Gates 3
  (RE-UE4SS attach) and 3b (Signature Bypass AOB scan) both revert to unknown** — 3b in
  particular scans for a byte pattern and patches a fixed address, and that is the one
  dependency `AllWeaponsUnlockableFix` declares.

### Toolchain fallout: the `H:` → `D:` move

Every hardcoded path in the tooling points at a drive that no longer exists. Current locations:

| Thing | Hardcoded as | Actually at |
|---|---|---|
| Repos | `H:\Github Repositories` | `D:\Github Repositories` |
| Game | `H:\SteamLibrary\steamapps\common\The Forever Winter` | `D:\SteamLibrary\steamapps\common\The Forever Winter` |
| Steam acf | `H:\SteamLibrary\steamapps\appmanifest_2828860.acf` | `D:\SteamLibrary\steamapps\appmanifest_2828860.acf` |
| MO2 instance | `H:\MO2Instance_ModData\ForeverWinter\` | `D:\MO2_InstanceData\TheForeverWinter\` |

`tools/steam_state.ps1` does not merely miss the library — it **throws** on
`Join-Path` against the absent `H:` drive (line 37) before reaching its other candidate roots,
so the repo's own state check is dead until the roots are fixed. `tools/capture_baseline.ps1`
defaults (lines 28–29) are stale the same way, as are the `REPO` / `GAME_PAKS` assignments in
every mod repo's `build_fix.sh` and `ScavgirlCarryPerks/tools/verify_build.sh`.

## Post-patch close-outs

*(one dated section per completed update — see triage-pipeline Stage 9)*
