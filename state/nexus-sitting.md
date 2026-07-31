# The one Nexus sitting — 2026-07-31

**Answered same day** — items 1–3 came back; analysis of the comment log is in
[`community-reports.md`](community-reports.md). What remains below is marked.

## Paste these back (4 things)

1. ✅ **#110**: author is **LassyMorphee**; no permission block → no rights granted. **Decision
   made and implemented same day** (`5ed467c`): the regular Fix was rebuilt clean-room from
   vanilla — zero upstream bytes, A/B-identical. **Both variants cleared to upload.**
   New sanity size: regular inner `.ucas` = **75,174 B** (Trees unchanged, 79,239).

2. ✅ **SCP reports**: captured in `runninglog.txt`, parsed per-commenter in
   [`community-reports.md`](community-reports.md). Live items: reply to `4ce0fspades`
   (base-game bug, confirmed by their own wording) and `Southperry88` (needs one diagnostic
   question).

3. ✅ **Page numbers**: AWU = **mods/133**, SCP = **mods/135**. ⚠ Open sub-questions: does 133
   host BOTH variants or does Trees have its own page? And **what is mods/136** — fenixt34
   recommended it as "author's mod … adds rigs to the perks tree", which *describes SCP*.

4. ⬜ **Still open**: is the carry-capacity warning posted on the SCP page? (The comment log
   suggests not.) If not, the substance below goes up — it likely closes `4ce0fspades` and
   possibly `Southperry88` outright.

## Optional while you're there: post the carry warning

If the answer to 4 is "no", the substance is below — your words, your formatting. This is the
likeliest cause of the "SCP needs an update" reports, so posting it may close them outright.

- The rigs (Pack Mule → Heavy Container) work and are unaffected.
- The **Carry Capacity weight line** (Unbalanced variants only) is hit by a **base-game bug**, not
  the mod: the game silently drops the effect when you enter a location or switch characters, and
  only a full game restart restores it. Reproduced with **zero mods installed** on BagMan, who has
  the perk natively — native BagMan and Shaman players are affected too.
- Practical rule: **don't pack past your base capacity in the hub.** The bonus vanishes on load-in
  and you arrive over-encumbered; items dropped in-raid can't be picked back up.
- The displayed weights also render inflated while the perk is active, so the fill bar overstates
  how full you are.
- A pak mod cannot fix this; a runtime (UE4SS) fix is planned. Evidence and test method are
  documented in the repo (`docs/carry-capacity.md`).

## Reply substance, ready when the pastes land

**To the SCP reporters** — pick the branch that matches what they describe:
- *Branch A — the carry branch is visible in the tree, but the effect stops working after
  entering a location:* that's the base-game bug above, not an SCP/AWU compat issue. Point at the
  warning; no update needed; runtime fix planned.
- *Branch B — the carry branch doesn't appear in ScavGirl's tree at all, and they also run AWU:*
  load-order collision — both mods override ScavGirl's skill-tree root, and on their install AWU's
  pak is winning. Ask which AWU files sit in their `Content\Paks\Mods\` (exact filenames). Interim
  advice: Combined-* is the variant designed for running with AWU.
- *Either way:* SCP itself was re-verified against the current game build (all four variants,
  every reference resolves, nothing the patch changed touches it) — "needs an update" is not it.

**To `disxmfk` on the AWU Trees page** (owed since their report):
- They were right, and the report was the thing that surfaced it — say so.
- Plain-language cause: the update renamed every weapon's internal data asset; the mod's shipped
  weapon table still pointed at the old names, so the parts/customization screen lost every
  weapon. Equipping and skill trees kept working, which is why reports disagreed.
- Both variants are rebuilt against the new game build and verified (every reference now
  resolves). Goes up with the next file update.
- Their report also led to a permanent automated check in the build, so this whole class of break
  gets caught before upload from now on.

**AWU upload facts** — already researched, in [`HANDOFF.md`](../HANDOFF.md): versions decided —
**1.2.1 (regular) / 1.1.1 (Trees)**; dependency is Signature Bypass **only**; the `Paks\Mods\` folder
doesn't exist on stock installs; **the pak filename changed** so upgraders must delete the old
`AllWeaponsUnlockable_P.*` / `AllSkills_P.*` files — changelog + sticky-worthy.
Sanity sizes before upload, exact match required: regular `.ucas` = **75,174 B** (the clean-room
build), Trees = **79,239 B**. Anything else (110,000 / 110,008 / 112,133 / 81,372) is superseded
or broken — do not ship. **Neither variant waits on anything anymore.** Worth one changelog line
on the regular page: this build ships 5 assets instead of 8 (BagMan/Gunhead trees untouched now)
and contains no files from the original mod.

## Parked (needs a launch session, ~30–60 min, another day)

Gate 5a (TFWWorkbench reads new paks) · AWU + SCP collision winner · in-game tests of AWU fixes +
SCP on 24479102 · the HRF `WeaponDamage` hypothesis. All listed on the board; none urgent today.
