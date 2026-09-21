# Iron-Mario verification

## Windows failure and repair

The previously distributed executable was rebuilt by directly patching its PE resource-pack section. Its enlarged section overlapped the next virtual section, and its raw size violated file alignment. Windows could reject that image before Godot started.

Production builds now come from the official Godot 4.4.1 export templates. The Windows executable is byte-identical to the official release template; game data lives in the adjacent Iron-Mario.pck. The unsafe binary-patching scripts are not part of this repository. Always extract the complete ZIP.

## Automated coverage

`tools/check_engine.py` fails on script/resource errors even if Godot exits with code zero. It uses an isolated save directory, imports the editor project, runs the mechanics suite, starts F5's configured title scene, and launches all 22 scene files (including the original bonus and legacy scenes).

The runtime suite checks:
- All seven success paths, keyboard movement and jump requests, mouse target clicks and chip drops.
- Laser collision, parry penalties, rescue misses, wrong sequences, and timeouts.
- Lives, score, streak, loop difficulty, failed-round retry, restart, seven-clear Winner, power-down ending, and title routing.
- Correct script wiring for the painted title and both endings.
- Saved mute/volume/bonus records and migration from the original JSON save.
- Bonus Flappy mouse/keyboard input, consecutive best-score updates, 100 bounded pipe gaps, restart cleanup, and floor/shield behavior.
- Callsign/reactor persistence, profile UI save, lifetime records, and scene readiness during briefing.

The original five-life design is preserved. Original four-game scenes remain available for compatibility; the title PLAY button launches the new seven-game manager.

## Build validation

The workflow in `.github/workflows/deploy.yml` pins Godot 4.4.1. It tests source and exports Windows, Linux, and single-threaded Web on Linux, then tests both source and the downloaded Windows package on a Windows runner. GitHub Pages publishes only after both jobs pass.

Results of each commit are recorded in [GitHub Actions](https://github.com/Hustlenix/Iron-Mario/actions). A successful build and Windows job are required before describing a release as Windows-tested.

## Scope of verification

Automated checks exercise keyboard/mouse events and game state headlessly. They do not replace a human testing a physical keyboard/mouse, hearing audio, or checking a particular Windows GPU/driver. Godot 4.7.1 itself has not been tested; 4.4.1 is the actual compatibility baseline.

Documentation previews are SVG/PNG renders of scene drawing commands, explicitly not live GPU screenshots. The game visuals are original programmatic artwork with an intentionally handmade MS Paint look.

## Reproduce

    python tools/validate_project.py
    python tools/check_engine.py /absolute/path/to/godot
    python tools/check_engine.py build/windows/Iron-Mario.exe --exported

For an interactive preview, import project.godot in Godot and press F5.
