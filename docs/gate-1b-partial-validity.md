# What still works while gate 1b is red

**"The usmap is stale, so everything is void" is too coarse**, and treating it as the rule freezes a
cycle that could still be doing useful work. This is the precise version: which conclusions survive
a stale type map, which do not, and which *look* like they survive and do not.

Written 2026-09-10, during the `25071553` cycle, after the same defect was found in three separate
repos' verifiers.

## The mechanism, stated once

A usmap maps each struct to an **ordered property list**. UE5 unversioned property serialization
writes values in class order **with no names attached**. The reader recovers names by walking the
map in lockstep with the bytes.

So a stale map does not fail. It **misaligns** — and then reports real bytes under neighbouring
property names, plausibly, with exit 0. That is the documented silent-failure mode, and it is why
`FWWeaponDefinition` currently decodes 30 properties where provenance records 57.

Everything below follows from one question: **did this conclusion come from the type map, or from
the package's own name table?**

## Sound while 1b is red

These read no type map, or read only the name table:

| Conclusion | Why it survives |
|---|---|
| **Raw byte comparison via `retoc to-legacy`** | retoc is passed no usmap at all. **This is the gold standard while 1b is red** and the instrument every usmap-free check should be built on. |
| Package existence, filelist membership, path moves | Filesystem and container index. No properties read. |
| `FPackageId` binding, load-order collisions | Hash of the package name. |
| DataTable **row keys** | Name table. |
| Soft object paths / `AssetPathName` / `ObjectPath` **string values** | Name table. |
| String-table namespaces and keys | Name table. |
| Script-object name-set diffs | The global store, not the type map. |
| Container structure — `retoc verify`, chunk ids | Container layer, below properties. |

## Void while 1b is red

Anything the type map mediates:

- **Property counts.** "Decodes 57 properties" is the exact figure a stale map corrupts.
- **Property names.** The whole failure mode is real bytes under the wrong names.
- **Every scalar value.** Damage numbers, health, rates, flags.
- **"0 properties dropped" / "N of M properties present."**
- **Anything derived from those**, including a catalog rebuilt from a decode.

## ⚠ The trap: relative comparison is not as safe as it feels

The tempting argument is *"both sides are read with the same stale map, so the comparison is
fair."* It is **half true**, and the half that is false is the dangerous half.

**A detected DIFFERENCE is sound.** Two different byte streams read through one misaligned map
generally produce different output. If a verify says base and shipped differ, they differ.

**A detected IDENTITY is NOT sound.** A stale map commonly **truncates** the read — stopping at 30
of 57 properties is exactly what is happening right now. Everything past the truncation point is
never compared at all, so:

> **"Identical" under a stale map means "identical in the part the map could still reach."**
> A genuine difference living past the truncation point reports as clean.

**And characterisation is never sound.** Even where a difference is real, the property *names*
attached to it are wrong, so "the mod changed `MaxAmmo`" is not a claim a stale map can support.

### The specific way this produces a false green

A soft-reference check reads `AssetPathName`/`ObjectPath` strings — name-map data, so the strings
themselves are trustworthy. **But whether the check ever reached the property holding a given
reference depends on the type-map walk.** A truncating map means the scan silently covers less than
it thinks, and reports **0 dangling** because it never looked.

That is the same shape as the vacuous checks this project keeps rediscovering: a softref check on
cooked `Texture2D` exports that hold no paths at all, and a static mount that supplies the very
global store the pak disagrees with and then reports the content fine. **A check that cannot fail
is not a check that passed.**

## The rule for verifier scripts

Three repos' verifiers were found this cycle to resolve a `USMAP` and pass `FW_USMAP` to the
decoder for both the base and shipped dumps — `UnkillablesRebalanceFix`
(`tools/verify_build.sh:97,159`), `HeavyRifleRebalanceFix` (both `build_fix.sh` and
`verify_build.sh`), and `TFWCharModelSelFramework` (checks `[3]` and `[4]`). In each case the run
**completes and exits 0** under a red 1b.

**So:**

1. **A verifier that resolves a usmap must say so in its output**, and must refuse or loudly warn
   when the map's provenance does not match the live build. `mappings/provenance.json` exists
   precisely so this is checkable without a launch. Exiting 0 against a stale map is the failure.
2. **Separate usmap-free checks from usmap-dependent ones and label them**, so a reader can tell at
   a glance what survives. CMSF's check `[5]` — a byte comparison of the build tree against the live
   cook — is the model.
3. **Prefer the byte instrument.** `UnkillablesRebalanceFix`'s gate B was deliberately written in
   bytes "so it holds even when the decoder or the usmap is unavailable". That judgement is now
   vindicated: it is the only part of that repo runnable today.
4. **Never report "fully green" while 1b is red.** Report which checks ran soundly and which were
   skipped or are void.

## What this unblocks right now

The cycle is not frozen. Runnable today, no launch and no usmap:

- **`retoc to-legacy` byte comparison** of any shipped pak's packages against the live cook. This is
  the real content-reversion test and it is available for every Class A repo.
- **Filelist and path-existence** work of every kind.
- **Script-object name-set diffs** (`tools/scriptobjects_diff.py`).
- **`PackageImport` public-export-hash comparison**, including the pure before/after variant that
  diffs a July-cooked pak's `ImportedPublicExportHashes` against a live-cooked rebuild's without
  consulting the live cook at all.
- **Deployment, load-order and ship-state auditing** — none of it touches a decoder.

Regenerating the usmap remains the single action that unblocks the rest, and it needs a game launch.
