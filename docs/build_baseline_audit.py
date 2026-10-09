"""Regenerate the truthful baseline inventory from shipped definition files.

This records evidence from tests already executed on 2026-10-09. It does not run
tests or infer a new pass when source changes. Update evidence only after reruns.
"""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DETAILS = {
    "target_lock": ("Reaction aiming", "Moving bullseyes; each accepted center tap spawns the next target; timer failure.", "B", "Add a readable first-target pulse and varied target travel paths; measure human aim difficulty."),
    "reactor_parry": ("Reaction timing", "Three approaching sparks; accept taps in the green ring and reject early/late parries.", "B", "Show the allowed timing band consistently; test reaction windows on lower frame rates."),
    "power_sequence": ("Memory sequence", "Watch a seeded color sequence, wait for repeat phase, then reproduce it without a wrong pad.", "B", "Make observation/repeat phase labels and keyboard pad focus more explicit."),
    "stop_bar": ("Precision timing", "Stop an oscillating needle inside a seeded green interval; off-target tap fails.", "B", "Preview the timing window and vary speed smoothly without changing rules."),
    "odd_one": ("Visual search", "Find the Q among O letters across successive grids; wrong-cell selection fails.", "B", "Review letter-tail readability at small landscape viewports and add accessible symbol alternatives."),
    "rhythm_knock": ("Rhythm timing", "Four authored beats cross the timing line; mistimed or missed beats end the round.", "B", "Measure audiovisual synchronization and test fair windows with actual audio devices."),
    "whack_mole": ("Reaction selection", "Tap the active mole while it changes holes; wrong holes fail and correct bonks count toward the goal.", "B", "Review small-screen hit targets and introduce deterministic fair hole pacing."),
    "coin_catch": ("Catching movement", "Catch three sequential seeded falling coins by steering the basket; a missed coin fails.", "B", "Add route variety while preserving reachable basket movement and test thumb tracking."),
    "shield_turn": ("Directional reaction", "Match a sequence of incoming directions before each defense timer expires.", "B", "Display direction-pad hit areas clearly and verify thumb reach on actual devices."),
    "trace_wire": ("Drag sequence", "Press node one, hold and drag through five ordered nodes before timeout.", "C", "Add continuous wire-path validation; current gameplay accepts direct drags between checkpoints."),
    "balloon_pump": ("Tap speed", "Pump toward a target while air leaks between taps; insufficient input loses on time.", "C", "Add overpressure or deliberate timing decisions; current challenge is primarily repeated taps versus leakage."),
    "hold_balance": ("Hold precision", "Hold to fill a meter, then release in the target band; early/late release and overflow fail.", "B", "Show an explicit release cue and measure human timing tolerance."),
    "color_switch": ("Stroop selection", "Select ink color while a conflicting color word distracts; complete three correct selections.", "B", "Add non-color labels for color-vision accessibility and verify word/pad contrast."),
    "number_order": ("Ordering puzzle", "Tap a shuffled six-number grid in increasing order; out-of-order taps fail.", "B", "Add a richer spatial arrangement and clear already-selected tile feedback."),
    "mirror_match": ("Directional inversion", "Read the direction cue and choose its opposite; a distinct rule from matching shield defense.", "B", "Improve the initial opposite-direction tutorial and distinguish it visually from shield defense."),
    "orbit_snap": ("Angular timing", "Stop an orbiting satellite inside an angular target band; an off-target snapshot fails.", "B", "Show rotation direction and keep target-band presentation aligned with collision acceptance."),
    "light_out": ("Grid toggle puzzle", "Tapping toggles a tile and its orthogonal neighbors; authored scramble from an all-off state guarantees a solution.", "B", "Offer reset/undo for standalone practice and test a broader seeded puzzle set."),
    "safe_dial": ("Directional memory", "Read the left/right combination and commit exactly one direction per gesture.", "B", "Add a deliberate observation phase if a true memory challenge is desired; current code remains visible."),
    "fuse_cut": ("Precision selection", "Read a safe wire number and select only that horizontal wire; the wrong wire fails.", "C", "Require a crossing cut path rather than accepting a same-location tap; improve wire identity cues."),
    "pixel_repair": ("Pattern copying puzzle", "Toggle the right 3x3 pattern until it equals the left target; mismatches remain repairable until time expires.", "B", "Add reset/undo, accessible pattern markers and more varied but solvable layouts."),
    "maze_runner": ("Collision maze", "Move around two collision walls to the exit; wall hits are blocked and the clock supplies the failure condition.", "B", "Add authored maze variants and swept collision for large frame deltas."),
    "gravity_flip": ("Gravity dodge", "Switch between floor and ceiling lanes; survive three moving blockers with collision failure.", "B", "Add safely spaced seeded obstacle variations and clear switch anticipation."),
    "word_sort": ("Semantic sorting", "Route six alternating fruit/tool words left or right; a wrong semantic choice fails.", "C", "Shuffle a richer word set; current alternating fixed order can be memorized without reading."),
    "echo_taps": ("Rhythm memory", "Observe a seeded rhythm then reproduce its three beat intervals with timed taps.", "B", "Measure cue-to-input latency and make listen/repeat phases unmistakable."),
    "door_peek": ("Wait-and-react", "Wait for a seeded doorway opening and tap within its short window; early, late and missed input fail.", "B", "Add fair doorway animation and log human reaction time without invented latency numbers."),
    "arc_dash": ("Two-rail runner", "Switch rails to avoid four blockers; contact fails and passing the final blocker wins.", "B", "Add reachable obstacle-pattern variety and keep switching response readable."),
    "laser_tunnel": ("Duck/stand runner", "Hold to duck high beams and release for low beams; four beam collisions decide the round.", "B", "Add body-state anticipation and ensure held touches recover after pause/orientation."),
    "armor_repair": ("Drag placement", "Select and drag three numbered plates onto matching locations; score only after all placements.", "B", "Add clearer selected-plate feedback and varied layouts while preserving large targets."),
    "rocket_rescue": ("Collection navigation", "Steer to collect three friends, then reach an exit; no obstacle collision is currently present.", "C", "Add navigation hazards or acceleration so free pointer teleporting cannot trivialize the rescue."),
    "flappy_bonus": ("Tap flight", "Tap against gravity through three gap gates; ceiling, ground and gate collisions fail.", "B", "Preserve the separate endless Flappy cabinet; vary seeded reachable gaps for replay."),
    "swing_rescue": ("Projectile landing", "Choose swipe launch velocity from a swinging rope and land near the rescue mattress.", "B", "Add a readable launch arc preview and compare touch versus virtual-cursor gesture precision."),
    "meteor_dodge": ("Survival movement", "Steer horizontally to avoid six falling meteors until the survival timer completes.", "C", "Current authored meteor lanes allow a permanently safe edge; add fair variation without removing all safe routes."),
    "parcel_catch": ("Multi-object catching", "Catch four staggered parcels; any uncaught parcel past the floor fails.", "B", "Broaden seeded falling routes while guaranteeing travel time between catches."),
    "ice_slide": ("Friction aiming", "One swipe sets velocity; friction brings the puck to rest and the final ring distance decides success.", "B", "Expose direction/strength feedback and validate the keyboard gesture tutorial."),
    "rail_grind": ("Jump runner", "Tap to jump three rail hurdles under gravity; contact fails, clearing the last hurdle wins.", "B", "Add jump buffering and fair obstacle-pattern variation."),
    "balloon_lift": ("Hold flight", "Hold to rise and release to descend while moving horizontally toward a rooftop.", "B", "Make rooftop landing tolerance visible and add wind variety with reachable landing checks."),
    "magnet_haul": ("Drag attraction", "Bring a magnet within range of scrap, then pull the moving scrap into its home.", "C", "Add obstacle interaction or limited magnetic reach to make hauling a physical puzzle."),
    "rope_bridge": ("Path tracing", "Follow ordered bridge checkpoints; positions too far from any bridge segment fail.", "B", "Validate the swept drag segment so coarse pointer jumps cannot skip off-path movement."),
    "paint_skate": ("Checkpoint route", "Drag through four ordered skate checkpoints; unvisited checkpoints and time provide the goal and failure.", "C", "Add skating inertia and hazards; current direct pointer positioning overlaps the tracing family."),
    "shield_surf": ("Swipe timing defense", "Swipe up while bolts are inside the defense band; deflect three and avoid missed bolt impacts.", "B", "Tighten presentation of the accepted band and test swipes under touch latency."),
    "boulder_push": ("Swipe effort", "Right swipes push a rock uphill while it slips backward; reach the parking goal.", "C", "Add slope/momentum or alternate force choices so the loop gains decisions beyond repeated swipes."),
    "river_hop": ("Directional hopping", "Choose each next lily-pad direction; wrong hops fail and four valid hops finish.", "B", "Add moving hazards and authored route variation while preserving fair directions."),
    "glider_gust": ("Gust flight", "Swipe upward for vertical impulse while gliding horizontally; reach the island within its height band.", "B", "Add clear impulse feedback and varied reachable wind patterns."),
    "orbit_escape": ("Radial launch", "Choose orbital launch timing; the ship travels along its radial velocity toward a dock.", "B", "Provide dock-alignment cues and verify acceptance radius visually."),
    "spring_vault": ("Charged projectile", "Hold to charge horizontal launch strength, release, then land within the green platform tolerance.", "B", "Match meter band to the actual accepted landing interval and show launch anticipation."),
    "cloud_ferry": ("Drag delivery", "Position a cloud beneath a friend, pick them up, and carry them home; no environmental hazard is present.", "C", "Add wind, collision or constrained motion so transporting requires more than direct pointer placement."),
    "parachute_drop": ("Steered landing", "Steer horizontal position during gravity descent and small drift; land on the green platform.", "B", "Add fair wind variation and inspect landing hitbox/readability on phones."),
    "pinball_rescue": ("Tap pinball", "Tap near the flippers to launch the falling ball; hit the top three times and avoid bottom drain.", "C", "Add meaningful flipper timing/angle or bumpers; the current interaction is a broad upward impulse."),
    "conveyor_sort": ("Moving drag sorting", "Drag moving A/B parcels to their matching bins before they pass the conveyor floor.", "B", "Add seeded parcel schedules and reject drops visibly without losing pointer ownership."),
    "comet_curl": ("Bank-shot friction", "A diagonal swipe must bank off the gold ceiling, clear a red obstacle and stop in the target ring.", "B", "Preview the bank constraint and test swept collision at larger frame deltas."),
}
CONTROLS = {
    "TAP": "Mouse/touch tap; keyboard/controller virtual cursor plus Space/A",
    "HOLD": "Mouse/touch hold and release; Space/A hold and release",
    "MOVE": "Mouse/touch drag; arrows/WASD/stick continuous axis",
    "DRAG": "Mouse/touch drag; arrows/WASD/stick virtual cursor with Space/A press/release",
    "SWIPE": "Mouse/touch swipe; arrows/D-pad short swipe; hold Space/A and move cursor for a precise gesture",
    "DIRECTIONAL": "Touch board direction affordances/swipe; arrows/WASD/D-pad",
    "ARCADE": "Per-game arrows/WASD/stick, Space/A and select/secondary actions; drawn touch pads, swipe or drag as indicated by the game's hint",
}
entries = []
for pack in ["a", "b"]:
    raw = json.loads((ROOT / f"microgames/pack_{pack}.json").read_text(encoding="utf-8"))
    for item in raw:
        genre, mechanic, grade, plan = DETAILS[item["id"]]
        entries.append({
            "id": item["id"], "name": item["name"],
            "files": [item["script"].removeprefix("res://"), f"microgames/pack_{pack}.json", "microgames/microgame_base.gd"],
            "genre": genre, "duration_seconds": item["duration"],
            "status": "working_in_executed_simulations", "quality_grade": grade,
            "grade_basis": "Provisional engineering grade from source inspection and action-driven simulation; human enjoyment and visual polish are not scored as measured facts.",
            "controls": {"mode": item["input"], "mapping": CONTROLS[item["input"]]},
            "gameplay": mechanic,
            "art": {"implementation": "Original procedural Paint-style primitives and shared handmade hero", "per_game_visual_review": "not performed in this headless audit"},
            "performance": {"frame_time": "unmeasured", "memory": "per-round instance cleanup checked; sustained browser heap trace unmeasured"},
            "mobile": {"normalized_action_loop": "passed", "shared_touch_router": "24-check suite passed with six representative integrations and two simultaneous touches", "per_game_physical_phone": "untested"},
            "critical_bugs": "None reproduced by executed cases; deterministic source/gameplay limitations are recorded in the upgrade plan.",
            "upgrade_plan": plan,
            "qa": {"result": "pass", "evidence": [f"tests/pack_{pack}_test.gd", "tests/catalog_audit_test.gd"],
                   "win_cases": "difficulty 1 and 6, seeds 17 and 92" if pack == "a" else "difficulty 1 and 6, seed 1204",
                   "failure_cases": "idle difficulty 1/6 plus wrong input at difficulty 6" if pack == "a" else "idle difficulty 1",
                   "lifecycle": "primary input, pause/resume, seeded restart, idle termination, single result, isolated second instance, destroy",
                   "complete_browser_loop": "not performed per game in this audit"},
        })

