# Shared pixel-art foundation

The 105-game catalog and mechanics remain unchanged. The asset gallery is generated at `build/shared-foundation/index.html`; its searchable data is `build/shared-foundation/catalog.json`.

Six original 320×180 pixel-art board scenes and a transparent four-frame effects sheet sit under `assets/shared_foundation/`. They use the arcade's warm paper, dark ink, blue rails, coral hazards, restrained pixels, and clear central play area. Artwork is composed at native pixel scale.

The supplied packs were inspected on 2026-10-09. Full Windows and RPG Maker Modern Interiors include commercial-use licenses with required LimeZu credit. The Modern Interiors free pack is noncommercial only. Fantasy Battlers, Fungus Cave, and Character Generator have no verified local license for public use, so their assets remain excluded pending license evidence. The Character Generator executable is inventoried and is not bundled in the game.

Run `python tools/build_shared_asset_catalog.py` to rebuild the scene previews and searchable gallery. Run `python tools/asset_foundation_check.py` to verify the exported PNG dimensions, integrity, and recorded source status.
