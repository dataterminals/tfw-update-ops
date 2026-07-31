# The one Nexus sitting — 2026-07-31

Everything currently blocked on Sylvia fits in one ~10-minute browser sitting. Open the tabs,
paste the answers into chat, done. Nothing here needs thought — it is all reading and copying.
(Claude can't do it: Cloudflare blocks fetches and the in-app browser crashes the app.)

## Paste these back (4 things)

1. **From mod #110's page** (<https://www.nexusmods.com/theforeverwinter/mods/110>):
   - the author's **username**
   - the **"Permissions and credits"** block, verbatim
   - *Why: gates whether the regular AWU Fix may be uploaded at all. Trees is exempt.*

2. **From your SCP page**: the **report comment(s)** about AWU compat — wording as-is, plus the
   commenter names. If they say which variant they run (Balanced / Unbalanced / Combined-*), grab
   that too.
   - *Why: decides which of three causes they're hitting; the replies differ.*

3. **Your page numbers**, all of them: SCP, AWU regular, AWU Trees (just the `mods/NNN` numbers).
   - *Why: the repos reference "the Nexus pages" and record none of them. Same gap as the #110
     username — gets written into the record once, never asked again.*

4. **Yes/no**: is the carry-capacity warning posted anywhere on the SCP page?

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

**AWU upload facts** — already researched, in [`HANDOFF.md`](../HANDOFF.md): suggested bumps
1.2.0 (regular) / 1.1.0 (Trees); dependency is Signature Bypass **only**; the `Paks\Mods\` folder
doesn't exist on stock installs; **the pak filename changed** so upgraders must delete the old
`AllWeaponsUnlockable_P.*` / `AllSkills_P.*` files — changelog + sticky-worthy.
Sanity sizes before upload, exact match required: regular `.ucas` = **110,000 B**,
Trees = **79,239 B**. (110,008 = the regressed build. 8 bytes. Check, don't eyeball.)
Regular upload additionally waits on item 1 above (permission). **Trees waits on nothing.**

## Parked (needs a launch session, ~30–60 min, another day)

Gate 5a (TFWWorkbench reads new paks) · AWU + SCP collision winner · in-game tests of AWU fixes +
SCP on 24479102 · the HRF `WeaponDamage` hypothesis. All listed on the board; none urgent today.
