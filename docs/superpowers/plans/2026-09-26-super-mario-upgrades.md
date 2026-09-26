# Super-Mario Upgrades — Plan Index

**Status:** Phase 1 ready to execute
**Date:** 2026-09-26
**Design:** `docs/superpowers/specs/2026-09-26-super-mario-upgrades-design.md`

## Why this is four plans and not one

The design covers four independent subsystems. Each one ships value on its own and
the game is playable and shippable after every one. Bundling them into a single
plan would produce a document that goes stale before it is used and would make a
partial failure expensive. So each phase gets its own plan, written at the start of
that phase, executed, and verified before the next begins.

| Phase | Subsystem | Plan | State |
|---|---|---|---|
| 1 | Rename to Super-Mario | `2026-09-26-phase-1-rename.md` | Ready |
| 2 | Mobile touch layer and installable web build | written at Phase 2 start | Not started |
| 3 | Original music system | written at Phase 3 start | Not started |
| 4 | Nine playable characters with powers | written at Phase 4 start | Not started |

## Global constraints

These apply to every phase. Copied from the design spec.

- Godot 4.7.1, engine binary at `C:\Users\LalithReddy.b\Godot\Godot_v4.7.1-stable_win64.exe`.
- Always run Godot with `--headless --path C:\Users\LalithReddy.b\Iron-Mario`.
- The player-visible name is `Super-Mario`. The repository folder stays `Iron-Mario`.
- No licensed Marvel, DC, Nintendo, or film audio or artwork is downloaded or bundled.
  All new art and audio is original or owner-supplied.
- Historical documents under `docs/superpowers/` and `.superpowers/sdd/` are not
  rewritten to reflect a rename; they record what was true when written.
- Every phase ends with a clean headless boot check and a committed change.
- The game must stay playable on desktop keyboard and mouse throughout.

## Phase file surfaces

Rough map of what each phase touches, so changes are reviewable in isolation.

### Phase 1 — Rename

- `project.godot` — `config/name`
- `scenes/title_screen.tscn` — `TitleLabel` text
- `export_presets.cfg` — web PWA app name, Windows product name, file
  description, Windows export path
- `README.md` — heading, plus a fan-project and trademark note
- `tools/gen_audio.ps1` — header comment

### Phase 2 — Mobile

- Create `scenes/touch_controls.tscn` and `scripts/touch_controls.gd`
- Modify `project.godot` — autoload entry
- Modify `scenes/level_scene.tscn` — instantiate the touch layer
- Modify `scenes/flappy_bird.tscn` — instantiate the touch layer
- Modify `export_presets.cfg` — enable PWA, landscape orientation, mobile texture
  compression, head include
- Modify `scripts/Global.gd` — `low_quality` flag, touch-controls setting

### Phase 3 — Music

- Modify `tools/gen_audio.ps1` — add the sequencer
- Create `scripts/music_player.gd` — crossfade autoload
- Modify `project.godot` — `Music` autoload, `Music` audio bus
- Modify `scenes/settings_scene.tscn` and `.gd` — music volume slider
- Modify `scripts/Global.gd` — persist `music_volume`
- Modify `scenes/title_screen.gd`, `scenes/level_scene.tscn`, `scenes/timer_screen.gd`
  — track changes per scene

### Phase 4 — Characters

- Create `scripts/hero_data.gd` — hero roster as a resource-backed table
- Create `scenes/hero_select.tscn` and `scenes/hero_select.gd`
- Create `scripts/power_bus.gd` — power dispatch
- Modify `scenes/title_screen.tscn` and `.gd` — route through hero select
- Modify `scripts/Global.gd` — persist `selected_hero`
- Modify `scenes/player.gd` — dash, teleport, invulnerability
- Modify all four `scenes/minigame_*.gd` — one handler per power family
- Create art under `assets/heroes/` — nine original hero designs
- Create `test_heroes.gd` — headless power driver, removed after the phase lands
