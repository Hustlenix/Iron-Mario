# OnlyEducation

The playable historical arcade is now in arcade/. See ../docs/arcade/README.md for run instructions, architecture and verification.

# OnlyEducation - historical arcade foundation

The new pitch is a focused 20-game journey through early gaming mechanics. This directory isolates its Canvas asset integration from the existing Godot arcade. The old 105-game catalog has not been renamed into 20 supposedly finished new games.

## This milestone

95 original shared pixel assets: 24 pieces, 8 tiles, 15 UI elements, 4 animated effects, 4 era scenes, 20 art concepts and 20 medallions. All four effects have still alternatives. The browser asset lab consumes the same manifest-driven renderer that future games can import.

- Original exports: ../assets/shared_foundation/history_arcade
- Editable Aseprite sources: ../source_art/history_arcade
- Three new curator studies: ../source_art/history_arcade/curators (private authoring only)
- Source decisions: ../source_art/history_arcade/source_notes.json
- Browser preview: http://127.0.0.1:8785/history-assets/

Build artwork and real Aseprite sources:
python tools/build_history_assets.py

Package existing exports without requiring the authoring app:
python tools/package_history_assets.py

Verify:
python tools/validate_history_assets.py
node tools/history_assets_smoke.cjs

The Playwright check expects the existing static server on port 8785 serving build/web.

## Reuse from Canvas

Import PixelAssets from asset-lab/shared/pixel-assets.js. Load assets/manifest.json with an optional {ids: [...]} subset so an individual game loads only the art it needs, then call draw(ctx, id, x, y, {frame, scale}). Frame coordinates, integer scaling, anchors, palettes, status, and nine-patch margins are recorded. panel() draws the scalable UI pieces. Effect frame() accepts a reduced-motion flag.

The roadmapped titles are art concepts, not released game implementations. All published kit pixels are original project artwork; the publication license will need to be stated at release. Third-party pack-derived curator studies are kept separate and are not included in the browser package.
