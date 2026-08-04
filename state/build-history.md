# Build history

Ledger of TFW builds and their depot manifest IDs. **The manifest ID is the rollback key** —
record it while the build is installed, because Steam overwrites it on patch.

App `2828860` · Depot `2828861` · Install: `H:\SteamLibrary\...` on **SylDesk**,
`D:\SteamLibrary\...` on **SylG5**

> **The install path is per-machine, not moved.** The paragraph that used to sit here said
> `H:\` "is no longer present on this machine" — true on SylG5, where it was written, and false
> on SylDesk, where `H:` is the NVMe holding both the library and the repos. Corrected
> 2026-08-03 after reading `H:\SteamLibrary\steamapps\appmanifest_2828860.acf` directly. Every
> entry below 2026-08-01 was recorded on SylDesk; the `24501089` row was recorded on SylG5.
> **The two installs are independent Steam copies and can sit at different builds** — as they
> did from 2026-08-01 to 2026-08-03. See the 24501089 section for the toolchain fallout.

| Build ID | Depot manifest | Steam `LastUpdated` | Size on disk | Notes |
|---|---|---|---|---|
| `24097213` | `7600230730618885177` | 2026-07-07 16:55 EDT | 50,779,543,727 B | Previous baseline. Almanac data stamped to this build. usmap `ForeverWinter-5.4.2.usmap` corresponds to it. Datamine tagged `baseline-24097213`. |
| `24479102` | `6430523508700280691` | 2026-07-30 17:34 EDT | 50,815,237,941 B | Applied 2026-07-30 17:34 EDT. 819,642,192 B download; install grew 35,694,214 B. Weapons-systems overhaul — see [`patch-notes-24479102.md`](patch-notes-24479102.md). All Session-1/2 triage work is stamped to this build. |
| `24501089` | `6443337773729671953` | 2026-08-01 06:42 (file mtime; no `LastUpdated` key in the acf) | 50,812,092,213 B | **Installed on BOTH machines** — SylG5 auto-applied 2026-08-01 06:42, SylDesk deliberately 2026-08-03 11:36:51. 686,534,560 B download; install **shrank** 3,145,728 B (exactly 3 MiB). Patch notes not yet reviewed. |
| `24536482` | *(not installed — no manifest yet)* | — | — | **PENDING on SylG5, not applied.** 413,369,888 B to download, **0 downloaded**. `StateFlags 6` (UpdateRequired + FullyInstalled). Baseline `pre-24536482` captured 2026-08-03 20:10 EDT **while `24501089` was still on disk**. SylDesk state on this build not read. |

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

### Toolchain fallout: the tooling is single-machine

**There are two work machines, and every script hardcodes the desktop's layout.**

| Thing | SylDesk (desktop) — what the scripts assume | SylG5 (laptop) — where this was run |
|---|---|---|
| Repos | `H:\Github Repositories` | `D:\Github Repositories` |
| Game | `H:\SteamLibrary\...\The Forever Winter` | `D:\SteamLibrary\...\The Forever Winter` |
| Steam acf | `H:\SteamLibrary\steamapps\appmanifest_2828860.acf` | `D:\SteamLibrary\steamapps\appmanifest_2828860.acf` |
| MO2 instance | `H:\MO2Instance_ModData\ForeverWinter\` | `D:\MO2_InstanceData\TheForeverWinter\` |

`H:` is the desktop's NVMe and is not a drive letter on the laptop at all. So these paths are
not stale — they are correct on SylDesk and absent on SylG5. **The fix is per-machine
resolution, not a global find-and-replace**, which would just invert the breakage.

Failure modes observed on SylG5:

- `tools/steam_state.ps1` **throws** on `Join-Path` against the absent `H:` (line 37) before
  reaching its other candidate roots, so it dies instead of falling through to the roots that
  do exist. The candidate list is right; the iteration is not drive-safe.
- `tools/capture_baseline.ps1` defaults (lines 28–29) point at `H:` with no fallback.
- Every mod repo's `build_fix.sh` assigns `REPO` / `GAME_PAKS` to `H:` paths, as does
  `ScavgirlCarryPerks/tools/verify_build.sh` (which at least reads them from the environment
  first, so it is overridable today; the `build_fix.sh` scripts are not).

**Consequence for the ledger:** builds recorded before 2026-08-01 were measured on SylDesk.
`24501089` was read on SylG5. The two installs are independent Steam copies and **can sit at
different builds** — do not assume a build row describes both machines.

## 24479102 → 24501089 on **SylDesk** — applied 2026-08-03 11:36:51 EDT, deliberately

The desktop ran two days behind the laptop. `AutoUpdateBehavior` here is **`1`** ("only update
when I launch it"), not the `0` recorded from SylG5 — so the hotfix sat pending on this machine
from 2026-08-01 until it was pushed through on request.

- Applied **without launching the game**, via the Steam client's Downloads page (the app was
  listed under *Scheduled* as "UPDATE ON LAUNCH, this week 6:31 PM"; its start-now button was
  clicked). `steam://install/<appid>` did **not** work — Steam was running tray-only with no
  client window and silently dropped the protocol call, and it dropped it again with the window
  open. **Opening Downloads and clicking the per-app start button is the reliable route**, and it
  avoids launching, which matters whenever a baseline window is still open.
