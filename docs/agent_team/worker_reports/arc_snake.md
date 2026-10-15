# Arc Snake presentation worker

Status: **implemented, awaiting rendered review**.

Owned files: `ui/game_presentations/arc_snake.gd` and this report. Inspected `games/cabinets/arc_snake.gd`, `microgames/microgame_base.gd`, the presentation contract, the dedicated-worker brief, and `docs/UI_ACCEPTANCE_STANDARD.md`. Viewed `build/visual-before/catalog-qa/arc_snake_board.png` with `view_image`.

The baseline has a pale green 24-by-9 grid, dark wall border, red head and gold tail blocks, one blue core, dark text on cream, and three large blue bottom controls. A faint unrelated skyline fills the perimeter. The grid occupies `Rect2(96, 93, 768, 288)` with a 5-pixel expanded border. Header text reaches y43; instructions use x96 onward at y84. Left, boost, and right buttons occupy `Rect2(30,387,210,90)`, `Rect2(375,387,210,90)`, and `Rect2(720,387,210,90)`.

Implemented an original reactor inspection tray on a coolant service bench. A quiet rear wall, bench surface, and recessed tray bevel establish depth. Meaningful perimeter props are a banded coolant expansion vessel with return elbow, folded hose rack, finned return heat exchanger, louvered service hatch, and ventilation in the two gaps between controls. Muted sage metal and desaturated copper reinforce collecting reactor cores without adding bright target-like indicators. Detailed hardware stays within x0-84 or x876-960; ventilation stays in x263-352 and x608-697 beneath y405. Existing grid, foreground actors, outlines, labels, and controls remain authoritative.

All scenery is deterministic and static, so pause and reduced motion retain the same appearance. No RNG, transforms, resources, context mutation, gameplay, timing, input, shared-file edits, Git, or engine processes were used.

Integration caveat: `paint()` draws an opaque pale-green rectangle over the grid and a dark expanded border. This intentionally hides backdrop content within the playable cells; setting comes from visible perimeter hardware. It does not draw an opaque full-board rectangle. The base already invokes the presenter before foreground paint. Parent/QA must still run consolidated parsing/import, render before/after and action captures at matching seed/state, inspect overlap/readability and mobile landscape, and validate gameplay/lifecycle. No rendered acceptance or gameplay verification is claimed by this worker.
