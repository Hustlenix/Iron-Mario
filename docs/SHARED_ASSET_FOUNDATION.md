# Shared asset foundation

The 105-game catalog remains unchanged while this layer is prepared. The asset gallery is generated at `build/shared-foundation/index.html`; the searchable data is `build/shared-foundation/catalog.json`.

The project now contains six original retro-future toybox zone compositions plus UI and effects reference kits under `assets/shared_foundation/`. They are SVG compositions so they remain crisp at the existing 960x480 board and at mobile preview sizes. They use the Iron-Mario palette and leave the board center readable for existing game interactions.

The supplied packs were inspected on 2026-10-09. The full Windows and RPG Maker Modern Interiors packs include commercial-use licenses with required LimeZu credit. The Modern Interiors free pack is noncommercial-only. Fantasy Battlers, Fungus Cave, and Character Generator have no usable local art-output license statement in the supplied folders, so they are recorded as restricted source references and are excluded from the public build. The Character Generator executable and installer are not bundled or run automatically.

Use `python tools/asset_foundation_check.py` for the deterministic foundation check and `python tools/build_shared_asset_catalog.py` to regenerate the gallery. The Godot SVG importer was run successfully for all eight kit files; headless pixel capture is left to a visible rendering backend because this environment's headless renderer stalls during `frame_post_draw`.
