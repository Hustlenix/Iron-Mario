# OnlyEducation — Play the Past. Build the Future.

A Hustlenix browser arcade with original implementations of historical game ideas. This is the new lightweight Canvas platform; the existing 105-game Godot arcade remains separate and intact.

## Run locally
From C:\Users\LalithReddy.b\Iron-Mario\IRON-MARIO:
```powershell
rtk proxy python tools/package_arcade.py
rtk proxy python -m http.server 8785 --bind 127.0.0.1 --directory build/web
```
Open http://127.0.0.1:8785/arcade/ . Existing art review is /history-assets/ and the legacy arcade is /portal/.
No install, bundler, account, external CDN, or production server is needed.

## First checkpoint
Six independent games have been implemented: Grid X, Paddle Panic, Byte Munch, Brick Burst, Crate Shift, Stackfall. The other fourteen remain planned until their own rules and QA pass. See STATUS.md for the current verification boundary.

Controls appear beside each game. Every game supports keyboard and on-screen touch controls. Grid X and Crate Shift also support direct board taps; Paddle Panic supports pointer aiming and Brick Burst supports dragging. Pause with P/Escape, restart with R, or use the visible buttons. Scores, best reached levels, plays and achievements stay in local browser storage. There are no accounts or cloud saves. Sessions restart fresh; interrupted boards are not resumed.

## Development
- Source: onlyeducation/arcade/
- Shared art: assets/shared_foundation/history_arcade/
- Editable artwork: source_art/history_arcade/
- Engine and game tests: tests/arcade/
- Browser verification and screenshots: build/arcade/
- Packaging: tools/package_arcade.py
- Game API: onlyeducation/arcade/CONTRACT.md

The package uses plain ES modules. Each game owns its rules and state, and the host owns input listeners, audio, animation scheduling, navigation and saves. New games are not exposed as playable until tested.

## Authorship and rights
AI assisted architecture, coding, tests and documentation, under human creative direction. This does not establish human development hours or third-party program eligibility. The games are independent interpretations, not original-game emulators. No original commercial game code, audio or level layouts were imported. See ASSETS.md and the game-specific historical references.

This checkpoint is local development. No production deployment or content publication is authorized by this brief.
