# The global script-object store — a new failure mode, and an undisclosed subsystem

**Cycle:** `24536482` → `25071553`. **Written:** 2026-09-10.

Two sessions produced this. The `scriptobjects.bin` parse, the name-set diff and the symbol
reading are the `TFWCharModelSelFramework` session's work. The build-by-build dating, the
size reconciliation and the `FWPakManifest.json` finding are this repo's, from the baselines it
owns. Where the two disagree or where nothing settles a question, it says so.

---

## 1. Content staleness and container staleness are different, and only one was ever tested

Every verification harness in the collection tests whether a shipped pak's **content** still
matches the live cook — reversion checks, softref checks, provenance gates, property-value
comparison. None of them tests whether the pak's **container** can still be resolved.

The reason the gap existed is structural, not careless. A mod pak has no ScriptObjects chunk of
its own and cannot be read without one, so **every static check mounts the mod alongside the live
`global.utoc`/`global.ucas`**. That is necessary — and it means the harness supplies the very
global store the shipped pak disagrees with, then correctly reports that the content is fine.

A Zen container serialises its imports of native classes, functions, properties and structs as
references into that global store, resolved by `retoc to-zen` at pack time. If the store changes
underneath a shipped pak, its imports may no longer denote what they did.

## 2. What actually changed — parsed, not scraped

Both stores were parsed with the real UE5 layout: `u32 Num`, `u32 NumStringBytes`,
`u64 HashVersion 0xC1640000`, `Num×u64` hashes, then a **contiguous** block of `Num×2`-byte
`FSerializedNameHeader`, then string data. The headers are *not* interleaved with the strings — a
first parse that assumed they were produced wrong answers. Format validated two ways:
`declared_strbytes == consumed` on both files, and the trailing remainder is exactly
`4 + Num×32` bytes, the `FScriptObjectEntry` array to the byte.

| | July cook (2026-07-21) | Live (`25071553`) |
|---|---|---|
| `scriptobjects.bin` | 3,012,295 B | 3,017,553 B |
| names | 43,394 | 43,470 |
| script objects | 46,497 | 46,576 |

**Removed — the complete set, two entries:**

```
FWReplicatedAimRecord
OnRep_AimReplication
```

**Added: 78.** So the live store is **not** a strict superset of July's.

### The predicate is removal, not growth

A script import is an `FPackageObjectIndex` of type ScriptImport whose value is a **hash of the
object's path name**, and the ScriptObjects chunk is a hash→entry map. Resolution is by hash, not
by array position. **Appending symbols therefore cannot break an existing pak.** A pak is exposed
iff it imports a symbol that was *removed or renamed*:

> **Exposure = `imports ∩ {FWReplicatedAimRecord, OnRep_AimReplication}`**

That is a two-symbol set covering aim replication. **Almost nothing will intersect it.** Both
symbols are the client-aim-replication rework described in the `0.9.5.0` notes; their replacements
are in the added set (`ServerFireWithTarget`, `WeaponFiredMulticastRPC`,
`FireCosmeticsMulticastRPC`, `GetLastFiredShotId`, `OnWeaponFired__DelegateSignature`).

**Consequence: do not tell six repos to rebuild on this basis.** The correct instruction is
*investigate*, and for almost every repo the investigation will come back clean.

### This does not explain the CMSF crash — the mechanism is still open

Neither removed symbol is referenced by any of the seven CMSF-overridden assets. The negative was
sanity-checked (script-object names *are* greppable in `retoc to-legacy` output —
`FWSkinChangeComponent` appears 4× in `BP_Player_Girl.uasset`), so 0 hits is meaningful rather
than an artifact.

**Honest limit on that negative:** `FWReplicatedAimRecord` is a *struct type* and
`OnRep_AimReplication` a *RepNotify function*. Neither would necessarily appear as an **import**
in a child Blueprint even if the native parent pawn declares them. "Not imported" ≠ "not exposed"
— it rules out a dead ScriptImport, not schema misalignment.

**Leading remaining candidate:** native parent property-layout change. If `FWReplicatedAimRecord`
was a `UPROPERTY` on the native pawn and was removed, July-cooked `BP_Player_*` unversioned
property data misaligns against the September schema — which would crash at pawn construction,
i.e. at launch. **Evidence against it:** the game's own recooked pawn `.uexp` files are the same
length as July's with only 2–23 scalar bytes changed, which argues the serialized property set did
not change. Genuinely unresolved.

## 3. Dating it — the store moved in three steps, not one

