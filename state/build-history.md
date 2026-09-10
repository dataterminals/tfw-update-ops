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
| `24536482` | `7134816348397298387` | 2026-08-03 20:21:32 EDT | 50,813,198,796 B | **Current on SylG5.** Applied deliberately 20:21:32 EDT via the Steam Downloads page, **without launching**. 414,173,424 B download; install grew **1,106,583 B**. Baseline `pre-24536482` captured before it downloaded a byte. **SylDesk is still on `24501089`** — the two machines are diverged. |
| `25071553` | `4492887131597018203` | (no `LastUpdated` key; pak mtimes 2026-09-03 11:57) | 50,814,351,716 B | **Current on SylG5.** Auto-applied — `AutoUpdateBehavior` is `0` on this machine, so it landed unattended. 646,420,448 B download; install grew **1,152,920 B**. **No `pre-25071553` capture exists** — see the section below. Accumulates game versions `0.9.5.0` (08-28) through `0.9.5.3` (09-02); the intermediate depot manifests are unrecoverable. **SylDesk state unknown as of this entry.** |

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

## 24501089 → 24536482 on SylG5 — applied 2026-08-03 20:21:32 EDT, deliberately

**The pre-patch window was caught, deliberately rather than by luck.** Steam held `24536482` as a
pending update long enough for `pre-24536482` to be captured with the `24501089` files untouched
on disk, so this cycle has a true pre-patch baseline. Contrast the previous cycle, which installed
unattended and survived only because `post-24479102` happened to serve as the "before" side.

**Rollback key for `24536482`: `7134816348397298387`** — captured immediately on completion. The
previous key (`6443337773729671953` → `24501089`) is in the table above and remains usable; it is
the one that matters most right now, because SylDesk is still on that build.

Sequence of record:

- **Before** — `buildid 24501089` · `TargetBuildID 24536482` · `StateFlags 6` ·
  `BytesToDownload 413,369,888` · **`BytesDownloaded 0`**. Nothing had been fetched.
  `AutoUpdateBehavior 0` with `ScheduledAutoUpdate` = 2026-08-04 03:08:17 EDT, i.e. it would have
  landed unattended overnight. **SylDesk is `1`** — this setting is per-machine.
- **Applied without launching the game**, via the Steam client's Downloads page, following the
  route established on SylDesk earlier the same day. Confirms that finding on a second machine.
- Transition observed in the acf: `StateFlags 6` → **`1030`** (Uninstalled|UpdateRequired|
  UpdateRunning) while downloading → **`4`** (FullyInstalled) on completion, `UpdateResult 0`.
  Start to finish **under three minutes** on a ~394 MiB download.
- **Download 414,173,424 B — the acf predicted 413,369,888.** The prediction ran ~803 KB light.
  SylDesk saw the same direction of error on the previous patch and much larger (predicted
  686,538,384, actual 757,311,296), so **`BytesToDownload` is an estimate, not a contract** —
  do not use it to verify a patch completed. `BytesDownloaded == BytesToDownload` plus
  `StateFlags 4` is the real completion test.
- Install grew 50,812,092,213 → **50,813,198,796 B (+1,106,583 B)**. A ~1 MiB net delta on a
  394 MiB patch is consistent with rewriting existing assets rather than adding content — the
  same signature `24479102` and `24501089` both showed.

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

**Patch notes not reviewed.** This build has no blast-radius characterization from the developers'
side. `24479102` was a restructure and `24501089` a pure value tune; measured, this one is
**structurally near-inert but schema-breaking** — see below.

### Gate results measured the same evening

- **Gate 1a — AES key survives.** The decoder mounted **76,310** files with the key at
  `decoder/Program.cs:28` unchanged. The IoStore index is AES-encrypted, so the mount is the test.
- **Gate 1b — FAILS. The usmap must be regenerated.** Full detail on the board. The short version:
  the active usmap is the **`24479102`** regeneration and no longer matches `FWWeaponDefinition`.
  `DA_WPN_PLAYER_HRF01` decodes 30 of 57 properties and stops; `HRF02` decodes 56 **under partly
  wrong names**. The diagnostic tell is `MaxImpactFX` landing at index 29 where `NumberOfBuckshots`
  belongs — and `MaxImpactFX` is *not* new (it is in the `24097213` archive map too), so this is a
  misaligned fragment walk, not a missing mapping. Everything before the shift point reads
  correctly, which is what makes it survivable-looking.
