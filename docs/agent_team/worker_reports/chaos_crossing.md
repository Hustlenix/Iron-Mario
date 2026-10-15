# Chaos Crossing presentation

Status: **implemented, awaiting rendered review**.

- Inspected `games/classics_a/chaos_crossing.gd` setup, lane-center calculation, movement, collision and paint; also read `ui/game_presentation.gd` and `docs/UI_ACCEPTANCE_STANDARD.md`.
- Viewed assigned baseline `build/visual-before/catalog-qa/chaos_crossing_board.png` with `view_image`. It shows opaque green/gray/blue strips, red cars, brown logs and a small hero over cream, with a faint generic skyline under the controls. Foreground outlines and instruction text already have strong dark contrast.
- Functional lane rectangles occupy x35–925, y96–365. The hero uses x70–890 and y350–107 across rows 0–9; moving cars/logs can extend through the side margins. HUD occupies y0–66; controls begin around y380. Scenery is concentrated in y72–93 and y367–377, avoiding false obstacles beside moving hazards.
- Added an original canal-maintenance yard: distant pump house with vents, covered timber stacks, hose-drying rack, reeds, low quay masonry and a handrail. Lower stone paving and drainage grates tie the starting bank to the water-crossing action. Muted pale materials keep dark gameplay outlines prominent.
- Entire scene is static and deterministic, so reduced motion retains exactly the same presentation. No RNG, imports, transforms, resource loading or gameplay/context mutation.
- Integration caveat: `paint()` draws ten opaque full-width lane rectangles over the presenter's active field. Its HUD and controls also cover part of the background. The scene deliberately uses narrow exposed banks; root/QA must confirm their visibility and that pump-house details are legible at mobile landscape sizes. Shared paint was not edited.
- No engine import, rendered after-capture, gameplay test, mobile review or visual acceptance was performed by this worker. Parent owns consolidated integration and checks.

Owned deliverables: `ui/game_presentations/chaos_crossing.gd` and this report only.
