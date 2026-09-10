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
FWHardpointContainerComponent.OnRep_AimReplication
```

**Added: 78** — `/Script/FWAICore` 28, `/Script/FWWeapon` 19, `/Script/AgentAI` 12, remainder
scattered. So the live store is **not** a strict superset of July's.

### ✅ RESOLVED — container staleness is refuted. Resolution is by id, not by position.

This was proposed as the cause of CMSF's launch crash, tested three independent ways, and **is
not**. The route is closed; do not reopen it without new evidence.

**1 — The format itself.** `FScriptObjectEntry` stores an **explicit 64-bit `GlobalIndex`** per
entry (top two bits `01`, spread across the 62-bit space). *An array-position encoding would never
need to store the position.*

**2 — The measurement.** Across the two cooks, of 46,497 shared paths: **zero changed their
`GlobalIndex`**, while **46,374 — 99.7% — sit at a different array position.** Position moved for
almost everything. Not one id did.

**3 — The artifact test, which settles it.** The *actually shipped, actually crashing* July
`CMSF_Core_9_P` was unpacked and the `ImportMap` of all 199 zen package headers parsed:
**220 distinct ScriptImports, all 220 resolve against the live store to identical paths, zero
dangling**, and neither removed object is referenced. The Octogirl skin pak: 19 imports, 0
dangling.

**So the exposure predicate is removal, and the removal set is two symbols wide:**

> **Exposure = `imports ∩ {FWReplicatedAimRecord, FWHardpointContainerComponent.OnRep_AimReplication}`**

Both are the client-aim-replication rework from the `0.9.5.0` notes; their replacements are in the
added set (`ServerFireWithTarget`, `WeaponFiredMulticastRPC`, `FireCosmeticsMulticastRPC`,
`GetLastFiredShotId`, `OnWeaponFired__DelegateSignature`). **Measured exposure across every audited
pak is zero.**

**Growth is a non-event.** The +5,258 bytes that started this investigation are causally inert.

**Consequence — the CMSF rebuild is a null intervention.** 193 of its 199 packages are
byte-identical to the July pak with identical import lists throughout. It fixes a real staleness
that was **never the cause**, and must not be presented as a fix.

**Do not tell any repo to rebuild on this basis.** Not "rebuild", not even "investigate container
staleness" — that route is closed.

### CMSF's crash is still unexplained

Two candidates survive.

**Native parent property-layout change.** If `FWReplicatedAimRecord` was a `UPROPERTY` on the
native pawn and was removed, July-cooked `BP_Player_*` unversioned property data misaligns against
the September schema, crashing at pawn construction — i.e. at launch. **Evidence against:** the
game's own recooked pawn `.uexp` files are the same length as July's with only 2–23 scalar bytes
changed, arguing the serialized property set did not change.

**`PackageImport` public-export-hash staleness — untested by anything so far, and the better-formed
hypothesis.** Distinct from ScriptImports: CMSF's 199 packages carry **1,094 `PackageImport`s**
resolving by `(ImportedPackageIndex, ImportedPublicExportHashIndex)` against the *target base
package's* public export hashes — which live in the **live cook**, not the script store. A removed
or renamed public export in a reworked base package is a missing import, and **fatal in shipping
builds**. `0.9.5.0` rebuilt the AI subsystem from the ground up, so reworked base packages are
exactly what exists this cycle.

**This generalises further than ScriptImports do**, because a mod that overrides or references a
base package in a reworked subsystem is exposed regardless of what it imports from `/Script/`. See
§5.

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

> **✅ Superseded, and the bound held.** The build is now known exactly — **`24479102`** — from the
> datamine's archived per-build usmaps ([Appendix A](#a-fwmodintegritysubsystem-is-dated-exactly--build-24479102-and-no-depot-download-needed)).
> That is one of the two candidates this arithmetic left standing, so the bound was correct and is
> kept as a worked method: **when only container sizes survive, the byte budget still constrains
> what a step can contain.** It is the fallback for any future symbol a usmap does not record.

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

**Settled — the build. ✅ `24479102`, 2026-07-30.** Closed by direct measurement, not by the byte
bound: the datamine repo archives a usmap per build, and a usmap is a full type dump.
`FWModIntegritySubsystem` is **absent** from the `24097213` map and **present** in the `24479102`
map. Controls behave (`FWWeaponDefinition`, `FWPartySubsystem` hit all three;
`FWAIGoal_Investigate_Phased`, `BTTask_SuppressiveFire` are `25071553`-only and miss all three).
Full working in [Appendix A](#a-fwmodintegritysubsystem-is-dated-exactly--build-24479102-and-no-depot-download-needed).

**Two unrelated artifacts land on the same patch** — the usmap type ladder and this repo's
`FWPakManifest.json` baseline evidence (§4 below). That is convergence, not one finding counted
twice.

**⇒ This retires the subsystem as a crash candidate.** Six weeks live, symptomless, across three
builds our mods ran on. It remains a **real concern for the weapon mods in multiplayer** — that is
untouched — but it is not what broke anything this cycle.

**Not settled:**

- **Behaviour.** Everything above is read off *names* and *types*. The names are unusually
  unambiguous — the subsystem is literally called `FWModIntegritySubsystem` — but a name is not an
  implementation, and nothing here has been observed running. **A usmap dates the type, not the
  moment behaviour behind it was switched on**; a type can ship dormant and be enabled later by a
  server flag with no cook change at all.
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
been running against it all along without symptoms.

**✅ And the correlation is now a match.** The usmap type ladder independently places
`FWModIntegritySubsystem` at **the same build, `24479102`** ([Appendix A](#a-fwmodintegritysubsystem-is-dated-exactly--build-24479102-and-no-depot-download-needed)) —
so the manifest (a *data* artifact, dated from this repo's pak inventories) and the subsystem (a
*type*, dated from the datamine's archived maps) shipped together, established from two unrelated
artifacts by two methods that share no inputs. The whole feature landed on 2026-07-30.

**That retires it as a crash candidate for this cycle** and it is why the row-count lesson matters:
the 118→119 delta *was* the feature arriving, and it sat unread in a baseline for six weeks. **A
changed row count is a question, not a datum — read what the new row is.**

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

### 🚨 Doctrine — this rig cannot test any integrity path, and never could

**The MO2 instance runs `Signature Bypass` (`dsound.dll`) `+`enabled.** Whatever
`FWModIntegritySubsystem` does about container or manifest validation, **no measurement taken on
SylG5 is a valid control for it.** A clean local launch proves the bypass works, not that the mods
are undetected.

This has been true for every measurement this project has ever taken and was never stated. It
belongs in the pre-launch routine beside the exe-hash check: **before concluding "mods are fine"
from a local session, say which of `Signature Bypass` / `RE-UE4SS` were loaded.** Any real test of
the integrity path requires disabling the bypass, which is a separate deliberate experiment.

### The durable predicate, for `asset-dependencies.md`

Not *"packed before date X"* — that rubric is dead. It is:

> **A pak is exposed iff its ScriptImport set intersects the set of script-object paths REMOVED or
> RENAMED since it was packed.** Growth is a non-event.

For this cycle that set is exactly
`{FWReplicatedAimRecord, FWHardpointContainerComponent.OnRep_AimReplication}`.

### Checks worth having

1. **Compare script-object *name sets*, report removals only.** Implemented as
   `tools/scriptobjects_diff.py` in the `TFWCharModelSelFramework` repo — name-set diff, removals
   only, `--refs` for the exposure test, **exit 2 = could-not-run so it is never a silent pass**,
   with a negative control proving it fires. **Vendor it into this repo's `tools/`**: every Class A
   repo needs the same check and one copy should be canonical. It is usmap-free and launch-free,
   so **it is not blocked by gate 1b** — one of the few things this cycle can act on today.
   *Caveat now known: it will return clean nearly everywhere. That is a true negative, not
   coverage.*
2. ✅ **DONE — capture the global containers in every baseline.** `capture_baseline.ps1` now has
   step **`[3/7]` Global containers**, which **copies** `global.utoc` + `global.ucas` rather than
   extracting — retoc, the AES key and .NET are three dependencies that script must not acquire, and
   `global.ucas` is only 15 bytes larger than the `scriptobjects.bin` inside it (§3). Verified here:
   steps renumbered 1..7, **zero non-ASCII bytes** (PowerShell 5.1 reads UTF-8-without-BOM as ANSI,
   so an em-dash is a parse error), and `post-25071553/global/` backfilled at `global.ucas`
   3,017,568 B / `global.utoc` 1,615 B — matching the figures §3 derived independently.
   `tools/scriptobjects_diff.py` reads a stored `global.ucas` directly (chunk at offset 0, 15-byte
   container footer), so an archived baseline is diffable with no extraction step.
   **Authored by the `TFWCharModelSelFramework` session**; it landed in commit `ceed333` under this
   repo's authorship because of the shared-working-tree defect described in
   [`docs/multi-session-protocol.md`](../docs/multi-session-protocol.md). Recorded here because the
   commit log gets it wrong.
3. **Warn when the copied catalog's build stamp does not match the baseline's label.**
   `capture_baseline.ps1` copies whatever catalog sits in the datamine repo without comparing.
   `post-25071553/catalog/` is stamped `24536482` for exactly this reason.

### Questions that need a decision, not a script

- **Does `Nexus #123` need a pinned note?** If the integrity subsystem normalises weapon damage,
  HRF's headline feature may not do what its page says in multiplayer — independently of the
  schema problem already on the board. **Nexus-facing prose is Sylvia's**; this is flagged, not
  drafted.