- Download 757,311,296 B (the acf predicted 686,538,384). `StateFlags` settled to `4`.
  Size on disk 50,812,092,213 B — **exact match** for the figure recorded from SylG5.
- **Rollback key `6443337773729671953`** — identical to the laptop's. Confirms the key is a
  property of the depot, not of the machine.
- Shipping exe SHA256 `E4E76D0E…` — **identical to the laptop's recording**. First cross-machine
  confirmation that two independent Steam copies land byte-identical.

### The finding: this desktop had been running the *previous build's* executable

Measured immediately before the update, the game-dir exe was **169,513,984 B, mtime
2026-07-07T20:47:57Z** — an exact size-and-timestamp match for the **`24097213`** row in
`baselines/pre-24479102/binaries-win64.csv` (SHA `CAEFF67E…`), and a mismatch on both fields
against the `24479102` exe that `baselines/post-24479102/` captured on 2026-07-30
(169,584,128 B / `58EE4F8D…`).

So while Steam's manifest read `24479102` for four days, the binary on disk was `24097213`'s.

**Where the real one went is hash-proven:** the `24479102` exe is sitting in the MO2 instance at
`overwrite\Root\Windows\ForeverWinter\Binaries\Win64\ForeverWinter-Win64-Shipping.exe` —
169,584,128 B, SHA `58EE4F8D…`, mtime `2026-07-30 17:22:43` (the moment Steam wrote it). Root
Builder pulled the patched executable *out* of the game directory into MO2's overwrite and
restored its own pre-patch backup in its place, almost certainly on exit from the Gate 3/3b
session at 17:50 that day. This is the failure mode the standing note about Root Builder's
`GameData.json` cache and backup describes, landing on the shipping executable itself.

**Two consequences.**

1. **Gate 3 and 3b's green marks are still good, but for a narrower claim than the board
   implies.** They were measured *during* that session, so they tested RE-UE4SS and Signature
   Bypass against the correct `24479102` binary. Anything launched on this desktop *after* that
   session ran the `24097213` exe against `24479102` paks.
2. **The stale copy is still armed.** MO2's `overwrite\` deploys at the highest priority, so the
   next Root Builder session would copy that `24479102` exe over the `24501089` one Steam just
   wrote — silently reverting the executable one build behind, again. **This must be cleared
   before any in-game measurement**, or the HRF damage reading, the Gate 3/3b re-clear and the
   Class B functional tests all get taken against the wrong binary. Not cleared here: MO2 was
   running at the time, and the established procedure is that the backup and the `GameData.json`
   cache must be removed **together** — removing the backup alone leaves the cache authoritative.

**Method note:** the game-dir exe was sized and timestamped before the update but never hashed,
so identification of it as `24097213` rests on size + mtime, not on a digest. Steam has since
overwritten it, so that can no longer be upgraded to proof. The *displaced* copy in MO2's
overwrite is hash-proven. **Add the shipping exe's SHA256 to the pre-launch checklist** — the
baselines capture it, but nothing compares it before a session.

## 24501089 → 24536482 — PENDING on SylG5 as of 2026-08-03 20:10 EDT, not yet applied

**The pre-patch window was caught this time, deliberately rather than by luck.** Steam is holding
`24536482` as a pending update and the `24501089` files are untouched on disk, so `pre-24536482`
is a true pre-patch baseline. Contrast the previous cycle, which installed unattended and survived
only because `post-24479102` happened to serve as the "before" side.

