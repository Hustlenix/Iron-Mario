# Boulder Push presentation worker

Status: **implemented, awaiting rendered review**.

Inspected `microgames/pack_b.gd` setup (97–100), tick (233–235), input (352–358), helpers (402–405), and paint (407–411, 517–523), plus `ui/game_presentation.gd`, the acceptance standard and the assigned queue row. Viewed `build/visual-before/catalog-qa/boulder_push_board.png` directly. The baseline has a cream field, a blue disc and hero, one dark ground stroke, the green PARK goal and faint bottom dashes; it does not establish a distinct location.

The boulder begins at (180, 300), radius 53. Rightward swipes advance its x position by 130, with rollback after progress and success at x >= 755. The hero follows 75 units to its left. PARK occupies x690–850/y265–335; the existing ground stroke occupies x80–890 at y358. The background therefore keeps the intended rolling corridor and instruction area quiet. No geometry, target, input, timing, state or scoring was changed.

The original environment is a park stoneworks delivery yard: distant stepped quarry cuts, stacked sawn blocks with top/side facets, a parked gantry with an empty hook and straps, a pale paved apron, chisel/mallet tray and folded sack with rolled lifting straps. Meaningful props sit above y233 or below y401; the foreground apron begins at y389. Central paving seams are thin and subdued. The active field remains light for the existing dark INK actors and instruction text.

The scene is entirely static and deterministic, so reduced motion has the identical stable setting. It imports no resources and performs no RNG calls, canvas transforms or context/gameplay mutation.

Integration caveat: the shared pack currently gates its full-board PAPER fill and bottom dashes behind `presentation == null`, so they should not obscure this background. Parent must confirm the existing foreground, hook/props contrast, action feedback and desktop/mobile captures after consolidated import. No engine, Git or rendered acceptance was run or claimed by this worker.

Owned outputs: `ui/game_presentations/boulder_push.gd` and this report only.
