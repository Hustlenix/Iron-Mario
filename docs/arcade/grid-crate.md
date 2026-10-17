# Grid X and Crate Shift — Wave A

Both games are independent Canvas modules at 480×320. They use the shared OnlyEducation palette and existing original pixel sprites. No ROMs, emulators, copied game code, copied commercial levels, or third-party game imagery are included.

## Grid X

Three noughts-and-crosses terminals form a complete run. The player is X and starts each round. Make a horizontal, vertical, or diagonal line of three; a draw also advances. A terminal win ends the run. Clear all three terminals to win the run.

- Round 1, Curious: chooses a seeded random legal square. The opening round can be beaten.
- Round 2, Tactical: first takes a winning square, then blocks an immediate player win; otherwise chooses a seeded legal square.
- Round 3, Expert: searches every legal continuation using minimax. Sound defence earns a draw and clears the terminal.
- Score: a player win earns `200 × round`; a draw earns `80 × round`.

Controls: tap any empty square, or use arrows/WASD/Dpad to move the gold cursor and Space/Enter/Action to place X. After a successful round, tap **Next Terminal** or press Action. The host owns pause and restart. Pointer clicks outside the board or while the AI is thinking cannot place marks.

The game board starts at native `(36,52)` and each square is 68×68. A square centre is `(70 + column × 68,86 + row × 68)`. The next-round button occupies `(274,220,184,38)`. A fixed test RNG returning zero permits the first-round player sequence `[0,2,1]`, with 0.5 seconds of AI thinking between moves. Normal platform seeds can choose other moves; browser tests should read the board and choose legal input rather than assume that fixed fixture sequence.

Historical note: the Computer History Museum records Alexander Douglas's OXO on Cambridge's EDSAC in 1952, played through a rotary dial with a CRT board display. Grid X is a new educational interpretation of noughts and crosses, not an OXO emulator. [Computer History Museum — 1952 timeline](https://www.computerhistory.org/timeline/1952/).

## Crate Shift

Move the workshop scout around five original warehouses. Push every crate onto a gold pad. Only one crate can be pushed at a time, crates cannot be pulled, and walls block both player and crates. Completed crates have a teal lower marker. The HUD reports steps, pushes, filled pads, and score.

Controls: arrows/WASD/Dpad move. Tapping an immediately adjacent tile also moves one step; distant clicks do not teleport. Hold a direction for controlled repeat after 0.24 seconds. Z/Backspace/Secondary or the canvas **Undo** button restores the previous legal move. After solving a room, tap **Next Room** or press Action.

Undo also reverses a room-completion score before advancing, so a player cannot farm points by repeatedly undoing and repeating the final push. History is reset after the player explicitly advances to the next room. A non-goal crate pushed into a wall corner displays a jam warning; it is still recoverable with Undo. There is no arbitrary timer or forced failure while a recoverable history exists. The final room's actual goal completion wins the run.

Score per room: `max(100,500 + zeroBasedRoom × 100 - steps × 3 - pushes × 2)`. The score rewards efficient paths but does not require optimal play.

These layouts were authored for this implementation and independently checked with a breadth-first solver. The solver is test-only. It does not run in the shipped game.

| Room | Name | Crates | Shortest verified move sequence | Moves |
| --- | --- | ---: | --- | ---: |
| 1 | First delivery | 1 | `RR` | 2 |
| 2 | Twin bays | 2 | `LURDRU` | 6 |
| 3 | Side passage | 2 | `LURRDRU` | 7 |
| 4 | Around the bend | 3 | `LUUDRRDRULULLULUR` | 17 |
| 5 | Last dispatch | 3 | `LUUULURRRDRDLLDDLUUUDRRUULL` | 27 |

`L/R/U/D` mean one left/right/up/down key press. Release each key before the next press. Press Action after rooms 1–4 to begin the next one. For pointer QA, tile centres are `(40 + column × 32,58 + row × 32)`. The Undo button occupies `(328,204,128,32)`; Next Room occupies `(328,246,128,36)`.

Historical note: the original Sokoban official history lists December 1982 releases on PC-8801, FM-7, and PC-8001mk2. This page supplies the contextual release year; Crate Shift's layouts, art treatment, and implementation are original. [Sokoban official release history](https://www.sokoban.jp/history.html).

## Verification

Run from the requested project directory:

```powershell
rtk proxy node --test tests/arcade/grid-crate.test.mjs
```

The 13 tests cover winning-line evaluation, beginner beatability through input, tactical wins and blocks, expert search against every reachable legal player continuation, keyboard and pointer filtering, seed determinism, full three-round completion, a real AI loss outcome, independently solved warehouse levels, invalid maps and illegal moves, undo and score restoration, reversible corner jams, adjacent pointer movement, and all five room solutions through game input. Boundary/outcome fixtures are explicitly distinct from browser input evidence. No browser success is claimed by these Node tests.

Source references were opened and checked on 2026-10-15.
