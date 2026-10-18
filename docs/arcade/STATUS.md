# Implementation status

Updated 2026-10-18. **20 playable local cabinets, one planned; public deployment remains the prior 14-game release.**

New tested cabinets: Orbit Duel, Armored Arena, Invader Patrol, Soft Landing, Dot Gobbler and Bug Blaster. Rockfall Mines remains planned. The existing 14 cabinets and the legacy Godot tree are retained.

TESTED means automated rules and real browser input checks passed. It does not mean human enjoyment review, physical phone testing, or public release approval.

179 rule/engine/input/library tests, 100 per-cabinet browser checks, 23 platform checks, 14 navigation checks, 11 design checks, three accessibility checks, and seven focused retention checks passed. Legal-input completion simulations cover all six new cabinets. No completed human review has been recorded.

See [TWENTY_GAME_BETA.md](TWENTY_GAME_BETA.md) for changes, reproducible commands, evidence and limits. [PLAYTESTING.md](PLAYTESTING.md) describes the remaining human release gate. The older Wave A/B and redesign reports remain historical evidence for their respective checkpoints.

All 130 baseline Godot game/UI files retain their hashes. The 95 shared original assets remain intact; 891 asset checks passed. No supplied licensed source-pack directories were repackaged.

Source branch: codex/onlyeducation-history-arcade. Only work in the authorized outer IRON-MARIO checkout.
