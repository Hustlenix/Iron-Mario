# Town character authoring

These six .aseprite files are actual Aseprite-saved editable timelines at 16×32. Each has 88 frames and 20 named tags: static idle, walk, animated idle, hit and hurt in four directions. Walk poses can play faster as run timing; there is no separate source run cycle.

Source pixels are composed from the user's full Modern Interiors character layers, with LimeZu credit. Source recipes live in assets/shared_foundation/town_cast/recipes.json. The code-generated Lua timeline assembly preserves native source frames and anchors; it does not claim hand-drawn animation.

Rebuild: tools/export_town_aseprite.py then tools/build_town_spriteframes.py. The first rebuilds the authored timelines from compact source strips, so preserve manual edits separately before intentionally regenerating. Runtime PNG/JSON files are in assets/shared_foundation/town_cast. source_art/.gdignore excludes editable files from Godot imports.

The installed Character Generator app did not expose a usable window during the 2026-10-15 retry. The earlier application-generated NPC is recorded separately; these six repeatable recipes use full licensed source layers.