cabinets = []
cabinet_info = {
    "arc_snake": ("Grid snake", "Turn, grow, collect eight reactor cores, optionally boost; walls/body cause loss.", "Tail-vacating cell is legal; food placement exhaustively selects only free cells."),
    "brick_reactor": ("Breakout physics", "Launch and steer paddle; ball-wall/paddle/brick collisions clear forty-five bricks; falling out loses.", "Collision substeps and directional separation prevent fast-ball tunneling and repeated contact."),
    "tower_bounce": ("Vertical auto-bounce platformer", "Steer with acceleration, land on one-way platforms and climb 1000 pixels; falling loses.", "Scroll now advances generation cursor; reachable gaps/center shifts generate new platforms and remove old platforms."),
}
for item in json.loads((ROOT / "games/cabinets.json").read_text(encoding="utf-8")):
    genre, mechanic, repairs = cabinet_info[item["id"]]
    cabinets.append({"id": item["id"], "name": item["name"], "original_source": f"C:/Users/LalithReddy.b/Iron-Mario/scenes/{item['id']}.gd",
                     "files": [item["script"].removeprefix("res://"), "games/cabinets.json"], "genre": genre,
                     "status": "restored_component_tests_passed_app_integration_pending", "quality_grade": "B",
                     "controls": "ARCADE: arrows/stick/Space plus drawn touch-button hitboxes; drag paddle for Brick Reactor",
                     "gameplay": mechanic, "repairs": repairs, "duration_seconds": 90, "tournament_enabled": False,
                     "qa": {"result": "pass", "evidence": "tests/cabinets_test.gd: 151 checks, 0 failures", "cases": "actual action/physics wins and restarted losses, difficulty 1/6 seeds 23/94; primary touch buttons, input cancellation, pause, result idempotence, cleanup"},
                     "art": "Original procedural Paint-style drawings; browser screenshots pending",
                     "performance": "Frame times and physical-phone sustained memory unmeasured",
                     "upgrade_plan": "Verify shared-app registration, replay/exit and responsive touch-button layout in the browser before release."})

