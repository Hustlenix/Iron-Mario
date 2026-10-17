# Stackfall: the block workshop

Stackfall is an independently written falling-block puzzle for OnlyEducation. It uses original Canvas-drawn workshop blocks, a navy/cream interface, and a short-session goal: clear **24 rows** before the stack reaches the ceiling. It does not import another game's code, art, music, layout, or rotation table.

## Historical context

Falling-block arrangement became a defining computer-puzzle idea in the 1980s. The Strong National Museum of Play describes Alexey Pajitnov's 1984 puzzle as an adaptation of his interest in pentominoes; its complete-row mechanic is the historical reference for this original implementation. [The Strong: Tetris](https://www.museumofplay.org/games/tetris/). MoMA also identifies the work and creator as 1984. [MoMA collection record](https://www.moma.org/collection/works/152403).

These references explain the design lineage. They are not asset sources or affiliation claims. No museum artwork or original-game assets are bundled.

## Rules and controls

- Left/right arrows or A/D: move. Hold to repeat after a short initial delay.
- Up arrow or W: rotate clockwise; Z: counterclockwise.
- Down arrow or S: soft drop, earning one point per cell.
- Space/Enter: hard drop to the outlined ghost, earning two points per cell.
- Touch: the host's directional pad and action/secondary buttons map to the same commands.
- A filled row clears. One/two/three/four simultaneous rows earn 100/300/550/900 points multiplied by the current gear. Consecutive clears add a chain bonus.
- Every four cleared rows increase gravity. Clear 24 rows to complete the workshop.
- Three upcoming pieces are visible. Each shuffled seven-piece bag contains all seven shapes once; the supplied host seed reproduces the run.
- A grounded piece allows 0.34 seconds of adjustment, with at most eight grounded movement/rotation resets. An original bounded kick search allows wall and floor turns. A blocked spawn or locking above the ceiling ends the run.
- Pause and restart remain host controls. The game has no timers, DOM listeners, storage, external requests, or cleanup requirements.

## Integration

Module: `onlyeducation/arcade/games/stackfall.js`. ESM export `createGame(api)` returns `{ state, update, draw }`. Fixed-step input and deterministic RNG follow `onlyeducation/arcade/CONTRACT.md`. All rendering fits a 480×320 Canvas. Board cells are 14 native pixels and the board is 10×18. The ghost, score, line target, level, queue, and controls remain visible during play.

Stackfall's pieces are original pixel geometry rendered with Canvas; neither licensed pack characters nor asset-lab-only concept art are presented as a playable mechanic. The host can place its shared asset frames around the game without changing game logic.

## Validation and browser review

Run `rtk proxy node --test tests/arcade/stackfall.test.mjs` from the requested project root. Tests cover seeded replay and complete bags, walls/floor/stack collision, inverse rotations, wall/floor kicks, blocked rotations, ghost-to-hard-drop correspondence, row collapse, four-line scoring, soft-drop response, progressive gravity, bounded lock delay, held movement, both topout routes, victory, and terminal input freeze. Tests that set board state are explicit boundary fixtures, not claims of human/browser completion.

Host browser checks should start a normal seeded game, move/rotate/drop using keyboard events and touch buttons, verify next/ghost update, pause and resume, restart, verify no scrolling while control input is active, and inspect both desktop and narrow touch layouts. A long enough unassisted stationary run should top out; a successful 24-line run requires actual play or clearly labeled logic fixtures. The renderer should be smoke-tested for console errors and Canvas overflow at native and mobile scale. The root integration test supplies browser evidence; the unit tests alone do not establish it.
