# Iron Mario: adventure and arcade verification

## Latest workspace check — 19 October 2026

The root workspace now contains the adventure-first source, matching the active
`classic-seven-games` checkout. Static validation passes for the seven quick games,
all twenty catalogued cabinets, adventure dependencies, input registration and
resource paths. All five warehouse layouts pass the independent solver, and the
browser test script passes Node's syntax check.

Official Godot 4.4.1 was subsequently downloaded and the complete source check
passed: **316 assertions** (82 gameplay, 51 profile/touch, 183 adventure/arcade)
and **51 engine checks**, including all 46 scenes and F5 startup. Windows, Linux
and Web exports complete without engine diagnostics. The exported Linux package
passes all 47 launch checks (F5 plus 46 scenes). Browser/Windows checks and
publishing are recorded separately below when completed. Physical
phone and audible playback testing remain outstanding.

## New coverage

The new source suite passes 183 assertions covering all twenty cabinet scenes, frozen briefings, start inputs, pause, physical collision/scoring boundaries, AI, puzzles, save reloads, legal traversal of the three authored stages, and a boss pilot with three hulls. Regression checks cover touch-only wave/terminal/pad continuation, held-finger driving and release, drag-frequency-independent speed, tennis double-scoring, Grid X selection boundaries, crate undo score restoration, and survival/top-out lives. The independent warehouse solver finds legal solutions for all five rooms. Existing 82 gameplay and 51 hero/touch assertions also pass. The browser suite checks each cabinet's briefing, start, keyboard/pointer input, pause and return to the library, plus the adventure, Flappy, mobile controls and Vault.

# Super-Micro Heroes verification

## Home and two-thumb controls

New runtime checks open each of seven Home selections, finish single rounds with wins and losses, replay the same game, return Home, and verify that single play preserves Tournament records. Touch checks cover direction changes, the neutral zone, captured thumb drags, and tap-chip/tap-socket repair. The browser flow covers simultaneous two-finger move/jump, single-game results, replay/Home, and Tournament entry.

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

`tools/check_engine.py` fails on script/resource errors even if Godot exits with code zero. It uses an isolated save directory, imports the editor project, runs the mechanics suite, starts F5's configured title scene, and launches all 23 scene files (including the original bonus and legacy scenes).

The runtime suite checks:
- All seven success paths, keyboard movement and jump requests, mouse target clicks and chip drops.
- Laser collision, parry penalties, rescue misses, wrong sequences, and timeouts.
- Lives, score, streak, loop difficulty, failed-round retry, restart, seven-clear Winner, power-down ending, and title routing.
- Correct script wiring for the painted title and both endings.
- Saved mute/volume/bonus records and migration from the original JSON save.
- Bonus Flappy mouse/keyboard input, consecutive best-score updates, 100 bounded pipe gaps, restart cleanup, and floor/shield behavior.
- Callsign and legacy reactor persistence, hero selection, lifetime records, and scene readiness during briefing.

The original five-life design is preserved. Original four-game scenes remain available for compatibility; Home offers standalone games and a separate Tournament using the same manager.

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
