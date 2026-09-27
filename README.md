# SUPER-MICRO HEROES

> **Original work.** Super-Micro Heroes is an independent, non-commercial project.
> Every character, sprite, sound, and asset in it was created for this game. It is not
> affiliated with, sponsored by, or endorsed by Nintendo, Marvel, DC, or any film, comic,
> or game publisher, and it contains no licensed characters, artwork, or audio.

A rapid-fire microgame gauntlet starring a cast of tiny original heroes, each one thrown
into a single absurd ten-second challenge after another. Snag power shards, whack
teleporting targets, dodge sweeping laser beams, parry a sweeping gauge, and keep your
cores burning through a back-to-back gauntlet where every failure costs a life. Clear all
four microgames with power left and you win; run out and the suit powers down. Win rounds
to build a **streak**, then hit **CONTINUE (HARDER)** to loop back through with a faster
clock.

Built with [Godot 4.7.1](https://godotengine.org/) (1280x720).

## Game Idea

Inspired by the rapid-fire microgame genre: zero tutorials, zero mercy. Each microgame is
a single absurd goal with a ticking clock — then it's on to the next.

- Your lives are **five glowing power-core icons**.
- Pickups are **gold power shards**.
- Your hero is one of **nine original micro heroes**, or **Flappy** for a bonus round.

**Core loop:** Title (**START / SETTINGS / QUIT**) → intermission (cores + level + 5s
countdown) → microgame (10s clock) → intermission → microgame → … → **YOU WIN!** or
**GAME OVER**.

Fail a microgame and you lose a core — the failed mission replays. Survive all four
microgames with at least one core intact to win. **PLAY AGAIN** resets the gauntlet;
**CONTINUE (HARDER)** raises the loop counter and starts a fresh gauntlet: time limits drop
(10s → 9s → 8s, floor 5s), the clicker's target runs away faster, and the dodge lasers
sweep quicker. **BEST STREAK** persists between runs via a save file.

## The Roster

Pick a hero on the title screen; your choice is remembered between runs. The nine heroes
are original designs built around four shared power families, so every suit reads
differently while the power behaviour stays consistent.

| Hero | Power family | Power | What it does | Cooldown |
| --- | --- | --- | --- | --- |
| **Dart** | DASH | Lunge | Arcs forward and up; passing through the target resolves it | 3s |
| **Bolt** | DASH | Overdrive | A long flat burst — the fastest dash — with brief invincibility | 3s |
| **Echo** | REVEAL | Sonar | Reveals the next shard, the next laser, or the parry zone | 3s |
| **Frost** | REVEAL | Deep Freeze | Freezes moving hazards, the target, or the parry bar for a second | 3s |
| **Tether** | REACH | Tether | A long-range auto-hit that also pulls you toward the goal | 3s |
| **Snap** | REACH | Snap | An instant long-range auto-hit | 3s |
| **Aegis** | REACH | Aegis | Slower than the other reachers, but it absorbs one hit | 3s |
| **Pulse** | BLAST | Pulse | Pulls shards in, vaporises the target, deletes a laser, snaps the parry bar home | 3s |
| **Lance** | BLAST | Lance | The pulse at longer range, on a longer cooldown | **4s** |

**Flappy** is the bonus character: no power, a different whole game.

Art lives in `assets/heroes/<id>.svg` — nine hand-authored 64×64 sprites, dark outline
weight, and a distinct silhouette per hero so they stay readable at gameplay size. See
`assets/heroes/README.md` for the art notes.

## How to Play

| Action | Keyboard | Touch |
| --- | --- | --- |
| Move left | `A` / `←` | on-screen ◀ |
| Move right | `D` / `→` | on-screen ▶ |
| Jump | `Space` / `W` | on-screen JUMP |
| Fire power | `Shift` / `E` | *not bound yet* |

`SETTINGS` opens the settings scene (volume slider, touch controls, controls reference,
progress reset). `QUIT` closes the game.

### Mobile and web

The game is **landscape-only**. On a phone or tablet:

- The on-screen buttons appear automatically once you touch the screen, so hybrid laptops
  that report a touchscreen still get them on first tap.
- Held buttons drive the same `left` / `right` / `jump` actions the keyboard uses, so every
  microgame works by touch as well as by key.
- The `power` action is **keyboard-only for now** — the hero powers have no on-screen
  button, so a touch player never fires one. See Next Steps.
- Buttons are sized in **physical** pixels, so they stay at least 88 px wide after the
  game letterboxes to fit your screen — the 64 px accessibility floor is never breached.
- Rotate back to landscape to play. Held in portrait, the game shows a rotate prompt
  instead of an unplayable view.

Touch controls can be switched off in `SETTINGS`. The web build also installs as a
Progressive Web App (standalone window, landscape, with icons), so it can be added to a
phone home screen.

## Microgames

1. **The Platformer Gauntlet** — Move and jump around a three-level platform course and
   snag **3 gold power shards** before time runs out.
2. **Target Tag** — Click the teleporting gold target **5 times** before time runs out.
   The target moves when hit — and on its own every 0.6s — so it never stays still.
3. **Dodge the Lasers** — Survive as three red laser bars sweep the arena; move with
   arrows/WASD, jump with Space/W. Every brush with a beam costs a core.
4. **Gauge Parry** — A gold marker sweeps back and forth across the arena. Press
   **Space/W when the marker is inside the green zone** **3 times** before time runs out.
   Miss and the marker just resets — no life penalty, but the clock keeps ticking.

## Audio

All sound is **generated from scratch** by `tools/gen_audio.ps1` (16-bit PCM mono 22050 Hz
WAVs synthesized with `BinaryWriter`, peaks normalized to −1 dBFS). No external audio
files.

**Sound effects:** `tick.wav` (countdown blip), `win.wav` (rising arpeggio), `fail.wav`
(descending sting).

**Music** is a four-part sequencer (bass, chords, lead, drums) rendering MIDI note tables
through synthesized voices — plucked string, kick, snare, hats, crash, and riser. Tracks:
`music_title.wav` (8 bars at 120 BPM, title screen and Flappy), `music_gauntlet.wav`
(8 bars at 150 BPM, during microgames), `music_danger.wav` (4 bars at 180 BPM, same
harmony but faster and percussive, for the final 3 seconds of a timer),
`music_intermission.wav` (one-shot build-up between microgames). Loops are assembled with
wrap-around mixing, so note tails fold into the next pass instead of being chopped, and the
generator verifies each seam: the last-to-first sample step must be smaller than the
largest natural step near the join. It fails loudly rather than shipping a click.

Regenerate anytime with:

```
powershell -ExecutionPolicy Bypass -File tools\gen_audio.ps1
```

## Settings

The settings scene (`settings_scene.tscn`) has separate **SFX** and **MUSIC** volume
sliders, a **TOUCH CONTROLS** toggle, a controls reference, and **RESET PROGRESS** (clears
best streak, streak, and loop count). Music rides its own `Music` bus routed to Master, so
the music slider can never disturb effect levels. Both volumes, best streak, and the
touch-controls choice persist across restarts; resetting progress leaves your settings
alone.

## How to Run

Open the project folder in the Godot 4.7.1 editor, or run it directly with the path to your
checkout:

```
Godot_v4.7.1-stable_win64.exe --path "C:\path\to\Iron-Mario"
```

To produce the installable web build yourself (the output folder must already exist):

```
Godot_v4.7.1-stable_win64.exe --headless --path "C:\path\to\Iron-Mario" --export-release "Web" "C:\path\to\Iron-Mario\build\web\index.html"
```

That writes `index.html`, the generated PWA manifest, its icons, and an offline-capable
service worker. Icons are generated from the original `assets/web_orb.svg` by
`tools/gen_pwa_icons.gd`; rerun it after changing the mark.

> The repository folder is still named `Iron-Mario` — that is just a checkout path, not the
> game's name. The player-visible title is **Super-Micro Heroes**.

## Continuous Integration

Pushing to `main` triggers `.github/workflows/deploy.yml`, which imports the project,
exports the Web build headlessly, and publishes it to the `gh-pages` branch — the live site
updates automatically with no local export needed.

Live build: **https://hustlenix.github.io/Iron-Mario/** (landscape-only; best in a desktop
browser with a keyboard, since hero powers are keyboard-only).

