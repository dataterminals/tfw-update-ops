# Triage pipeline (post-update)

Ordered. Each stage gates the next — running out of order wastes work, because a fix made against
stale dumps has to be made again.

Update `state/status.md` as you go. That file, not this one, is the source of truth for progress.

---

## Stage 0a — Before ANY session that launches the game: check the exe hash

**Compare the shipping exe's SHA256 against the current baseline's `binaries-win64.csv`.** If it
does not match, stop — the install is not the build you think it is, and every measurement taken
in that session is void.

```powershell
(Get-FileHash "<game_path>\Windows\ForeverWinter\Binaries\Win64\ForeverWinter-Win64-Shipping.exe" -Algorithm SHA256).Hash
```

**Why this is a standing rule, not a precaution.** MO2's **Root Builder caches the game's file
inventory keyed on the *engine* version** (`5_4_2_0`), which has been identical across
`24097213` → `24479102` → `24501089` → `24536482`. A content patch never invalidates it, so on
exit Root Builder "restores" a months-old backup over the freshly patched game. On 2026-08-03
this reverted SylG5 by **three builds** — the exe plus 20 of 118 paks — and deleted
`FWPakManifest.json`. It was found only because the decoder suddenly mounted the pre-`24479102`
file count.

The baselines have **always** captured this hash. Nothing ever read it. That single comparison
would have caught the same bug on SylDesk four days earlier.

**Remediation when it fires:** Steam **verify**, then delete Root Builder's `GameData.json` **and**
its sibling `Backup\` **together** — removing only the cache leaves ~47 GB of stale files ready to
restore; removing only the backup leaves the cache asserting the game looks like July.

## Stage 0 — Record the landing

Run `tools/steam_state.ps1`. Append the new row to `state/build-history.md`: new build ID, new
depot manifest ID, date, download size. **The new manifest ID is the rollback key for the *next*
patch** — capture it while it's in front of you.

## Stage 1 — Can we still decode? (blocks everything)

1. **AES key.** Re-run AESDumpster against the new shipping exe. If the key rotated, everything
   stops until it's recovered — that becomes the only task.
2. **usmap.** Try decoding a known asset with the existing `.usmap`.
   - Values look sane → the type layout survived; keep the old usmap and note it.
   - Values are garbage, or properties are missing → **regenerate.** Per the datamine README:
     install the **experimental** UE4SS into `…/Binaries/Win64`, add a Lua mod calling
     `DumpUSMAP()` (auto-dumps ~20 s after load, or `Ctrl+Numpad6`), then **remove UE4SS again**.
     Remember UE4SS emits usmap **v4**, which needs CUE4Parse `1.2.2.202607` (net10) — already
     pinned in `decoder/fwextract.csproj`.
   - "Looks sane" is a judgement call. If in doubt, regenerate; it costs 20 minutes and the
     alternative is silently wrong data propagating into the almanac.

**Do not proceed to Stage 2 until a known asset decodes to plausible values.**

## Stage 2 — Re-decode and diff

```bash
cd "H:/Github Repositories/forever-winter-datamine/datamine/decoder"
dotnet run -c Release -- list                        # new filelist.txt
```

Capture a post-patch baseline, then diff the two:

```bash
powershell -File tools/capture_baseline.ps1 -Label post-24479102 -RunDecoderList
powershell -File tools/diff_baseline.ps1 -Before pre-24479102 -After post-24479102
```

**This is the intelligence product** — added, removed, and moved assets, which is exactly what
Class A cares about. Intersect the churn against [`../state/asset-dependencies.md`](../state/asset-dependencies.md),
which maps every Class A/B mod to the specific asset paths, DataTables, classes and tags it
depends on. That intersection *is* the Stage 5 work list.

⚠️ The diff compares **schema and row counts**, not values. This patch is a weapons *tuning*
pass, and a retuned DataTable that keeps its RowStruct and row count is invisible to it. Treat a
clean catalog diff as "nothing was restructured," never as "nothing changed."

Then force-re-decode every dumped family:

```bash
python -m fwdata get <asset> --force
```

⚠️ `fwdata build all` does **not** re-decode — it re-stamps existing dumps with the new build
number. Force-decode first, then build the catalog, or the catalog claims a build its data
didn't come from.

Diff `catalog/tables.json` old vs new: a changed `RowStruct` or a moved row count is a direct
pointer at which Class A mod is now wrong.

## Stage 3 — Does UE4SS attach? (blocks all of Class B)

Enable **RE-UE4SS** + **Signature Bypass** only, launch, read `UE4SS.log`.

- Attaches → proceed.
- Doesn't → check for a newer experimental build upstream. If none exists yet, **Class B is
  blocked on upstream**; mark the whole class blocked in `status.md` and move to Class A. Don't
  let it stall the rest of the work.

## Stage 4 — Class B (Lua) — cheap intel first

Enable Class B mods one at a time; read the log. Their resolution failures name the exact paths
that moved, which sharpens Stage 5 from "diff everything" to "diff these."

Fix in each mod's own repo. Tick the row here.

## Stage 5 — Class A (paks) — the expensive one

For each Class A mod, in `status.md` order:

1. Look up its source assets in the Stage 2 filelist diff and the `tables.json` diff.
2. **Unchanged** → mark *likely-clean*, smoke test, done.
3. **Changed** → rebuild against the new assets via TFWWorkbench. Verify the *values*, not just
   that the game launches — this class fails silently.

Check **TFWWorkbench reads the new paks** before starting; if it can't, all of Class A is
blocked on that one tool.

Special handling:
- `UnkillablesRebalanceFix` — BP rebuilds silently revert any dev-side BP edits. Diff the boss BPs
  specifically, even if nothing else in the family moved.
- `TFWCharModelSelFramework` — verify the **frozen slot paths** first. Third-party skin authors
  write to those; breaking them breaks other people's mods, not just ours.

## Stage 6 — Class C (data products)

Only once Stage 2 is genuinely finished. Re-run `parse_*.py`, rebuild the catalog, restamp,
regenerate any mod manifests derived from `fwdata.query` (e.g. `TFWQuestItemTag`), and redeploy
the almanac / maps.

`fwact` cannot be built or tested on this desktop (Rust toolchain can't link — no `as.exe`, no
MSVC). Note it and move on.

## Stage 7 — Class D (tooling) smoke test

MO2 support, Workbench patcher, Modding Assistant, setup docs. Only rebuild on a failed smoke
test. Update install docs if the game layout moved.

## Stage 8 — Ship

Per mod, in its own repo: bump version, note the supported build ID in the README, package
**both layouts** (manual-install as the default — that's the community norm — and MO2-compatible
alongside), and update the Nexus page.

Nexus-facing prose is Sylvia's. Hand over plain-language substance — what changed, what broke,
what's verified — not a draft to paste.

## Stage 9 — Close out

Roll `status.md` into a dated section of `state/build-history.md`, reset the board, and record
anything the next patch should do differently.