The July→live diff spans **four** builds. This repo's baselines split it. `global.ucas` is the
container that carries the ScriptObjects chunk, and across every build it is exactly **15 bytes**
larger than the `scriptobjects.bin` extracted from it:

| Build | `global.ucas` | ⇒ `scriptobjects.bin` | Step |
|---|---|---|---|
| `24097213` (July cook, 2026-07-21) | — | 3,012,295 *(measured)* | — |
| `24479102` (2026-07-30) | 3,014,224 | 3,014,209 | **+1,914** |
| `24536482` (2026-08-04) | 3,014,592 | 3,014,577 | **+368** |
| `25071553` (2026-09-03) | 3,017,568 | 3,017,553 *(measured)* | **+2,976** |

**The three steps sum to +5,258, which is the measured July→live delta exactly.** That is an
independent corroboration of the parse: two different methods, on two different machines' worth of
data, closing to the byte. `global.utoc` is 1,615 B in all three baselines — it indexes one chunk,
so a constant size is expected.

### The full byte budget reconciles

Live: entries `4 + 46,576×32 = 1,490,436`; name batch `3,017,553 − 1,490,436 = 1,527,117`, of
which `16` header + `43,470×8` hashes + `43,470×2` name headers leaves **1,092,401 B of strings
for 43,470 names ≈ 25.1 chars average.** July gives 25.1 as well. Nothing is unaccounted for.

**Marginal cost of one script object:** 32 B (entry) + 8 B (hash) + 2 B (name header) + ~25 B
(string) ≈ **67 B** with a fresh name, or **32 B** if it reuses an existing name.

### The bound that follows

| Step | Bytes | Objects it can hold |
|---|---|---|
| `24097213` → `24479102` | +1,914 | ~28 (fresh names) to ~59 (all reused) |
| `24479102` → `24536482` | +368 | **~5 to ~11** |
| `24536482` → `25071553` | +2,976 | ~44 to ~93 |

The 13 `FWModIntegritySubsystem` symbols are 13 *distinct new names*, costing at minimum
`13 × 67 ≈ 871 B`. **The `24536482` step cannot hold them.** They landed either at `24479102` or
at `25071553` — the four-build window narrows to two candidate builds, from data already on disk,
with no download.

## 4. 🔴 `FWModIntegritySubsystem` — mod detection with party-wide replication

Thirteen symbols absent in July, present live, forming one coherent surface:

```
FWModIntegritySubsystem          Default__FWModIntegritySubsystem
GetFindings
IsPotentiallyModded              IsLocalGamePotentiallyModded
IsHostPotentiallyModded          IsPartyHostPotentiallyModded
IsPartyMemberPotentiallyModded
OnRep_PotentiallyModded          ServerReportPotentiallyModded
IsStockWeapon                    GetBaseWeaponDamage / SetBaseWeaponDamage
ClearWeaponDamageOverride        OnRep_WeaponDamageOverride
```

Read together: **mod detection that replicates party-wide** (`ServerReportPotentiallyModded`,
`OnRep_PotentiallyModded`, and separate host / party-host / party-member predicates), plus a
**weapon-damage override path gated on `IsStockWeapon`**. That shape points at server-side
normalisation of modified weapon stats and propagation of a "this client is modded" flag to the
session.

**None of it appears in any `0.9.5.x` patch note.**

### What is settled, and what is not

**Settled:** the symbols exist in the live cook and not in the July one. The names are read
verbatim from the parsed name table, not inferred.

**Not settled:**

- **Behaviour.** Everything above is read off *names*. The names are unusually unambiguous — the
  subsystem is literally called `FWModIntegritySubsystem` — but a name is not an implementation,
  and nothing here has been observed running.