NEW_DETAILS = {
    "water_sort": ("Contiguous liquid pouring with matching/empty tube and capacity rules", "Expand proven solvable scrambles; review source/destination and undo affordances."),
    "ball_sort": ("One-marble transfer puzzle with tube capacity and matching-color rules", "Compare its separate one-ball rule clearly with liquid pouring and vary valid arrangements."),
    "sliding_puzzle": ("Adjacent-gap tile movement restoring an eight-tile board", "Expose move count and reset/undo while retaining solvable scramble generation."),
    "sokoban": ("Push-only crate navigation to a goal with wall and occupancy checks", "Add authored crate layouts and retain undo before an irreversible push."),
    "minesweeper": ("Number deduction, marking mines and revealing every safe tile", "Review flag/reveal distinction and broaden deterministic boards with useful opening clues."),
    "tangram": ("Rotate and place pieces without overlap to fill a compact packing board", "Make selected shape rotation and rejected placement boundaries clear."),
    "nonogram": ("Match row and column group clues by filling or clearing cells", "Provide clear clue completion and verify solution uniqueness over more boards."),
    "domino": ("Append matching-number tiles to construct a chain with a prescribed end", "Add multiple valid hands and show both open-end and used-tile state."),
    "pipe_flow": ("Rotate connected pipe tiles from inlet to outlet", "Preview actual water connectivity and add seeded path variations."),
    "laser_reflect": ("Flip slash mirrors to route a traced beam into a receiver", "Keep visual beam path aligned with segment reflection rules and offer reset."),
    "tic_tac_toe": ("Legal cell placement against a minimax opponent, recognizing win or draw", "Make draw completion explicit and offer a short accessible opponent tutorial."),
    "connect_four": ("Gravity disk placement, four-in-a-row detection and opponent replies", "Review column controls and expand AI fairness/depth tests beyond fixtures."),
    "hex_rotation": ("Rotate hex-pipe orientations into a route through the outer tiles to a hub", "Show connection direction and improve color-independent orientation markers."),
    "word_ladder": ("Change one letter per valid word step from COLD to WARM", "Broaden dictionary-validated ladders and explain rejected word transitions."),
    "tower_hanoi": ("Transfer ordered disks between pegs without covering smaller disks", "Show selected disk and valid destination; keep reset and undo reachable."),
    "memory_pairs": ("Flip two cards, remember mismatches and clear weather pairs", "Review small-screen card readability and vary seeded symbol arrangements."),
    "chess_fork": ("Find a legal knight square simultaneously attacking king and rook", "Show knight movement rather than relying on prior chess knowledge."),
    "knight_tour": ("Visit each board cell once with knight moves and recognize trapped routes", "Expand proven-solvable tours and keep undo available before a trap."),
    "river_ferry": ("Transport wolf, goat and cabbage while rejecting unsafe unattended banks", "Show unsafe relationships before sailing and keep return trips obvious."),
    "peg_solitaire": ("Jump one peg over another into an empty hole until only one remains", "Add curated solvable starts and show candidate jump paths."),
    "logic_grid": ("Assign different tools to heroes from explicit role clues", "Expand clue sets and show constraint violations without ambiguous colors."),
    "train_shunt": ("Dispatch cars in order using last-in-first-out sidings", "Clarify siding stacks and add reachable traffic arrangements."),
    "circuit_logic": ("Toggle binary inputs until AND/OR/XOR outputs meet targets", "Explain each gate with visible truth feedback and accessible input labels."),
    "gear_link": ("Choose radii so adjacent gears mesh at their authored hub distances", "Make radius/distance constraints visible and add valid hub arrangements."),
    "code_breaker": ("Use exact-position and wrong-position feedback to deduce a color code", "Provide non-color peg labels and broaden duplicate-color feedback fixtures."),
    "metro_armor_rush": ("Three-lane runner with jump/slide hazards, distance, health and coins", "Retain repaired shuffled lane bags so idling cannot avoid all challenges; verify touch jump/slide timing."),
    "shadow_armor_duel": ("Windup/recovery combat, distance, attacks, blocking and opponent health", "Review hitbox and windup presentation; broaden block/counter and opponent state tests."),
    "scrap_hill_racer": ("Acceleration, terrain contact, fuel and vehicle-angle stability", "Review suspension/contact feedback and test slope/airborne control on actual touch hardware."),
    "temple_reactor_escape": ("Timed turn/jump/slide commands at a green response marker", "Make route anticipation clear and test reaction tolerance with human input latency."),
    "reactor_slice": ("Swept swipe slicing, combos, fruit trajectories and bomb avoidance", "Review simultaneous fruit/bomb readability and touch cancellation across two fingers."),
    "jetpack_test_lab": ("Hold-to-rise flight with gravity, hazards and collectibles", "Retain hold cancellation on pause and add fair obstacle-pattern variation."),
    "chaos_crossing": ("Grid crossings timed against cars and moving water logs", "Measure thumb timing and review log-carry and bank transitions."),
    "catapult_chaos": ("Drag slingshot projectile physics against two reactor targets with limited ammo", "Expose pull strength/direction and profile collision-heavy updates on phones."),
    "feed_reactor": ("Cut separate ropes and time a swinging battery into a receiver", "Review rope selection, gate/receiver collision and swipe-crossing precision."),
    "neon_rhythm_escape": ("Timed jumps over spike/gap obstacles in a short rhythm runner", "Measure audiovisual latency and keep grounded jump acceptance fair."),
    "skyline_jumper": ("Auto-jump rooftops with wind, steering and crumbling platforms", "Review reachable gaps and distinguish its wind/crumble rules from preserved Tower Bounce."),
    "turbo_flapper": ("Longer scored tap-flight run with gates, energy cells and shield", "Preserve the original short Flappy Bonus and clarify longer-run shield/collection goals."),
    "bridge_builder": ("Hold plank growth, release lowering, then cross a correctly measured gap", "Keep accepted landing length visible and expand reachable gap layouts."),
    "reactor_merge": ("Directional tile sliding/merging, new tiles, undo and reset", "Add board-state fixtures for blocked moves and preserve undo access on mobile."),
    "rooftop_defense": ("Place generators, turrets and barriers against approaching machines", "Review resource/build selection and balance first-wave economy using measured player sessions."),
    "mini_reactor_buddy": ("Manage fuel/hygiene/joy/heat with tradeoffs and a timed play action", "Keep request completion clear and test recovery from missed play timing and excess heat."),
    "brainrot_button_panic": ("Read changing directional prompts with opposite-rule reversals under shortening deadlines", "Clarify normal/opposite state and measure human readability at the fastest deadline."),
    "meme_dodge_arena": ("Avoid telegraphed object impacts with steering and a brief dash cooldown", "Review warning duration and ensure simultaneous impacts leave a reachable safe route."),
    "one_pixel_survival": ("Steer a small dot through moving laser gaps with geometric collision", "Review dot/hitbox visibility and actual touchscreen precision before assigning extreme difficulty."),
    "impossible_parking": ("Steering, throttle/reverse, braking, wall collision and valid parking alignment", "Review simultaneous steering/throttle holds and parking tolerance on touch devices."),
    "reaction_relay": ("Wait for GO, reject early taps, measure reaction time across eight rounds", "Report actual reaction measurements without presenting simulated input latency as human performance."),
    "chaos_elevator": ("Choose floors, pick up guests and deliver each to a matching destination", "Make passenger ownership and next-floor selection readable at small sizes."),
    "dont_press_red": ("Tap green while allowing red to expire for a sequence of decisions", "Vary fair color schedules and add shape labels for color-vision accessibility."),
    "fall_forever": ("Steer a falling body through procedural gaps with a descent brake", "Keep obstacle gaps reachable under the current fall rate and measure simultaneous touch holds."),
    "physics_disaster": ("Cut a support to launch a physical chain reaction into a bell while sparing a bomb", "Expand reproducible arrangements and make the release/collision consequences legible."),
    "paint_frontier": ("Leave owned territory and close a trail to capture space while avoiding an eraser", "Review enclosed-region capture rules and add explicit interrupted-trail feedback."),
    "notebook_platformer": ("Move, jump with grounded/coyote rules, collect a core and reach an exit", "Preserve this complete platformer as the antecedent of the older gauntlet; broaden platform/power integration separately."),
}
ADDED_PACKS = [
    ("microgames/pack_c.json", "tests/pack_c_test.gd", "difficulty 1/6 with seeds 17/92; 100 solved boards, 50 idle losses", 834),
    ("games/classics_a.json", "tests/classics_a_test.gd", "difficulty 1/3/6, seed 1204; real wins, restarted idle losses, pause and one completion", 144),
    ("games/classics_b.json", "tests/classics_b_test.gd", "keyboard-equivalent difficulty 1/6 seed 1204 and touch-handler difficulty 3 seed 902 at 30 Hz; losses, restart and rule fixtures", 99),
    ("games/chaos.json", "tests/chaos_test.gd", "difficulty 1/3/6, seed 123; real wins, valid scores, pause/restart and idle failures", 165),
]
performance = json.loads((ROOT / "build/catalog-qa/performance_report.json").read_text(encoding="utf-8"))
performance_by_id = {item["id"]: item for item in performance["records"]}
for pack, test, cases, count in ADDED_PACKS:
    for item in json.loads((ROOT / pack).read_text(encoding="utf-8")):
        mechanic, plan = NEW_DETAILS[item["id"]]
        entries.append({"id": item["id"], "name": item["name"],
                        "files": [item["script"].removeprefix("res://"), pack, "microgames/microgame_base.gd"],
                        "genre": item["category"].capitalize(), "duration_seconds": item["duration"],
                        "tournament_enabled": item.get("tournament_enabled", True),
                        "status": "working_in_executed_simulations", "quality_grade": "B",
                        "grade_basis": "Provisional source/rule and executed-loop assessment; native captures are available, physical-device polish and human enjoyment unmeasured.",
                        "controls": {"mode": item["input"], "mapping": CONTROLS[item["input"]], "hint": item["hint"]},
                        "gameplay": mechanic,
                        "art": {"implementation": "Original Paint presentation; designated licensed room artwork where applicable, see ASSET_USAGE_MAP.md", "capture": f"build/catalog-qa/{item['id']}_board.png", "physical_phone_review": "unperformed"},
                        "performance": {},
                        "mobile": {"normalized_actions": "passed", "shared_touch_router": "representative suite passed", "physical_phone": "untested"},
                        "critical_bugs": "None reproduced by recorded tests after Metro lane-bag repair; browser release review remains separate.",
                        "upgrade_plan": plan,
                        "qa": {"result": "pass", "evidence": [test, "tests/catalog_audit_test.gd"], "suite_checks": count, "cases": cases,
                               "app_lifecycle": "launched, paused/resumed, restarted, simulated to results, recorded once and exited to menu", "browser": "not verified by this audit"}})
