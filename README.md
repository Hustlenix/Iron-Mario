# Super-Micro Heroes

A hand-drawn Godot arcade with **50 playable microgames**, ten cosmetic heroes, quick play, a five-heart Tournament, and a deterministic ten-game Daily Challenge.

[Play in the browser](https://hustlenix.github.io/Iron-Mario/)

The 2.0 rebuild replaces the prototype's scenes and menus. It keeps original music and migrates both historical `save.dat` and deployed `iron_mario_save.cfg` records into a versioned profile with backups. Previous prototype code remains recoverable in Git history.

## Play

Tap, hold, swipe, or drag as shown by each game. Keyboard uses arrows/WASD and Space; controllers use the stick/D-pad and A. For a directional swipe, use a direction. For a precise physics swipe, hold Space/A, move the crosshair, then release. Escape/Start pauses. Portrait and focus changes safely pause play.

All games and heroes are immediately available. XP, mastery, medals, missions, favorites, records and cosmetic coins are saved locally. Coins buy cosmetic effects only. Billing, ads and external analytics are disabled adapters, not simulated purchases.

## Develop

Open `project.godot` in **Godot 4.7.1**. The renderer uses OpenGL compatibility and the Web export is single-threaded. The project has no third-party runtime dependencies.

```sh
godot --headless --path . --editor --import --quit
godot --headless --path . --script res://tests/services_test.gd -- --test
godot --headless --path . --script res://tests/pack_a_test.gd -- --test
godot --headless --path . --script res://tests/pack_b_test.gd -- --test
godot --headless --path . --script res://tests/input_test.gd -- --test
godot --headless --path . --script res://tests/app_test.gd -- --test
```

Game tests drive actual input and time to win and fail each entry at different difficulties. Service tests cover migration, corrupt saves, reward idempotence, daily generation and Tournament state. App tests cover navigation, scoring, pause, orientation, aspect preservation and repeated scene cleanup. Tests use disposable profile paths; `--test` keeps the profile autoload away from real saves.

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
