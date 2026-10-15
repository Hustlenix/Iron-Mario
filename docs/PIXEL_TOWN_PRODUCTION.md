# Pixel Town production order

## Current evidence

- Six cast sheets composed from full Modern Interiors layers and imported by Godot.
- Aseprite 1.3.18.6 local build now saves six editable 16×32 timelines under source_art/town_cast, each with 88 frames and 20 named source-animation tags. PNG/JSON atlas exports are verified for tag boundaries. Godot SpriteFrames consume these exports.
- Character Generator successfully produced the earlier workshop NPC. Current six cast sheets use repeatable layered composition with recorded recipes.
- The selector uses the shared town character renderer, authored pixel button textures and success effect. Native desktop/mobile selection, equipment and celebration captures are stored in build/visual-after. Gameplay input verification is tracked separately.
- District kits and the complete 105-game replacement are unfinished.

## 2026-10-15 local checkpoint

- Six district interiors and exteriors now export at 320×180, with 288 populated tile assignments, 144 prop assignments, 24 hazard assignments and five shared animated objects. Counts distinguish assignments from unique exports in town_library/catalog.json.
- Twelve original eight-frame feedback effects and static alternatives, 29 icons, panels, buttons, badges, banners, meters and a bitmap font are in town_fx_ui. Selector buttons and celebration feedback consume these assets.
- Searchable browser catalog now includes 124 exported image records and nine family contact sheets. This is a local review package, not a public release or a claim that all games use these assets.
- PNG/source/frame validation: 2070 checks passed. QA evidence: build/qa-town/audit.md. UI GPU 512, save/service 207, viewport alignment 44, catalog lifecycle 1492, input 24 and mobile native-event 91 checks passed.
- Character Generator's installed app failed to expose a window during this turn. Earlier app output and present full-pack layer recipes remain documented separately. Current cast authoring/export was performed through the local Aseprite build.
- Remaining: character accessories/missing states and per-game visual adapters/application. No game is marked visually complete from shared-renderer work alone.

## Tool responsibilities

1. Character Generator: audition body/outfit/hair combinations and verify poses. Save named recipes; never randomize accepted character identities during rebuilds.
2. Aseprite: the locally built application at Downloads/aseprite/build/bin/aseprite.exe owns editable timelines and PNG/JSON exports. Run tools/export_town_aseprite.py, then tools/build_town_spriteframes.py after source changes. The older trial is not used for these exports.
3. Batch pipeline: compose approved layers, extract only animation cells, export compact sheets and portraits, retain provenance. Do not overwrite authored corrections; generated files and manual overrides have separate paths.
4. Godot: own SpriteFrames, frame timing, consistent foot anchors, input and display scaling. Reuse visual resources across games.

## Source assignments

- Full Modern Interiors Windows: canonical 16px interiors, character layers, props and animated objects.
- RPG Maker edition: comparison/reference; select a variant only when it improves the needed asset. Never bundle duplicate packs.
- Free Modern Interiors: reference/comparison; prefer corresponding full-version assets for exports.
- Character Generator Linux build: recipe/component reference on Windows; use the installed Windows application.
- Fantasy Battlers Complete/Free: silhouette and pose reference, then selected compatible creature assets with recorded source terms. Deduplicate overlapping images.
- Fungus Cave: underground tile and creature reference, selected exports once source terms are recorded.

## Ordered milestones

1. Cast: compact clean animation exports, six identities, consistent foot anchors, selection portraits and removal of active superhero copy. Review full roster and one gameplay scene in Godot.
2. Workshop pilot kit: one complete room, curated props, four animated objects, readable UI and character actions. Resolve scale and palette here before producing the remaining districts.
3. District library: Sky Foundry, Neon Workshop, Reactor Works, Fungus Underworks, Training Yard, Chaos Carnival. Each has modular tiles, props, hazards, effects and assembled previews.
4. Six representative games: skyline_jumper, armor_repair, reactor_merge, maze_runner, shadow_armor_duel, brainrot_button_panic. Review actors and interactive objects as well as backgrounds.
5. Remaining games: apply approved kits in batches by presentation needs. Every game keeps an individual review entry; shared rendering alone never counts as a complete art replacement.
6. Release review: regenerate thumbnails, remove stale assets from export, check save compatibility and local web rendering, then verify any separately authorized publication.

## Completion accounting

Use separate statuses: planned, exported, integrated, visually reviewed, behavior verified. Each entry names its source, export, consumer and evidence. Counts describe actual exported resources, not palette variations or empty placeholders. No milestone is complete merely because a script generated files or Godot imported them.

Keep the existing 105 game IDs and mechanics. Character choice is cosmetic. Preserve profile IDs internally while displaying the new cast names, so scores, mastery and saved selections stay compatible.
