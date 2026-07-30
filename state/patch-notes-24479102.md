# Patch notes — build 24479102

Source: official Discord announcement (Nightmare / "Fundog", CotHM Founder), 4-part post.
Raw paste supplied by Sylvia 2026-07-30, archived verbatim below (Discord timestamp artifacts
left as-is). Announcement date not preserved in the paste.

**One-line read:** content patch — comprehensive weapons-systems overhaul (recoil, bloom, ADS,
sway, mod/customization effects, skill scaling) plus AI fixes, networking reliability, and crash
fixes. No engine-version bump mentioned anywhere. ~820 MB download is consistent with a
data/content patch, not an engine bump.

## What this means for us

Blast-radius read against the registry, before any diff exists. The filelist/tables diff
(Stage 2) confirms or clears these — this is where to look first, not a verdict.

| Announcement item | Our exposure |
|---|---|
| "All weapons received a tuning pass (including their DPM in some cases)"; complete overhaul of how mods affect recoil/accuracy/stability; reload scales with mag mods | **`HeavyRifleRebalanceFix` near-certain hit** (its source stat tables changed under it, and its tuning targets moved). **`AllWeaponsUnlockableFix`** weapon/customization data adjacent. **Almanac gunsmith section** is directly about weapon mods — its data is now materially stale, not just restamp-stale. |
| Skill scaling reworked ("No longer linear"), scav skills hooked to new weapon systems | **`ScavgirlCarryPerks`** (skill-tree adjacent — carry perks aren't weapon-handling, but if skill tables were restructured wholesale it's in scope). **`TFWStaggerControl`** resistance skill tree, same reasoning. |
| AI fixes (invalid-goal race, pot shots, standing corpses, Opal landing explosion, flyer crashes) | AI BPs were touched. **`UnkillablesRebalanceFix`** — diff the 6 boss BPs specifically (already board policy; this raises the prior that they moved). |
| Buddy AI command-anim fix, third-person crosshair adjustments, a UI crash fix | Widget/HUD surface moved at least a little. **`TFWLootAll`** (`W_LootUI_C`), **`TFWQuestHUDToggle`**, **`TFWQuestGiverPortraitPatch`** — low-moderate; let the filelist diff say. |
| Networking/session-join reliability pass | Native-code changes → new shipping exe guaranteed (it always is). **RE-UE4SS signatures + Signature Bypass** still need re-verification, but nothing here suggests an engine upgrade, which is the good case for the usmap surviving. |
| Innards/HUB upgrade system reworked; one-time migrate-and-refund on first post-update load | Not a mod surface. **Player-facing caveat for Sylvia** — see below. |

Not mentioned at all: character models, portraits, skins, loot UI content, maps. Prior for
**`TFWCharModelSelFramework`**, the four deployed skins, and the maps repos is correspondingly
lower — verify via diff, but they're not in the announced blast radius.

**Player-facing caveat:** if a HUB/Innards facility upgrade is in progress on the save when the
patched game first loads, it gets canceled and refunded (credits + items), and must be re-bought
and re-waited. One-time migration check. Nothing to do about it — collecting the upgrade first
would itself require launching — but don't be surprised by it.

---

## Verbatim announcement

4:45 PM]Nightmare, CotHM Founder [BUNG], :
Hello @Scavs

Here is a big one: a comprehensive overhaul of the weaponry systems focused on the issues and wants that you asked for via various communication channels such as Discord and the weapon survey we sent out a few months back. We got a TON of useful, tangible feedback and want to thank you for all of it.

As we said in a previous update, the focus on the weapon improvements were focused primarily on the following:

Recoil & Bloom. (the most common thread in the survey).

Weapon Class Identity. (Pistols, SMGs, Rifles, Shotguns, and heavier weapons having clear roles).

ADS Responsiveness & Weapon Weight. (Time to aim, Aim Consistency, etc.)

The crux of this push is to make sure weapon handling is improved, and that the weapon parts and player skills work together to make the weapons fit both their role, and improve the player experience. The goal wasn't to over-power the player scavs; it was to make sure all weapon and weapon-related-skills functioned as intended and expand on player choice.

Our other goal with this is to be able to shift to the other part of the equation and focus on improving enemy AI in the QOL push.

Full info below. See you in the wastes!

-Fundog Out

(1/4)

5 PM]Nightmare, CotHM Founder [BUNG], :
Weapons — Systems & Features
Overhaul of all weapon systems for player handheld weaponry (accuracy, recoil, camera shake, upgrades, etc.) to focus on the specifics of the player user feedback. (Major survey-based weapons pass)

