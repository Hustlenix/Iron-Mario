# Iron-Mario visual acceptance

This is the working review gate for the existing 105-game catalog, not a completion report. The four original hero selector is the first established visual reference. New games remain out of scope until the interface milestone is accepted.

## What the inspected baseline shows

`build/visual-before/catalog-qa/contact_sheet_1.png` shows reaction and timing boards sharing a cream field, faint city outline and sparse functional geometry. `contact_sheet_3.png` shows the same backdrop behind puzzles with very different rules. Functional targets are visible, but the settings and compositions are often indistinguishable. Changing only colors, borders or a common background does not satisfy the requested redesign.

`build/visual-after/hero_prism_1280x900.png` and `heroes_top_390x844.png` demonstrate the new selector reference: dark arcade framing, cream text, restrained accent colors, distinct original silhouettes and purposeful power previews. Match its clarity and hierarchy; do not place its detailed character illustrations behind puzzle targets.

## Acceptance of one game

Each catalog ID needs a separate review row. Mark it accepted only when all applicable checks below have direct evidence.

| Check | Required observable result |
|---|---|
| Identity | A setting and composition tied to this game's action; the card depicts its actual board or actors. A renamed/tinted duplicate scene is insufficient. |
| Hierarchy | The main playable objects are immediately easier to identify than scenery. Instructions remain legible before and during the round. |
| Geometry | Existing 960×480 board coordinates, actor bounds, target positions and input mapping remain aligned. Art preserves actor proportions and does not disguise hazards or usable space. |
| State | Score, time, moves, health, rounds and other values come from implemented state. Show only metrics the game actually owns. |
| Feedback | At least one meaningful interaction has visible state feedback, such as selection, impact, progress or a changed piece. Inspect both the resting and action state. |
| Flow | Launch, pause, resume, result, retry and exit work without duplicate reward delivery, stale input or advancing a paused timer. |
| Responsive | Inspect desktop and mobile landscape gameplay; portrait menus remain usable at 375, 390 and 430 CSS pixels. No stretched arena, clipped labels or hidden controls. |
| Accessibility | Visible focus and selected/disabled states; target identity is not conveyed solely by color. Required mobile actions have reachable controls. Reduced motion retains state feedback without decorative travel, shake or cycling scenery. |
| Assets | Every included external asset has verified usage permission and required attribution. Unverified packs and private Marvel/DC concepts stay outside the public build. |
| Evidence | Before/after board captures, at least one action-state capture, actual gameplay validation and an honest reviewer outcome are recorded for this ID. |

Use `queued`, `implemented`, `captured`, `reviewed`, `accepted`, or `blocked` distinctly. A generated source file means implemented at most; a screenshot means captured at most. A shared test pass does not by itself establish aesthetic acceptance or physical-device testing.

## Practical art direction for workers

- Keep the arcade frame consistent with the selector: near-black blue panels, cream typography, gold primary actions and restrained per-game accents. Make the board world appropriate to its genre.
- Preserve the established dark `INK` text and actor outlines on a light central field unless all foreground paint in that game is deliberately updated and inspected. Pale edge scenery may add depth; busy texture or dark panels under existing labels are regressions.
- Use one deliberate environment motif, a readable foreground/play field and a quieter depth layer. Put meaningful props where they support the setting. Avoid decorative labels, random sparkles and identical skyline outlines repeated across the catalog.
- Inspect the game's `paint()` and setup/target range before positioning scenery. There is no universally safe empty center or edge: `target_lock`, for example, moves targets through x100–860 and y130–360. Do not draw a decorative object that can be mistaken for a target.
- Keep hand-drawn outlines approximately 3–4 logical board pixels for active objects; quieter scenery can be thinner or lower contrast. Use consistent pixel resolution and nearest-neighbor scaling for actual pixel assets. Preserve texture aspect ratio.
- Microinteractions acknowledge input immediately. Use approximately 80–120 ms press feedback, 120–180 ms hover/focus response, and 180–260 ms transitions; never delay control activation to finish an animation. Honor reduced motion.
- Match mobile controls to existing actions and avoid covering the board. Menu/button touch targets should be at least 44×44 CSS pixels. If an existing game has smaller cell hit areas, record it and solve input accessibility separately rather than silently shifting geometry in a background-only patch.

## Genre-specific scene and HUD requirements

| Existing genre | Scene treatment | Necessary readability / HUD check |
|---|---|---|
| Reaction / timing / rhythm | Purpose-built instrument, signal station or tactile mechanism. Its framing reinforces the tested action. | Timer dominates when timing matters. Valid zone, current phase and count remain unmistakable; decorative lights cannot resemble cues. |
| Puzzle / memory / logic | Tactile board, recessed tray, workshop table or diagram with intentionally quiet space. | Cells, symbols, selected source, progress and existing undo/reset controls stay clear. Do not invent hints, move counts or new rules. |
| Runner / platformer / traversal | Layered terrain/horizon, grounded platforms and a coherent travel direction. | Character, landing edges and threats separate from scenery. Existing distance, score or survival time is accurate. Do not add apparent solid platforms. |
| Fighting / survival / shooter | Arena depth and contextual props outside the active conflict area. | Player/enemy silhouettes, attack tells, damage and real health/round values remain clear. Cosmetic particles cannot mask incoming attacks. |
| Racing / physics / transport | Readable roadway, track or machine interior with consistent perspective. | Collision boundaries, destination and vehicle orientation match existing physics. Background markings cannot imply false lanes or collision surfaces. |
| Absurd / brainrot | A specific original comic situation with exaggerated props and expressive feedback. | The joke strengthens the actual action; challenge cues, result reason and restart remain clear. |

## Implementation boundary

`ui/game_presentation.gd` loads one `RefCounted` presenter at `ui/game_presentations/<catalog_id>.gd`. Its `draw_background(canvas, context)` receives the existing board rectangle and gameplay elapsed time. Presenters must not mutate gameplay, RNG state, transforms, input regions or context. Decorative movement must respect `context.reduced_motion`; elapsed-based effects pause with gameplay. A presenter is a safe starting integration, not proof that foreground actors and feedback have been redesigned.

The original four public characters use original identities and visuals. Current selection is cosmetic; power demonstrations are previews and Play opens a matching existing game. Do not claim skeletal animation, a complete combat animation set, or a roster-wide ability system from illustration posing, shader motion and effects. Private reference concepts are a separate deliverable and cannot enter the public bundle.

## Batch gate and honest reporting

Compare actual before/after captures at the same seed, difficulty, board dimensions and elapsed state. Inspect a full-sized image when contact sheets conceal small text or target overlap. Validate the affected gameplay and shared lifecycle after integration. Inspect all 105 rows before claiming catalog-wide review; count only accepted rows as accepted.

Native engine rendering, synthesized input, local browser verification, deployed browser verification and physical touch/controller testing are separate evidence categories. Do not infer one from another. If publication cannot be verified, label the change locally verified. Keep all private concepts and unused asset packs excluded from export.
