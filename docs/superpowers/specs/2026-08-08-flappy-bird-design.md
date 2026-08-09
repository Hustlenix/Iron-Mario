# Iron-Mario: Flappy Bird (Standalone Mode) — Design

Date: 2026-08-08
Status: Approved for implementation

## Overview

A full standalone endless Flappy Bird game accessible from the title screen, using the new Iron-Slinger themed art (flappy_hero.svg as the bird, flappy_bg.svg as the background, web_orb.svg as the pickup; see Art Direction below) and Juice/SceneFade systems. Best score persists to `user://`.

Research basis: flow theory (challenge/skill match via a difficulty ramp), fairness (shrunk hitboxes, consistent physics), quick-replay loop (zero-downtime restart), milestone medals, mid-run NEW BEST excitement, and layered juice (squash/stretch, trails, particles, audio on every action).

## Art Direction: Iron-Slinger Comic Identity

Mashup language: Spider-Man's red/blue web-suit + Iron Man's gold/red armor + arc-reactor glow. Style rules: bold INK keyline outlines (#1a1a1a), flat 3-tone comic shading (base/shade/highlight with hard edges), web motifs (concentric arcs + radial spokes) for texture, halftone dot clusters for depth, arc-reactor glows (gold rings + cyan core + white hot spot). Banned look (the old "vibe-coded" feel): soft gradient blobs, plain unfilled rects, default-UI elements, thin outlines, small art with margin whitespace. Presence: hero art fills its frame edge-to-edge; bigger silhouettes everywhere.

| Asset | Use | Size |
| --- | --- | --- |
| `flappy_hero.svg` | Flappy bird hero + cyan trail afterimage | 128x128 art, rendered in the 70x70 Bird rect (gameplay constants untouched) |
| `flappy_bg.svg` | Flappy background (webs between buildings, moon web, gold windows; ground strip kept at y=636-640) | 1280x720 |
| `pipe_body_red/blue.svg` | Pipe bodies, vertical-stretch tile | 110x64 |
| `pipe_rim_red/blue.svg` | Pipe gap-facing caps, web bands + gold bolts | 110x16 |
| `web_orb.svg` | Feather pickup + HUD feather icon | 40x40 |
| `medal_bronze/silver/gold/platinum.svg` | Medal icons (tinted reactors) | 48x48 |
| `title_hero.svg` / `logo_web.svg` / `button_web.svg` / `bg_title.svg` | Title screen (bigger hero, web logo emblem, comic buttons) | — |

## Entry Point

`title_screen.tscn` gets a `FlappyButton` ("FLAPPY") under `MenuButtons`, wired to `_on_flappy_button_pressed()` which fades out and loads `res://scenes/flappy_bird.tscn`. The button label shows the saved best, e.g. "FLAPPY  BEST: 12" (set in `_ready` from the save file).

## Scene: `scenes/flappy_bird.tscn` (Node2D, script `flappy_bird.gd`)

- `Background` — TextureRect with `flappy_bg.svg` (navy sky, moon with web overlay, skyline with webs strung between buildings, gold-lit windows, ground strip at y=636-640)
- `Pipes` — Node2D container for pipe pairs
- `Bird` — TextureRect, `flappy_hero.svg` (Spidey+Iron hybrid, arc-reactor eye, fills the frame for 2x presence), node stays 70x70 at x=200 — gameplay constants untouched
- `Pickups` — Node2D container for web_orb pickups
- `ScoreLabel`, `BestLabel`, `MedalLabel`, `MedalIcon` — RichTextLabels in existing HUD style; `MedalIcon` (48x48 TextureRect, top-right) shows the tinted reactor icon
- `SfxFlap`, `SfxScore`, `SfxHit`, `SfxPickup`, `SfxWin` — `AudioStreamGenerator` beeps synthesized in `_ready` (no new files; silent fallback on failure)
- `Bgm` — reuse `bgm.wav` at low volume (-14 dB)

## Core Loop (`flappy_bird.gd`, manual math — no physics engine)

States: `title` → `playing` → `game_over` (also `dying` between impact and overlay).

- Gravity `1400 px/s²`, terminal velocity `900`, flap sets `velocity.y = -420` (instant, like the original)
- Input: tap/click/space via `_unhandled_input` on `jump` action; ESC in any state → fade to title
- Bird tilt: lerp rotation toward `velocity.y`-based target, clamped ±35°; tilt up on flap, nose-dive on fall
- Pipe pairs: themed pipe art — `pipe_body_red/blue.svg` bodies + `pipe_rim_red/blue.svg` gap-facing caps (red/blue colorways alternate per pooled pair), width 110 / rim 16 unchanged; gap 280px, spawn every ~1.5s from x=1400, gap center random in [200, 560], recycled off-screen (pooled: 6 pair nodes reused)
- Difficulty ramp (score-based): gap shrinks 280→210 by score 25; speed 240→330 px/s by score 25; spawn interval 1.5s→1.1s by score 25 (linear interpolation across score 0..25)
- First pipe: generous random delay (1.6–2.4s) so the player gets a free flap-learning window; first 3 gaps ≥ 280px
- Scoring: +1 per pair passed (tracked per pair), `SfxScore`, `Juice.text` "+1", tiny shake; pair's `scored` flag prevents double count
- Collision: Rect2 vs bird rect shrunk 15% on pipes and ground; ground at y≥620 (below the bg's ground strip); ceiling clamps at y=0 (no death, matching the original)
- **NEW BEST moment**: when score passes the saved best mid-run, score label flashes gold, `Juice.burst`, `SfxWin` sting, "NEW BEST!" `Juice.text`

## Milestone Medals

Score 5/10/20/40 → Bronze/Silver/Gold/Platinum (tinted reactor icons `medal_bronze/silver/gold/platinum.svg` shown via the HUD `MedalIcon` + `MedalLabel` text, e.g. "MEDAL: GOLD", + `Juice.burst` + `SfxScore`). Each medal fires once per run; medal names reused from the original for the "you want it even if you don't know what it is" pull. Thresholds and label colors unchanged.

## Pickups (Feather)

- Every 8–12 pipes (random), a `web_orb.svg` pickup spawns in the gap center
- Collecting it grants one **Feather**: the next pipe/ground hit is a shield-pop instead of death — burst of cyan particles, hit-stop, 1s invulnerability blink (bird modulates alpha 0.3/1.0), then plays on
- Feather state shown as a small `web_orb.svg` icon under the score; only one Feather can be held
- No pickup appears in the first 3 pipes

## Juice & Feel

- Flap: bird scale squash (1.25, 0.75) → spring back; `SfxFlap`; 2-3 cyan `Juice.burst` particles at the bird's tail
- Continuous: a short cyan afterimage trail (few pooled, fading TextureRects of flappy_hero.svg) following the bird's arc
- Fall: slight stretch (0.85, 1.15)
- Hit: `Juice.hit_stop` (0.08s), `Juice.shake(0.6)`, `SfxHit`, red burst; then bird tumbles (rotation to 180°) and falls to ground
- Game over overlay: `Juice.text` "GAME OVER" + score/best, with zero-downtime restart (any flap input = instant retry); score 0 runs show no extra delay before the retry prompt
- Ambient: a thin `#4fd1ff` glow line pulses near the ground strip for motion (the bg is a static TextureRect; no parallax)

## Persistence

`user://flappy_best.save` (ConfigFile, key `score`). Loaded in `_ready`; written when beaten (after game over and on mid-run new-best). Title screen reads the same file to show "BEST: N" on the FLAPPY button. Failures to read/write are silent (default 0).

## Death / Retry / Exit

- Game over: score + best displayed, "TAP TO RETRY" (any flap input restarts instantly, resetting state, pipes pool, score, feathers) / "ESC FOR MENU" (fade to title)
- All state fully reset on retry in-place — no scene reload (zero-downtime loop)

## Error Handling

- `AudioStreamGenerator` synthesis wrapped in try/except → silent fallback if unsupported
- Save file corrupt/unreadable → treated as best 0, overwritten on next save
- `await` chains guarded against node-freed (`is_instance_valid` / `is_inside_tree` checks) following the `themed_timer.gd` pattern

## Testing

Headless Godot run with a scripted driver (same pattern as the previous playthrough harness, deleted after use):
1. Auto-flap at fixed intervals → assert score increments, pipes recycle, no SCRIPT ERRORs
2. Force collision → game over overlay, save file written with correct best
3. Simulate Feather pickup → next forced hit is a shield-pop (no death), then a second hit kills
4. ESC → title scene loads
5. Headless boot clean with `--import`, boot log free of errors

## Files

- `scenes/flappy_bird.gd` (+ auto `.uid`)
- `scenes/flappy_bird.tscn`
- `title_screen.gd` / `title_screen.tscn` — FLAPPY button + best-score display
- New art: `flappy_hero.svg`, `flappy_bg.svg`, `pipe_body_red.svg`, `pipe_rim_red.svg`, `pipe_body_blue.svg`, `pipe_rim_blue.svg`, `web_orb.svg`, `medal_bronze.svg`, `medal_silver.svg`, `medal_gold.svg`, `medal_platinum.svg`, `title_hero.svg`, `logo_web.svg`, `button_web.svg`, `bg_title.svg` (rework)
- No changes to Global/minigame flow

## Out of Scope (future ideas recorded)

- Night mode / weather, moving pipes, golden 3x pipes, alternate modes, leaderboards
