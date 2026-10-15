# Bridge Builder presentation

Status: **implemented, awaiting rendered review**.

Owned source: `ui/game_presentations/bridge_builder.gd`.

Inspected `games/classics_b/bridge_builder.gd`, the worker-010 queue row, `ui/game_presentation.gd`, `docs/UI_ACCEPTANCE_STANDARD.md`, and the assigned baseline image `build/visual-before/catalog-qa/bridge_builder_board.png` with `view_image`.

The starting island is x120–230/y330–440; destination starts 100–220 pixels past its edge and is 65–100 pixels wide. Subsequent islands recenter at x175 with the prior destination width. Planks grow vertically from the island edge up to 620 pixels, rotate to y330, then the builder crosses or falls toward y470. Existing instruction text occupies x24/y35–65 and x560/y180–216. The entire central area stays pale, with no dark props behind labels or the rising plank.

Baseline observations: readable dark text, a blue island and green destination with gold bonus strip, a small builder, and a generic faint city outline. The replacement is an original canal construction yard: pale embankments create depth, quiet water sits below the real piers, a cable hoist and drum occupy the far-right service bank, and strapped timber plus a survey tripod/closed tool case sit on the bottom/right and left margins. These props describe measuring and building a crossing while leaving actual endpoint tops and the gold target strip authoritative.

The scene is static and deterministic, so reduced motion has identical scenery and no decorative travel. No gameplay, input, transforms, RNG, resources, shared code, or context is modified. Paint contains no opaque full-board fill. Foreground boxes cover portions of the water naturally.

Integration caveat: parent must check the rendered resting and extended/walking plank states, including the narrow service props at x866–960 and the survey prop below y359. No Godot import, engine test, Git operation, or rendered acceptance was run by this worker.
