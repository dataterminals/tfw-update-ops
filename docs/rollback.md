# Rollback — recovering an old build

The escape hatch. Slow and clumsy, which is exactly why `baseline-capture.md` exists.

## The keys

Steam can re-download a specific historical build **if you know the depot and manifest IDs**.
Those live in `appmanifest_2828860.acf` while that build is installed, and are overwritten the
moment it patches. `state/build-history.md` is where we keep them after the fact.

| Field | Value |
|---|---|
| App ID | `2828860` |
| Depot ID | `2828861` |
| Shared depots | `228989`, `228990` (from app `228980` — VC redists; not build-specific) |

Per-build manifest IDs: see [`../state/build-history.md`](../state/build-history.md).

## Procedure

1. Steam → open the console: `steam://open/console` in a browser, or launch Steam with `-console`.
2. `download_depot 2828860 2828861 <manifest_id>`
3. It lands in `steamapps/content/app_2828860/depot_2828861/`, **not** over your install. That's
   the point — it's a second copy you can decode against without disturbing the live game.
4. Point the decoder at it:
   `export FW_PAKS="…/steamapps/content/app_2828860/depot_2828861/Windows/ForeverWinter/Content/Paks"`

Caveats worth knowing before you rely on this:

- ~50 GB and no progress bar worth the name. Budget an evening.
- Valve can and does prune very old manifests. Recent ones are reliable; year-old ones are not
  guaranteed.
- `download_depot` needs the depot to be one you own — fine here, TFW is a single-depot game.

## Preventing an unwanted update

Steam's per-game setting is **Properties → Updates → "Only update this game when I launch it."**
That stops scheduled background updates, but it still patches on launch — so with that setting
you must not launch the game until you're ready.

The `.acf` field is `AutoUpdateBehavior`: `0` = always keep updated, `1` = only on launch,
`2` = high priority. Read it, don't write it — Steam owns that file and will overwrite hand edits.

## Preserving a working setup across a patch you can't refuse

The MO2 mod store (`H:\MO2Instance_ModData\ForeverWinter\`) is outside the game directory and is
**not** touched by a Steam update. Built mod artifacts survive on their own. What you lose is the
*game-side* half — the paks the mods were built against — which is what the rollback above buys
back, and what the baseline capture makes it unnecessary to buy back in most cases.
