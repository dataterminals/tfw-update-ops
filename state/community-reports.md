# Community reports — parsed 2026-07-31

Source: Sylvia's saved comment log (`runninglog.txt`), comments from the SCP page. Page numbers
per Sylvia: **AWU = mods/133**, **SCP = mods/135** (but see the 136 puzzle below). The original
mod is **#110 by LassyMorphee** — no permission block on their page.

## The thread, diagnosed

| Who | When | Report | Diagnosis |
|---|---|---|---|
| `fenixt34` | 20 Jul | Can't find the Carry Capacity perk (Unbalanced); tried alone and with AWU; followed instructions | **Old RIG04-chain design failure** — the pre-redesign SCP grafted onto RIG04 and a deep cross-character graft renders only one hop; Carry Capacity's first node landed under Stamina v5. SCP's README cites these very comments. **Superseded by the ROOT redesign (23 Jul).** |
| `JacobShade` | 21 Jul | Same; rig perks don't appear/unlock either | Same cause, same resolution. |
| `jakmarston` | 22 Jul | With AWU: "Stamina upgrade Lv5 seem to cover up the Weight Skill" | The literal Session-1 symptom, verbatim. Same resolution. |
| `fenixt34` | 22 Jul | "U will get carry capacity perk if u install All Weapons Unlockable Fix (uploaded 2:45PM) but it still looks weird" | See "the 2:45PM insight" below. |
| `dataterminals` | 22 Jul | "working on this now" | Acknowledged; ROOT redesign landed next day. |
| `4ce0fspades` | 24 Jul | Updated version: "perks are there and can be upgraded, and the stats change in the innerts, but they reset to default values once I'm in a location" | **The base-game Carry Capacity bug, exactly** (`ScavgirlCarryPerks/docs/carry-capacity.md`: effect dropped on location entry, reproduced modless). The redesign works; the game drops the GE. **Reply owed — substance ready.** |
| `Southperry88` | 31 Jul | "may need an update to work with the newest version of AWU" | **Undiagnosable as written.** Post-patch (24479102 landed 30 Jul). Candidates: ROOT collision (carry branch absent), base-game bug (branch present, effect drops), or pre-patch AWU's dead-pointer table making the combo look broken. **One diagnostic question decides it** (below). |

Also in-thread: `fenixt34` requests a stagger fix ("remove stun or add it as perk") →
`TFWStaggerControl` feature request; that mod is incomplete-by-design-state and developed on
another client. Logged, no action here.

## The 2:45PM insight (worth keeping)

fenixt34 reported that installing the AWU Fix *gave* them the carry perk ("but it still looks
weird"). At that date SCP was still the RIG04-chain design (no ROOT collision with AWU — different
assets), and the interplay of AWU's root + SCP's half-rendering chain produced a partially visible
carry line. Users were treating a **bug interaction as the working configuration**. This is why
"worked with AWU before, broken now" reports cannot be taken at face value — the "before" state
was two defects propping each other up. The ROOT redesign made SCP self-sufficient; the question
that remains is only who wins the ROOT collision now (launch-gated).

## Replies owed, substance ready (prose is Sylvia's)

- **`4ce0fspades`**: it's a bug in the game itself, not the mod — the game drops the perk's
  effect when you enter a location (and on character switch); full restart restores it. Happens
  to native BagMan/Shaman players with zero mods too. Don't pack past base capacity in the hub —
  drop-in over-encumbrance can't be undone in-raid. Displayed weights also render inflated.
  A pak can't fix it; a runtime fix is planned. (Then the page warning goes up, if it isn't up.)
- **`Southperry88`**: one question — when running SCP + AWU on the current game build, does the
  carry branch **appear in ScavGirl's tree at all**?
  - Doesn't appear → ROOT collision, AWU's pak winning on their install; ask which
    `AllWeapons*`/`AllSkills*` files are in `Content\Paks\Mods\` and which SCP variant.
  - Appears but stops working in locations → base-game bug (see above), nothing to update.
  - Also relevant: the AWU files currently on Nexus predate the game patch and break the
    customization UI regardless of SCP — that fix is built and pending upload.
- **`disxmfk`** (AWU page, owed): unchanged — substance in `state/nexus-sitting.md`.

## The 136 puzzle

`fenixt34` recommends "author's mod" **mods/136** — "adds rigs to the perks tree", which
*describes SCP*. Sylvia says SCP = **135**. So 136 is either a misremembered number (hers or
fenixt34's), or a third dataterminals page the repos know nothing about. **One click for Sylvia.**

## Still unknown

- Whether the carry-capacity warning is posted on the SCP page (log suggests not — no warning
  reply appears after the 22 Jul "working on this").
- Whether AWU page 133 hosts both variants as files or Trees has its own page.
- What mods/136 is.