for item in cabinets:
    entries.append({**item, "qa": {**item["qa"], "app_lifecycle": "passed through actual app with the full 105-entry audit"},
                    "status": "working_in_executed_simulations", "controls": {"mode": "ARCADE", "mapping": item["controls"]},
                    "upgrade_plan": "Verify final browser replay/exit and simultaneous touch holds; preserve score on loss and enlarged 90px logical buttons."})
for entry in entries:
    timing = performance_by_id[entry["id"]]
    entry["performance"] = {"measurement": "native headless unattended simulation CPU cost, not rendered FPS",
                             "sample_frames": timing["sample_count"], "p95_update_usec": timing["p95_update_usec"],
                             "mean_update_usec": timing["mean_update_usec"], "scene_children_delta_after_free": timing["scene_children_delta_after_free"],
                             "GPU_browser_phone_frame_time": "unmeasured", "browser_heap": "unmeasured"}
    entry.setdefault("qa", {})["app_lifecycle"] = "passed: actual launcher, pause/resume, fresh restart, simulated result, one profile record, menu exit and bounded nodes"
    if isinstance(entry["art"], dict): entry["art"]["capture"] = f"build/catalog-qa/{entry['id']}_board.png"

catalog = {"schema_version": 2, "audit_date": "2026-10-09", "baseline_registered_games": 50, "registered_modules_audited": len(entries),
           "scope": "Executed baseline engineering audit; additions must not be represented as already deployed.",
           "qa_totals": {"existing_five_suites": 924, "catalog_lifecycle": 1492, "restored_cabinets": 151,
                         "pack_c": 834, "classics_a": 144, "classics_b": 99, "chaos": 165, "performance": 424, "GPU_captured_modules": 105, "failures": 0},
           "games": entries, "restored_cabinets": cabinets,
           "older_local_games_not_yet_ported_by_this_auditor": [
               {"id": "flappy", "name": "Flappy Bonus (endless cabinet)", "files": ["C:/Users/LalithReddy.b/Iron-Mario/scenes/flappy_bird.gd", "C:/Users/LalithReddy.b/Iron-Mario/scenes/flappy_bird.tscn"], "status": "implemented source inspected; separate longer loop from deployed three-gate flappy_bonus; parent owns integration"},
               {"id": "minigame_1", "name": "Platformer Gauntlet", "files": ["C:/Users/LalithReddy.b/Iron-Mario/scenes/minigame_1.gd", "C:/Users/LalithReddy.b/Iron-Mario/scenes/player.gd", "C:/Users/LalithReddy.b/Iron-Mario/scenes/minigame_1.tscn"], "status": "implemented collectibles/platforming/power source inspected; not preserved as a complete platformer by deployed50; parent owns integration"},
           ]}
