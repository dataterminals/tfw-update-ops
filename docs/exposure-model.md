# Exposure model

Why we sort by *how a thing breaks* rather than by what it does: the fix procedure follows the
failure mode, not the feature.

## The engine facts that drive everything

- **UE 5.4.2.** Paks are IoStore (`.utoc`/`.ucas`), Oodle-compressed, AES-encrypted index.
- **AES key** has been constant across patches so far:
  `0x84B2244BE0AF90C22976D739FA0665569219F4CEA119CEA37C81F2D9ABEE4795`
  — "so far" is doing work in that sentence. Re-verify with AESDumpster after a patch; if it
  rotated, *nothing* decodes and the whole pipeline stops until it's recovered.
- **Unversioned properties.** You cannot read property values without a matching `.usmap`.
  A patch that changes the type layout invalidates ours, and every dump becomes garbage —
  usually garbage that still *parses*, which is the dangerous part.
- **Host-authoritative multiplayer.** A non-host's data mods change only their own UI; the
  host's change it for everyone. Relevant to what "verified" means: verify as host.

## Class A — Pak / asset mods

**Contract:** "this exact asset, at this exact path, with this exact layout."

**How a patch breaks it, worst to least:**
1. The asset moves or is renamed → the mod's pak overlays nothing. **Silent.** Game looks normal;
   the mod simply does nothing.
2. The asset's struct changes (a new field, a reordered enum) → mod loads and writes garbage into
   real gameplay values. **Silent and harmful.**
3. The pak format or IoStore chunk IDs shift → game refuses the pak, or crashes on load. **Loud.**
4. Nothing relevant changed → works untouched. Common for cosmetic/texture mods.

**Why this class is worst:** the two most likely outcomes are silent. You cannot smoke-test your
way to confidence — you have to diff the source asset against the baseline dump and *know*.

Special cases we own:
- **BP rebuilds** (`UnkillablesRebalanceFix`) — rebuilding a Blueprint bakes in whatever the BP
  graph looked like at build time. Any upstream BP edit by the devs is silently reverted by our
  mod. Highest-maintenance technique in the collection.
- **Frozen slot paths** (`TFWCharModelSelFramework`) — the framework's entire public contract is
  a set of asset paths that third-party skin authors write to. If those move, we don't just break
  our mod, we break other people's.
- **Texture rebakes** (`TFWQuestGiverPortraitPatch`) — depends on both the texture families and a
  fixed 2:1 button brush geometry.

## Class B — UE4SS / Lua runtime mods

**Contract:** "this class/BP/widget exists at runtime and has these members."

**How a patch breaks it:**
1. UE4SS itself doesn't attach to the new exe → **everything in this class is dead at once.**
   Check this first; it's one test that covers the whole class.
2. A resolved path returns nil → the mod errors in the UE4SS log. **Loud and traceable.**
3. A member is renamed but still resolves → wrong behavior. Uncommon but possible.

**Why this class is easier:** failures announce themselves in a log file. Triage is reading
`UE4SS.log`, not diffing binaries.

**The dependency:** stable UE4SS v3.0.1 *fails* on this exe (FText AOB scan times out). We run
the **experimental** build. After a patch, expect to need a newer experimental build, and expect
to wait on upstream if the signatures shifted.

## Class C — Datamine + data products

**Contract:** "the dumps in this repo reflect the shipped game."

`forever-winter-datamine` is upstream of the almanac, maps, fwact, and the manifests that Class A
and B mods generate. **It is always the first thing fixed and the last thing trusted.**

The specific trap, quoted from the datamine README:

> A build bump does not re-decode. `fwdata build all` globs `datamine/dumps/` directly, so on its
> own it just re-stamps already-committed dumps with the new number.

So the catalog will happily claim build `24479102` while holding `24097213` data, and everything
downstream inherits the lie. **Re-decode with `--force` first, stamp second.**

Also: `GAME_BUILD` auto-reads Steam's app manifest, which means it moves *by itself* the moment
Steam patches — before anyone has re-decoded anything.

## Class D — Tooling / infra

**Contract:** "the install layout and the mod-loading mechanism are what we assumed."

Content patches leave these alone. What breaks them is structural: the exe moving, the Paks
folder relocating, a new anti-tamper step, MO2's VFS interacting differently. Smoke test; only
rebuild if a smoke test fails.

`TFWWorkbench` is third-party but sits here in practice — it is the build tool for Class A, so
**Workbench failing to read the new paks blocks every Class A rebuild.** It gates more than it
looks like it does.

## Class E — Research

Nothing ships. A patch can invalidate a *finding*, which matters only when a downstream fix leans
on that finding. Don't spend patch-day time here. Re-verify on demand.

## Triage order (why it is what it is)

```
AES key  →  usmap  →  re-decode  →  UE4SS attaches  →  Class B  →  Class A  →  Class C  →  Class D
   \_______ blocks everything _______/   \_ blocks B _/
```

Class B before Class A because B tells you *what moved* via its own error logs, cheaply — and
that intel makes the expensive Class A diffing targeted instead of exhaustive.
