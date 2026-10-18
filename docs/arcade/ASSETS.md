# Asset and license register

The current arcade uses the existing 95-asset original history kit; no additional raw pack assets are needed for Waves A and B.
Original exports are under assets/shared_foundation/history_arcade, with per-file hashes and provenance in manifest.json. Editable pixel art timelines live under source_art/history_arcade. Aseprite previously produced ten validated timelines (seven original kit sources and three private character studies); those outputs were reverified, not unnecessarily regenerated.

| Family | Use | Publication decision |
| --- | --- | --- |
| Original history scenes, concept boards and medallions | Collection, timeline and featured cabinet | Original project artwork |
| Original terminal, scout, crate, steel tile, robot, bug, ship, rock and turret | Gameplay across both waves | Original project artwork |
| Original OE mark | Brand and favicon | Original project artwork |
| Canvas primitives and synthesized tones | Game objects, feedback and HUD | Newly authored implementation |
| Modern Interiors full pack | Previously used for private curator source-layer studies | Not included in this arcade package |
| Character Generator application | Previously inaccessible; no new successful app exports claimed | No output included |
| Fantasy Battlers Complete / Free | Visual reference only in earlier asset phase | No copied art included |
| Fungus Cave 16x16 | Visual reference only in earlier asset phase | No copied art included |
| Modern Interiors Free and RPG Maker variants | Previously inventoried overlapping sources | No copied art included |

The three private curator studies and all third-party source packs remain excluded. The full Modern Interiors license permits use in games with LimeZu credit but not standalone redistribution. The new arcade does not need those images. No new public redistribution license is asserted for the project's own work; owner licensing remains a release decision.

Game-specific historical references are in grid-crate.md, byte-brick.md, stackfall.md, cavern-color.md, court-hop-flag.md and rock-sky.md. Paddle Panic references the Computer History Museum's Pong exhibit: https://www.computerhistory.org/revolution/computer-games/16/183 . History dates identify inspirations, not the publication dates of these new games.

Aseprite was invoked again on 2026-10-17 to export shared_pieces.aseprite. All 24 frames matched the existing PNG sprites exactly; see aseprite-roundtrip.json.

## Dino Dash bonus
Original runtime sprite strip and cover: onlyeducation/arcade/art/. Editable five-frame Aseprite timeline: source_art/dino_dash/runner.aseprite. Both were authored for OnlyEducation and contain no third-party pixels. The game-specific manifest keeps the base 95-asset history kit intact.

## Gameplay discovery thumbnails
All fourteen public previews in onlyeducation/arcade/art/previews are native 480x320 captures of the actual original game canvases. tools/capture_arcade_thumbnails.cjs records normal-input gameplay and exports only the rendered canvas. No third-party site art or logos are included.


## Playground feature art
The redesigned collection uses the existing project-original art/dino-dash-card.png for its feature. Standard card previews, recommendation images and switcher images retain the native gameplay captures. No external artwork or font bundles were imported.
