# HANDOFF — start here

**Written:** 2026-07-31, end of the session that applied the patch and did the first triage pass.
**State:** patch **applied**. 6 of 7 gates green. One mod fixed and deployed but **not released**.

---

## The situation in five lines

- Build `24479102` landed 2026-07-30 17:34 EDT. Both baselines captured; the window was not missed.
- **Gates 0, 1a, 1b, 2, 3, 3b are all green.** Only **5a** (TFWWorkbench reads the new paks) is open.
- **`AllWeaponsUnlockableFix` is fixed** (both variants), verified, deployed to MO2, **not on Nexus**.
- **`HeavyRifleRebalanceFix` is dead** and needs a *redesign*, not a rebase.
- Everything else structurally survived. Class B is fully intact.

## Do this first

**Nothing is blocked on analysis. The one user-facing gap is the Nexus upload.** Users are still
downloading pre-patch paks that break the gun-customization UI. Files are built, verified and
waiting in `AllWeaponsUnlockableFix/dist/`:

| Page | File | Sanity check |
|---|---|---|
| AWU | `dist/AllWeaponsUnlockableFix.zip` | inner `.ucas` = **110,000 B** (exactly — see below) |
| AWUTrees | `dist/AllWeaponsUnlockableTrees.zip` | inner `.ucas` = **79,239 B** |

Known-bad sizes, check **exactly**: `110,008` is the 07-31 morning build that silently
**resurrected the Session-2 carry grafts** (regression found 07-31, fixed `d12007d` — eight bytes
from the good build, so eyeballing is not checking). `112,133` / `81,372` are the pre-patch
builds with the dead DataAsset pointers. Ship only `110,000` / `79,239`.

**Permission gate found 2026-07-31 — read before uploading the regular variant.** The two builds
are not in the same copyright position. The **regular Fix ships six skill roots converted out of
the #110 author's own pak** (`build_fix.sh:42-46`) plus their AllowTags edits, so redistributing it
depends on their permission. **Trees inherits nothing from #110** but the concept and is free to
ship. Two facts needed and recorded nowhere: the author's **username** and their page's
**Permissions and credits** block — both one page-load from mod #110, but Cloudflare blocks
automated fetches, so it needs a logged-in browser. Full write-up in
`AllWeaponsUnlockableFix/CREDITS.md`. **If the answer is slow, ship Trees alone** — it is the
variant `disxmfk` was running.

**Release facts, already researched — do not re-derive:**
- Versions: regular is on **1.1.0**, Trees on **1.0.0**. They are *not* in step. Suggested bumps
  **1.2.0** and **1.1.0** (minor: behaviour unchanged, compatibility rebuild + filename change).
  Sylvia had not confirmed these when the session ended.
- **Dependency is Signature Bypass only.** Neither variant ships Lua or Workbench DataTable JSON,
  so neither needs RE-UE4SS or TFWWorkbench. Saying otherwise sends users to install a pinned
  UE4SS build for nothing.
