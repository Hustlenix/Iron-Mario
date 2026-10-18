# Dino Dash and terminal retry — 2026-10-17

The 21-entry collection now contains 14 tested games and seven planned entries. Dino Dash is a playful prehistoric bonus set 67 million years ago.

## Runner
The player should feel a steady rhythm of anticipation and recovery by choosing when to jump thorn clusters or duck low flyers. Ground hazards are introduced before flyers. Space, Enter, Up, a canvas tap or JUMP jumps. Hold Down, Z or DUCK to crouch. One collision ends this endless distance run; the host offers immediate replay and saves the best score.

Speed rises from 180 to 300 pixels/second. Jump velocity is -440, gravity 1200, and minimum spawn interval 1.35 seconds. A 0.12-second jump buffer accepts a tap just before landing. Holding Jump does not automatically repeat it. A normal-input bot cleared 30 hazards across each of 24 seeds, verifying a legal route under these rules, without establishing human difficulty.

Moss Rex is original teal/coral/gold pixel art. tools/build_dino_art.py creates integer-grid artwork; tools/export_dino_art.lua creates the five-frame Aseprite timeline. The runtime PNG is exported by Aseprite. Source: source_art/dino_dash/runner.aseprite. Game-local artwork has its own project-original manifest and does not modify the 95-asset shared kit.

## Grid X
RETRY TERMINAL resets the lost board, turn and AI delay while retaining round, score, wins and draws. It counts as the same session and grants no points. Restart resets the full run. Expert instructions explain that a draw clears the terminal.

The optional game retry() method returns true after restoring playing state. Runtime.retry clears held input, silences sound, resets the frame clock and schedules one new loop. Exceptions follow normal cleanup.

## Verification
144 rule/engine tests pass, including runner collisions, jumping, no air jump, buffering, deterministic spawning, fair spacing and retry score preservation.
Real desktop and 375px emulated touch each cleared seven hazards using jump and duck, then checked pause/restart/exit. A real Grid X round-three loss retried with two earlier clears and 360 points retained. Full Restart reset round/score.
Read-only QA snapshots guide real UI events; no game-state injection is used in browser runs.
See dino-retry-evidence.json. Physical-phone and human enjoyment review remain open.
