# Catapult Chaos presentation

Status: **implemented, awaiting rendered review**.

Owned files: `ui/game_presentations/catapult_chaos.gd` and this report.

Inspected `games/classics_a/catapult_chaos.gd` in full (configure, drag/release, physics and paint), `ui/game_presentation.gd`, the queue row and `docs/UI_ACCEPTANCE_STANDARD.md`. Viewed `build/visual-before/catalog-qa/catapult_chaos_board.png` with `view_image`. Baseline has a cream board, generic faint skyline, red launcher, two gold block towers and green reactor targets; text occupies y14–64 and y430–448.

The anchor is (170,315); dragging is bounded to 100 pixels from it, while the initial press radius is 110. Towers initialize at x650 and x800, block centers y355/319/283, targets y235. Balls and debris can cross the board. The actual floor is y380 in simulation and painted at y382. Kept the ballistic field pale and quiet; did not add usable surfaces, target-like cues or instructions.

Original setting: a decommissioned reactor proving yard. A faint overhead service gantry with an unloaded lifting hook and pale wall conduits supply distant depth. Below the actual floor, a parked cable winch, rack of spare launch beams, transport chest and folded lifting sling establish the launcher maintenance setting. These props occupy the y398–427 service apron; the central instruction strip remains clear. Existing INK actor outlines remain foreground-owned.

All art uses deterministic draw calls with typed locals. The scene is static, including when reduced motion is enabled; it uses no elapsed-time effects, RNG, transforms, resource imports or context/gameplay mutation.

Integration caveats: this game's `paint()` does not contain an opaque full-board fill, but parent must verify the shared bridge/base draw order and replacement of its old generic skyline. Decorative gantry and conduits are deliberately low contrast because projectile trajectories can overlap them. No engine/import, gameplay test, action capture, mobile inspection or visual acceptance was performed by this worker. Parent/QA must render and review this ID before marking it accepted.
