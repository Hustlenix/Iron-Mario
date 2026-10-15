# balloon_pump

Status: **implemented, awaiting rendered review**.

Inspected the worker queue row, presentation contract, UI acceptance standard, `microgames/pack_a.gd` setup/update/input/paint branches, and the assigned `build/visual-before/catalog-qa/balloon_pump_board.png` with `view_image`.

The baseline has a red balloon centered at (480, 225), a dark goal circle, string ending at y440, top-left objective, and `TAP TAP TAP!` around (370, 425), with a generic faint skyline. Setup sets the goal to 10 + difficulty; radius is 40 + value * 6 and the goal ring is 40 + goal * 6. The live central envelope and text remain on a pale field. No gameplay bounds or tap mapping were changed.

The new setting is a festival inflation stall: a shallow striped awning, recessed side alcoves, narrow curtains, folded uninflated rubber sleeves in a supply tray, a ribbon reel with loose ribbon, and an idle manual pump with its hose coiled at the right edge. These props tie the environment to inflation without adding spare balloon shapes or apparent targets. Side wall shadows and peripheral floor seams provide depth; the x322–638 lower central field stays clear for existing text and string.

All scenery is deterministic and static, so reduced motion has identical behavior. The file contains only drawing calls and local typed values; it does not alter context, gameplay, transforms, resources, or RNG.

Integration caveat: inspected `pack_a.gd` paint does not add an opaque full-board fill after the presentation. Parent must confirm the shared bridge order, goal-ring clearance at supported difficulty, and final label contrast with a full-sized resting/action capture. No engine, Git, import, or gameplay test was run by this worker; visual acceptance remains pending.
