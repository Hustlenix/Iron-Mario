# Arc Dash presentation worker

Status: implemented; awaiting parent render review. Not visually accepted.

## Inspected evidence

- Read `ui/game_presentation.gd`, `docs/UI_ACCEPTANCE_STANDARD.md`, Arc Dash setup/tick/action/paint in `microgames/pack_b.gd`, and hero/draw ordering in `microgames/microgame_base.gd`.
- Called `view_image` on `build/visual-before/catalog-qa/arc_dash_board.png`. Baseline is a largely empty cream board with blue rails, red rectangular hazards, a gold-headed hero, and the upper-left switch instruction. Sparse lower-edge marks do not establish a distinct setting.
- Board is 960 × 480. Functional rails extend x50–910 at y215 and y345. Hero stays at x180 and toggles center y170/y300; its drawing reaches x137–203 and y127–353. Hazards begin x500/760/1020/1280, center y300/170 alternately, move left at 215 × level_speed, and draw 56 × 80 rectangles. Collision compares x distance <35 and y distance <65. Instruction baseline is (45,70).

## Original design

Suspended rail depot over a recessed cable workshop. A cropped roof duct with suspension brackets establishes the upper interior. An edge wall pier, diagonally recessed underside, folded copper busbars held by broad insulating clamps, and an oblique louvered transformer cabinet establish distinct depth and meaningful rail-support machinery. The entire moving-hazard region stays light and quiet; no scenery supplies another rail, usable platform, target, actor, or cue. Lower props begin below y393 and the fixed hero's lowest pixel. All art is deterministic native drawing authored for this game; no external assets or RNG.

## Boundaries and caveats

- Owned files only: `ui/game_presentations/arc_dash.gd` and this report. No gameplay, inputs, hit areas, shared files, or Git changes.
- Draw-only `RefCounted` with typed metadata and variables. Reads `board_rect`; no canvas transform/state or context mutation. Entire environment is static, so reduced motion has no decorative travel and pause cannot advance scenery.
- At initial inspection `pack_b.paint()` painted opaque PAPER across the full board after the presenter, which would hide the whole environment. Parent reports this resolved in shared integration: legacy board fill/strokes now run only when `presentation == null`. This worker did not alter that shared code; actual visibility remains subject to parent render review.
- Existing gameplay feedback and instruction geometry remain the parent’s gameplay/lifecycle review responsibility. Native render, action-state comparison, mobile layout, and input testing have not been run by this worker; the parent owns consolidated testing.
- No visual acceptance claim is made from source implementation. Parent must inspect rendered desktop/mobile boards and the action state before advancing status.
