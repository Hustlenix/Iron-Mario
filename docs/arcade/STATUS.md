# Implementation status

Updated 2026-10-17. Local development checkpoint; no public release.

| Wave | Games | State |
| --- | --- | --- |
| A | Grid X, Paddle Panic, Byte Munch, Brick Burst, Crate Shift, Stackfall | TESTED |
| B | Sidecourt, Dark Cavern, Rock Drift, Sky Shield, Hopway, Flag Run, Color Steps | TESTED |
| C | Orbit Duel, Armored Arena, Invader Patrol, Soft Landing, Dot Gobbler, Bug Blaster, Rockfall Mines | PLANNED |

TESTED means independent gameplay, automated rule tests and real desktop/touch browser interaction evidence. It does not mean a human enjoyment review, physical phone test or public release approval.

## Current evidence
- 134 Node rule/engine tests pass.
- 23 platform browser checks pass: 320/375/430/768px layouts, real fullscreen, focused Enter/Space, mute, persistence, delayed/failed network recovery, denied/corrupt storage and switch cleanup.
- All thirteen games have actual desktop and emulated-touch input evidence, scoring/progression, pause, restart and exit cleanup.
- Wave A full wins: Grid X three AI rounds (840), Crate Shift five original rooms (3267). Other Wave A games exercised actual scoring and terminal losses.
- Wave B full wins: Dark Cavern hunt/two caches/return (965), Color Steps all three pyramids with active pursuer (3980). Both also exercised real losses. Sidecourt scored a point, Hopway scored and collided with traffic, Flag Run collected a flag/fuel and used smoke, Rock Drift destroyed real rocks, Sky Shield intercepted a real missile on desktop and touch.
- Complete campaign outcomes for the remaining Wave B games are covered by rule fixtures and simulations, not claimed as completed browser campaigns.
- Zero page errors and normal-request failures in the game suites. Deliberate HTTP503 injections belong to separate recovery tests.
- 891 asset checks pass. All 130 preserved legacy game/UI files match their earlier hashes.
- Actual Aseprite batch re-export of shared_pieces.aseprite produced 24 frames with 24 pixel-exact matches to existing sprites. No new Character Generator application export is claimed.

Reports are retained beside this file: wave-a-evidence.json, cavern-color-evidence.json, court-hop-flag-evidence.json, rock-sky-evidence.json, platform-evidence.json, aseprite-roundtrip.json.
Actual screenshots remain under build/arcade. No state injection is used by the browser game suites.

## Changes from play checks
A quick touch tap could end and emit pointerleave before the next simulation tick, discarding its active press. The input layer now preserves it until exactly one update consumes it; a regression test and actual Sky Shield touch interception pass.
Fullscreen now includes toolbar/touch controls and a reachable exit button. Touch labels describe individual game actions; Color Steps shows diagonal arrows and the correct Space recall hint.

## Work boundary and resume
The user requested simple, steady progress. This checkpoint consolidates thirteen games before the final seven. Existing delegated workers reached a reported account usage limit while finishing Wave B; their files were preserved and the parent completed integration, bug fixes and final QA. No claim of background continuation is made.

Next: implement Wave C using the same independent module contract, existing artwork and per-game rule/browser checks. Do not add planned cabinets to playable listings until those checks pass. Preserve the Godot legacy tree and third-party source packs.

Branch: codex/onlyeducation-history-arcade. Earlier verified commits: c239e31 (six-game foundation), 8a5354a (fullscreen and original Aseprite sources).
No GitHub push, production deployment, content publication or Stardance eligibility claim was made.