- ~~**Is an exact date worth a depot download?**~~ **Answered — no, and Sylvia never needed to be
  asked.** The date was recoverable from an artifact already in the repo set: the datamine's
  archived per-build usmaps are full type dumps, and the type ladder places
  `FWModIntegritySubsystem` at `24479102` outright ([Appendix A](#a-fwmodintegritysubsystem-is-dated-exactly--build-24479102-and-no-depot-download-needed)).
  **The generalisable lesson is the one worth keeping: before proposing a ~50 GB depot pull to date
  a symbol, check whether an artifact already on disk encodes the same fact.** The rollback keys
  (`24479102` `6430523508700280691`, `24501089` `6443337773729671953`, `24536482`
  `7134816348397298387`) remain the route of last resort for anything a usmap does *not* record.

### What NOT to conclude

- **Not** that any pak must be rebuilt for container staleness. Measured exposure is **zero
  everywhere**. The route is closed.
- **Not** that container staleness explains the CMSF launch crash. Proposed, tested three ways,
  **refuted**. The rebuilt CMSF pak is a **null intervention** — 193 of 199 packages byte-identical
  to the July pak — and must not be presented as a fix.
- **Not** that a clean name-set diff means a pak is healthy. It rules out dead ScriptImports and
  nothing else. `PackageImport` public-export-hash staleness is untested, better-formed, and
  generalises further.
- **Not** that a clean local launch means mods are undetected. **`Signature Bypass` is enabled on
  this rig.**

---

## 6. Class A exposure — audited, and what it actually means

Seven repos audited read-only by the CMSF session. **Ratings were assigned under the
now-refuted rubric ("ships Blueprints + packed pre-`0.9.5.0`"), so read the column as *overlap with
the reworked subsystems*, not as script-import exposure — which is zero everywhere.**

| Repo | Zen pak | pre-`0.9.5.0` | overrides base | BPs | MO2 | rated |
|---|---|---|---|---|---|---|
| **`UnkillablesRebalanceFix`** | yes | yes | yes | **7 of 11** | **`+`ENABLED** | **critical** |
| `HeavyRifleRebalanceFix` | yes | yes | yes | no | disabled | medium |
| `forever-winter-skin-mods` | yes | yes | yes | no | absent | medium |
| `ScavgirlCarryPerks` | yes | yes | yes | no | disabled | low |
| `TFWQuestGiverPortraitPatch` | yes | yes | yes | no | absent | low |
| `TFWQuestItemTag` | no | n/a | no | no | absent | none |
| `TFW_CyborgNerfFix` | no | n/a | no | no | absent | none |

⚠ **`AllWeaponsUnlockableFix` and the whole-tree sweep are still owed** — the audit hit a session
limit. Flagged so a gap does not read as coverage. AWU is `+`enabled.

### 🔴 `UnkillablesRebalanceFix` is the one that matters — for content reversion, not containers

It **whole-asset-overrides eleven base packages**, including `BP_AI_Euruska_MeatMan`,
`BP_Mech_Toothy` and `BPC_IncomingDamageMod` — *precisely the AI subsystem `0.9.5.0` rebuilt from
the ground up.* Packed 2026-08-01/08-24, last commit 2026-08-23 (**before `0.9.5.0` shipped**), and
**enabled in the profile right now**. A whole-asset override of a reworked base package silently
reverts the developers' work for every user — the Group 1 staleness inversion
[`asset-dependencies.md`](asset-dependencies.md) exists to catch.

**⚠ Correction to the obvious next move.** Re-running its `tools/verify_build.sh` is **not** the
cheap first test — it is **void under gate 1b**, and worse than useless: line 97 hard-fails without
a `USMAP`, line 159 passes `FW_USMAP` to the decoder for *both* the base and shipped dumps, so it
will run to completion and **exit 0 with plausible property-shape numbers read against a stale
map**. That is the documented silent-failure mode, aimed at the one repo we most need a true
answer from.

**The usmap-free test that does work today:** `build_fix.sh` step `[2]` is
`retoc -a $AES to-legacy` of all 11 packages from the current base game (line 186) — no decoder, no
usmap, deliberately written in bytes "so it holds even when the decoder or the usmap is
unavailable". **Extract the 11 live packages and byte-compare them against the shipped pak's
extracts.** That detects content reversion directly, needs no type map and no launch, and is
therefore actionable *this cycle*. Its owner-session's call to run it.

---

# Appendix — the raw sets, and §3's dating question ANSWERED

Added by the CMSF session (`tfwcharmodelselframework-c9`) 2026-09-10, at the board's request.
Machine-readable copy: [`so-namediff-25071553.json`](so-namediff-25071553.json).
Regenerate either side with [`../tools/scriptobjects_diff.py`](../tools/scriptobjects_diff.py),
which accepts a `scriptobjects.bin` **or** a raw/archived `global.ucas` on either side.

## A. `FWModIntegritySubsystem` is dated EXACTLY — build `24479102`, and no depot download needed

§3 bounded the integrity symbols to "either `24479102` or `25071553`, not in between" by byte
arithmetic, and §5 asked whether pinning it down was worth ~50 GB of depot traffic. **It is not —
the answer was already on disk.** The datamine repo archives a usmap per build, and a usmap is a
full type dump of the build it came from:

| usmap | `FWWeaponDefinition` | `FWPartySubsystem` | `FWModIntegritySubsystem` | `FWReplicatedAimRecord` |
|---|---|---|---|---|
| `archive/…-build24097213.usmap` | yes | yes | **absent** | yes |
| `archive/…-build24479102.usmap` | yes | yes | **PRESENT** | yes |
| live `ForeverWinter-5.4.2.usmap` (`24536482`) | yes | yes | PRESENT | yes |

**So the subsystem first appears at `24479102`** — the 2026-07-30 patch. That is *independent
confirmation of* §"The manifest is six weeks old": `FWPakManifest.json` is absent in
`pre-24479102` and present in `post-24479102`, so the manifest and the subsystem arrived in the
**same patch**, established from two unrelated artifacts. §3's byte bound was correct, and this
lands inside it.

Controls, because a bare grep over a binary proves nothing by itself: `FWWeaponDefinition` and
`FWPartySubsystem` hit in all three maps (positive), while `FWAIGoal_Investigate_Phased` and
`BTTask_SuppressiveFire` — both `25071553`-only — miss in all three (negative). The greps
discriminate.

> **⚠ This retires the subsystem as a candidate for the CMSF crash.** The crash is reported from
> `0.9.5.0` onward; the subsystem has been shipping since 2026-07-30 and the collection ran six
> weeks against it without symptoms. It remains a live concern for the **weapon** mods
> (`IsStockWeapon` plus the damage-override path) and for multiplayer, but it cannot explain an
> onset at `0.9.5.0`. §4's "what is settled" should be read with that.
>
> The caveat that does not go away: a usmap records classes, structs and enums, so this dates the
> **type**. It does not date when any behaviour behind it was switched on.

**Corollary for §3.** `FWReplicatedAimRecord` is present in the `24536482` map, so its removal
falls in the last step (`24536482 → 25071553`) — consistent with the `0.9.5.0` client-aim rework.
The removal set really is a `0.9.5.0` event.

## B. The removed set — the exposure predicate, complete

    FWReplicatedAimRecord
    OnRep_AimReplication

> These are the raw **name-map entries**, which hold path *components* rather than full paths.
> Resolved through their outer chain they are `FWReplicatedAimRecord` and
> `FWHardpointContainerComponent.OnRep_AimReplication` — the spelling used in §2. Same two
> objects, not a discrepancy.

Two symbols wide. **Almost nothing will intersect it**, which is why "rebuild every pre-`0.9.5.0`
pak" is the wrong instruction. CMSF's own shipped pak carries 220 distinct ScriptImports across
199 packages and **zero** of them intersect this set.

## C. The mod-integrity surface — 15 symbols, absent at `24097213`, present live

    ClearWeaponDamageOverride
    Default__FWModIntegritySubsystem
    FWModIntegritySubsystem
    GetBaseWeaponDamage
    GetFindings
    IsHostPotentiallyModded
    IsLocalGamePotentiallyModded
    IsPartyHostPotentiallyModded
    IsPartyMemberPotentiallyModded
    IsPotentiallyModded
    IsStockWeapon
    OnRep_PotentiallyModded
    OnRep_WeaponDamageOverride
    ServerReportPotentiallyModded
    SetBaseWeaponDamage

Fifteen, not the thirteen first reported to the board: the earlier count used a narrower pattern
that missed `GetBaseWeaponDamage` / `SetBaseWeaponDamage`.

## D. All 78 added names, `24479102`-cook → `25071553`

Spread across the announced work — `/Script/FWAICore` 28, `/Script/FWWeapon` 19,
`/Script/AgentAI` 12. These are additions across the **whole** 2026-07-21 → live window, so they
span three patch steps and are **not** all `0.9.5.0`.

    BTDecorator_IsAtCoverPoint
    BTDecorator_MuzzleBlocked
    BTDecorator_NoEffectiveFire
    BTService_CoveringFire
    BTTask_MoveToCoverPoint
    BTTask_SuppressiveFire
    ClearWeaponDamageOverride
    ClientSetScopedCounter
    ComputeRecoilScore
    ComputeStabilityScore
    Default__BTDecorator_IsAtCoverPoint
    Default__BTDecorator_MuzzleBlocked
    Default__BTDecorator_NoEffectiveFire
    Default__BTService_CoveringFire
    Default__BTTask_MoveToCoverPoint
    Default__BTTask_SuppressiveFire
    Default__FWAIDangerFieldSubsystem
    Default__FWAIGoal_Investigate_Phased
    Default__FWAccumulatedKnockDownDamageType
    Default__FWBTDecorator_AlertPhase
    Default__FWBTDecorator_ClaimSquadMoveToken
    Default__FWBTDecorator_DangerLane
    Default__FWBTDecorator_SquadCohesion
    Default__FWBTDecorator_TargetType
    Default__FWBTTask_HoldSuspiciousStance
    Default__FWModIntegritySubsystem
    EFWAIAlertPhase
    EFWAIPlayerFacingAlertState
    EFWSquadCohesionTestMode
    FWAIAlertPhaseData
    FWAIAlertPhaseTuning
    FWAIAlertStateOrPhaseChangedSignature__DelegateSignature
    FWAIDangerFieldSubsystem
    FWAIGoal_Investigate_Phased
    FWAccumulatedKnockDownDamageType
    FWBTDecorator_AlertPhase
    FWBTDecorator_ClaimSquadMoveToken
    FWBTDecorator_DangerLane
    FWBTDecorator_SquadCohesion
    FWBTDecorator_TargetType
    FWBTTask_HoldSuspiciousStance
    FWModIntegritySubsystem
    FWRecoilStatInput
    FWStabilityStatInput
    FWWeaponShotFiredEventInfo
    FireCosmeticsMulticastRPC
    GetAlertPhase
    GetBaseWeaponDamage
    GetFindings
    GetHoverHeightOffset
    GetLastFiredShotId
    GetOrCreateInstancedWeaponDefinition
    GetPhaseStimulusLKP
    GetPhaseStimulusPlayer
    GetPlayerFacingAlertState
    GetPlayerWeaponLevel
    GetWeaponDamage
    GetWeaponPartNames
    IsFullyAwareOf
    IsHostPotentiallyModded
    IsLocalGamePotentiallyModded
    IsPartyHostPotentiallyModded
    IsPartyMemberPotentiallyModded
    IsPotentiallyModded
    IsStockWeapon
    MakeAINoiseForFactions
    OnClientProjectileStop
    OnMontageAborted
    OnRep_PotentiallyModded
    OnRep_WeaponDamageOverride
    OnWeaponFired__DelegateSignature
    OnWeaponPartsReady__DelegateSignature
    ServerFireWithTarget
    ServerReportPotentiallyModded
    SetBaseWeaponDamage
    SetPlayerWeaponLevel
    SetWindowedScopedCounterValue
    WeaponFiredMulticastRPC
