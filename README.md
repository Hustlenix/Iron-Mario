# Iron-Mario — Super-Micro Arcade

A Godot arcade with **105 playable games**: 50 preserved microgames, 25 puzzles, 16 original classics, 11 chaos games and 3 restored cabinets. The opening screen features four original superheroes: **Solstice, Vector, Umbra and Prism**, with large illustrated previews, entrances, timed power demonstrations, sound cues, keyboard/controller navigation and responsive phone layouts. Quick play, a five-heart Tournament and a deterministic ten-game Daily Challenge remain available through ARCADE.

[Play in the browser](https://hustlenix.github.io/Iron-Mario/)

The 3.0 catalog adds searchable, paginated shelves, favorites, recent games, sorting, rendered board previews and control instructions. Short games enter the quick-play pool; longer cabinets launch individually. Original music and migration from historical `save.dat` and `iron_mario_save.cfg` profiles remain supported.

## Play

Tap, hold, swipe, or drag as shown by each game. Keyboard uses arrows/WASD and Space; controllers use the stick/D-pad and A. Arcade puzzles also use 1–4 to select, E/B for a secondary action, R to reset and U to undo where supported. For a precise physics swipe, hold Space/A, move the crosshair, then release. Escape/Start pauses. Portrait and focus changes safely pause play and cancel held inputs.

All games and the four featured heroes are immediately available. Selection is cosmetic; power demonstrations are presentation previews and PLAY opens a matching existing game. Native saves preserve XP, mastery, medals, missions, favorites, records and cosmetic coins. Browser hero and reduced-motion preferences survive immediate reload through validated localStorage keys. Broader browser record durability currently needs further repair; an IndexedDB reload check exposed stale saved data. Coins buy cosmetic effects only. Billing, ads and external analytics are disabled adapters, not simulated purchases.

## Develop

Open `project.godot` in **Godot 4.7.1**. The renderer uses OpenGL compatibility and the Web export is single-threaded. The project has no third-party runtime dependencies.

```sh
godot --headless --path . --editor --import --quit
python tools/run_checks.py godot
```

Fourteen suites drive action-based wins, losses, restart, pause, scoring, save migration, native keyboard/touch/controller events, responsive hero selection and cleanup. All 105 IDs are exercised through the actual application. Tests use disposable profiles; `--test` keeps the profile autoload away from real saves. CPU measurements are headless update costs, not physical-device FPS.

See the [hero selection milestone](docs/HERO_SELECTION_MILESTONE.md) for art provenance, saved-ID compatibility, browser preferences and the remaining broader visual work. Run `godot --path . --script res://tests/capture_visual.gd -- --test` to capture all four heroes, their powers and mobile layouts into `build/visual-after`.

See [game audit](docs/GAME_AUDIT.md), [machine catalog](docs/game_catalog.json), [46 verified Play Store references](docs/PLAY_STORE_RESEARCH.md), [asset licenses](docs/ASSET_LICENSES.md) and [release progress](docs/IMPLEMENTATION_PROGRESS.md). Small authored garage interiors use commercially licensed Modern Interiors by [LimeZu](https://limezu.itch.io/). Unverified and noncommercial asset packs are excluded; supplied installers were not run.

To inspect layouts on a graphics-capable machine:

```sh
godot --path . --script res://tests/capture.gd -- --test
```

Captures go to `build/qa`. They are development artifacts and are excluded from exports.

## Architecture

- `core/input_router.gd`: touch, mouse, keyboard and controller into one input vocabulary.
- `microgames/microgame_base.gd`: timing, results, feedback and lifecycle.
- `microgames/pack_*.json`: registry metadata; `pack_*.gd`: distinct game rules.
- `core/run_director.gd`: shuffled Tournament queue, difficulty and score multipliers, daily schedule.
- `core/save_store.gd`: sanitized profiles, migration, backup recovery and progression.
- `ui/`: responsive application shell and painted controls; `art/`: original primitive-built character art.
- `scripts/music_player.gd`: bounded original-music crossfades.

Add metadata and a `MicrogameBase` implementation to expand the library. Menus and modes consume the registry automatically; they do not enumerate game buttons independently. Only the active microgame is instantiated.

## Export

Create `build/web` and `build/windows`, then run:

```sh
godot --headless --path . --export-release Web build/web/index.html
python tools/finish_web.py
godot --headless --path . --export-release "Windows Desktop" build/windows/Super-Micro-Heroes.exe
```

Serve the Web directory through HTTP. GitHub Actions tests and exports before publishing it to the existing GitHub Pages URL. The PWA uses Godot's generated service worker and a custom loading/offline shell. Offline play requires a completed first download.

Native Android packaging, store billing, online leaderboards and server-authoritative dailies require separate platform integration. The current daily date and records are local. Real-device performance and gamepad ergonomics should continue to be checked alongside automated coverage.
