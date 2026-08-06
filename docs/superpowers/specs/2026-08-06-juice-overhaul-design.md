# Iron-Mario 2.0 — Juice & Presentation Overhaul (Design)

Date: 2026-08-06. Status: approved by user.

Goal: make the game visibly, feelably better — game feel, visuals, pacing, presentation. No content-count changes (4 minigames stay).

## 1. Game Feel (juice)

- `scripts/juice/screen_shake.gd` — camera shake: `shake(intensity, duration)` with decaying noise; attached to a camera rig in each gameplay scene. Trigger: player hit, explosion, win/lose, parry success.
- `scripts/juice/floating_text.gd` — node that pops text at a position and drifts up + fades (label or RichTextLabel). `spawn(text, color)`.
- `scripts/juice/particles.gd` — reusable CPUParticles2D presets: burst (`burst_burst`), trail. Configured per use.
- Hit-stop: on win/lose, `Engine.time_scale = 0.05` for ~0.08s then back to 1.0 (use a short timer; careful with await in scene scripts).
- Screen flash: full-screen ColorRect pulse on win (gold) / lose (red).
- Player squash & stretch: scale tween on jump (0.8, 1.2) / land (1.15, 0.85) in `minigame_1_player.gd`.
- Floating texts: `+1` on collect, `MISS` on clicker miss, `PARRY!` on parry success, `REACTOR DOWN` on hazard hit.

## 2. Visuals

- Redraw SVGs in `assets/` with gradients + glow: `hero.svg` (shaded armor, glowing chest reactor), `bg_title.svg`, `bg_game.svg`, `bg_win.svg`, `bg_death.svg` (gradient skies, silhouette layers), `target.svg`, `shard.svg`, `reactor.svg`, `parry_bar.svg`, `parry_zone.svg` (glow strokes).
- Parallax: `bg_game.svg` is one layer; add a simple two-layer parallax (static far + slow-scrolling mid layer) in minigame scenes.
- Title screen: hero sprite bobbing (tween), logo pulsing (scale/glow), particles behind.
- HUD reactors: subtle pulsing glow on alive reactors.

## 3. Gameplay & Pacing

- `READY` / `GO!` countdown in `level_scene` (intermission): big animated numbers with tick.wav, then `GO!` flash. Intermission 5s → 3s.
- Gauntlet progress: 4 small icons in intermission showing completed minigames (filled = done).
- Streak multiplier label mid-run: show current streak on intermission.
- Minigame 3: lasers flash (modulate red) 0.4s before sweeping.
- Minigame 2: combo text on each hit (`x2`, `x3`...).
- Minigame 4: arrow indicator above the zone when bar is within 150px of it.

## 4. Presentation

- Fade transitions: `scripts/juice/fade.gd` — full-screen ColorRect fade-in/out; helper `fade_out()` before `change_scene_to_file`. Applied in all scene-changes (title → level, minigames, winner, death, settings).
- Winner scene: confetti particles, stats line (rounds cleared = minigames_done, best streak), keep PLAY AGAIN / CONTINUE.
- Death scene: red vignette pulse, brief slow-mo on last reactor loss.
- Settings scene: match new visual style (already functional; light styling).

## 5. Structure

- New `scripts/juice/` (screen_shake.gd, floating_text.gd, particles.gd, fade.gd) — strictly typed, `class_name` for editor autocomplete.
- Existing scenes edited in place; no new scenes except optional shared juice nodes added as children.

## Verification

- `--headless --import`, boot `--quit-after 120`, temp load-all-scenes script, Windows + Web export, push → CI deploys.

## Out of scope

- New minigames, new content. Enterprise refactor (managers/DI/etc.). Audio pass (already generated).
