# Brick Reactor presentation worker

Status: **implemented, awaiting rendered review**.

Inspected the worker-009 queue entry, presentation contract, UI acceptance standard, complete `games/cabinets/brick_reactor.gd` (setup, collision and paint), and `build/visual-before/catalog-qa/brick_reactor_board.png` using `view_image`.

The authoritative chamber is Rect2(45, 65, 870, 316). Forty-five bricks occupy x72–884/y91–257, paddle starts at x405/y350 with 150×18 size, and the ball traverses the chamber. Controls occupy x30–240, x375–585, x720–930 at y387–477. Title and actual brick count occupy the upper band. These geometries remain untouched.

Baseline showed clear colored brick rows and paddle inside a pale blue rectangle; surrounding cream field had unrelated faint skyline lines. The new original setting is a ceramic pulse chamber with narrow cooling jackets, twin upper coolant feeds, corner fasteners and two recessed heat-exchanger service bays between the existing controls. Casing shadows and recessed grooves establish depth without creating false targets. All decorative structure stays outside the authoritative chamber/control rectangles; existing dark text retains a pale backing.

Presenter is deterministic and static, with explicitly typed declarations and loops. Reduced motion therefore receives the same stationary environment; there are no resource imports, RNG calls, transform changes, elapsed effects, gameplay/context mutations or invented metrics.

Integration caveat: the existing `paint()` draws opaque `box(BOARD, Color("e0eaf5"))`; this hides presenter pixels inside the play chamber. The design intentionally places its distinguishing machinery outside that opaque rectangle. Parent must verify the shared background bridge replaces the old generic skyline and review native captures at rest/action state, control legibility and desktop/mobile fit. No Godot or Git processes were run by this worker. No render acceptance is claimed.

Owned deliverables: `ui/game_presentations/brick_reactor.gd` and this report. Existing lifecycle/gameplay verification belongs to parent/QA.