- **The control matters as much as the failure.** `AIDEF_Sensor_Damage_Default`, `_TTKDummy` and
  `_ESP_Default` round-trip **byte-identical** against their committed dumps. That is the same
  evidence that wrongly cleared 1b on `24479102`. **A usmap is per-struct.** Any future "1b is
  fine" claim has to name which struct family it tested.
- **Filelist diff is structurally clean:** 76,309 → 76,310, with 108 of 109 additions being
  case-only directory renames in map/level geometry, **zero real removals**, one real addition
  (`WBP_PopUp_Gift_July2026Drone.uasset`), zero hits across all 69 dependency patterns in
  `asset-dependencies.md`, and `ForeverWinter/Content/CMSF/` still at 0.

**The pairing is the finding.** A completely clean path diff and a broken struct schema occurred in
the same patch. Neither check substitutes for the other, and a future cycle that runs only the
filelist diff will conclude "nothing to do" on a build that silently corrupts every weapon decode.

### The stale-executable blocker does not reach SylG5 — checked, not assumed

The desktop session above found the `24479102` exe displaced into MO2's `overwrite\` with a stale
pre-patch backup restored over it. **The same check on SylG5 comes back clean.** A recursive
search of `D:\MO2_InstanceData\TheForeverWinter` finds **no `ForeverWinter-Win64-Shipping.exe` at
all**; `overwrite\Root\Windows\ForeverWinter\Binaries\Win64\` holds only `bitfix.txt` and
`UE4SS.log`. There is **no `GameData.json`** under the instance, `%LOCALAPPDATA%\ModOrganizer` or
`%APPDATA%\ModOrganizer`, so neither half of the SylDesk remediation applies here.

Checked immediately before the patch, so the finding is about the *staging*, not about one build:
nothing exists in this MO2 instance that could displace a shipping executable, which is the
property that persists across patches. At that moment the game directory held the correct
`24501089` binary, hash-proven `E4E76D0E…`. **In-game measurement on SylG5 is not blocked by
this.** The `post-24536482` capture re-hashes the exe, so the same claim is re-established for the
new build rather than carried over on faith — and that hash becomes the pre-launch check the
desktop session asked for.

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

## 24536482 -> 25071553 — landed unattended, recorded 2026-09-09

**The pre-patch window was missed, and this time not recoverable by luck alone.** SylG5 runs
`AutoUpdateBehavior` `0` ("always keep this game updated"), so the patch applied itself with
nobody watching. Worse than the `24501089` case: the installed build has accumulated **four
announced game versions** — `0.9.5.0` (2026-08-28), the `0.9.5.1` same-day hotfix, `0.9.5.2`
(08-31) and `0.9.5.3` (09-02) — and the pak mtimes are all 2026-09-03 11:57. Only the final
build ID and its manifest survive; **the three intermediate depot manifests are gone**, so the
rollback granularity for this cycle is one step, not four.

The `post-24536482` baseline serves as the "before" side of the diff, exactly as
`post-24479102` did for `24501089`. Nothing needed for triage is lost.

**Rollback key for `25071553`: `4492887131597018203`.**

### Stage 0a — the install is genuinely the new build, not a Root Builder revert

The shipping exe is **169,740,288 B / `D87AE674…`**, mtime 2026-09-03 11:57:09 — Steam's own
patch write. It differs from `post-24536482`'s `169,641,472` / `5D9F12E6…` because the build
genuinely moved, which is the expected reading. The standing pre-launch check is satisfied:
this is not the 2026-08-03 revert mechanism firing again. Note that the game has **not been
launched under MO2 since 2026-08-04** — `overwrite\Root` is absent and there is no `UE4SS.log`
anywhere under the instance — so Root Builder has had no opportunity to rebuild its cache
against this build. **Expect the revert mechanism to be armed on the next launch** and clear
`GameData.json` + `Backup\` together first.

### Stage 1a — AES key survived 🟩

The decoder mounted **76,321 files** with the key still hardcoded at `decoder/Program.cs:36`,
unchanged. The IoStore index is AES-encrypted, so the mount is the test. (`24536482`: 76,310.)

### Stage 1b — usmap is STALE and must be regenerated 🟥

**This is the blocker for the cycle.** Measured on the `FWWeaponDefinition` export of
`DA_WPN_PLAYER_HRF01`, decoded three ways with an identical extraction:

| decode | properties |
|---|---|
| build `24536482`, its own correct usmap (committed dump) | **57** |
| the `post-24536482` baseline's kept `-STALE-USMAP` sample | 30 |
| **build `25071553`, the current live usmap** | **30** |

57 is the exact figure `mappings/provenance.json` records as verification for the current map,
and gate 1b's own note in `status.md` says it "was stopping at 30" before regeneration. It is
stopping at 30 again, and the values it does produce look plausible — no garbage numbers, no
error, exit 0. That is the documented silent-failure mode verbatim.

`bConvergeADSAimToCamera` reads at index 28 of 30 rather than provenance's index 46 of 57.
That is not evidence of health; it is the "reads real bytes under neighbouring property names"
symptom, and it is consistent with `0.9.5.x` having moved the weapon struct again — the patch
notes describe a recoil/stability **display** rework, height-over-bore work and per-weapon
reload scaling, all of which touch that definition.

**Consequence:** every value-level decode for this build is void until the map is regenerated,
and no Class A pak may be rebuilt against it. Structural findings that do **not** read the type
map are still sound and are the only things this cycle may act on so far:

- the filelist (76,321 entries) and everything derived from path existence,
- raw byte comparisons taken through `retoc to-legacy`, which is passed no usmap at all.

**To clear it** (doctrine Stage 1, needs a game launch, so it is Sylvia's): experimental UE4SS
into `Binaries\Win64`, a Lua mod calling `DumpUSMAP()`, then remove UE4SS again. Archive the
outgoing `24536482` map under `mappings/archive/` with its build in the filename and update
`provenance.json` in the same commit.

### Stage 3 — UE4SS attach: UNKNOWN ⬜

Not merely unscored — **unattempted**. There is no `UE4SS.log` anywhere under
`D:\MO2_InstanceData\TheForeverWinter`, so nothing has run against this exe. All of Class B is
unknown for `25071553`, including `CMSFUnlock`, and the `-894` experimental pin has never been
tested against a September binary.

### Filelist diff `post-24536482` -> `25071553`: 153 added / 142 removed, and most of it is noise

The bulk is **directory-case churn** and should not be read as movement: `Posed/` -> `posed/`,
`DataLayers/` -> `Datalayers/`, `images/` -> `Images/`, `TOOTHY/` -> `Toothy/`,
`Bagman/` -> `BagMan/`. Per `asset-dependencies.md`, case-only changes are benign because UE
lowercases the package name before hashing `FPackageId`.

The genuinely new or moved content:

- **Europa soldier behaviour trees `Trees_v2` -> `Trees_v3`**, plus new EQS queries
  (`EQS_FindSearchLocation`, `EQS_FleeTarget_V3`, `EQS_DangerCloseFireLine_V3`) and
  `BTDecorator_DangerCloseFoe`. This is the announced AI state-machine rework landing as assets.
- **`BTTask_AI_FindRandomSpotNearKey` removed** — worth a look from anything touching AI tasks.
- **Shaman MAY skin materials renamed**: `MI_EUP_INF_head_V4` -> `MI_SCV_SHM_Head`,
  `MI_EUP_INF_torso_2` -> `MI_EUP_INF_torso`, `VMI_EUP_INF_eyes_2` -> `MI_EUP_INF_eyes`.
  Matches the "Shaman: improved materials" note. **Direct exposure for
  `forever-winter-skin-mods`**, whose ranked failure modes put `M_FW_Char`-class material
  renames at "drops all materials to default".
- **`SM_WPN_SHG05_RCV` split** into `_IronSight` / `_NoIronSight` variants.
- New `Toothy` AI definition set at the recased path.

Nothing in the diff touches any asset `TFWCharModelSelFramework` owns or reads — see the CMSF
section of the mod-side findings.

## Post-patch close-outs

*(one dated section per completed update — see triage-pipeline Stage 9)*
