# Byte Munch and Brick Burst

These are independently implemented, original Canvas games for OnlyEducation. They are complete score-chasing modes with genuine losses, progression, deterministic restarts, keyboard controls and the shared touch controls. Neither module owns listeners, timers, storage, pause or restart; the host owns those.

## Historical references

- [Museum of the Game: Blockade (1976)](https://www.arcade-museum.com/Videogame/blockade): a directional line-survival game in which a wall or trail collision ends play. Byte Munch develops the broad grid-survival idea as a single-player food-and-growth game; it is not a reproduction of Blockade's competitive rules or artwork.
- [The Strong National Museum of Play: Steve Jobs, Breakout Pioneer](https://www.museumofplay.org/blog/steve-jobs-breakout-pioneer/): historical context for the 1970s paddle-and-wall genre.
- [The Strong collection, hosted by Google Arts & Culture: Arcade game, Breakout](https://artsandculture.google.com/asset/arcade-game-breakout/lAGqT3nqUqeBig?hl=en): the core paddle, ball and brick-wall interaction. Brick Burst adds its own colors, patterns, reinforced bricks, upgrades and progression.

Sources were read on 15 October 2026. They informed mechanics and history, not copied pixels, audio or code. All drawing in these two modules is original integer-aligned Canvas geometry using the shared navy, paper, teal, gold and coral palette.

## Byte Munch

- **Goal:** collect gold bytes, grow a longer train, and survive increasingly quick circuits. A full free board is a genuine completion win.
- **Controls:** arrows/WASD or host D-pad. A canvas tap chooses the dominant direction from the head to the tap. Hovering alone does nothing.
- **Rules:** walls, posts and the body end the run. The tail's vacated cell remains a legal destination. Reverse directions are rejected and up to two perpendicular turns can be buffered.
- **Score:** gold food gives 20 × current circuit; every fifth food is coral and gives 50 × current circuit.
- **Progression:** every five foods raises the circuit. Movement starts at 0.16 seconds per cell and caps at 0.075. A circuit change schedules two sparse posts with 1.2 seconds of warning. Posts are cancelled if they would appear under the body, food or within three cells of the head.
- **Fair spawning:** food prefers cells currently connected to the head. If a temporarily coiled body blocks that flood fill, free cells remain eligible; a small flood fill never causes a false win.
- **Native board:** 28 × 16 cells, 16 pixels each, inside a 480 × 320 frame.

## Brick Burst

- **Goal:** clear successive brick waves and preserve three lives.
- **Controls:** left/right arrows, A/D or host D-pad; hold and drag on the canvas to move. Space/Enter/host action or a canvas tap serves a docked ball.
- **Aiming:** paddle center sends the ball mostly upward; paddle edges create wider angles. A small horizontal minimum avoids perfectly vertical stalls.
- **Collision:** the square pixel ball advances in substeps of at most three pixels. Top, bottom and side normals are resolved separately. The paddle catches only descending balls crossing its top; it cannot rescue a ball from underneath.
- **Progression:** four recurring wave silhouettes; increasing speed and rows; reinforced two-hit bricks from wave two; three-hit top bricks from wave five. Every third wave grants one life, capped at five.
- **Score:** each brick contact gives 5 × wave. Destruction gives (20 + capped combo bonus) × wave. Clearing gives 200 × wave. Upgrades give 25.
- **Upgrades:** marked bricks drop a W chip (116-pixel paddle for 12 seconds) or S chip (72% ball travel for 10 seconds). Missing a drop does not cost a life.
- **Loss:** passing below the arena consumes a life and docks a fresh ball; the third miss ends the run. A new wave waits for a deliberate serve.
- **Native arena:** 480 × 320; compact HUD and controls stay inside this frame.

## Automated verification

Run from the project root:

```text
rtk proxy node --test tests/arcade/byte-brick.test.mjs
```

20 tests pass. They cover seeded reproducibility, food/growth/score, circuit changes, warning cancellation, reversal protection, turn buffering, vacating-tail legality, wall/body/post loss, board completion, tap controls, launch, paddle bounds, edge aiming, underside misses, fast-ball tunnelling, side collisions, final-brick progression, extra lives, upgrade effects/expiry and frozen terminal states.

The tests use explicit state fixtures for rare collision boundaries and full-board completion. Those fixtures are unit-test evidence, not evidence of a person playing through every wave.

## Browser review and integration strategy

Both real modules were loaded into Chromium, created with a seeded API and drawn on native 480 × 320 Canvas surfaces. Initial and progressed frames were visually inspected. Byte Munch rendered circuit two with warning cells; Brick Burst was simulated through a real brick contact and rendered its score, trail and remaining bricks. All four frames drew without a runtime exception. This isolated render review does not substitute for host controls testing.

Host browser checks should:

1. Open each real catalog card and start through the host ready screen.
2. Byte Munch: press right/up/left through separate simulation frames; assert the read-only snapshot changes direction and head position. Run into a wall and verify the host loss overlay; restart and compare the initial seeded board.
3. Brick Burst: start, serve with Space, move the paddle with held keys, catch a descending ball and observe positive brick-hit score. Let a ball miss and verify lives decrease; after three misses verify the loss overlay. Restart should restore lives and bricks.
4. Pause each game, sample its state twice, verify no simulation advances, then resume.
5. At 375px viewport width, use the host D-pad and action buttons; test Brick Burst canvas drag with a touch pointer.
6. Check focus visibility, game instructions, no page errors, no missing module requests and no horizontal overflow.

All browser assertions should use actual input for host behavior. Fixture-specific unit outcomes are recorded separately above.
