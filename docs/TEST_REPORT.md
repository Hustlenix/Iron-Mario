# Super-Micro Heroes verification

## Flappy repair

Five additional runtime assertions cover the camera transform, on-screen Menu
position, direct touch flapping, duplicate/release input rejection, and immediate
retry position/scale reset. The browser script also exercises desktop start,
floor collision, retry and Menu, then repeats the touch flow on a mobile viewport.
Browser screenshot coverage is distinct from the headless assertions below.

## 2.0.0 coverage

Local Godot 4.4.1 validation passed 46 existing gameplay assertions, 44 new
hero/touch assertions, and 26 engine checks (import, both suites, F5, 22 scenes).
Headless music playback is disabled because there is no audio device; all nine
music resources are loaded and their durations checked.

New coverage includes all nine saved hero IDs, shared character instances,
unknown/legacy ID fallback, the unchanged save directory, simultaneous movement
and jump, independent finger release, focus/scene cleanup, duplicate emulated
mouse rejection, drag ownership, parry taps, memory tiles, rescue steering, and
focus pause/resume.

The Web shell supports landscape phones, safe-area margins, download progress,
optional fullscreen, and a portrait prompt. `tools/browser_smoke.cjs` exercises
the exported Web game in Chromium with desktop and mobile touch contexts,
capturing screenshots for visual review. The local execution environment blocks
browser sockets, so that check runs in GitHub Actions. Physical Android/iPhone
testing and listening to the soundtrack on a device remain separate checks.

## Windows failure and repair

The previously distributed executable was rebuilt by directly patching its PE resource-pack section. Its enlarged section overlapped the next virtual section, and its raw size violated file alignment. Windows could reject that image before Godot started.

Production builds now come from the official Godot 4.4.1 export templates. The Windows executable is byte-identical to the official release template; game data lives in the adjacent Super-Micro-Heroes.pck. The unsafe binary-patching scripts are not part of this repository. Always extract the complete ZIP.

## Automated coverage

`tools/check_engine.py` fails on script/resource errors even if Godot exits with code zero. It uses an isolated save directory, imports the editor project, runs the mechanics suite, starts F5's configured title scene, and launches all 22 scene files (including the original bonus and legacy scenes).

The runtime suite checks:
- All seven success paths, keyboard movement and jump requests, mouse target clicks and chip drops.
- Laser collision, parry penalties, rescue misses, wrong sequences, and timeouts.
- Lives, score, streak, loop difficulty, failed-round retry, restart, seven-clear Winner, power-down ending, and title routing.
- Correct script wiring for the painted title and both endings.
- Saved mute/volume/bonus records and migration from the original JSON save.
- Bonus Flappy mouse/keyboard input, consecutive best-score updates, 100 bounded pipe gaps, restart cleanup, and floor/shield behavior.
- Callsign and legacy reactor persistence, hero selection, lifetime records, and scene readiness during briefing.

The original five-life design is preserved. Original four-game scenes remain available for compatibility; the title PLAY button launches the new seven-game manager.

## Build validation

The workflow in `.github/workflows/deploy.yml` pins Godot 4.4.1. It tests source and exports Windows, Linux, and single-threaded Web on Linux, then tests source and the exported Windows package on a Windows runner. A separate browser job checks desktop and touch UI. GitHub Pages waits for all three jobs.

Results of each commit are recorded in [GitHub Actions](https://github.com/Hustlenix/Iron-Mario/actions). A successful build and Windows job are required before describing a release as Windows-tested.

## Scope of verification

Automated checks exercise keyboard/mouse events and game state headlessly. They do not replace a human testing a physical keyboard/mouse, hearing audio, or checking a particular Windows GPU/driver. Godot 4.7.1 itself has not been tested; 4.4.1 is the actual compatibility baseline.

Documentation previews are SVG/PNG renders of scene drawing commands, explicitly not live GPU screenshots. The game visuals are original programmatic artwork with an intentionally handmade MS Paint look.

## Reproduce

    python tools/validate_project.py
    python tools/check_engine.py /absolute/path/to/godot
    python tools/check_engine.py build/windows/Super-Micro-Heroes.exe --exported

For an interactive preview, import project.godot in Godot and press F5.
