# chess_fork presentation worker

Status: **implemented, awaiting rendered review**.

Owned files: `ui/game_presentations/chess_fork.gd` and this report only.

Inspected the assigned queue row, `microgames/pack_c.gd` setup (117–121), grid/cell mapping (157–176), knight action (323–337), paint and grid branches (704–718, 808–837, 877), the presentation bridge, base draw order, and `docs/UI_ACCEPTANCE_STANDARD.md`. Viewed `build/visual-before/catalog-qa/chess_fork_board.png` with `view_image`.

The baseline has a cream field, faint unrelated skyline, alternating light teal/gold squares, red K/R targets, blue N, dark outlines, top instruction, and bottom Moves/UNDO/RESET. The 5×5 input rectangle is x325–635, y65–375 with 62-pixel cells; painted cells are 56 pixels wide. The instruction baseline is y50; message y397, Moves y451, UNDO x570–745/y416–471, and RESET x765–940/y416–471 are kept quiet.

The original setting is a chess-study desk with a shallow wooden board tray, twin-faced mechanical chess clock to the left, three closed strategy volumes and cloth bookmark, an empty fitted piece-storage case to the right, and a blank ruled scoresheet with pencil. Pale desktop edges and subtle prop shadows provide depth. No extra chess actors, threat paths, move hints, targets, or decorative labels are introduced. The active squares and their dark outlines remain owned by gameplay.

The 99-line presenter uses explicitly typed local values and static deterministic draw calls. It does not read elapsed time or reduced-motion state because the scenery does not animate; both motion settings receive identical scenery. No context/gameplay/RNG/transform mutations, engine runs, imported assets, or shared-file changes were made.

Integration caveats: inspected `microgames/microgame_base.gd` currently draws the presenter before `paint()` and suppresses its prior skyline when a presenter exists. `pack_c.gd` does not paint an opaque full-board background, so no known occlusion blocker exists. The original cells, input feedback, undo/reset, timing, lifecycle, responsive behavior, and actual render remain unverified by this worker. Parent/QA must run consolidated parsing, resting/action captures, and visual acceptance. The clock hands are decorative fixed artwork and do not imply a game timer.
