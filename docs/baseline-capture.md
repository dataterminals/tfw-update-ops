# Baseline capture (do this BEFORE the update)

## Why

After Steam applies an update, the old build is gone from disk. The only route back is a depot
downgrade (`docs/rollback.md`) — a ~50 GB download, a Steam console incantation, and a second
copy of the game. Everything below is small, takes minutes, and makes the *diff* possible.

**The diff is the whole point.** Without a baseline you can only ask "does this still work?"
(unanswerable for Class A, which fails silently). With one you can ask "what actually changed?"
and route the answer at the exact mods that care.

## What to capture, and why each item earns its place

| Artifact | Why |
|---|---|
| Steam state (`buildid`, `TargetBuildID`, depot manifest, sizes, timestamps) | The rollback key. Without the manifest ID the old build is unrecoverable. |
| Pak **file listing + sizes + hashes** (not the paks themselves) | ~50 GB of paks is impractical to keep; the manifest of them is a few hundred KB and answers "which chunk changed." |
| `filelist.txt` — the decoder's full asset list | The single most useful diff input. Asset added/removed/moved falls straight out of it. |
| Existing `datamine/dumps/**` (already committed) | Already in git — just confirm it's committed and clean, and tag the commit. |
| The current `.usmap` | Already committed. Tag it so the pre-patch type layout is addressable by name. |
| `fwdata` catalog (`items.json`, `widgets.json`, `tables.json`) | Structured, diffable summary of every DataTable + row count. A row-count delta is a strong signal. |
| Shipping exe hash + size | Tells you whether Signature Bypass / UE4SS signatures are likely to need work. |
| MO2 mod store listing + load order | The smoke-test loadout, frozen. Also proves what was actually deployed at baseline. |
| Per-mod pak inventory (our own `.pak`/`.utoc`/`.ucas` + hashes) | Lets you confirm a mod's own artifacts didn't change while you were debugging. |

## Procedure

```bash
powershell -File tools/steam_state.ps1
```

Confirms the game is still on the old build. **If `buildid` already equals the target, stop —
you're past the window; go to `docs/rollback.md`.**

```bash
powershell -File tools/capture_baseline.ps1 -Label pre-24479102
```

Writes everything above to `state/baselines/pre-24479102/`. Read the summary it prints.

Then, in `forever-winter-datamine`:

```bash
cd "H:/Github Repositories/forever-winter-datamine/datamine/decoder"
dotnet run -c Release -- list
```

…and copy `out/filelist.txt` into the baseline directory. (The capture script will do this for
you if the .NET 10 SDK is present; it warns and skips if not.)

Finally, commit and tag on both sides:

```bash
git -C "H:/Github Repositories/forever-winter-datamine" tag baseline-24097213
git -C "H:/Github Repositories/tfw-update-ops" add -A
```

## What NOT to capture

- **The paks themselves.** ~50 GB. The depot manifest ID is a better insurance policy and costs
  nothing. (Also: do not hardlink them into a "backup" folder — TFW staging dirs elsewhere on
  this box are already hardlinks into the Steam install, and hardlinks do not survive Steam
  replacing a file.)
- **The whole game folder.** Same reasoning.
- **Save games.** Not our surface, and not ours to move around.

## After capture, before giving Steam the go-ahead

Sanity check that the capture is actually usable:

1. `state/baselines/pre-<target>/filelist.txt` exists and is non-trivial (tens of thousands of lines).
2. `forever-winter-datamine` has a clean tree and a `baseline-<build>` tag.
3. `steam-state.txt` in the baseline contains a depot `manifest` value.

If any of the three is missing, the baseline is decorative. Fix it before patching.
