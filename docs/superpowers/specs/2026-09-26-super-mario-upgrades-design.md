# Super-Mario Upgrades — Design

**Status:** Approved
**Date:** 2026-09-26
**Scope:** Heroic rename, mobile support, original music, nine playable characters

## Context

Iron-Mario is a four-minigame gauntlet: collect three shards, click a moving target,
dodge sweeping lasers, and time a parry. Five lives, escalating timer, streak
multiplier. A standalone Flappy Bird mode sits alongside it. The game ships to
GitHub Pages as a web export, and a Windows desktop build is produced alongside it.

Three upgrades were requested: heroic music, a roster of real playable characters,
and mobile support. The game is also being renamed to Super-Mario.

## Goals

1. The game presents itself as Super-Mario everywhere a player can see it.
2. Players on phones can play the whole gauntlet.
3. The game has original heroic music that escalates with the timer.
4. Nine heroes are selectable and genuinely playable, each with a distinct power.
5. Every phase leaves the game in a shippable, verified state.

## Non-goals

- No native Android/Play Store build in this effort. It is a separate optional
  phase; it needs the owner's Google Play developer account and a signing key.
- No licensed Marvel, DC, Nintendo, or film audio or artwork is downloaded or
  bundled. All new art and audio is original or owner-supplied.
- No rename of the repository folder. It stays `Iron-Mario`; the build and deploy
  pipeline depend on the path. Renaming the folder is a separate, riskier step.
- No rework of the core gauntlet loop, scoring, lives, or streak economy.

## Approach

Phased, with mobile before characters. Mobile is second because it is the phase most
likely to surface layout and input problems that would otherwise be discovered late,
while touching touch controls and the character HUD is still cheap. Characters go
last because they are the largest change and benefit from a settled layout and
existing audio.

Two alternatives were considered and rejected: a single full rewrite (cleanest end
state, but discards a working prototype and delays anything playable), and a
cosmetic-only roster (fastest, but fails the "real playable characters" requirement).

## Phase 1 — Rename to Super-Mario

Change the player-visible name only:

- `project.godot` → `config/name`
- `scenes/title_screen.tscn` → `TitleLabel` text
- `export_presets.cfg` → web PWA `app_name`, Windows `product_name`,
  `file_description`, and the Windows `export_path` filename
- `README.md` heading
- `tools/gen_audio.ps1` header comment

Historical documents under `docs/superpowers/` and `.superpowers/sdd/` are left
alone. They record what was true when written.

The README gains a note that this is an unofficial fan project and that the name
resembles a trademarked title, so the owner knows the risk before publishing.

## Phase 2 — Mobile

### Orientation

Landscape only. Every minigame positions elements at fixed coordinates designed for
a 1280x720 canvas, so forcing landscape preserves all four challenges exactly as
they behave on desktop. Portrait shows a rotate-your-device prompt.

### Touch controls

An on-screen control layer renders `left`, `right`, and `jump` buttons styled to
match the game, plus a slot for the `power` button that Phase 4 fills in. The
`power` action does not exist until Phase 4, so Phase 2 must not register a button
for it; the layer is built to accept it later without restructuring.

Buttons are `Control` nodes with `mouse_filter = STOP` that call
`Input.action_press` / `Input.action_release`. Two consequences fall out of this:

- The minigames need no input changes. They already read the `left`, `right`, and
  `jump` actions, so button and keyboard paths are identical.
- A touch on a button is consumed by the UI and never reaches
  `_unhandled_input`, so the tap-to-hit minigame cannot register a stray miss.

Tap-to-target already works on touch devices through Godot's default
touch-to-mouse emulation, so no new input branch is required for it.

### Touch layer behaviour

The layer appears on the first touch event, not on device detection, so a
touchscreen laptop does not show controls to a player using a keyboard. A settings
toggle lets a player on a hybrid device hide them permanently.

Buttons are at least 64 pixels on their shortest edge, hold high contrast against
whatever sits behind them, and are never the only route to an action: the keyboard
path stays fully available, so nothing becomes mouse- or touch-only.

### Installable web build

Enable the PWA in the web export preset with a landscape orientation, and supply a
custom HTML head include that prevents pinch-zoom and rubber-band scrolling, and
sets a fullscreen-capable viewport. The result is a shareable link that installs to
the home screen and opens fullscreen.

### Performance

Enable mobile VRAM texture compression in the export preset. Thread support stays
off. A `low_quality` flag on `Global`, auto-set when the platform reports a mobile
device, caps particle counts and disables per-frame allocations in the gauntlet.

## Phase 3 — Music

### Composition