(ROOT / "docs/game_catalog.json").write_text(json.dumps(catalog, indent=2) + "\n", encoding="utf-8")

lines = ["# Game audit", "", "Audited on **2026-10-09** with official **Godot 4.7.1**. The starting deployed baseline defines **50 playable modules**, not an assumed 100. The current working catalog contains **105 implemented modules: 50 preserved baseline, 25 new puzzles, 16 original classics, 11 chaos games and 3 restored cabinets**. None is described here as deployed before live release verification.", "",
         "## Evidence and grading", "", "**924 baseline checks, 834 puzzle checks, 144 classics A checks, 99 classics B checks, 165 chaos checks, 151 restored-cabinet checks, 1492 catalog/app lifecycle checks and 424 compute/cleanup checks passed.** Actual GPU renders of all 105 initial boards and representative application/mobile states were captured without engine errors. These are executed tests and native captures, not fabricated browser or phone passes. Exact scope is documented in `BASELINE_ARCHITECTURE.md`.", "",
         "Every baseline entry has action-driven win/failure coverage, a meaningful primary action check, pause/resume, seeded same-instance restart, terminal-result idempotence, independent-instance isolation and cleanup. All 105 IDs were also launched through the actual application, paused/resumed, restarted, simulated to results, checked for exactly one profile record, then returned to the menu with bounded nodes. Complete browser launch/replay/return loops for every individual game remain unverified by this audit.", "",
         "Grades are provisional engineering judgments from inspected rules and simulated loops: **B** means fully playable in these tests but requires refinement; **C** means functional with a specific shallow, repetitive or exploitable mechanic. No game receives an A-ready claim from headless execution. Fun, human difficulty and per-game visual polish require human/visual review.", "",
         "For every row below: **status=working in executed simulations; art=original Paint presentation with native board capture available; browser/phone GPU frame times=unmeasured; physical phone=untested**. Per-module headless CPU update timings and zero scene-node cleanup deltas are recorded in the JSON catalog. Shared touch routing passed including two fingers and representative integrations. That does not prove every game on an actual phone. Source files include the indicated implementation/JSON and shared lifecycle base.", "",
         "## All 105 current working modules", "",
         "| Stable ID / name | Files | Genre and implemented loop | Controls | Grade | QA evidence | Specific upgrade |",
         "| --- | --- | --- | --- | --- | --- | --- |"]
