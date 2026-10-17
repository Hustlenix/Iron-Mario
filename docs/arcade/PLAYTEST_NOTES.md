# Interaction review — 2026-10-17

Scope: local Wave A Canvas build, Chromium desktop and emulated touch. Goal: understand controls in seconds, acknowledge actions, recover quickly, keep a small retro arcade footprint. Evidence: actual UI test input, read-only game state, screenshots, source inspection. No claim of human enjoyment, physical-device testing or listening QA.

## Actions and consequences
- Grid X: selecting a free square places a mark; a visible AI delay precedes its legal reply. Draws advance expert rounds, so perfect defence does not block progression.
- Paddle Panic: moving the paddle changes return angle; crossing the side boundary awards a point; first to five resolves the match.
- Byte Munch: a queued turn changes the next grid step; food grows the trail; walls/body end the run.
- Brick Burst: launch releases the ball; paddle contact changes angle; destroyed bricks award points; misses consume lives.
- Crate Shift: an adjacent move may push one crate; a blocked push leaves the board unchanged; undo reverses both board and completion score.
- Stackfall: rotation checks occupied cells and kicks; hard drop commits the ghost landing; complete rows score; a blocked spawn ends the run.

## Observations and changes
1. Observed: the canvas tag matched an unanchored key filter, so keyboard commands did nothing. Fixed exact interactive-tag matching and verified held canvas keys.
2. Observed: Space on a focused toolbar button was swallowed on key release. Key release now clears held sources while preserving native button activation. Real Enter/Space tests pass.
3. Observed: a failed dynamic import stayed cached after a same-URL retry. Recovery reloads the document while retaining the cabinet route. Injected HTTP failure followed by recovery passes.
4. Observed: fullscreen displayed only the canvas, hiding touch input and exit. Fullscreen now contains the toolbar, touch controls and game surface; the real fullscreen button can exit.
5. Measured: ready/paused screens stop RAF scheduling; returning home leaves zero game listeners, RAF callbacks, HUD timers and voices.

## Pacing and unknowns
Ready -> active play -> earned outcome -> immediate restart is present in every game. Pause preserves simulation without replaying held keys. Node solver evidence proves five warehouses can be solved; browser evidence completed them. Automated scripts deliberately missed in several action games to exercise failure, so those outcomes do not establish that difficulty is fair or unfair for new human players. Next review should observe first-time players predicting controls, then measure comprehension and retry willingness.

Severity after fixes: no known blocking Wave A interaction regression. Open review: physical phone controls, human difficulty and enjoyment, speaker/headphone mix, and accessibility beyond keyboard focus and reduced-motion presentation.