Original heroic music, generated by extending the existing `tools/gen_audio.ps1`
synthesizer into a small sequencer supporting bass, chords, lead, and drums, so the
tracks are reproducible from source rather than hand-placed binaries.

| Track | Purpose | Notes |
|---|---|---|
| Title theme | Title screen | Epic, moderate tempo, seamless loop |
| Gauntlet loop | During minigames | Driving, seamless loop |
| Gauntlet danger | Final 3 seconds of a timer | Same harmony, faster and percussive |
| Intermission sting | Between minigames | Short build-up |
| Win / lose | End of gauntlet | Extend the existing stingers |

Every loop is authored so its end meets its start without an audible seam.

### Playback

A `Music` audio bus, separate from sound effects, with its own volume slider in
settings and persisted through the existing save. An autoload crossfades between
tracks by scene, so a transition is never a hard cut.

Mobile browsers require a user gesture before audio starts. The title screen's
START button is already a tap, which satisfies this.

## Phase 4 — Nine playable characters

### Select

A character-select screen between the title screen and the gauntlet, with a random
option. The selection is stored on `Global` and persisted in the existing save, and
survives sessions. It is not reset by `Global.reset()`, which clears per-run state
only.

The selected hero is drawn in the shard and dodge minigames, appears as a badge in
the tap and parry minigames, and stands in for the title screen's static hero art.
Flappy Bird uses the selected hero as its sprite; Flappy stays visual-only and
gains no power. The existing `flappy_hero.svg` remains the fallback if a hero's art
does not read at Flappy's smaller scale.

### Power system

One power per hero, on a shared three-second cooldown with an on-screen cooldown
ring. Powers fall into four families, and each of the four minigames implements one
short handler per family. This is sixteen behaviours rather than thirty-six, which
is what keeps the change maintainable.

| Hero | Power | Family | Effect |
|---|---|---|---|
| Spider-Man | Web Swing | Dash | Arcs forward and up; passing through the target or parry zone resolves it |
| Superman | Super Speed | Dash | Long flat burst, the fastest, with brief invincibility |
| Batman | Bat-Sense | Reveal | Reveals the next shard, the next laser, or the parry zone |
| Wanda Maximoff | Telekinesis | Reveal | Freezes moving hazards, the target, or the parry bar for one second |
| Wonder Woman | Lasso | Reach | Long-range auto-hit that also pulls the player toward the goal |
| Black Widow | Baton Whip | Reach | Instant long-range auto-hit |
| Captain America | Shield | Reach | Slower, but absorbs one hit |
| Iron Man | Repulsor | Blast | Pulls shards in, vaporises the target, deletes a laser, or pulls the parry bar into the zone |
| Homelander | Optic Beam | Blast | The repulsor at longer range, on a four-second cooldown |

All heroes share identical basic controls. Only the power differs. Heroes within a
family differ by cooldown length, arc shape, range, and effect strength.

## Verification

Each phase is verified before the next begins:

- The project imports and boots cleanly under a headless run:
  `godot --headless --path . --quit-after 30`
- Each hero's power is exercised in each of the four minigames by a headless
  driver, following the existing `test_flappy.gd` convention: a `--script` entry
  point run with named flags per case, removed once the phase lands.
- A phone-sized viewport capture confirms the touch controls do not occlude play.
- The web export succeeds and the deployed site returns 200.
- Existing keyboard play still passes.

## Risks

| Risk | Mitigation |
|---|---|
| On-screen controls cover the action on short landscape screens | Capture at phone viewport; keep the control strip in the lower margin below the play area |
| Touch-to-mouse emulation double-fires on the tap minigame | UI buttons consume their own touches via `mouse_filter = STOP` |
| Loop points click at the wrap | Author loops to a whole number of bars and verify the seam by ear |
| Mobile audio silently muted by the OS | Start audio on the title tap; note the iOS silent-switch behaviour in the README |
| "Super-Mario" resembles a trademarked title | Flag it in the README; the owner decides whether to publish |
| Character art is original stand-in art, not licensed likenesses | Ship original hero designs; document them as such |
| Hero art does not read at Flappy Bird's small scale | Keep `flappy_hero.svg` as the Flappy sprite; treat the hero swap as optional polish |
| Touch controls appear on a touchscreen laptop during keyboard play | Reveal on first touch event, not on device detection, and add a settings toggle |

## Assumptions

Agreed unless the owner says otherwise:

- Identical basic controls across all heroes, power as the only differentiator.
- Mobile means a landscape installable web app first; native Android is optional later.
- Music is original, not existing Marvel or film music.
- The repository folder stays `Iron-Mario`; only the in-game name changes.
