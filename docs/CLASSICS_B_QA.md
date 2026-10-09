# Classics B module QA

Executed on 9 October 2026 with Godot 4.7.1 stable. The eight modules are in `games/classics_b/`; metadata is `games/classics_b.json`.

## Executed checks

Command: `Godot_v4.7.1-stable_win64_console.exe --headless --path <arcade checkout> --script res://tests/classics_b_test.gd -- --test`.

Result: **99 checks, 0 failures**. This includes 24 complete wins: every module at difficulties 1 and 6 using keyboard-equivalent routed actions with seed 1204 and a 0.01 second step, and every module at difficulty 3 using touch gesture handlers with seed 902 and a 1/30 second step. Every module also had a complete unattended loss, restart state reset, paused-time check and once-only terminal result check.

These tests call the same module `handle_action` methods used by the input router. They are simulation tests, not claims of physical keyboard, touchscreen or gamepad operation. Parent integration tests and browser checks remain separate release gates.

| Game | Mechanics exercised | Seeded win time, difficulty 1 | Additional rule evidence |
|---|---|---:|---|
| Feed the Reactor | Constrained pendulum, rope-order support puzzle, retained release momentum, reversed destination | 5.02 s | Touch cuts cross real rope segments; failed drops consume attempts |
| Neon Rhythm Escape | Grounding, jump arc, spike collision, floor gaps, fourteen obstacles | 14.21 s | Cue travel matches evenly spaced obstacles; original synthesized click uses Master volume |
| Skyline Jumper | Automatic bounce, lateral acceleration, moving/crumbling platforms, camera-relative fall | 11.47 s | Height score tracks maximum climb; twenty-five bounded platform records |
| Turbo Flapper | Flap impulse, moving gates, wind, energy cells, shield use, twelve scored gates | 23.01 s | Each gate scores once; actual circle/gap collision and world bounds |
| Bridge Builder | Held extension, release/fall, supported walking, six new gaps | 14.05 s | Cancel clears holding without lowering; a too-short bridge produces actual fall loss |
| Reactor Merge | Grid compression, equal-value merges, spawned tiles, 128 target | 2.01 s bot simulation | One merge per tile; undo restores RNG/score/moves; invalid moves do not spawn |
| Rooftop Defense | Placement, generation, spending, turret bolts, enemy damage, twelve-wave kills | 23.71 s | Occupied cells and insufficient energy reject spending; base breach loses |
| Mini Reactor Buddy | Fuel/cleanliness/joy/heat, cooldowns, timed play, three care requests | 12.36 s | Feeding raises heat and reduces cleanliness; cooldown rejects spam |

The short win times are deterministic bot simulation times, not typical human session measurements. Advertised metadata limits are 45–90 seconds. Research session estimates in `PLAY_STORE_RESEARCH.md` describe the reference families and should not be mistaken for measured times in this implementation.

## Visual review

Executed `tests/classics_b_capture.gd` with an actual OpenGL compatibility renderer on the AMD Radeon graphics device. Eight 1280×640 board images were saved to `build/qa/classics_b/` and inspected. The review corrected an overlapping rope instruction, moved its hint below gameplay, enlarged the merge buttons, and enlarged defense/care action cards. Each module displays its input instructions and game-specific status.

Screenshots cover the module boards rather than the full application shell. Shared mobile shell layout, navigation, pause overlay and production rendering are the parent release verification scope. No phone frame-rate claim or memory-profile claim is made here. Original geometric art and synthesized sound require no third-party game asset reuse.

## Integration notes

- Input mode is `ARCADE`. Modules consume `action`, `press`, `release`, `direction`, `move`, `swipe`, `select`, `secondary`, `reset`, `undo`, and `cancel` only where appropriate.
- Number keys select defense/care actions or numbered ropes; touchscreen cards and cuts provide the equivalent choices.
- Bridge `cancel` preserves plank length while clearing a held press. Skyline cancel clears steering. Other instantaneous interactions have no retained held state.
- Register metadata and include `classics_b` in the check runner. The research catalog remains a design/research artifact, not an authoritative playable inventory.
- No changes or commits were made to shared core, application or CI files by this module owner.

