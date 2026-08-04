# Correction: `pakchunk20_s8-Windows.ucas` hash in `paks-inventory.csv`

**Made 2026-08-04, after the Steam verify that repaired the Root Builder revert.**

## What happened

Re-verifying the repaired install against this baseline, 118 of 119 paks and 9 of 9 Win64
binaries matched by SHA256. One did not:

| | SHA256 | Bytes |
|---|---|---|
| As captured here 2026-08-03 ~20:22 | `B8A4D690C6D1…` | 2,033,965,920 |
| After Steam verify, 2026-08-04 00:00:34 | `D3B88BBE87DD…` | 2,033,965,920 |

**Identical length, different content.**

## Which one is right

**Steam's.** A completed `Verify integrity of game files` leaves every file matching the depot
manifest for the installed build, and the app settled to `StateFlags 4` with
`BytesDownloaded == BytesToDownload`. That is an authoritative check against Fun Dog's published
manifest. This baseline, by contrast, is a filesystem snapshot taken by us and never validated
against anything.

The current file was also confirmed **stable** (hashed twice, same result) and the install was
**functionally proven** after the repair: the decoder mounts **76,310** files — the correct
`24536482` count, where 76,589 would mean still-reverted — `DA_WPN_PLAYER_HRF01` decodes a full
57 properties, and `AIDEF_Sensor_Damage_Default` round-trips byte-identical to its committed dump.

## Why the capture disagreed — two candidates, not distinguished

1. **Torn read during capture.** `capture_baseline.ps1` was started roughly 30 seconds after the
   patch reported complete, and hashes ~48 GB in directory order. If Steam was still finalising
   this file, the hash would be of a transient state.
2. **The original patch write differed from the manifest**, and the verify corrected it.

Both fit the evidence and **neither is proven**. Note that the ~5.9 GB the verify re-downloaded
does *not* discriminate between them: the 20 Root-Builder-reverted paks include several
multi-GB chunks, and Steam fetches only differing chunks, so 5.9 GB is unremarkable on its own.

## What was changed

`paks-inventory.csv` row for `pakchunk20_s8-Windows.ucas` now carries the **Steam-validated**
hash `D3B88BBE87DD…`, so automated comparison against this baseline passes on a correct install.
The originally captured value is recorded above and is not lost.

**Nothing else in this baseline was modified.** The `filelist.txt`, catalog, binary hashes and
Steam state are exactly as captured.

## Lesson for the next capture

**Do not start `capture_baseline.ps1` the instant `StateFlags` hits 4.** Let Steam settle, or
better, run a `Verify integrity of game files` *before* capturing a post-patch baseline — that
makes the baseline manifest-validated rather than merely observed, which is the property that
would have made this discrepancy impossible.
