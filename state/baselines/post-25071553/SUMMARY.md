# Baseline: post-25071553

Captured: 2026-09-09 21:36:28 -04:00
Game path: D:\SteamLibrary\steamapps\common\The Forever Winter

## Files
- appmanifest.acf (971 bytes)
- binaries-win64.csv (1189 bytes)
- datamine-git-state.txt (88 bytes)
- mo2-modlist.txt (529 bytes)
- mo2-mods.txt (455 bytes)
- paks-inventory.csv (16123 bytes)
- steam-state.txt (689 bytes)
- catalog\items.json (431687 bytes)
- catalog\tables.json (4503 bytes)
- catalog\widgets.json (2589 bytes)

## Warnings
- filelist.txt NOT captured (-RunDecoderList not set). This is the single most useful diff input -- capture it before patching.

## Provenance notes added 2026-09-09 (read these before diffing)

**`filelist.txt` was added by hand after the capture, not by `-RunDecoderList`.** It is the same
76,321-entry listing produced by `fwextract list` against the same `Content\Paks` at 2026-09-09
21:2x, minutes before this capture, with the same decoder binary
(`forever-winter-datamine` HEAD `4dda097c`). Same build, same containers, same tool — it is a
sound diff input. It is recorded here rather than silently, because the capture script's own
warning says it was missing.

**`catalog/` is CARRIED OVER FROM `24536482` and is NOT this build's data.** `tables.json` is
stamped `"build": 24536482` and all three files date from 2026-08-05. `capture_baseline.ps1` copies
whatever catalog is sitting in the datamine repo without comparing its `build` stamp against the
installed build, so an unchanged catalog here means **"not rebuilt"**, never "nothing changed".

It was deliberately not rebuilt: **gate 1b is red for this build** — the usmap decodes
`FWWeaponDefinition` at 30 properties instead of 57 — so a catalog rebuilt now would bake in wrong
values with a success exit. Rebuild it only after the usmap is regenerated, then re-stamp. See
`build-history.md`, "24536482 -> 25071553".

*Fix owed to the tooling:* `capture_baseline.ps1` should warn when the catalog's `build` stamp does
not match the installed build. Silently copying a stale catalog into a baseline named after a newer
build is the same class of laundered non-result the usmap provenance file exists to prevent.
