# Root cause — "gun customization UI items are not functioning properly"

**Reported by:** Nexus user `disxmfk` on AllWeaponsUnlockableTrees, 2026-07-30.
> *"Since the July 31 update, the gun customization UI items are not functioning properly.
> I have confirmed that a conflict occurs between that mod and this update."*

(Reporter is in a timezone where `24479102` landed on the 31st; same patch we applied 07-30 17:34 EDT.)

**Verdict: user is correct, the diagnosis is confirmed, and it affects BOTH variants.**

---

## The mechanism

Both AllWeaponsUnlockable variants ship an overridden `WeaponsDetailsData`. Each of its rows
carries a `DataAsset` soft-object pointer (`InventoryDangly` property `[17]`) naming that weapon's
definition asset.

Build `24479102` **renamed every player weapon DataAsset**:

```
DA_WPN_RFL01_v2   ->   DA_WPN_PLAYER_RFL01
DA_WPN_HRF01_v2   ->   DA_WPN_PLAYER_HRF01
…all of them
```

The shipped paks were built before the patch, so every row still pins the **`_v2`** name. Because
the mod *overrides* the table, the game reads the mod's pointers instead of the patched ones — and
every one of them names an asset that no longer exists.

Measured by decoding each pak inside a full game mount against the patched build:

| Table source | Rows | Rows whose `DataAsset` no longer exists |
|---|---|---|
| **Deployed `AllWeaponsUnlockableTrees_P` (07-20)** | 56 | **56 / 56** |
| **`AllWeaponsUnlockable_P` (regular, 07-19)** | 56 | **56 / 56** |
| Patched vanilla base | 53 | 0 |
| **Rebuilt Trees pak (07-30)** | 53 | **0** ✅ |

So this is not a partial or cosmetic break: **every weapon in the game loses its definition
pointer** for anyone running either mod. The customization UI is downstream of that DataAsset, which
is exactly the symptom reported.

## Corrections to earlier analysis in this repo

Two things recorded earlier were wrong and are superseded:

1. **"Live risk is low."** That was based on the 3 deleted `RFL01_Red/Blue/Green` rows being
   orphans nothing references — true, but it was the *wrong variable*. The damage is not the 3
   extra rows, it is the **53 shared rows** whose `DataAsset` pointers all went stale. The orphan
   analysis was correct and irrelevant.
2. **Framing the fix as "drop 3 rows + update the verifier."** The rebuild works for a different
   reason than stated: `retoc to-legacy` pulls **fresh base rows**, which carry the corrected
   `DA_WPN_PLAYER_*` pointers. Dropping the 3 rows was necessary for the verifier, but the
   *user-facing* fix is the refreshed `DataAsset` pointers.

The rebuild was right; the reasoning recorded for it was incomplete.

## Why the other report is not a contradiction

Nexus user `Akelaphobia`, same day, on the **regular** variant: *"Still works with today's update,
surprisingly."* Not a contradiction — they were equipping weapons and using the skill tree, which
still function. The `DataAsset` break surfaces in the **customization/parts UI**, a screen they did
not report visiting. Two users, two different surfaces, both reports accurate.

Useful reminder that "a user says it works" is not coverage.

## Ruled out along the way

- **usmap / schema drift.** `InventoryDangly` is **byte-identical** across the old and new usmaps
  — all 27 properties, same order, same types. The mod's table is not structurally stale.
- **`LevelPartUnlockTable` dangling.** 0 dangling in both the mod's table and base; mod and base
  point at the *same* unlock table on all 53 shared rows. The `DT_*_WeaponPartUnlocks` tables
  survived the patch.
- **The deleted `DA_WPN_*_BaseTuning_WeaponParts_Curves` tree.** Deleted game-wide (every weapon
  family), but neither mod ships them, so not the conflict.
- **`AllowTags` widening.** Working as intended; the mod's edits target surviving rows.

`DataAsset` was the only non-`AllowTags` field differing between the mod's table and base — and it
differed on **every single row**.

## Status

- **Trees** — fixed and verified (`AllWeaponsUnlockableFix@3dafbc5`), 0 dangling. **Not yet
  deployed to MO2, not yet released.**
- **Regular** — same defect, needs the same rebase rebuild.
- Both need a Nexus note. This is a real user-facing break, not a cosmetic one.
