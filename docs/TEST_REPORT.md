# Iron Mario: adventure and arcade verification

## Latest workspace check — 19 October 2026

The root workspace now contains the adventure-first source, matching the active
`classic-seven-games` checkout. Static validation passes for the seven quick games,
all twenty catalogued cabinets, adventure dependencies, input registration and
resource paths. All five warehouse layouts pass the independent solver, and the
browser test script passes Node's syntax check.

Official Godot 4.4.1 was subsequently downloaded and the complete source check
passed: **335 assertions** (82 gameplay, 51 profile/touch, 202 adventure/arcade)
and **51 engine checks**, including all 46 scenes and F5 startup. Windows, Linux
and Web exports complete without engine diagnostics. The exported Linux package
passes all 47 launch checks (F5 plus 46 scenes). Windows/browser checks and publication also pass, as recorded below. Physical
phone and audible playback testing remain outstanding.

## Latest control fixes

Adventure held-action polling now uses the same InputMap mapping as key events: holding Blast no longer keeps Jump held. Byte Munch and Dot Gobbler use finger displacement from the gesture origin, with a dead zone and release/focus cleanup. Soft Landing places its fuel gauge above the flight area. Nineteen regression assertions cover these changes. The updated source suite passes 202 assertions locally and in CI. The complete source check passes 335 assertions and all 46 scenes; Windows and Linux package checks and the expanded browser test also pass.

## Current published build

[GitHub Actions run 39217221876](https://github.com/Hustlenix/Iron-Mario/actions/runs/39217221876) passes Vault, build, Windows, browser and deployment for runtime commit `00c0a60`.

- Source: 335 assertions and 51 engine checks, including F5 and all 46 scenes.
- Exported Windows and Linux: F5 plus all 46 scene launches.
- Browser: twenty cabinets, adventure, original quick-game navigation, Flappy, two-finger input, board taps, snake/maze swipes, the lander HUD, pause and orientation.
- The screenshot artifact contains 51 PNG captures. The new phone snake, maze and lander images were visually inspected; the fuel gauge no longer covers the ship.
- Renamed Linux download: starts with the adjacent `Iron-Mario.pck`. Delivered executables and game data are unchanged CI artifact bytes, with Linux execute permissions restored in the ZIP.

The live root HTML, JavaScript, PCK, retirement worker and Vault HTML match the tested Web artifact byte for byte; its WebAssembly URL returns HTTP 200. The current Web runtime prefix is `classic-seven-3623fb5e0321385e`. Physical phone and audible playback checks remain outstanding.

## Previously published build

[GitHub Actions run 39205435457](https://github.com/Hustlenix/Iron-Mario/actions/runs/39205435457) passes all five jobs: Vault, source/export build, Windows, browser, and deployment. Tested runtime commit: `19d6eec`.

- Official Godot 4.4.1: 316 assertions and all 46 source scenes pass.
- Exported Windows and Linux packages: F5 and all 46 scenes pass.
- Chromium: all twenty briefings, PLAY, gameplay input, pause/result routing and library return pass.
- Mobile emulation: simultaneous two-finger adventure input, Grid X taps, pause and orientation pass.
- Preserved Flappy: start, collision, retry and exit pass.
- The 105-game Vault loads and its return link reaches Iron Mario.
- The browser artifact contains 48 actual exported-game screenshots. Home, cabinet, mobile and Vault images were visually inspected.

The live root HTML, JavaScript, PCK, retirement worker and Vault HTML match the tested Web artifact; its WebAssembly URL responds successfully. Verified core runtime prefix: `classic-seven-70527326b452fb0e`.

Physical phone and audible playback tests are still not claimed. The local sandbox's Chromium crashes during startup; the successful browser run above comes from GitHub's Linux runner.

## New coverage

The new source suite passes 202 assertions covering all twenty cabinet scenes, frozen briefings, start inputs, pause, physical collision/scoring boundaries, AI, puzzles, save reloads, legal traversal of the three authored stages, and a boss pilot with three hulls. Regression checks cover touch-only wave/terminal/pad continuation, held-finger driving and release, drag-frequency-independent speed, tennis double-scoring, Grid X selection boundaries, crate undo score restoration, and survival/top-out lives. The independent warehouse solver finds legal solutions for all five rooms. Existing 82 gameplay and 51 hero/touch assertions also pass. The browser suite checks each cabinet's briefing, start, keyboard/pointer input, pause and return to the library, plus the adventure, Flappy, mobile controls and Vault.

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

`tools/check_engine.py` fails on script/resource errors even if Godot exits with code zero. It uses an isolated save directory, imports the editor project, runs the mechanics suite, starts F5's configured title scene, and launches all 46 scene files (including the original bonus and legacy scenes).

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

Automated checks exercise keyboard/mouse events and game state headlessly. They do not replace a human testing a physical keyboard/mouse, hearing audio, or checking a particular Windows GPU/driver. The core assertions use Godot 4.4.1. The optional preserved Vault is exported with Godot 4.7.1 and checked separately in the browser.

Files named `paint_*` are SVG/PNG renders of scene drawing commands. Images in `docs/screenshots/` are captures of the exported game in Chromium. The game visuals are original programmatic artwork with an intentionally handmade MS Paint look.

## Reproduce

    python tools/validate_project.py
    python tools/check_engine.py /absolute/path/to/godot
    python tools/check_engine.py build/windows/Super-Micro-Heroes.exe --exported

For an interactive preview, import project.godot in Godot and press F5.