All handheld weapons adjusted for accuracy, recoil, and stability
Several improvements for accuracy (bloom) including first-shot-perfect systems for appropriate weaponry (sniper rifles, modded firearms with longer barrels, etc.)
Each weapon now has its own appropriate enter / exit ADS speed
Entering and exiting ADS is faster for the lighter weapons, slower for the big ones
Weapon sway overhaul
Heavier weapons sway more (lag in frame when looking left / right / up / down, etc.)
Lighter weapons sway much less (pistols). Heavier ones sway more (LMGs, HMGs)
Adjusted recoil and sway so shooting no longer causes the gun to climb in frame (when in ADS) and block your sight picture / target (but the recoil does cause the camera to climb unless you compensate)
Reload speed now scales with magazine mods
Larger-than-stock mags take longer to reload, smaller ones are faster
Complete overhaul of how the mods / customizations improve the weapon recoil, accuracy, and stability
Part removal adjustments: Removing critical items like the weapon’s stock will now negatively impact its performance
Improvement for agro related to weaponry
Smaller firearms draw less agro than bigger ones. Agro accrued with these smaller weapons disperses more quickly
HK reaction to the big guns such as the Mass is still there. So don't get cocky
Scav skills hooked up to the improved systems (handling of firearm classes improves with better skills)
Adjusted how MUCH skills impact the weapon stats. No longer linear. Lower level = minor improvement. Max level = really good improvement.

(2/4)

M]Nightmare, CotHM Founder [BUNG], :
Weapon-level reload buff — Each weapon’s level increases that weapon’s reload rate. This improvement is present regardless of which scav is using the weapon. This is in addition to the already-existing system that allows vendors to sell you better customization options as the weapon level increases.
Third person crosshairs adjusted to better approximate the weapon’s current accuracy
All weapons received a tuning pass (including their DPM in some cases) with this new system

Additional General Weapon Fixes

Reload anim desync fixed — gun and scav reload animations no longer drift apart
Gunhead head-weaponry improvement — Gunhead’s head weapon will always fire at center mass instead of occasionally targeting the target's feet

AI

Fixed an issue where AI might error out if fed a goal or target that is no longer valid (rare race condition)
“Pot shots” now have an additional fix / guard: Extra code to ensure AI no longer takes random shots at players they are not yet aware of
Standing-corpse fix — AI dying far from a client will now now ragdoll correctly vs. occasionally remaining standing
Fix for specific AI spawning: AI like the Opal will no longer occasionally explode the moment their landing sequence ends
Fix for flying AI — flyers such as choppers should now no longer smash themselves into the ground occasionally
Buddy AI command bug — interrupting a command anim (point, wave, etc.) no longer occasionally causes the player to lose functionality (such as jumping, mantling, etc.)

Multiplayer / Networking

Networking note:
Networking and issues related to networking are notoriously difficult to track down due to the number of variables (distance between players, network conditions, types or routers and modems and ISPs, you-name-it). We will continue to focus on issues found here & areas that existing systems can be made better as we continue to update the game

(3/4)

M]Nightmare, CotHM Founder [BUNG], :
Network reliability pass:
Improvement for session joining. If a session join fails, it now fails cleanly instead of potentially hanging
Hosting: hosts now hold reservations (an anticipated joining player) for a longer amount of time  to help with party stability
Client joins: An improvement was made where clients attempt to auto-reconnect on connection loss instead of instantly dissolving the party
Client skills/abilities fix: a fix for several of the instances where clients would occasionally not have their skills enabled when they spawn
Projectiles: a fix was put in to prevent projectiles from occasionally remaining still on screen for clients (making said projectiles look like they are floating in air vs. moving)

Stability / Crash Fixes
An uncommon texture page-map crash was fixed (fixes an occasional crash that sometimes occurred when extracting back to Innards)
A UI crash was addressed (fixes an occasional UI crash that occurred in specific, rare situations)
A manufacturing HUB / Innards facilities fix was implemented: Innards upgrades should no longer occasionally get "lost" or eat resources only to appear much later

NOTE: Players who update to this new version of the game while they have a HUB / Innards upgrade is in progress:
These players will have the in-progress upgrade’s Credit Cost and Item Cost refunded
The in-progress upgrade will be canceled
Players who have this occur will have to buy the upgrade again (and wait the full time)
The improved system is different enough that this step is necessary. It is a one-time-only check to potentially refund and reset

(4/4)
