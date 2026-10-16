# Game Registry — Iron-Mario / Super-Micro Heroes

Internal registry of every game that currently exists in the repo.

> Every iteration, this registry must stay in sync with the actual scenes/scripts.
> When a new game lands, append a new entry and re-run the smoke tests.

---

## Game: Platformer Gauntlet (minigame_1)
- **Scene:** `res://scenes/minigame_1.tscn`
- **Script:** `scenes/minigame_1.gd`
- **Genre:** Platforming collect-a-thon
- **Status:** Playable, wired into the gauntlet
- **Core mechanic:** Move/jump through a small platformer to collect 3 gold shards before the clock.
- **Controls:** `A/D` move, `Space/W` jump, `power` for hero power.
- **Mobile:** Touch left/right/jump/POWER buttons; POWER is shown when a handler and active hero power exist.
- **Round length:** ~10s (scales down with loop, floor 5s).
- **Scoring:** 1 core lost on failure; 3 shards = win.
- **Major problems:** Touch POWER behavior needs cross-minigame playtest; limited vertical camera.
- **Keep / Rework:** Keep, verify POWER feedback and add mild camera follow.
- **Quality:** 7/10

## Game: Target Tag (minigame_2)
- **Scene:** `res://scenes/minigame_2.tscn`
- **Script:** `scenes/minigame_2.gd`
- **Genre:** Aim / reaction
- **Status:** Playable
- **Core mechanic:** Click 5 teleporting targets before time runs out.
- **Controls:** Mouse / touch click; hero powers auto-hit or vaporize.
- **Mobile:** Works with touch.
- **Round length:** ~10s.
- **Scoring:** 5 hits = win.
- **Major problems:** POWER behavior needs cross-minigame playtest; target occlusion is handled, but there are no penalties for miss streaks.
- **Keep / Rework:** Keep, consider miss penalty and stronger POWER feedback.
- **Quality:** 7/10

## Game: Dodge the Lasers (minigame_3)
- **Scene:** `res://scenes/minigame_3.tscn`
- **Script:** `scenes/minigame_3.gd`
- **Genre:** Avoidance / dodge
- **Status:** Playable
- **Core mechanic:** Dodge 3 sweeping laser bars for the countdown. One brush = core lost.
- **Controls:** WASD/arrows + jump; power per hero family.
- **Mobile:** Touch controls and POWER button are available when the power handler is registered.
- **Round length:** ~10s.
- **Scoring:** Win = survive; lose = life cost.
- **Major problems:** Invincibility timing can be brief; POWER needs real-device verification.
- **Keep / Rework:** Keep, verify POWER feedback and add brief stun frames if needed.
- **Quality:** 7/10

## Game: Gauge Parry (minigame_4)
- **Scene:** `res://scenes/minigame_4.tscn`
- **Script:** `scenes/minigame_4.gd`
- **Genre:** Timing / skill
- **Status:** Playable
- **Core mechanic:** Press Space/W when the sweeping marker is inside the green zone 3 times.
- **Controls:** Space/W.
- **Mobile:** Works via on-screen jump button; no explicit parry button.
- **Round length:** ~10s.
- **Scoring:** 3 clean hits = win; miss = reset marker only.
- **Major problems:** Uses the shared touch action button labeled for the current scene; visual zone is small.
- **Keep / Rework:** Keep, tune touch-safe input feedback and zone enlargement on fail.
- **Quality:** 7/10

## Game: Flappy Bonus (flappy_bird)
- **Scene:** `res://scenes/flappy_bird.tscn`
- **Script:** `scenes/flappy_bird.gd`
- **Genre:** Endless one-button
- **Status:** Playable bonus path
- **Core mechanic:** Flap through gaps.
- **Controls:** Space / touch.
- **Mobile:** Works.
- **Round length:** Variable.
- **Scoring:** Distance / pipes.
- **Major problems:** No leaderboard or restart shortcut; visual style is distinct but functional.
- **Keep / Rework:** Keep, add best-score persistence and quick restart.
- **Quality:** 6/10

## Game: Tower Bounce (tower_bounce)
- **Scene:** `res://scenes/tower_bounce.tscn`
- **Script:** `scenes/tower_bounce.gd`
- **Genre:** Vertical arcade / auto-bounce
- **Status:** First playable expansion cabinet
- **Core mechanic:** Steer left/right while automatically bouncing across hand-drawn platforms; climb as high as possible.
- **Controls:** `A/D` or arrows; touch left/right; `Space/W` retries after falling.
- **Mobile:** Uses the shared touch layer with direction controls; portrait still shows the rotate prompt.
- **Round length:** Open-ended, typically 15–60s.
- **Scoring:** Height climbed, with a persistent best height.
- **Major problems:** Needs deeper visual playtesting and a stronger landing sound once the core loop stabilizes.
- **Keep / Rework:** Keep as the first arcade expansion; tune platform fairness after broader playtests.
- **Quality:** 5/10 (new playable baseline)

