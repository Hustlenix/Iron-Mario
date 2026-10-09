# Iron-Mario shared asset foundation

This directory is the first asset-only layer for the 105-game arcade. It contains original vector zone compositions, the shared palette, UI/effect rules, and source/licensing records. Existing game mechanics and catalog entries are unchanged.

## Kits

| Kit | File | Use |
|---|---|---|
| Sky Foundry | `zone_kits/sky_foundry.svg` | launch decks, turbines, cables, warning lights |
| Neon Workshop | `zone_kits/neon_workshop.svg` | benches, screens, tools, storage |
| Reactor Core | `zone_kits/reactor_core.svg` | containment, conduits, power chambers |
| Fungus Underworks | `zone_kits/fungus_underworks.svg` | caves, crystals, spores, organic hazards |
| Battle Lab | `zone_kits/battle_lab.svg` | arenas, targets, barriers, boss entrances |
| Chaos Carnival | `zone_kits/chaos_carnival.svg` | signs, comic machinery, surprise props |

SVG is intentional here: it stays sharp at 960x480 gameplay scale and at mobile preview sizes, while allowing later rasterization into atlases without losing the style system.

## Source policy

`source_inventory.json` records the seven supplied folders, observed counts, and current release status. The full Modern Interiors packs are the only supplied third-party sources currently marked public-ready. They require LimeZu credit. Free or unverified sources remain restricted until their licenses are confirmed.

The Character Generator executable and extracted Linux build are recorded as tooling references. No installer or unknown asset license is bundled into the public game.