## Current State

Playable prototype: the complete title → intermission → microgame → win/lose flow runs end
to end, with difficulty loops, streaks, save persistence, generated audio, a nine-hero
roster, and a settings scene. It is playable on desktop (keyboard/mouse) and on phones and
tablets (touch, landscape-only), and ships as an installable web app. All art is
**original and created for this project** (hand-drawn SVG assets: nine hero sprites, the
bonus Flappy sprite, power-core life icons, shard collectibles, clicker target, parry bar
and zone, and four background scenes).

## Stardance Submission Checklist

| # | Requirement | Status |
| --- | --- | --- |
| 1 | Made in Godot | Done (Godot 4.7.1) |
| 2 | Minigames respond to player input | Done (keyboard + mouse + touch) |
| 3 | Minimum 5 hours spent coding | Tracked via Hackatime |
| 4 | Minimum 2 minigames | Done (platformer + clicker + dodge + parry = 4) |
| 5 | Implement your own assets | Done (original SVGs in `assets/`) |
| 6 | A well-written README | This file |
| 7 | None to minimal AI usage | See Development Log below |
| 8 | An original Winner Scene and Death Scene | Done (`winner_scene.tscn`, `death_scene.tscn`) |

## Development Log

The game structure, design, and art were built as a learning exercise with AI assistance:
scaffolding, scene wiring, and engine-API debugging were done with help, then tuned by hand.
Before submitting, make the project your own — especially these three files, which you
should **rewrite yourself by hand**:

1. `scenes/minigame_1.gd` — the platforming collect-a-thon: timer, pickups, win/lose flow,
   difficulty scaling.
2. `scenes/minigame_4.gd` — the parry minigame: sweeping tween, hit detection, zone
   placement, round logic.
3. `scenes/timer_screen.gd` — the intermission: countdown, lives display, and the routing
   that chains the gauntlet.

**Rewrite checklist** for each file: read it line by line until you can explain it, rewrite
it from scratch in your own words (same behavior, your structure), then change **one**
behavior (e.g. shards needed, parry zone width, intermission length) and confirm it works
in-game. Also give the SVG art in `assets/` a pass in an editor. The AI was used to set up
scaffolding and fix engine bugs, not to replace your learning.

## Next Steps

- More microgames to keep the gauntlet sprinting (memory, aim, etc.)
- Add an on-screen **POWER** button so touch players can fire their hero's power
- Per-minigame art and animations (the parry bar/zone are the newest assets)
- Balanced difficulty curve per loop (zone speed scaling)
- Polish the SVG art (shading, animation, backgrounds)

## Credits

Rapid-fire microgame genre; the game loop and intermission design were built as a learning
exercise from a public "make your first WarioWare-style game" tutorial, then rethemed
around an original micro-hero roster. Built for the Stardance Challenge.
