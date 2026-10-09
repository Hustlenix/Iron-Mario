# Asset usage map

Inventory and local license inspection completed on 2026-10-09. The permitted full Modern Interiors art is now incorporated into one flattened, game-specific room backdrop at `assets/rooms/reactor_garage.png`. It is used by `impossible_parking` and `chaos_elevator` in `games/chaos.gd`. This records implemented usage; live deployment verification is a separate release check.

| Source | Suitable game roles | Proposed narrow integration | Current status |
|---|---|---|---|
| Modern Interiors full | Garage parking and elevator delivery interior | A flattened room composite at `assets/rooms/reactor_garage.png`, assembled from selected permitted full-version atlas regions. Referenced only by `impossible_parking` and `chaos_elevator`. | Implemented. Local commercial game-use license confirmed. SETTINGS includes the required LimeZu credit; raw source atlas and source pack are not shipped. |
| Modern Interiors RPG Maker full | Interior puzzles with RPG Maker-format room/character artwork | Convert a small, identified source region only if the plain full-version art does not meet the gameplay need. | Permitted by local full license, not integrated. No reason to ship duplicate resolution/format sets. |
| Modern Interiors free | Noncommercial prototype only | None for the intended monetizable arcade. | Excluded because commercial use is explicitly prohibited. |
| Character Generator parts/output | Custom original avatar or NPC animation | Potential future exported character after explicit output license and frame-layout verification. | Blocked by missing rights. No executable run and no parts copied. |
| Fantasy Battlers complete/free | Boss portraits, enemy selection, turn-based combat | Small individual battler selection after exact package rights are verified; do not label static variants as animation frames. | Blocked by missing rights. |
| Fungus Cave | Cave exploration, underground puzzle rooms, platform hazards | Small tileset selection after exact package rights and collision/frame layouts are established. | Blocked by missing rights. |
| Original arcade art | Runners, timing, physics, strategy and reaction games | Existing handmade drawings and newly created primitive illustrations. | Current production art source; no supplied-pack rights dependency. |

The mandatory credit appears in SETTINGS: **Modern Interiors by LimeZu — https://limezu.itch.io/**. The full-version local license remains the evidence for game-use permission. The free-version pack and all unverified packs remain excluded.

The shared cream/red/yellow/navy shell, controls and typography remain the common presentation. The permitted pixel room is restricted to the two interior games whose mechanics benefit from it.

Release checks: verify the exported build includes only the incorporated composite and required game resources; verify the settings credit and local/base-path loading in the deployed build. Unverified packs remain excluded until reliable permission is attached to the exact source package.
