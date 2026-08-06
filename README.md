# IRON-MARIO

A WarioWare-style microgame gauntlet starring Mario's armored twin — a red-and-gold hero thrown into one absurd ten-second challenge after another. Collect arc-reactor shards, whack teleporting targets, dodge sweeping laser beams, parry a sweeping gauge, and keep your reactors burning through a back-to-back gauntlet where every failure costs a life. Clear all four microgames with power left and you win; run out and the suit powers down. Win rounds to build a **streak**, then hit **CONTINUE (HARDER)** to loop back through with a faster clock.

Built with [Godot 4.7.1](https://godotengine.org/) (1280x720).

## Game Idea

Inspired by the rapid-fire microgame genre (WarioWare Inc.): zero tutorials, zero mercy. Each microgame is a single absurd goal with a ticking clock — then it's on to the next.

- Your lives are **five glowing arc-reactor icons**.
- Pickups are **gold arc-reactor shards**.
- The hero is a tiny armored Mario, tinted in the suit's red and gold.

**Core loop:** Title (**START / SETTINGS / QUIT**) → intermission (reactors + level + 5s countdown) → microgame (10s clock) → intermission → microgame → … → **YOU WIN!** or **GAME OVER**.

Fail a microgame and you lose a reactor — the failed mission replays. Survive all four microgames with at least one reactor intact to win. **PLAY AGAIN** resets the gauntlet; **CONTINUE (HARDER)** raises the loop counter and starts a fresh gauntlet: time limits drop (10s → 9s → 8s, floor 5s), the clicker's target runs away faster, and the dodge lasers sweep quicker. **BEST STREAK** persists between runs via a save file.

## How to Play

| Action | Keys |
| --- | --- |
| Move left | `A` / `←` |
| Move right | `D` / `→` |
| Jump | `Space` / `W` |

`SETTINGS` opens the settings scene (volume slider, controls reference, progress reset). `QUIT` closes the game.

## Microgames

1. **The Platformer Gauntlet** — Move and jump around a three-level platform course and snag **3 gold arc-reactor shards** before time runs out.
2. **Reactor Tag** — Click the teleporting gold target **5 times** before time runs out. The target moves when hit — and on its own every 0.6s — so it never stays still.
3. **Dodge the Lasers** — Survive as three red laser bars sweep the arena; move with arrows/WASD, jump with Space/W. Every brush with a beam costs a reactor.
4. **Reactor Parry** — A gold marker sweeps back and forth across the arena. Press **Space/W when the marker is inside the green zone** **3 times** before time runs out. Miss and the marker just resets — no life penalty, but the clock keeps ticking.

## Audio

All sound is **generated from scratch** by `tools/gen_audio.ps1` (16-bit PCM mono 22050 Hz WAVs synthesized with `BinaryWriter` — sine tones with quick attack/decay envelopes, peaks around -10 dB). No external audio files. Assets: `tick.wav` (countdown blip), `win.wav` (rising arpeggio), `fail.wav` (descending sting), `bgm.wav` (16-note original loop on the title screen). Regenerate anytime with:

```
powershell -ExecutionPolicy Bypass -File tools\gen_audio.ps1
```

## Settings

The settings scene (`settings_scene.tscn`) has a master volume slider (saved to `user://save.dat`), a controls reference, and **RESET PROGRESS** (clears best streak, streak, and loop count). Best streak and volume persist across restarts.

## How to Run

Open the project folder in the Godot 4.7.1 editor, or run it directly:

```
Godot_v4.7.1-stable_win64.exe --path "C:\Users\LalithReddy.b\Iron-Mario"
```

## Continuous Integration

Pushing to `main` triggers `.github/workflows/deploy.yml`, which imports the project, exports the Web build headlessly, and publishes it to the `gh-pages` branch — the live site updates automatically with no local export needed.

## Current State

Playable prototype: the complete title → intermission → microgame → win/lose flow runs end to end, with difficulty loops, streaks, save persistence, generated audio, and a settings scene. All art is **original and created for this project** (hand-drawn SVG assets: armored hero sprite, arc-reactor life icons, shard collectibles, clicker target, parry bar and zone, and four background scenes).

## Stardance Submission Checklist

| # | Requirement | Status |
| --- | --- | --- |
| 1 | Made in Godot | Done (Godot 4.7.1) |
| 2 | Minigames respond to player input | Done (keyboard + mouse) |
| 3 | Minimum 5 hours spent coding | Tracked via Hackatime |
| 4 | Minimum 2 minigames | Done (platformer + clicker + dodge + parry = 4) |
| 5 | Implement your own assets | Done (original SVGs in `assets/`) |
| 6 | A well-written README | This file |
| 7 | None to minimal AI usage | See Development Log below |
| 8 | An original Winner Scene and Death Scene | Done (`winner_scene.tscn`, `death_scene.tscn`) |

## Development Log

The game structure, design, and art were built as a learning exercise with AI assistance: scaffolding, scene wiring, and engine-API debugging were done with help, then tuned by hand. Before submitting, make the project your own — especially these three files, which you should **rewrite yourself by hand**:

1. `scenes/minigame_1.gd` — the platforming collect-a-thon: timer, pickups, win/lose flow, difficulty scaling.
2. `scenes/minigame_4.gd` — the parry minigame: sweeping tween, hit detection, zone placement, round logic.
3. `scenes/timer_screen.gd` — the intermission: countdown, lives display, and the routing that chains the gauntlet.

**Rewrite checklist** for each file: read it line by line until you can explain it, rewrite it from scratch in your own words (same behavior, your structure), then change **one** behavior (e.g. shards needed, parry zone width, intermission length) and confirm it works in-game. Also give the SVG art in `assets/` a pass in an editor. The AI was used to set up scaffolding and fix engine bugs, not to replace your learning.

## Next Steps

- More microgames to keep the gauntlet sprinting (memory, aim, etc.)
- Per-minigame art and animations (the parry bar/zone are the newest assets)
- Balanced difficulty curve per loop (zone speed scaling)
- Polish the SVG art (shading, animation, backgrounds)

## Credits

WarioWare-style microgame genre; game loop and intermission design based on the "How to Make Your First WarioWare-style Game" tutorial — rethemed as an Iron Man + Mario crossover. Built for the Stardance Challenge.
