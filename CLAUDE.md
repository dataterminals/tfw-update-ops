# CLAUDE.md — tfw-update-ops

## What this repo is

The command post for handling a Forever Winter game update across all 25 TFW repos. It holds
**no mod code**. Fixes land in each mod's own repo; this repo tracks that they happened.

Start every session by reading [`state/status.md`](state/status.md) — its top banners and the
Gates table are the live state. [`HANDOFF.md`](HANDOFF.md) is a **per-cycle** document and goes
stale between patches; check its date before trusting it.

## Rules

1. **`state/status.md` is the source of truth for progress.** Update it as work completes — in
   the same turn the work completes, not later. A finished fix that isn't on the board doesn't
   exist as far as the next session is concerned.
2. **Respect the gate order** in [`docs/triage-pipeline.md`](docs/triage-pipeline.md). AES → usmap
   → re-decode → UE4SS → Class B → Class A → Class C → Class D. Fixing a mod against stale dumps
   means fixing it twice.
3. **Read the update behaviour; do not assume it.** `AutoUpdateBehavior` is **per-machine** —
   SylG5 is `0` ("always keep updated", so a patch lands on its own schedule whether or not you
   launch), SylDesk is `1`. Run `tools/steam_state.ps1` rather than relying on the old blanket
   rule that "launching *is* the update", which is false on SylG5. **A pending patch no longer
   forces a choice between patching and testing:** apply it deliberately from the Steam client's
   **Downloads page** (`steam://install/<appid>` is silently ignored) — established on both
   machines 2026-08-03. Completion is `BytesDownloaded == BytesToDownload` **and** `StateFlags 4`;
   `BytesToDownload` is an estimate, not a contract.
4. **Read the MO2 mod store to see what's deployed**, never the game folder. The game directory
   is clean by design. **The store is per-machine — resolve it from `registry/repos.json` →
   `roots.<hostname>`, never from a hardcoded drive:** SylG5 is
   `D:\MO2_InstanceData\TheForeverWinter\mods\`, SylDesk is
   `H:\MO2Instance_ModData\ForeverWinter\mods\`. Load order in `profiles\Default\modlist.txt`.
   `H:\` does not exist on SylG5, and joining it throws `DriveNotFound` rather than reporting
   nothing deployed — that class of failure already took down `tools/steam_state.ps1` once.
5. **Don't edit Steam's `.acf`.** Read it. Steam owns it and overwrites hand edits. Update
   behavior is changed in the Steam UI by Sylvia.
6. **This repo is private and stays private.** Baselines contain decoded catalog JSON derived from
   copyrighted game assets — same rule as `forever-winter-datamine`.

## Scripts

PowerShell 5.1 is the target. **ASCII only** — 5.1 reads UTF-8-without-BOM as ANSI, so an em-dash
in a string is a parse error. Both existing scripts are ASCII-clean; keep them that way.

```bash
powershell -File tools/steam_state.ps1
```
Read-only. Prints installed/target build, StateFlags, auto-update behavior, and the depot
manifest ID (the rollback key).

```bash
powershell -File tools/capture_baseline.ps1 -Label pre-24479102 -RunDecoderList
```
Snapshots Steam state, pak inventory + SHA256, Win64 binary hashes, the MO2 deployment, the
fwdata catalog, and the datamine git SHA into `state/baselines/<label>/`. Add `-SkipPakHashes`
for a fast pass (~118 pak files, 48.5 GB — hashing is the slow part). `-RunDecoderList` needs the
.NET 10 SDK and produces `filelist.txt`, the most valuable diff input.

```bash
powershell -File tools/diff_baseline.ps1 -Before pre-24479102 -After post-24479102
```
Compares two baselines into `state/diffs/<before>__vs__<after>/` — a `REPORT.md` plus
`filelist-added/removed.txt`, `paks-changed.csv`, `binaries-changed.csv`, `tables-changed.csv`.
**This is the Stage 2 intelligence product.** Cross-reference its asset churn against
[`state/asset-dependencies.md`](state/asset-dependencies.md) to get the per-mod hit list.
Note what it does *not* tell you: it compares schema and row counts, so a tuning pass that
rewrites values in place shows up as "no change." Only a dump diff proves values are intact.

## Conventions carried over from the other repos

- Commit with `git commit -F <file>` — PowerShell mangles `-m` with quoted multi-line strings.
- Push to `dataterminals` freely; no need to ask.
- Nexus-facing prose is Sylvia's. Supply plain-language substance, not a draft to paste.
- Ship mods in **both** layouts: manual-install as the default, MO2-compatible alongside.
- `fwact` cannot be built or tested on this desktop (Rust toolchain can't link).
