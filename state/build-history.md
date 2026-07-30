# Build history

Ledger of TFW builds and their depot manifest IDs. **The manifest ID is the rollback key** —
record it while the build is installed, because Steam overwrites it on patch.

App `2828860` · Depot `2828861` · Install `H:\SteamLibrary\steamapps\common\The Forever Winter`

| Build ID | Depot manifest | Steam `LastUpdated` | Size on disk | Notes |
|---|---|---|---|---|
| `24097213` | `7600230730618885177` | 2026-07-07 16:55 EDT | 50,779,543,727 B | Current baseline. Almanac data is stamped to this build. usmap `ForeverWinter-5.4.2.usmap` corresponds to it. |
| `24479102` | *(unknown — capture after install)* | *pending* | — | **Queued, not applied.** ~820 MB download (819,646,731 B). |

## In-flight: 24097213 → 24479102

Observed 2026-07-30 ~16:50 EDT from `appmanifest_2828860.acf`:

- `StateFlags` `6` — fully installed **+ update required**
- `TargetBuildID` `24479102`, `BytesToDownload` `819646731`, `BytesDownloaded` `0`
- `ScheduledAutoUpdate` `1785489964` → **2026-07-31 05:26 EDT** (a scheduled slot still exists)
- `AutoUpdateBehavior` was `0` (always keep updated) on first read, then observed as **`1` — only
  update when I launch it**. That setting neutralizes the 05:26 slot: the patch now lands only on
  a deliberate launch. **So the hold is real, but launching the game applies the update.** Do not
  launch TFW until the baseline is captured.

**Baseline capture: NOT YET RUN.** See [`../docs/baseline-capture.md`](../docs/baseline-capture.md).

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
