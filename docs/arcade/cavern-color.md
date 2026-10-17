# Dark Cavern and Color Steps — Wave B

Two independent 480×320 games built for the existing shared runtime. They own no DOM listeners, external requests, storage, or timers. Runtime pause, restart, sound settings, saves, and touch controls remain platform features.

## Dark Cavern

An expedition through an original twelve-room graph: a ring with six opposite-room tunnels. Each room has three neighbours. One creature, two pits, and two crystal caches occupy distinct seeded rooms. The entrance and its immediate neighbours are always free of lethal hazards. Generation verifies that both caches and a safe firing position can be reached without entering a hazard.

Read the neighbouring-room warnings, locate the creature, shoot it from an adjacent room, collect both caches, then return to Room 01. Scraping indicates an adjacent creature; cold air indicates an adjacent pit; a glimmer indicates an adjacent cache. These signals can overlap and require deduction across rooms. Discovered room numbers stay lit on the map. The creature stays in place, so previously observed warnings remain useful.

Controls:

- Left/right or up/down: select one of the three tunnel cards.
- Space/Enter/Action: enter the selected tunnel in Walk mode, or fire into it in Aim mode.
- Z/Backspace/Secondary: switch Walk/Aim mode. A large canvas mode button does the same.
- Tap a tunnel card: select and use that tunnel in the current mode.

Three bolts are available. Entering a pit or the living creature ends the expedition. Three missed shots also end it. A successful shot disperses the creature, making its room safe. New rooms earn 10 points, caches 150 each, the creature 250, and successful return earns `max(100,400 - moves × 5)`. Merely shooting or collecting a cache does not mark the game won.

Native canvas targets: tunnel cards start at x20, x172, x324, each 136×40 at y262. Mode button is `(288,168,168,30)`. Tests use seeded map observations only to choose real inputs; they do not change the game state.

Seed 1972 walkthrough, using the visible one-based room numbers: `01 → 12 → 11`, switch to Aim, fire into Room 10, return to Walk, then `11 → 05 → 04 → 03 → 02 → 01`. The two caches are collected along this route. Starting with this route earns 975 points; extra exploratory movement changes the return bonus.

Historical context: the original People's Computer Company publication, archived by the Computer History Museum, credits Greg Yob, mentions its 1973 publication, and describes Wumpus as a graph-based world. Dark Cavern uses its own twelve-room topology, expedition objective, interface, generation rules, and implementation. No historical BASIC listing was copied. [Computer History Museum — People's Computer Company, volume 6 number 5](https://archive.computerhistory.org/resources/access/text/2017/09/102661095/102661095-05-v6-n5-acc.pdf). The museum's indexed text was available during research; direct PDF retrieval failed, so no claim is made that its full scan was visually reviewed.

## Color Steps

A small repair robot paints a pyramid while a scrap bug chases it. Three pyramids form a full run: four rows with one coat per tile, five rows with one coat, then five rows requiring two coats. The third pyramid's first coat is teal and the finished coat is gold. Repeatedly visiting an already completed tile adds no score.

The four keys map to diagonal hops:

| Input | Hop | Coordinate change |
| --- | --- | --- |
| Left / A | Down-left | row + 1, same column |
| Down / S | Down-right | row + 1, column + 1 |
| Up / W | Up-left | row − 1, column − 1 |
| Right / D | Up-right | row − 1, same column |

Tap an adjacent diamond to hop there. Distant taps do not teleport. Space/Enter/Action uses one recall per pyramid: return to the peak and briefly delay the bug. After completing a pyramid, the same Action button advances. The screen explicitly shows these controls.

There are three lives. Falling off an edge or touching the bug costs a life. Respawn preserves completed paint, provides temporary protection, and delays the enemy. The bug starts after a grace period and follows shortest graph routes toward the player. It moves faster in each pyramid. Filling every required coat across all three pyramids wins; losing all three lives loses. A new coat earns `20 × pyramid` and completing a pyramid earns `250 × pyramid`.

Tile centres are `x = 178 + (column − row / 2) × 58`, `y = 62 + row × 41`. Pointer hit testing uses the diamond shape, not an oversized rectangular region. Recall/Next is `(338,189,124,32)`.

Historical context: the American Classic Arcade Museum's interview with original developer Warren Davis records Q*bert's 1982 release and describes the development of hopping over a pyramid and changing cube colours. Color Steps uses an original robot and bug, separate code, different progression, recall rules, and palette. [American Classic Arcade Museum — Warren Davis interview](https://www.classicarcademuseum.org/q-bert).

## Assets and verification

Dark Cavern draws its graph and interface directly. Color Steps uses the existing original `pieces_robot` and `pieces_bug` sprites from the shared history kit. No new licensed pack pixels are introduced by this pair.

```powershell
rtk proxy node --test tests/arcade/cavern-color.test.mjs
rtk proxy node tools/cavern_color_browser.cjs
```

The 15 Node tests cover graph symmetry/connectivity, 250 deterministic solvable cave layouts, warning correctness, genuine expedition completion, misses and hazards, pointer filtering, seeded reproducibility, legal pyramid geometry, scoring, falls/lives, recall, enemy pursuit/collision, and complete three-pyramid progression with the pursuer active. A deterministic full Color Steps solution reaches 3980 points with one remaining life; no enemy or progress state is injected for that solve.

The browser script is a separate proof layer. It opens the real homepage cards, uses real key presses/canvas clicks/touch events, observes the read-only QA snapshot, and records its actual results in `build/arcade/browser/cavern-color-report.json`. It checks a real win and loss for each game, pause/resume, restart, resource disposal, 375px layout, and touch controls. Browser screenshots are saved alongside that report. Historical sources checked 2026-10-17.