## Game: Brick Reactor (brick_reactor)
- **Scene:** `res://scenes/brick_reactor.tscn`
- **Script:** `scenes/brick_reactor.gd`
- **Genre:** Breakout-inspired arcade
- **Status:** First playable baseline
- **Core mechanic:** Move the paddle, launch the core, and clear five rows of hand-drawn reactor bricks.
- **Controls:** `A/D` or arrows; `Space/W` launches and restarts; touch left/right + LAUNCH.
- **Mobile:** Uses shared touch controls with a named LAUNCH action.
- **Round length:** Usually 60–90s.
- **Scoring:** 100 points per brick, persistent personal best.
- **Major problems:** Needs richer brick patterns and powerups after the core loop receives more playtesting.
- **Keep / Rework:** Keep; expand with controlled powerups, not random clutter.
- **Quality:** 5/10 (new playable baseline)

## Game: Arc Snake (arc_snake)
- **Scene:** `res://scenes/arc_snake.tscn`
- **Script:** `scenes/arc_snake.gd`
- **Genre:** Fast grid arcade / reaction
- **Status:** First playable baseline
- **Core mechanic:** Turn a growing reactor snake through a grid, collect Arc Orbs, and use BOOST to create a higher-risk score ceiling.
- **Controls:** `A/D` or left/right turn; arrow keys for direct keyboard turns; `Space/W` or touch BOOST.
- **Mobile:** Shared left/right and BOOST touch controls.
- **Round length:** Usually 20–90s.
- **Scoring:** 100 points per orb, persistent personal best.
- **Major problems:** Needs more pickup variety and a safer first-turn tutorial beat.
- **Keep / Rework:** Keep; add restrained hazards after the base loop gets more playtime.
- **Quality:** 5/10 (new playable baseline)

## Game: Arc Break (arc_break)
- **Scene:** `res://scenes/arc_break.tscn`
- **Script:** `scenes/arc_break.gd`
- **Genre:** Top-down action / energy puzzle
- **Status:** First playable story slice
- **Core mechanic:** Repulsor bolts charge resonance relays; the current travels through the lab's fungus network to unlock a cave route, where the same mechanic exposes and defeats the breach core.
- **Controls:** WASD/arrows to move, E/Shift to fire, Space to talk, Escape to return.
- **Mobile:** Dedicated four-way touch pad + REPULSOR button.
- **Round length:** About 2–3 minutes.
- **Scoring:** Relay links and boss hits; persistent best score.
- **Assets:** Modern Interiors Full resonance-machine/screen art and a Character Generator premade scientist; custom-drawn cave, mycelium, repulsor, hero/boss accents. Credit is required for Modern Interiors; unlicensed Fungus Cave/Fantasy Battlers art is not included.
- **Keep / Rework:** Keep as the first narrative anchor; expand its sector chain only after player feel is validated.
- **Quality:** 5/10 (first playable prototype)

## Game Shell: Title / Hero Select / Level Intermission
- **Scenes:** `title_screen.tscn`, `hero_select.tscn`, `level_scene.tscn`, `timer_screen.tscn`, `settings_scene.tscn`, `death_scene.tscn`, `winner_scene.tscn`
- **Status:** Functional
- **Core mechanic:** Menu, gauntlet routing, lives, streaks, countdown, win/lose.
- **Major problems:** No arcade category menu yet; powers are keyboard-only for touch; registry doc did not exist until now.
- **Keep / Rework:** Rework into arcade hub later.
- **Quality:** 7/10

## Assets / Resource Provenance Snapshot

| Pack | Path | Contents | Godot usability | License / Restriction |
|---|---|---|---|---|
| Modern Interiors (Full) | Downloads | 51k PNGs, .ase/.aseprite, .gif | Low for Godot without re-export; RPG Maker tile layout | Non-commercial allowed, credits required, no resale/distribution of raw assets |
| Modern Interiors (Free) | Downloads | ~1% of full | Low | Non-commercial only |
| Fungus Cave [16x16] | Downloads | 79 PNGs | Usable if style fits a cave game | Unknown / readme not present — do not ship until verified |
| Fantasy Battlers (Complete) | Downloads | 250 PNGs + .aseprite | Usable for fantasy battlers | Unknown / must verify exact license before use |
| Fantasy Battlers (Free) | Downloads | 46 PNGs | Usable for RPG Maker MV size; sample | Suggests buying if liked; no explicit license text shown |
| Character Generator 2.0 | Downloads | Standalone Unity app (Windows exe + Linux bag) | Not importable; cannot run unknown installers | Unknown |

---

*Last audited: 2026-10-06. Any new scene/script must appear here before it is counted toward the 100+ target.*