for entry in entries:
    test = entry["qa"].get("evidence")
    if isinstance(test, list): test = test[0]
    lines.append(f"| `{entry['id']}` / **{entry['name']}** | `{entry['files'][0]}` + `{entry['files'][1]}` | {entry['genre']}: {entry['gameplay']} | {entry['controls']['mode']} | {entry['quality_grade']} | `{test}` win/loss + app lifecycle **PASS** | {entry['upgrade_plan']} |")
lines += ["", "The machine-readable `game_catalog.json` expands every entry with device-specific control mappings, evidence cases, functional status, art/performance/mobile limitations and upgrade plans. Closely related families are called out rather than concealed: Pocket Change/Parcel Catch are catching variants; Live Wire/Rope Bridge/Paint Skate are ordered dragging variants; matching/opposite-direction games change the rule rather than only a skin. These are existing implemented entries; the audit does not claim fifty fundamentally unrelated genre engines.", "",
          "## Older local implementations absent from deployed baseline", "",
          "| Game | Original files and genuine mechanism | Current status / repair |",
          "| --- | --- | --- |"]
for item in cabinets:
    lines.append(f"| **{item['name']}** (`{item['id']}`) | `{item['original_source']}` + corresponding scene; {item['gameplay']} | Restored under `{item['files'][0]}`; action/physics and actual shared-app integration passed, browser release review pending. {item['repairs']} |")
