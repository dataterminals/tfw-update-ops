# Hotfix 24501089 — what it changed

**Measured 2026-08-01 on SylG5 (laptop) against the live install.** Compared to the
`post-24479102` baseline and the datamine repo's committed weapon dumps at `1c9e1bb`.

Released Friday 2026-07-31; auto-applied on SylG5 2026-08-01 06:42. 686,534,560 B download.

---

## One-line answer

**It is a player weapon damage buff and nothing else.** `WeaponDamage` on 32
`DA_WPN_PLAYER_*` assets is the only field that changed anywhere in the weapon set. No asset
was added, removed or renamed anywhere in the build.

## Evidence

| Check | Result |
|---|---|
| Filelist, live vs `post-24479102` | **Identical.** 76,309 entries, 0 added / 0 removed / 0 renamed |
| AES key | **Still valid.** Decoder mounted all 76,309 files; the IoStore index is AES-encrypted, so the mount is the test |
| Weapon dumps, 72 comparable | 40 identical, **32 changed** |
| Fields changed across all 32 | **`WeaponDamage` only.** Nothing else differs in any weapon asset |
| AI weapons (`DA_WPN_AI_*`) | **Untouched** |
| `WeaponsDetailsData` | **Identical** — the table `AllWeaponsUnlockableFix` overrides did not move |

## The 32 changed values

Most are a uniform uplift of about +11% (`x 1/0.9`, i.e. a reversal of a 10% reduction:
135→150, 270→300, 5.4→6.0, 900→1000). Two are far larger and read as deliberate
single-weapon buffs rather than part of the sweep.

| Weapon | 24479102 | 24501089 | Change |
|---|---|---|---|
| `HRF02` | 1100.0 | 1800.0 | **+63.6%** |
| `HMG01` | 315.0 | 472.5 | **+50.0%** |
| `HRF01` | 270.0 | 300.0 | +11.1% |
| `HRF05` | 9000.0 | 10000.0 | +11.1% |
| `LMG01` / `LMG03` / `LMG04` | 275.625 | 290.0 | +5.2% |
| `LMG02` | 236.25 | 250.0 | +5.8% |
| `LMG06` | 496.125 | 525.0 | +5.8% |
| `PST01` / `PST02` | 180.0 | 200.0 | +11.1% |
| `PST07` | 900.0 | 1000.0 | +11.1% |
| `PST08` | 540.0 | 600.0 | +11.1% |
| `RFL01` / `02` / `05` / `12` / `16` / `23` / `30` | 135.0 | 150.0 | +11.1% |
| `RFL01a` | 135.0 | 140.0 | +3.7% |
| `RFL01b` / `RFL15` | 157.5 | 175.0 | +11.1% |
| `RFL10` | 180.0 | 200.0 | +11.1% |
| `SHG01` | 13.5 | 15.0 | +11.1% |
| `SHG03` / `04` / `05` | 5.4 | 6.0 | +11.1% |
| `SHG06` | 5.94 | 6.6 | +11.1% |
| `SMG01` / `SMG08` | 180.0 | 200.0 | +11.1% |
| `SMG09` | 110.0 | 121.0 | +10.0% |

## Consequences

### `AllWeaponsUnlockableFix` — clear

Verified **directly**, not inferred: both built variants decoded inside a full live mount of
`24501089` and every reference resolved.

| Variant | `.ucas` | Dumps scanned | Refs checked | Dangling |
|---|---|---|---|---|
| regular | 75,174 B | 7 | 381 | **0** |
| Trees | 79,239 B | 7 | 383 | **0** |

Its override target `WeaponsDetailsData` is byte-identical to the base, and nothing was
renamed, so the stale-pointer class that broke it on `24479102` has not recurred.

### `HeavyRifleRebalanceFix` — the open hypothesis just got strong evidence

The board's standing question was whether `WeaponDamage` on `DA_WPN_PLAYER_*` became the
authoritative damage lever after the `FC_*_Damage` curve tree was deleted game-wide, or
whether it remained the "cosmetic" scalar the mod's own `docs/diagnosis.md` called it.

**This hotfix retunes damage by editing that field and only that field.** A developer
rebalancing weapon damage edits the value that governs damage. That is not proof — it remains
an inference from behaviour rather than a measurement — but it is considerably better evidence
than the redesign had before, and it arrived without spending a test session.

Note the redesign target moved: HRF01 is now 300.0, HRF02 1800.0, HRF05 10000.0. Any rebalance
must be recomputed against the new baseline, not the numbers in the existing worklog.

### `forever-winter-almanac` — damage figures are now stale as well

Already 🟥 for the deleted Stability system. Every published player-weapon damage number is
now low by the amounts above, and `HRF02` and `HMG01` are wrong by half. Whatever rework the
Stability section needs, the damage tables need a straight data refresh on top of it.

### Still open for this build

The shipping exe changed (same size, different SHA256 — see
[`build-history.md`](build-history.md)), so:

- **Gate 3** (RE-UE4SS attaches) — unknown, needs a launch.
- **Gate 3b** (Signature Bypass AOB scan) — unknown, needs a launch. This is
  `AllWeaponsUnlockableFix`'s only declared dependency.
- **Gate 1b** (usmap) — not formally re-verified. The weapon decode round-tripped cleanly
  against committed dumps and 40 of 72 came back byte-identical, which is meaningful evidence
  for `FWWeaponDefinition` specifically. Per the `24479102` lesson, that does **not**
  generalise to other struct families.
- `UnkillablesRebalanceFix` boss BPs are outside the weapon set and were not covered here.
