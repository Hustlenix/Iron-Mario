# IRON-MARIO

A WarioWare-style microgame gauntlet starring Mario's armored twin — a red-and-gold hero thrown into one absurd ten-second challenge after another. Collect arc-reactor shards, whack teleporting targets, dodge sweeping laser beams, and keep your reactors burning through a back-to-back gauntlet where every failure costs a life. Clear all three microgames with power left and you win; run out and the suit powers down.

Built with [Godot 4.7.1](https://godotengine.org/) (1280x720).

## Game Idea

Inspired by the rapid-fire microgame genre (WarioWare Inc.): zero tutorials, zero mercy. Each microgame is a single absurd goal with a ticking clock — then it's on to the next.

- Your lives are **five glowing arc-reactor icons**.
- Pickups are **gold arc-reactor shards**.
- The hero is a tiny armored Mario, tinted in the suit's red and gold.

**Core loop:** Title (**START / SETTINGS / QUIT**) → intermission (reactors + level + 5s countdown) → microgame (10s clock) → intermission → microgame → intermission → microgame → **YOU WIN!** or **GAME OVER**.

Fail a microgame and you lose a reactor — the failed mission replays. Survive every microgame with at least one reactor intact to win. **PLAY AGAIN** resets the gauntlet.

## How to Play

| Action | Keys |
| --- | --- |
| Move left | `A` / `←` |
| Move right | `D` / `→` |
| Jump | `Space` / `W` |

`SETTINGS` toggles fullscreen. `QUIT` closes the game.

## Microgames

1. **The Platformer Gauntlet** — Move and jump around a three-level platform course and snag **3 gold arc-reactor shards** before the 10s timer runs out.
2. **Reactor Tag** — Click the teleporting gold target **5 times** before time runs out. The target moves when hit — and on its own every 0.6s — so it never stays still.
3. **Dodge the Lasers** — Survive **10 seconds** as three red laser bars sweep the arena; move with arrows/WASD, jump with Space/W. Every brush with a beam costs a reactor.

## How to Run

Open the project folder in the Godot 4.7.1 editor, or run it directly:

```
Godot_v4.7.1-stable_win64.exe --path "C:\Users\LalithReddy.b\Iron-Mario"
```

## Current State

Playable prototype: the complete title → intermission → microgame → win/lose flow runs end to end. All art is **original and created for this project** (hand-drawn SVG assets: armored hero sprite, arc-reactor life icons, shard collectibles, clicker target, and four background scenes). Git history is managed via GitHub Desktop (commit + push as you work).

## Stardance Submission Checklist

| # | Requirement | Status |
| --- | --- | --- |
| 1 | Made in Godot | Done (Godot 4.7.1) |
| 2 | Minigames respond to player input | Done (keyboard + mouse) |
| 3 | Minimum 5 hours spent coding | Tracked via Hackatime |
| 4 | Minimum 2 minigames | Done (platformer + clicker + dodge = 3) |
| 5 | Implement your own assets | Done (original SVGs in `assets/`) |
| 6 | A well-written README | This file |
| 7 | None to minimal AI usage | See note below |
| 8 | An original Winner Scene and Death Scene | Done (`winner_scene.tscn`, `death_scene.tscn`) |

**Note on AI usage (requirement 7):** the game structure, design, and art were built as a learning exercise with AI assistance. Before submitting, review the scripts in `scenes/` and `scripts/` and make the project your own — rewrite the scripts by hand, tweak the art in an editor, and adjust the design so you can explain every line. The AI was used to set up scaffolding and fix engine bugs, not to replace your learning.

## Next Steps

- More microgames to keep the gauntlet sprinting (timing, memory, etc.)
- Snappy audio stingers (countdown, pickup, game over)
- A settings scene with volume/controls (current button is a fullscreen toggle)
- Polish the SVG art (shading, animation, backgrounds)

## Credits

WarioWare-style microgame genre; game loop and intermission design based on the "How to Make Your First WarioWare-style Game" tutorial — rethemed as an Iron Man + Mario crossover. Built for the Stardance Challenge.