- **Which build.** Narrowed to `24479102` or `25071553` (§3). Not closed.
- **The `FWPakManifest.json` link.** The manifest in `Content\Paks\` is a `Paks` list of
  name/size/`TailHash` plus a top-level `Signature`, and it is the obvious thing an integrity
  subsystem would consume. But **there is no `FWPakManifest` script symbol in either cook**, so if
  it is consumed it is from native code not exposed to script. The link is plausible and
  unconfirmed.

### 🔎 The manifest is six weeks old — this repo's baselines date it

| Baseline | `FWPakManifest.json` |
|---|---|
| `pre-24479102` | **absent** |
| `post-24479102` | present, 19,502 B |
| `pre-24536482` | present, 19,502 B |
| `post-24536482` | present, 19,502 B |
| `post-25071553` | present, 19,502 B |

**It first appears at `24479102`, 2026-07-30** — and it is precisely the 118→119 pak-inventory row
delta that cycle, which had been recorded as a row-count change without anyone reading what the
new row *was*. Its size is **19,502 B in every build while its hash changes every time**: same
entry count, same name lengths, values rewritten per cook. That is a manifest of the shipped paks,
regenerated each patch.

So the tamper-detection *surface* is **six weeks old, not new this cycle**, and the collection has
been running against some of it all along without symptoms. That materially lowers the urgency
from "a new subsystem landed under us" — but it does not close the question, because the
manifest's arrival at `24479102` correlates with the ~28-object step, and the 13 script symbols
could equally sit in the ~44-object `25071553` step.

### Blast radius: the weapon mods, not the cosmetics

`IsStockWeapon` + `GetBaseWeaponDamage` / `SetBaseWeaponDamage` / `ClearWeaponDamageOverride` is a
weapon-stat normalisation path. What it would act on:

| Repo | Exposure |
|---|---|
| `HeavyRifleRebalanceFix` | **Highest.** Its entire design is that `WeaponDamage` on `DA_WPN_PLAYER_*` is the field the game reads for damage — the launch gate is literally "HRF01 must deal ~780, not ~300". A server-side base-damage override is the one mechanism that could make that gate fail for reasons that have nothing to do with the pak being correct. **Live on Nexus #123.** |
| `AllWeaponsUnlockableFix` | Unlock data rather than damage values, but it is a weapon-table mod and it is **enabled**. |
| `UnkillablesRebalanceFix` | Damage-side: `BPC_IncomingDamageMod` is a damage component. **Enabled.** |
| `ScavgirlCarryPerks` | Skill/carry values, not weapon damage. Low. |
| `TFWCharModelSelFramework`, `forever-winter-skin-mods`, `TFWQuestGiverPortraitPatch` | Cosmetic. Should be indifferent. |

**This may change what "working" even means for a Class A weapon mod in multiplayer.** A pak can
be perfectly built, decode perfectly, and still have its numbers normalised away by the server —
or flag the player's whole party.

## 5. What to do about it

### Checks worth having

1. **Compare script-object *name sets*, report removals only.** Growth is a non-event; the
   invariant that matters is that nothing a pak imports has disappeared. The CMSF session is
   folding this into its `verify_build.sh` check [5] and will hand over the parser. It is
   usmap-free and launch-free, so **it is not blocked by gate 1b** — one of the few things this
   cycle can act on today.
2. **Capture `scriptobjects.bin` in every baseline.** `capture_baseline.ps1` does not. Had it,
   this cycle's dating would have been exact instead of bounded, and the intermediate `0.9.5.x`
   cooks would not have been lost. **Three lines, and it retires this whole class of archaeology.**
3. **Warn when the copied catalog's build stamp does not match the baseline's label.**
   `capture_baseline.ps1` copies whatever catalog sits in the datamine repo without comparing.
   `post-25071553/catalog/` is stamped `24536482` for exactly this reason.

### Questions that need a decision, not a script

- **Does `Nexus #123` need a pinned note?** If the integrity subsystem normalises weapon damage,
  HRF's headline feature may not do what its page says in multiplayer — independently of the
  schema problem already on the board. **Nexus-facing prose is Sylvia's**; this is flagged, not
  drafted.
- **Is an exact date worth a depot download?** We hold rollback keys for `24479102`
  (`6430523508700280691`), `24501089` (`6443337773729671953`) and `24536482`
  (`7134816348397298387`). Pulling `24536482`'s `global.ucas` and diffing its name set would
  settle §3 outright. Steam's `download_depot` fetches the whole depot (~50 GB); a
  file-filtered fetch would be ~3 MB. **Sylvia's call on disk and bandwidth**, and on whether
  knowing the exact build is worth it now that the manifest is dated to `24479102`.

### What NOT to conclude

- **Not** that every pre-`0.9.5.0` pak must be rebuilt. The removal set is two aim-replication
  symbols; almost nothing intersects it.
- **Not** that container staleness explains the CMSF launch crash. It was proposed, tested, and
  **does not**. The rebuilt CMSF pak fixes a real staleness that was probably never the cause, and
  is **not** a demonstrated fix.
- **Not** that a clean name-set diff means a pak is healthy. It rules out dead ScriptImports. It
  says nothing about native parent property-layout drift, which is the leading open candidate.
