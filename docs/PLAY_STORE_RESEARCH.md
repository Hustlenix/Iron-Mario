# Google Play research and original arcade specifications

Research date: 9 October 2026. Research began at [Google Play Games](https://play.google.com/store/games), then opened each of the 46 publisher listings below. These are verified listing candidates, not a popularity ranking. No ratings, downloads, engagement statistics or rankings are used to choose concepts.

Session length is a design estimate for a normal attempt/visit, not publisher telemetry. Return motivation, HTML5 feasibility and effort are design hypotheses. Control mappings not explicitly described in a listing are marked inferred or describe the original adaptation. No game was installed or played as part of this listing research. No APK, third-party art, music, levels or code was downloaded. Listings can change or vary by region.

The current Flappy Bird listing names Flappy Bird Publishing; this document does not represent it as the historic developer's original release. Angry Birds 2 is the current slingshot reference. The inaccessible Ketchapp 2048 URL was replaced by the verified Androbaby listing. Failed lookups (including Blek, aa, Super Hexagon, Downwell and Two Dots) were excluded from the verified count.

## Prioritized shortlist

24 concepts are shortlisted for variety and browser suitability: all 16 requested nostalgic adaptations, plus Stack Scrap, Coolant Sort, Bolt Sort, Cable Snake, Brick Barrage, Rivet Ring, Crate Escape and Falling Polyforms. This is an engineering prioritization, not evidence of commercial success. Implement in small batches, testing real collision, scoring and win/loss loops before raising the playable count.

## Priority A: sixteen requested classics

### Metro Armor Rush

Reference: [Subway Surfers](https://play.google.com/store/apps/details?id=com.kiloo.subwaysurf) — SYBO Games. Verified public listing on 2026-10-09.

- Mechanic: Three-lane obstacle runner with jumping and sliding.
- Controls: Directional swipes; keyboard lanes/jump/slide (adaptation).
- Session estimate: 1–5 min per run. Return hypothesis: Distance mastery, collectible routes and fresh obstacle patterns.
- Difficulty: Increasing speed and obstacle combinations.
- HTML5 feasibility: High: pseudo-3D lane projection avoids a full 3D world. Estimated complexity: High.
- Original scope: Hand-drawn courier dodges repair carts and low beams; route coins reward risky lanes.
- Implementation/QA brief: Guarantee at least one traversable route; test lane change, jump, slide, pickup, collision and restart.

### Shadow Armor Duel

Reference: [Shadow Fight 2](https://play.google.com/store/apps/details?id=com.nekki.shadowfight) — NEKKI. Verified public listing on 2026-10-09.

- Mechanic: 2D martial-arts duel with attacks, equipment and bosses.
- Controls: Touch movement and attack buttons; arrows plus attack/block in adaptation.
- Session estimate: 1–3 min per bout. Return hypothesis: Learning opponent tells and mastering attack spacing.
- Difficulty: Windups, recovery, range and enemy counterattacks.
- HTML5 feasibility: High: 2D state machines and explicit hitboxes; animation is the largest cost. Estimated complexity: High.
- Original scope: Original scrap silhouettes; light/heavy attacks, held guard, knockback and readable AI.
- Implementation/QA brief: Attack must hit once; guard reduces valid front damage; test opponent victory, player defeat and recovery locks.

### Scrap Hill Racer

Reference: [Hill Climb Racing](https://play.google.com/store/apps/details?id=com.fingersoft.hillclimb) — Fingersoft. Verified public listing on 2026-10-09.

- Mechanic: Terrain driving with vehicle balance, tricks and finite fuel.
- Controls: Gas/brake hold controls; two touch pedals in adaptation.
- Session estimate: 1–5 min per run. Return hypothesis: Improved distance and learning when to accelerate or brake.
- Difficulty: Slope torque, rollover risk and fuel management.
- HTML5 feasibility: High: constrained wheel/terrain simulation with fixed substeps. Estimated complexity: High.
- Original scope: Build a wobbly scrap buggy; fuel cans create route decisions and flips carry risk.
- Implementation/QA brief: Exercise hill collision, wheel contact, accelerating/braking, pickup, fuel exhaustion and roof impact.

### Temple Reactor Escape

Reference: [Temple Run](https://play.google.com/store/apps/details?id=com.imangi.templerun) — Imangi Studios. Verified public listing on 2026-10-09.

- Mechanic: Chase runner with turns, jumps, slides and collection.
- Controls: Swipe turns/jump/slide; tilt for lateral movement in source family.
- Session estimate: 1–5 min per run. Return hypothesis: Distance records and recognizing obstacle sequences.
- Difficulty: Correct turns at junctions plus rapid obstacle responses.
- HTML5 feasibility: High: route segments and projected track, independent from lane runner. Estimated complexity: High.
- Original scope: Escape a crumbling reactor corridor; mandatory junction choices distinguish it from Metro.
- Implementation/QA brief: Test left/right junction deadlines, jumping gaps, ducking beams and fair spawn spacing.

### Reactor Slice

Reference: [Fruit Ninja®](https://play.google.com/store/apps/details?id=com.halfbrick.fruitninjafree) — Halfbrick Studios. Verified public listing on 2026-10-09.

- Mechanic: Slice tossed objects, chain combos and avoid hazards.
- Controls: Swipe through objects; mouse drag in adaptation.
- Session estimate: 1–2 min per round. Return hypothesis: Combos, precision and a better score.
- Difficulty: Separating safe objects from hazards while paths overlap.
- HTML5 feasibility: High: swept segment-circle collision and ballistic spawns. Estimated complexity: Medium.
- Original scope: Slice flying power cells while avoiding unstable red cores; no borrowed fruit/branding.
- Implementation/QA brief: A slice crossing an object between frames must count once; hazard strike and missed-object limit must fail.

### Jetpack Test Lab

Reference: [Jetpack Joyride](https://play.google.com/store/apps/details?id=com.halfbrick.jetpackjoyride) — Halfbrick Studios. Verified public listing on 2026-10-09.

- Mechanic: Hold-to-fly runner through lasers, missiles and collectibles.
- Controls: One-touch hold to rise/release to fall.
- Session estimate: 1–5 min per run. Return hypothesis: Route mastery, survival distance and collectible patterns.
- Difficulty: Vertical inertia and predicting moving hazards.
- HTML5 feasibility: High: 2D velocity integration and warning telegraphs. Estimated complexity: Medium.
- Original scope: Redrawn test pilot flies through original lab obstacle sets; missiles telegraph before launch.
- Implementation/QA brief: Test lift/fall, ceiling clamp, coin pickup, laser collision and guided-missile warning time.

### Chaos Crossing

Reference: [Crossy Road](https://play.google.com/store/apps/details?id=com.yodo1.crossyroad) — HIPSTER WHALE. Verified public listing on 2026-10-09.

- Mechanic: Grid hopping through traffic, railways and rivers.
- Controls: Tap forward and swipe sideways; four arrows in adaptation.
- Session estimate: 30 sec–3 min per run. Return hypothesis: New layouts and an extra safe row.
- Difficulty: Traffic timing, moving logs and pressure against waiting forever.
- HTML5 feasibility: High: tile coordinates plus continuous vehicle motion. Estimated complexity: Medium.
- Original scope: Cross paint roads, scrap trains and conveyor rivers with original creatures.
- Implementation/QA brief: No generated row may be wholly impossible; test moving support, drowning, traffic collision and score only on new rows.

### Catapult Chaos

Reference: [Angry Birds 2](https://play.google.com/store/apps/details?id=com.rovio.baba) — Rovio Entertainment Oy. Verified public listing on 2026-10-09.

- Mechanic: Aim a slingshot projectile to knock down enemy structures.
- Controls: Drag backward to aim, release to launch.
- Session estimate: 1–3 min per level. Return hypothesis: Efficient solutions, different shots and collapse chains.
- Difficulty: Trajectory planning and selecting weak structural points.
- HTML5 feasibility: High: small rigid-body world with bounded debris. Estimated complexity: High.
- Original scope: Launch scrap balls at unstable cardboard robot forts with material-dependent break thresholds.
- Implementation/QA brief: Validate drag strength, gravity arc, impact damage, collapse and finite-shot failure.

### Feed the Reactor

Reference: [Cut the Rope](https://play.google.com/store/apps/details?id=com.zeptolab.ctr.ads) — ZeptoLab. Verified public listing on 2026-10-09.

- Mechanic: Cut supporting ropes to deliver an object through a physics puzzle.
- Controls: Swipe across ropes; numbered rope buttons also provided in adaptation.
- Session estimate: 30 sec–2 min per level. Return hypothesis: Trying a cleaner cut order and collecting optional sparks.
- Difficulty: Pendulum momentum and release timing.
- HTML5 feasibility: High: distance constraints and swept rope cuts. Estimated complexity: Medium.
- Original scope: Swing a battery into a hungry reactor; original anchors, gates and geometry.
- Implementation/QA brief: Release must preserve momentum; test correct delivery, premature cuts, floor miss and restart.

### Neon Rhythm Escape

Reference: [Geometry Dash Lite](https://play.google.com/store/apps/details?id=com.robtopx.geometryjumplite) — RobTop Games. Verified public listing on 2026-10-09.

- Mechanic: One-touch obstacle platforming synchronized with rhythm.
- Controls: Tap/Space to jump; held input can buffer jump in adaptation.
- Session estimate: 20 sec–2 min per attempt. Return hypothesis: Learning a readable obstacle course and improving completion.
- Difficulty: Jump timing over spike/gap sequences.
- HTML5 feasibility: High: authored beat-relative obstacle placement and fixed-step collision. Estimated complexity: Medium.
- Original scope: Paint waveform course with original metronome music, jump arcs and checkpoint-free short rounds.
- Implementation/QA brief: Test buffered jump, ground contact, spike collision, course completion and no dependence on wall-clock sound timing.

### Skyline Jumper

Reference: [Doodle Jump](https://play.google.com/store/apps/details?id=com.lima.doodlejump) — Lima Sky LLC. Verified public listing on 2026-10-09.

- Mechanic: Automatic jumping up platforms with moving or fragile surfaces.
- Controls: Source listing: tilt left/right and tap to shoot; adaptation uses touch halves or arrows.
- Session estimate: 30 sec–3 min per run. Return hypothesis: Higher altitude and exploiting platform routes.
- Difficulty: Lateral landing alignment and changing platform types.
- HTML5 feasibility: High: downward platform crossing checks plus vertical camera. Estimated complexity: Medium.
- Original scope: Armored jumper climbs rooftop ledges; wind and crumbling platforms add original route choices.
- Implementation/QA brief: Test auto-bounce, moving platform landing, camera tracking, height score and falling below camera.

### Turbo Flapper

Reference: [Flappy Bird](https://play.google.com/store/apps/details?id=com.flappybirdfoundation.flappybird) — Flappy Bird Publishing. Verified public listing on 2026-10-09.

- Mechanic: Tap flight through pipes and obstacles; current listing has Classic and Quest modes.
- Controls: Tap/Space for impulse.
- Session estimate: 10 sec–2 min per run. Return hypothesis: One more gate and increasingly consistent control.
- Difficulty: Vertical velocity and gap alignment.
- HTML5 feasibility: High: simple integration and forgiving circle/rectangle collision. Estimated complexity: Low.
- Original scope: Original cape glider crosses ink arches; this is a longer scored run distinct from existing three-gate Flappy Bonus.
- Implementation/QA brief: Test flap impulse, gate score once, gap collision, bounds and restart.

### Bridge Builder

Reference: [Stick Hero](https://play.google.com/store/apps/details?id=com.ketchapp.stickhero) — Ketchapp. Verified public listing on 2026-10-09.

- Mechanic: Hold to extend a bridge, release it across a gap.
- Controls: Hold/release; Space or touch.
- Session estimate: 15 sec–2 min per run. Return hypothesis: Estimating the next distance and hitting perfect centers.
- Difficulty: Bridge too short or too long.
- HTML5 feasibility: High: explicit growth/fall/walk phases and measurable support. Estimated complexity: Low.
- Original scope: Grow telescoping scrap planks between rooftop chimneys; gaps and landing widths vary.
- Implementation/QA brief: Test hold length, unsupported misses on both sides, walking and consecutive platform transitions.

### Reactor Merge

Reference: [2048](https://play.google.com/store/apps/details?id=com.androbaby.game2048) — Androbaby. Verified public listing on 2026-10-09.

- Mechanic: Slide equal numbered tiles together; each tile merges once per move.
- Controls: Four swipes or arrows; Undo/Reset controls in adaptation.
- Session estimate: 2–10 min per board. Return hypothesis: Tactical board planning and larger combinations.
- Difficulty: Avoiding a full board while preserving merge lanes.
- HTML5 feasibility: High: deterministic grid compression and validated move/spawn rules. Estimated complexity: Medium.
- Original scope: Reactor energy board with a short target and optional continued play; original artwork.
- Implementation/QA brief: Test directional moves, one merge per tile, invalid move creates no tile, undo, target completion and blocked-board failure.

### Rooftop Defense

Reference: [Plants vs. Zombies™](https://play.google.com/store/apps/details?id=com.ea.game.pvzfree_row) — ELECTRONIC ARTS. Verified public listing on 2026-10-09.

- Mechanic: Lane defense with limited resources, production and enemy waves.
- Controls: Select unit then tap a lane tile; resource pickups.
- Session estimate: 2–5 min per level. Return hypothesis: Building a better defense and responding to varied waves.
- Difficulty: Placement opportunity cost, resource supply and armored enemies.
- HTML5 feasibility: High: bounded 3-lane simulation; avoid replicating source units or stages. Estimated complexity: High.
- Original scope: Deploy battery generators, bolt turrets and barricades against original rooftop machines.
- Implementation/QA brief: Test spending rejection, generation, cooldowns, projectile hits, waves, unit destruction and base breach.

### Mini Reactor Buddy

Reference: [Pou](https://play.google.com/store/apps/details?id=me.pou.app) — Zakeh. Verified public listing on 2026-10-09.

- Mechanic: Care for a virtual pet through food, cleaning, play and customization.
- Controls: Tap/drag care items; numbered keyboard actions in adaptation.
- Session estimate: 1–5 min per visit. Return hypothesis: Expression, care feedback and trying playful interactions.
- Difficulty: Balancing several needs rather than a twitch obstacle.
- HTML5 feasibility: High: deterministic need rates and bounded local state. Estimated complexity: Medium.
- Original scope: A tiny friendly reactor needs fuel, polishing and play; complete a short care request without real-time neglect penalties.
- Implementation/QA brief: Each action affects a different need; test cooldowns, overfeeding tradeoff, request completion and timeout. No forced offline decay.

## Priority B: thirty additional distinct concepts

These are separate design specifications, not automatic claims of implementation. Broad shared genre primitives are acceptable; the changing state and scoring rules below distinguish each concept from the existing 50 microgames. Water and ball sorting are separate only if their transfer rules remain different. Chase and driving entries require distinct route/destruction/ghost systems to count as different games.

### Stack Scrap

Reference: [Stack](https://play.google.com/store/apps/details?id=com.ketchapp.stack) — Ketchapp. Verified 2026-10-09.

Mechanic: Place moving slabs; overhang trims the next platform. Controls: Tap/Space to drop. Session estimate: 20 sec–2 min. Return hypothesis: A taller, cleaner tower. Difficulty: Shrinking support surface.

Browser scope (Low estimated effort): High: rectangle overlap, camera and slab travel. Build uneven cardboard towers; perfect drops restore a little width. Different from Brake Check: spatial overlap changes all later moves. Test trimming, zero overlap and camera rise.

### Coil Descent

Reference: [Helix Jump](https://play.google.com/store/apps/details?id=com.h8games.helixjump) — VOODOO. Verified 2026-10-09.

Mechanic: Rotate segmented rings to guide a bouncing ball downward. Controls: Drag left/right or arrows rotate. Session estimate: 30 sec–2 min. Return hypothesis: Longer drop chains and level completion. Difficulty: Avoiding unsafe ring sectors.

Browser scope (Medium estimated effort): High: 2D angular slices can replace a 3D tower. Turn a scrap spiral so a bolt falls through safe gaps. Test bounce on safe sectors, hazard contact, continuous drop combo and bottom finish.

### Prism Gate

Reference: [Color Switch: Endless Play Fun](https://play.google.com/store/apps/details?id=com.colorswitch.switch2) — Color Switch Phoenix LLC. Verified 2026-10-09.

Mechanic: Cross moving obstacles only through matching colors. Controls: Tap to rise; timing is inferred from the listing's color-obstacle description. Session estimate: 15 sec–2 min. Return hypothesis: Learning rotating patterns. Difficulty: Matching a changing color while keeping altitude.

Browser scope (Medium estimated effort): High: ring-angle collision with shape labels for accessibility. Send a patterned spark through matching labeled gates. Distinct from Ink Trick: moving spatial barriers. Test mismatched contact and color changes.

### Paper Patrol

Reference: [Paper.io 2](https://play.google.com/store/apps/details?id=io.voodoo.paper2) — VOODOO. Verified 2026-10-09.

Mechanic: Leave safe territory, draw a loop, return to capture space. Controls: Drag/virtual stick; arrows in adaptation. Session estimate: 1–3 min. Return hypothesis: Risk/reward land capture. Difficulty: Exposed trail can be cut.

Browser scope (Medium estimated effort): High: grid flood fill and explicit local AI. Reclaim paint squares from visible patrol robots; label AI as local. Test enclosed-area flood fill, exposed trail collision and capture goal.

### Scrap Sink

Reference: [Hole.io - Original Hole Game](https://play.google.com/store/apps/details?id=io.voodoo.holeio) — VOODOO. Verified 2026-10-09.

Mechanic: Collect small objects to grow enough for larger objects. Controls: Drag/swipe movement. Session estimate: 1–3 min. Return hypothesis: Size growth unlocks new routes. Difficulty: Choosing feasible objects before a timer expires.

Browser scope (Medium estimated effort): High: top-down circles and a spatial grid. Guide a recycling hatch through a junkyard; objects have labeled minimum size. Test size gate, growth, bounded collection and goal failure; no fake multiplayer.

### Coolant Sort

Reference: [Water Sort Puzzle](https://play.google.com/store/apps/details?id=water.sort.puzzle.liquidsortpuzzle) — Xumeng puzzle games. Verified 2026-10-09.

Mechanic: Pour same-color liquid layers into bottles with space. Controls: Tap source then destination. Session estimate: 1–5 min. Return hypothesis: Finding fewer-move solutions. Difficulty: Capacity and color restrictions.

Browser scope (Medium estimated effort): High: small arrays and reverse-generated solvable puzzles. Sort labeled coolant layers with undo and a visible capacity. Do not duplicate ball sorting: pour contiguous runs, variable layer volumes. Test illegal pour and solvable generation.

### Bolt Sort

Reference: [Ball Sort Puzzle®](https://play.google.com/store/apps/details?id=com.GMA.Ball.Sort.Puzzle) — HM Games L.L.C-FZ. Verified 2026-10-09.

Mechanic: Move only the top colored ball into a compatible tube. Controls: Tap source/destination. Session estimate: 1–5 min. Return hypothesis: Planning tube order. Difficulty: Limited spare capacity.

Browser scope (Low estimated effort): High: discrete stacks and reversible generation. Group patterned bolts; one bolt moves per turn, with undo. Test top-only move, matching restriction, full tube rejection and completion.

### Cable Snake

Reference: [Snake.io - Fun Snake .io Games](https://play.google.com/store/apps/details?id=com.amelosinteractive.snake) — Kooapps Games | Fun Arcade and Casual Action Games. Verified 2026-10-09.

Mechanic: Eat to grow and avoid bodies; source adds arena opponents. Controls: Mobile joystick; arrows in adaptation. Session estimate: 30 sec–3 min. Return hypothesis: A longer cable and efficient routes. Difficulty: Increasing body length limits movement.

Browser scope (Low estimated effort): High: grid-based local variant avoids online dependence. Route a growing cable through repair snacks and wall gates. Classic grid snake, not an online imitation. Test growth, no immediate reverse and body collision.

### Brick Barrage

Reference: [Bricks Breaker Quest](https://play.google.com/store/apps/details?id=com.mobirix.swipebrick2) — mobirix. Verified 2026-10-09.

Mechanic: Aim bouncing balls at numbered bricks before they descend. Controls: Drag to aim then release (inferred). Session estimate: 1–5 min. Return hypothesis: Better bank shots and clearing a stage. Difficulty: Brick hit points and limited turns.

Browser scope (Medium estimated effort): High: swept circle/AABB collision with bounded volley count. Launch energy pellets into a descending numbered scrap wall. The listing is an aim-and-volley format, not evidence for a paddle game. Test bank angle, repeated hits and bottom failure.

### Rivet Ring

Reference: [Knife Hit](https://play.google.com/store/apps/details?id=com.ketchapp.knifehit) — Ketchapp. Verified 2026-10-09.

Mechanic: Throw into a spinning target while avoiding attached objects. Controls: Tap/Space throws (inferred). Session estimate: 15 sec–2 min. Return hypothesis: Completing rotating targets. Difficulty: Existing pins occupy landing angles.

Browser scope (Low estimated effort): High: angular intervals and throw travel. Rivet a rotating wheel without striking previous rivets. Different from Satellite Selfie: successful inputs permanently alter collision space. Test occupied angle and reversal.

### Traffic Thread

Reference: [Traffic Racer](https://play.google.com/store/apps/details?id=com.skgames.trafficracer) — skgames. Verified 2026-10-09.

Mechanic: Drive through traffic while collecting distance and near-miss rewards. Controls: Tilt/touch steering in family; arrows and two touch pedals in adaptation. Session estimate: 1–5 min. Return hypothesis: Cleaner near misses and longer distance. Difficulty: Relative vehicle speed and limited road width.

Browser scope (Medium estimated effort): High: top-down continuous steering and traffic gap checks. Steer a delivery trike through irregular local traffic with safe spawn gaps. Different from Metro: analog steering/braking instead of lane jumps. Test traffic collision and near-miss score once.

### Rooftop Hoops

Reference: [Basketball Stars: Multiplayer](https://play.google.com/store/apps/details?id=com.miniclip.basketballstars) — Miniclip.com. Verified 2026-10-09.

Mechanic: Shoot with trajectory control; source has competitive duels and shootouts. Controls: Swipe shot/drag aim (inferred). Session estimate: 1–3 min. Return hypothesis: A cleaner shooting streak. Difficulty: Distance, power and moving defense.

Browser scope (Medium estimated effort): High: local ballistic shootout; online duel infrastructure deliberately omitted. Sink hand-drawn balls through moving rooftop hoops with finite attempts. No advertised multiplayer. Test rim bounce, descending hoop crossing and miss accounting.

### Scrap Pool

Reference: [8 Ball Pool](https://play.google.com/store/apps/details?id=com.miniclip.eightballpool) — Miniclip.com. Verified 2026-10-09.

Mechanic: Cue shots with ball collision, pockets and turn rules. Controls: Aim cue, set power, release (inferred). Session estimate: 3–10 min. Return hypothesis: Position play and accurate shots. Difficulty: Angle, power and next-ball position.

Browser scope (High estimated effort): High for a small local table; full networking is outside scope. Pocket three scrap balls in a short original local puzzle table. Implement circle collision, cushion response, pockets and scratch loss; do not reduce it to click targets.

### Crate Escape

Reference: [Unblock Me](https://play.google.com/store/apps/details?id=com.kiragames.unblockmefree) — Kiragames Co., Ltd.. Verified 2026-10-09.

Mechanic: Slide constrained blocks to clear an exit route. Controls: Drag blocks along their allowed axis. Session estimate: 1–5 min. Return hypothesis: Fewer-move solutions. Difficulty: Spatial blocking and order.

Browser scope (Low estimated effort): High: integer grid occupancy and authored solvable boards. Move workshop crates so a battery cart reaches the exit. Test allowed axis, collision rejection, undo and exact exit recognition.

### Circuit Pairs

Reference: [Flow Free](https://play.google.com/store/apps/details?id=com.bigduckgames.flow) — Big Duck Games LLC. Verified 2026-10-09.

Mechanic: Join matching endpoints while covering a board without crossings. Controls: Drag paths. Session estimate: 1–5 min. Return hypothesis: Efficient complete coverage. Difficulty: Paths compete for limited cells.

Browser scope (Medium estimated effort): High: grid paths and validated authored puzzles. Connect patterned power terminals with separate routes. Different from Live Wire: multiple mutually exclusive paths plus whole-board coverage. Test crossing rejection and full coverage.

### Contraption Delivery

Reference: [Bad Piggies](https://play.google.com/store/apps/details?id=com.rovio.BadPiggies) — Rovio Entertainment Oy. Verified 2026-10-09.

Mechanic: Assemble components then simulate a vehicle reaching a destination. Controls: Tap/drag build parts, launch simulation. Session estimate: 1–5 min. Return hypothesis: Experimenting with different constructions. Difficulty: Mass, propulsion and stability.

Browser scope (High estimated effort): High but costly: restricted component sockets keep scope finite. Choose wheels, motor and balloon positions on a scrap frame, then test delivery. Test assembly validation, propulsion, rollover and endpoint; authored original challenge maps.

### Glass Corridor

Reference: [Smash Hit](https://play.google.com/store/apps/details?id=com.mediocre.smashhit) — Mediocre. Verified 2026-10-09.

Mechanic: Throw projectiles at approaching breakable obstacles. Controls: Tap to aim throw (inferred). Session estimate: 1–5 min. Return hypothesis: Keeping a resource-rich hit streak. Difficulty: Ammo conservation and approaching barriers.

Browser scope (Medium estimated effort): High: projected 2D depth and target sweeps. Break paper-glass panes through a reactor tunnel with limited bolts. Test ammo spending, obstacle depth hit, barrier collision and ammo pickups.

### Echo Commute

Reference: [Does not Commute](https://play.google.com/store/apps/details?id=com.mediocre.commute) — Mediocre. Verified 2026-10-09.

Mechanic: Drive sequential routes while earlier drives replay as traffic. Controls: Two steering inputs (inferred). Session estimate: 2–5 min. Return hypothesis: Planning a cleaner sequence of routes. Difficulty: Your earlier paths constrain later runs.

Browser scope (High estimated effort): High: deterministic sampled ghost paths and steering. Drive three repair carts; earlier routes replay visibly as local ghosts. Not another traffic runner: record/replay must be deterministic. Test ghost collision and cumulative route completion.

### Dune Combo

Reference: [Alto's Odyssey](https://play.google.com/store/apps/details?id=com.noodlecake.altosodyssey) — Noodlecake. Verified 2026-10-09.

Mechanic: One-touch sandboarding with flips, grinding and trick chains. Controls: Tap jump; hold for rotation (family inference). Session estimate: 1–5 min. Return hypothesis: Longer trick combos. Difficulty: Landing angle and linking terrain features.

Browser scope (Medium estimated effort): High: 2D slopes and explicit airborne rotation. Board across paper dunes; choose safe jumps or risky flip chains. Distinct from Rail Grind: rotation landing and linked score multipliers. Test failed landing angle and combo reset.

### Twin Orbit

Reference: [Duet](https://play.google.com/store/apps/details?id=com.kumobius.android.duet) — Kumobius. Verified 2026-10-09.

Mechanic: Rotate two linked objects to avoid incoming obstacles. Controls: Hold either screen side to rotate; arrows. Session estimate: 20 sec–2 min. Return hypothesis: Mastering paired geometry. Difficulty: Both opposite objects must remain safe.

Browser scope (Low estimated effort): High: two circle positions derived from one angle. Steer linked reactor satellites through asymmetric moving walls. Different from timing Orbit Escape: sustained dual-body collision decisions. Test either body hit and opposing holds.

### Tram Network

Reference: [Mini Metro](https://play.google.com/store/apps/details?id=nz.co.codepoint.minimetro) — Dinosaur Polo Club. Verified 2026-10-09.

Mechanic: Draw transit routes and allocate limited vehicles as demand grows. Controls: Drag station connections; resource controls. Session estimate: 5–15 min. Return hypothesis: More efficient networks. Difficulty: Demand, transfer paths and limited capacity.

Browser scope (High estimated effort): High for a small local map; graph routing and queues required. Connect rooftop delivery stops with a few cable trams. Test graph connectivity, passenger delivery, capacity and overload failure. Keep map bounded for mobile.

### Tiny Rooftops

Reference: [Super Cat Tales 2](https://play.google.com/store/apps/details?id=com.neutronized.supercattales2) — NEUTRONIZED. Verified 2026-10-09.

Mechanic: Touch-focused platform exploration with character abilities. Controls: Two-side movement (inferred from family); adaptation auto-vault plus arrows. Session estimate: 2–5 min per stage. Return hypothesis: Exploring hidden routes. Difficulty: Terrain, wall approaches and enemies.

Browser scope (Medium estimated effort): High: authored 2D stages with auto-vault rules. Explore original rooftop rooms with an armored squirrel; collect keys to open exit. Different from endless jumping: horizontal stage, keys and one-way platforms. Test wall auto-vault and locked exit.

### Scrap Chase

Reference: [PAKO - Car Chase Simulator](https://play.google.com/store/apps/details?id=com.treemengames.pako) — Tree Men Games. Verified 2026-10-09.

Mechanic: Survive a car chase inside a bounded arena. Controls: Listing explicitly describes two-button controls. Session estimate: 30 sec–3 min. Return hypothesis: A longer escape and clever turns. Difficulty: Pursuer interception and fixed scenery.

Browser scope (Medium estimated effort): High: bicycle steering and limited predictive AI. Escape paint patrol carts in a workshop courtyard. Use clear pursuer spawn telegraphs. Test steering inertia, wall collision and pursuer interception.

### Wrecking Run

Reference: [Smashy Road: Wanted](https://play.google.com/store/apps/details?id=com.rkgames.smashywanted) — Bearbit Studios B.V.. Verified 2026-10-09.

Mechanic: Vehicle escape through changing environments and escalating pursuit. Controls: Two-direction touch steering (inferred). Session estimate: 1–5 min. Return hypothesis: Finding routes and surviving escalation. Difficulty: Pursuers plus destructible navigation obstacles.

Browser scope (Medium estimated effort): High: top-down local version with capped actors. A heavy scrap truck breaks light fences but must avoid reinforced barriers. Distinct from Scrap Chase through destructible route planning and truck momentum. Test material collision and breach.

### Tether Thread

Reference: [One More Line](https://play.google.com/store/apps/details?id=com.smgstudio.onemoreline) — SMG Studio. Verified 2026-10-09.

Mechanic: Grapple nearby nodes, orbit them, release on a new trajectory. Controls: One-button hold/release (mechanic inference from listing presentation). Session estimate: 10 sec–2 min. Return hypothesis: A clean chain of tangential releases. Difficulty: Release direction and walls.

Browser scope (Medium estimated effort): High: analytic orbit plus momentum preservation. Thread a courier through hook posts with hold-to-tether movement. Different from one-shot Swing Rescue: repeated grapple choices. Test acquisition, tangential release and wall collision.

### Quiet Cast

Reference: [Fishing and Life](https://play.google.com/store/apps/details?id=com.nexelon.fishinglife) — Nexelon inc.. Verified 2026-10-09.

Mechanic: Cast a line and catch fish with simple controls. Controls: Tap/hold cast timing (inferred). Session estimate: 1–5 min. Return hypothesis: Finding deeper catches and improving a calm cast. Difficulty: Cast distance, fish movement and lure reach.

Browser scope (Medium estimated effort): High: small ballistic cast and hook overlap. Catch drifting scrap fish from a painted pier with finite cast attempts. Avoid repeating spring landing: reel movement and hook timing determine catch. Test cast, hook, reel and empty cast.

### Draw Counterweight

Reference: [Brain It On! - Physics Puzzles](https://play.google.com/store/apps/details?id=com.orbital.brainiton) — Orbital Nine Games. Verified 2026-10-09.

Mechanic: Draw physical shapes to satisfy a spatial objective. Controls: Drag drawing. Session estimate: 30 sec–5 min per puzzle. Return hypothesis: Alternative solutions and efficient shapes. Difficulty: Shape mass and contact behavior.

Browser scope (High estimated effort): High with point/segment budget; arbitrary geometry needs careful limits. Draw a weighted plank to tip a battery into a safe receiver. Bound vertex counts; test dynamic shape weight, collision, undo and puzzle condition.

### Ricochet Chord

Reference: [Okay?](https://play.google.com/store/apps/details?id=de.stollenmayer.philipp.Pop_1_1_Android) — Philipp Stollenmayer. Verified 2026-10-09.

Mechanic: Drag a trajectory that clears board elements. Controls: Listing explicitly says drag a line. Session estimate: 30 sec–3 min per puzzle. Return hypothesis: Finding one clean shot. Difficulty: Ricochet angles through multiple targets.

Browser scope (Medium estimated effort): High: swept collision and deterministic reflection. Fire a tuning bolt through original resonant panels; each struck panel contributes a note. Different from Comet Curl: multi-target destructive ricochet puzzle, not final stopping position. Test order-independent target clear.

### Falling Polyforms

Reference: [Tetris®](https://play.google.com/store/apps/details?id=com.n3twork.tetris) — PLAYSTUDIOS US, LLC. Verified 2026-10-09.

Mechanic: Place and rotate falling blocks to clear completed lines. Controls: Swipe/rotate/drop (source listing). Session estimate: 2–10 min. Return hypothesis: Better packing and longer survival. Difficulty: Increasing fall rate and holes.

Browser scope (Medium estimated effort): High: grid collision and deterministic piece queue. Use an original small set of scrap polyforms and original rotation/board design. Avoid borrowed branding and presentation. Test wall rotation rejection, line clear, stack overflow and bag fairness.

### Fuse Survey

Reference: [Minesweeper GO - classic game](https://play.google.com/store/apps/details?id=com.EvolveGames.MinesweeperGo) — evolvegames. Verified 2026-10-09.

Mechanic: Reveal safe cells using adjacent hazard counts; mark suspects. Controls: Tap reveal; explicit flag mode. Session estimate: 1–5 min. Return hypothesis: Reasoned solutions and cleaner deduction. Difficulty: Local count constraints and unknown cells.

Browser scope (Low estimated effort): High: small seeded board plus first-click safety. Survey a reactor floor for unstable fuses with numbered neighbors and undo before detonation. Test first-click safe generation, flood reveal, flags and hazard loss; label guessing if a board lacks proof of deduction.

## Verification and release boundary

The baseline metadata inspected was `microgames/pack_a.json` and `microgames/pack_b.json` (25 entries each). The briefs above intentionally add sustained physics, spatial planning, resource tradeoffs or staged progression beyond those short microgames. Turbo Flapper retains the requested family while expanding the existing Flappy Bonus into a longer scored course; it should not be counted as new solely for a new background or timer. Test evidence belongs in the game audit and implementation progress, not in this research catalog. Research references confer no asset license or permission to redistribute proprietary content.

