# Local visual asset map

Checked 2026-10-09. All seven extracted folders are present in `C:/Users/LalithReddy.b/Downloads`. File counts cover the full folders; headers are bounded samples for large packs, and alpha measurements cover the contact-sheet images. No supplied program was run.

Open [the private contact-sheet index](../build/visual-assets/index.html) for actual art, alpha previews and room compositions. [inventory.json](../build/visual-assets/inventory.json) records sampled dimensions, visible bounds, transparent-pixel ratios and observed sheet layouts. These outputs are under ignored `build/`, and must stay out of public distributions.

| Exact folder | PNG files | Actual art / layout findings | Release decision |
|---|---:|---|---|
| Character Generator 2.0 Linux Build | 1,439 | Separate body, eyes, outfit and accessory sheets; sampled grids 896×640, 1792×1280 and 2688×1920. Mostly transparent layers. Generator frame order and output rights unverified. | Exclude: no license/readme granting art or output rights. |
| moderninteriors-win | 51,904 | Room builder 1216×1808; theme sheets, individual props, UI 288×256, home previews, layered characters. 16/32/48 pixel variants. | Full local license permits game use and edits; mandatory LimeZu credit. Selected room composites only. |
| Modern_Interiors_RPG_Maker_Version | 494 | RPG Maker floor/wall and character sheets; common 144×384 and 768×768. Requires explicit atlas regions. | Full local license permits commercial game use and edits; mandatory credit. Available for later use. |
| Modern_Interiors_Free_v2.2 | 64 | Interior tiles and civilian poses; idle strips 64×32 show four 16×32 poses. Character sheets 48×128 show 3 columns × 4 rows of 16×32 frames. | Exclude: local license explicitly forbids commercial use, including edited sprites. |
| Fantasy Battlers - Complete | 250 | Static fantasy opponent illustrations and overview atlases. Individual 48×48 through larger sizes; variants are not verified animation frames. | Exclude: no supplied local license. |
| Fantasy Battlers - Free | 46 | Static fantasy opponents with original and ×2 images. README recommends a size but grants no rights. | Exclude: no supplied local license. |
| Fungus Cave [16x16] | 79 | Cave tilesets, static monsters and 48×128 character sheets: 3 columns × 4 rows of 16×32 frames. Direction order unverified. | Exclude: no supplied local license. |

Fantasy battlers are scenery/opponent candidates for a later licensed fantasy mode. They do not depict the four original heroes and should not replace that roster. Civilian Modern Interiors sprites may support background NPCs; this milestone keeps original hero identity.

## Authored backgrounds ready for integration

| Release asset | Intended use | Verified output |
|---|---|---|
| [menu_arcade_hub.png](../assets/rooms/menu_arcade_hub.png) | Menu or hero hall: arcade cabinets around a clear center | 640×360 RGB, 8,663 bytes |
| [hero_training_room.png](../assets/rooms/hero_training_room.png) | Four-hero selection or training: quiet central mat, gym equipment at edges | 640×360 RGB, 10,455 bytes |
| [reactor_workshop.png](../assets/rooms/reactor_workshop.png) | Parking / elevator scenery: side terminals and clear working area | 640×360 RGB, 8,199 bytes |

Each is an original room layout flattened from selected full-pack tile/prop regions plus original furniture or markings. No raw atlas or source pack was copied into the release. Use nearest filtering; roughly `Rect2(128,120,384,216)` is clear for overlay content. [room-provenance.json](../build/visual-assets/room-provenance.json) records exact source regions and output SHA256 values. UI integration and live screenshots are separate verification owned by the app work.

Required in-game credit: **Modern Interiors by LimeZu — https://limezu.itch.io/**. Local evidence: full pack `LICENSE.txt` SHA256 `e33effd51253bb90c0d83fb555405f300273e9772d5eb84105327b6fa3eab4c5`; RPG Maker full `LICENSE.txt`; free version `LICENSE.txt`. Full permission does not apply to free-version files. License bars distributing/reselling the asset itself; ship only selected art incorporated into the game.

Rebuild locally with `python tools/visual_asset_inventory.py --inventory --rooms`. The script reads only the seven named folders, PNGs and local license/readme documents. `.wakatime.cfg` and all tracking settings are untouched.