- Paks install to `...\The Forever Winter\Windows\ForeverWinter\Content\Paks\Mods\` — a folder
  that **does not exist on a stock install**. Most common "nothing happened" cause.
- **The pak filename changed** this session (`AllWeaponsUnlockable_P` → `AllWeaponsUnlockableFix_P`),
  so new files do **not** overwrite old ones. Upgraders must delete the old set or double-install.
  Covered in the readme; worth a changelog/sticky note too.
- A Nexus reply to user `disxmfk` is owed — they reported the break and were correct.

## What this patch actually did

Full analysis in [`state/stage2-findings.md`](state/stage2-findings.md); root cause of the
user-visible break in [`state/rootcause-awu-customization-ui.md`](state/rootcause-awu-customization-ui.md).

- **Weapons were restructured, not just retuned.** `DA_WPN_<code>_v2` split into
  `DA_WPN_PLAYER_<code>` + `DA_WPN_AI_<code>`, and the entire per-weapon `FC_*` curve tree was
  **deleted game-wide** (`FC_*_Damage` 44 → 0).
- **1,013 added / 1,293 removed is mostly noise** — 924 are case-only renames (`BagMan`→`BAGMAN`).
  Real churn is 369 removals, **358 of them under `FW/Weapons/`**.
- `WeaponsDetailsData` 56 → 53 rows; `DT_TagToRowHandle` 1176 → 1173. The cut rows are
  `RFL01_Red/Blue/Green`, unused dev-test entries.
- The AI vision sensors gained `Pawn.Player.HoldingPistol` (accum 1.2 / decay 0.8) — holding a
  pistol makes you **~20% slower to detect**. Publishable almanac Detection-tab update.

## Two hard-won lessons this patch taught

**1. A `.usmap` is per-struct.** Gate 1b was marked cleared on the strength of AI sensors decoding
perfectly (28 dumps byte-identical). That was real evidence and the wrong conclusion —
`FWWeaponDefinition` decoded to *shifted garbage*: correct values bound to neighbouring property
names, no error, entirely plausible. Regenerated via UE4SS `Ctrl+Numpad6` (already bound in the
built-in Keybinds mod — the README's "install experimental UE4SS + write a Lua mod" procedure is
more work than needed). **Never generalise usmap validity from one struct family.**

**2. Verification that doesn't check references isn't verification.** Three layers passed a pak in
which every weapon pointed at a deleted asset. A user found it. `tools/verify_softrefs.py` now
gates both AWU builds — it asserts every `AssetPathName`/`ObjectPath` resolves against a filelist
**regenerated from the live game each run**. Proven: 63 dangling on the broken pak, 0 on both
rebuilds. **It is mod-agnostic — porting it to the other pak mods is the highest-leverage
remaining work.**

## Work remaining, roughly in value order

1. **Nexus upload** (above). Only user-facing gap.
2. **Port `verify_softrefs.py`** to `UnkillablesRebalanceFix`, `HeavyRifleRebalanceFix`,
   `TFWQuestGiverPortraitPatch`, CMSF. Just needs calling.
3. **`HeavyRifleRebalanceFix` redesign.** 11 of its 13 targets are gone. The DataAssets are
   renamed (rebasable) but all 5 `FC_*_Damage` curves are **deleted**, and per the mod's own
   `docs/diagnosis.md` the *curve* was the real damage lever while the DA scalar is "cosmetic".
   A pure rebase would look rebuilt and do nothing. **Hypothesis to test, not assume:**
   `WeaponDamage` on `DA_WPN_PLAYER_*` (270.0 for HRF01) may now be authoritative. Verify by
   changing it on one weapon and confirming in-game damage moves.
4. **Gate 5a** — does TFWWorkbench read the new paks. Gates Class A rebuilds. Needs a launch.
5. **Content diff for the 🟨 Class A mods.** Their paths all survive, but a surviving path is not
   a surviving asset — BP graphs and DataTable values change without paths moving.
   `UnkillablesRebalanceFix` silently reverts upstream BP edits by construction.
6. **Nine dump subdirs sit outside `fwdata`'s taxonomy** (`ai_sensors`, `bosses`, `enemies`, …)
   and were not re-decoded. Verified 0 stale, so not suspect — but adding taxonomy entries is the
   natural cleanup.
7. **In-game test** of the AWU fixes. Static verification is not play.

## Things established — don't re-derive

- **Rollback key for `24479102`: manifest `6430523508700280691`** (app `2828860`, depot `2828861`).
  Recorded in `state/build-history.md`. Previous build's key is there too.
- **MO2 deploys RE-UE4SS / Signature Bypass via Root Builder**, which physically copies them into
  `Binaries\Win64` for the session. **During a session the live logs are at the real game path**
  (`…\Binaries\Win64\ue4ss\UE4SS.log`, `…\bitfix.txt`); they only reach MO2's `overwrite\` after
  cleanup on exit. Reading the overwrite copy mid-session gets you the *previous* session's log.
- **`forever-winter-skin-mods` is NOT deployed.** The four enabled skins (`101`–`104`) are
  third-party. Registry corrected. Only **5** of the 12 enabled mods are ours.
- **The MAY skin set is not new** — 179 assets before and after this patch, 0 added. It has rows
  in `DT_SkinUIData` for Girl/Gunhead/Shaman. Note the casing inconsistency: `Skin.Girl.MAY` but
  `Skin.Gunhead.May` / `Skin.Shaman.May`. Your repo covers ScavGirl and Shaman May but **not
  Gunhead** — a real gap.
- **The live usmap keeps a stable filename** (`ForeverWinter-5.4.2.usmap`); archived ones carry
  the build stamp in `mappings/archive/`. Nine build scripts hardcode the stable name — renaming
  the active file is a **breaking change**, not bookkeeping.
- **`fwdata get --force` does not update `datamine/dumps/`.** It writes to a build-namespaced
  cache while `build all` globs `dumps/`, so running the README's own remedy back-to-back yields
  a catalog stamped new and populated old. Promote manually. `fwdata` should be fixed.
- `dumps/lootobjects` is a deliberate **151-of-437 curation** — never blind-copy the cache over it.

## Tooling added this session

- `tools/diff_baseline.ps1` — diffs two baselines into `state/diffs/`. Tested against a synthetic
  patched baseline so every branch fired, not just the no-op path.
- `AllWeaponsUnlockableFix/tools/verify_softrefs.py` — the dangling-reference check.
- `assets.py` gained `player_weapons` / `ai_weapons` / `weapon_tables` (weapons were never in the
  taxonomy; they were ad-hoc decoder pulls).

## Current MO2 state

Both AWU variants are **disabled** in the Default profile — re-enable before testing. The three
Class B mods (`TFWLootAll`, `TFWStaggerControl`, `TFWQuestHUDToggle`) were enabled for the Gate 3
test and may still be. `TFWStaggerControl` runs in `mode=blanket`, which suppresses **all**
stagger — fine for a controlled test, not something to leave on for normal play.

Previous MO2 paks are backed up under the session scratchpad, but git is the durable copy.