lines += ["| **Flappy Bonus endless** (`flappy`) | Older `scenes/flappy_bird.gd` and `.tscn` implement a title/play/game-over endless gate loop. | Source inspected; materially different from three-gate `flappy_bonus`. Parent owns preservation/integration. |",
          "| **Platformer Gauntlet** (`minigame_1`) | Older `scenes/minigame_1.gd`, `player.gd`, collectibles and `.tscn` implement CharacterBody movement, jumping, collectible overlaps and hero powers. | Source inspected; complete platforming loop is missing from deployed fifty. Parent owns tested preservation. |", "",
          "Older `minigame_2` Target Tag, `minigame_3` Dodge the Lasers and `minigame_4` Gauge Parry are antecedents of deployed targeting/laser/parry concepts. Their source is preserved in the original checkout/history; they are not silently counted again as new games. `hero_select` is a selection screen and is not counted as a gameplay implementation.", "",
          "## Release gates still required", "",
          "- Preserve restored cabinets' 90-second standalone durations, retained loss scores, enlarged controls and tournament opt-out.",
          "- Run browser screenshot review, touch controls and complete replay/exit loops after final integration.",
          "- Measure browser frame-time and sustained memory traces; test a real ordinary phone before claiming 60 FPS or physical-device compatibility.",
          "- Preserve all baseline IDs and implementations while adding games. The all-entry audit catches missing or replaced baseline script paths.",
          "- Re-run affected tests after changes. This report records an execution checkpoint and does not automatically certify later edits."]
(ROOT / "docs/GAME_AUDIT.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
print(f"Wrote {len(entries)} baseline records and {len(cabinets)} restored-cabinet records.")
