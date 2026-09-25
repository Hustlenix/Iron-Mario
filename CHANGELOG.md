# Changelog

## 2.1.0 — Pick a game and two-thumb controls

- Added seven standalone game cards, a separate Tournament card, and bonus Flappy on Home.
- Added a single-game result screen with Play Again and Home, keeping Tournament records separate.
- Replaced phone movement buttons with a sliding thumb pad and enlarged jump/parry.
- Added tap-chip, tap-socket repair alongside dragging; retained tap targets, memory tiles, and Flappy.

### Flappy repair

- Centred Flappy's camera on the playfield so the hero, floor, instructions, and Menu button remain visible.
- Added direct touch handling and ignored duplicate emulated mouse clicks.
- Stopped overlapping flap tweens and reset the hero's position and scale immediately on retry.
- Added camera, touch, and retry regression checks plus desktop/mobile Flappy screenshot coverage.

## 2.0.0 — Super-Micro Heroes

- Renamed the game and export packages; retained the repository address and old save folders.
- Replaced reactor-colour selection with nine original heroes, equipment, poses, and world previews.
- Added nine character environments across briefings, gameplay, and endings.
- Composed nine original instrumental music loops with preview crossfades and mission/ending moods.
- Added simultaneous touch movement and jump, parry buttons, tap targets, finger-owned repair dragging, and tappable sequence tiles.
- Added mobile launch/fullscreen UI, download progress, portrait guidance, and focus/orientation pause.
- Added 44 hero/save/touch assertions alongside the 46 existing gameplay checks.
- Added desktop/mobile Chromium export checks and screenshot artifacts to the publication gate.
- Updated art previews, controls, Windows instructions, and README.

## 1.2.0 — Flight, suit, and profile update

- Fixed Flappy gaps extending below the floor, render-frame-dependent simulation, floor/shield behavior, and incomplete restart cleanup.
- Unified mouse and keyboard flight controls; added R retry after a crash.
- Redrew the armored hero with a full faceplate, two eyes, segmented armor, palms, and boot jets.
- Added seven themed mission briefings and a preparation bar backed by actual scene loading.
- Added a saved local callsign, reactor color, records, and mission-based rank.
- Retained existing save migration, five lives, settings, music, endings, and the bonus game.
- Updated README, previews, and regression coverage.

## 1.1.0

- Added the seven-game gauntlet and shared handmade drawing system.
- Repaired Windows packaging using an unmodified official Godot template and adjacent PCK.
- Added Windows/Linux automation and gated browser deployment.