State read from the SylG5 acf at capture time:

- `buildid 24501089` · `TargetBuildID 24536482` · `StateFlags 6` (UpdateRequired + FullyInstalled).
- `BytesToDownload 413,369,888` · **`BytesDownloaded 0`** — the download had not started.
- **`AutoUpdateBehavior 0`** ("always keep this game updated") with
  `ScheduledAutoUpdate` = **2026-08-04 03:08:17 EDT**. Note this is the laptop's setting;
  **SylDesk is `1`**, so the desktop will not take this build unattended and the two machines
  diverge again unless one is changed.
- Depot manifest still `6443337773729671953` — the `24501089` rollback key, unchanged by the
  pending update.

**Baseline `pre-24536482` — 0 warnings.** 119 pak files / 48,572,725,793 B SHA256-hashed,
`filelist.txt` at **76,309 entries**, catalog copied, MO2 deployment recorded, datamine at
`6f76f425`. Two consistency checks were run rather than assumed:

- The captured `ForeverWinter-Win64-Shipping.exe` hashes to
  `E4E76D0E37782EA8E846CF21369BDDEB230BA219999B67A4C03CEBDF55A41C1E`, **matching the `24501089`
  hash recorded above** — the snapshot is of the intended build, not a partially patched tree.
  This is also the check the SylDesk session recommends adding to the pre-launch checklist, and
  it is what proves the laptop is not running a displaced binary.
- The 76,309-entry filelist is **identical in count to `post-24479102`**, which is what the ledger
  already says about `24501089` (0 added / 0 removed / 0 renamed). The baseline agrees with the
  record.

**Rollback key for `24536482` is not captured yet** — it does not exist until the patch installs.
Read it out of the acf once the update completes.

**Patch notes not reviewed.** This build has no blast-radius characterization, so no mod has a
prior on it. `24479102` was a restructure and `24501089` a pure value tune; this one is
unclassified, and the gate order restarts from Stage 1 when it lands.

### The stale-executable blocker does not reach SylG5 — checked, not assumed

The desktop session above found the `24479102` exe displaced into MO2's `overwrite\` with a stale
pre-patch backup restored over it. **The same check on SylG5 comes back clean.** A recursive
search of `D:\MO2_InstanceData\TheForeverWinter` finds **no `ForeverWinter-Win64-Shipping.exe` at
all**; `overwrite\Root\Windows\ForeverWinter\Binaries\Win64\` holds only `bitfix.txt` and
`UE4SS.log`. There is **no `GameData.json`** under the instance, `%LOCALAPPDATA%\ModOrganizer` or
`%APPDATA%\ModOrganizer`, so neither half of the SylDesk remediation applies here. Combined with
the hash check above, the laptop's game directory holds the correct `24501089` binary and nothing
is staged that could displace it. **In-game measurement on SylG5 is not blocked by this.**

### Toolchain fix made to enable this capture

`tools/steam_state.ps1` could not run on SylG5 at all: `Join-Path` resolves the drive qualifier and
throws `DriveNotFound` on the absent `H:`, killing the candidate-root loop before it reached the
`D:` root that does exist. Since `capture_baseline.ps1` calls `steam_state.ps1` as its first step
under `$ErrorActionPreference = 'Stop'`, that one throw would have taken down the whole capture.
Fixed by building the candidate path as a plain string — `Test-Path` is drive-safe, `Join-Path` is
not. The candidate list itself was always correct and is unchanged, so this is per-machine
resolution rather than a find-and-replace, and **SylDesk is unaffected**.

`capture_baseline.ps1` still defaults to `H:` on all four path parameters. They are overridable on
the command line, which is how this capture was taken:

```
powershell -File tools/capture_baseline.ps1 -Label pre-24536482 `
  -GamePath 'D:\SteamLibrary\steamapps\common\The Forever Winter' `
  -AcfPath 'D:\SteamLibrary\steamapps\appmanifest_2828860.acf' `
  -Mo2Base 'D:\MO2_InstanceData\TheForeverWinter' `
  -DatamineRepo 'D:\Github Repositories\forever-winter-datamine' `
  -RunDecoderList
```

Giving it the same per-machine resolution as `steam_state.ps1` is still owed.

## Post-patch close-outs

*(one dated section per completed update — see triage-pipeline Stage 9)*
