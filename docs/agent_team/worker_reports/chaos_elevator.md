# Chaos Elevator presentation

Status: **implemented, awaiting rendered review**.

- Inspected `games/chaos.gd`: configuration, input, tick and paint branches for `chaos_elevator`; `ui/game_presentation.gd`; the execution brief and UI acceptance standard. Viewed assigned baseline `build/visual-before/catalog-qa/chaos_elevator_board.png` with `view_image`.
- Active geometry: four landing lines span x120–800 at y340, 270, 200 and 130. Floor labels start x120, guest destinations occupy x630–720 above the landings, and the lift car occupies x385–520 with its top moving from y285 to y75. Existing floor buttons occupy the lower board around y380–470. Background geometry does not move or redefine any of these bounds.
- Baseline: the blue repeating garage texture dominates the landing space; black floor labels and gold car are visible, but the room has little relation to passenger delivery.
- Implemented a light parcel-hotel lift atrium: shallow wall recesses, quiet cable shaft, ceiling pulley and vent hatch, parcel pigeonholes, a valet trolley with mismatched luggage, a glazed counterweight well, an oil can and folded service cloths. Props sit predominantly in the side strips x42–92 and x832–917. Existing dark foreground outlines keep priority over muted scenery; no decorative numbers or destination cues were added.
- Static deterministic drawing; no RNG, resource loading, transforms, state mutation or animation. Reduced motion receives the identical scene.
- Integration caveat: `paint()` at `games/chaos.gd:252` draws `reactor_garage.png` over Rect2(30,75,900,320) when present. This covers almost all of the bespoke interior after the background presenter runs. Parent integration must resolve that existing foreground texture; this worker did not modify the shared source. The inspected paint branch does not contain an additional full-board opaque rectangle.
- Verification: inspected typed source and owned-file scope only. No Godot process, render capture, gameplay test or aesthetic acceptance performed by this worker. Parent/QA still need consolidated import and resting/action rendered review, including mobile readability and the texture-layer caveat.

Owned deliverables: `ui/game_presentations/chaos_elevator.gd` and this report.
