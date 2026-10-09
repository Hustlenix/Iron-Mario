# Baseline architecture and state ownership

Audit performed on 2026-10-09 against the local checkout copied from the deployed Godot baseline. It contains **50 real registered microgames**, not 100. Additional cabinets restored during this audit are listed separately in `GAME_AUDIT.md`.

## Runtime boundaries

| Owner | Lifetime and authoritative state | Reset / persistence boundary |
| --- | --- | --- |
| `GameRegistry` (`core/game_registry.gd`) | Definition data: IDs, titles, script paths, controls, difficulty, duration; caches loaded script resources | Creates a fresh instance for each launch. Does not store score or mutable simulation state. |
| `MicrogameBase` (`microgames/microgame_base.gd`) | One active round: elapsed time, duration, RNG, terminal flag, score, particles | `start()` clears elapsed/finished/points/particles, seeds RNG and calls subclass `setup()`. `advance()` freezes when inactive. `completed` emits at most once. |
| `pack_a.gd` / `pack_b.gd` | Per-round mechanism state (`s` dictionary or explicit movement fields) | `setup()` resets its own state. Action handlers reject input after termination. They do not persist profile data or replace scenes. |
| `game_app.gd` (`ui/`) | Screen coordinator, active game, input routing, intro/result transitions, pause and orientation guards | `clear_page()` increments a generation token, resets/disables input, detaches and frees the old page including its arena. Intro/result timers check the token to reject stale callbacks. |
| `InputRouter` (`core/input_router.gd`) | Scene-local fingers, keys, axis and virtual cursor | Converts screen coordinates to the 960×480 arena. `reset()` clears held inputs and emits neutral movement. Accepts at most two simultaneous fingers. |
| `RunDirector` (`core/run_director.gd`) | Scene-independent run: mode, hearts, rounds, scores, streaks, shuffle bag, daily queue | `begin()` resets all run state. `submit()` accepts one result for the current ID. Daily selection is reproducible for a date and sorted input IDs. |
| `Profile` autoload (`core/save_store.gd`) | Device profile: XP, coins, records, mastery, favorites, recent games, achievements, settings | Version 2 primitive JSON snapshots, validation and migration; temp file and backup handling. Test startup bypasses actual profile loading with `-- --test`. |
| `Music` autoload (`scripts/music_player.gd`) | Process-lifetime audio playback/crossfades | Menu and gameplay choose tracks. Does not own active game nodes. Exit cleanup kills tweens. |
| `PlatformServices` (`core/platform_services.gd`) | Explicit optional service boundary | No claimed online leaderboard, live billing or advertising. Defaults remain disabled/unavailable. |

## Shared game lifecycle

The Godot equivalent of `init/start/update/render/pause/resume/restart/destroy` is:

1. `registry.create(id)` resolves and instantiates the script.
2. `start(metadata, difficulty, seed)` initializes a playable round.
3. `advance(delta)` updates simulation; `_draw()` calls `paint()` for presentation.
4. The app routes normalized input only while active and unfinished.
5. `refresh_pause()` sets `current_game.active` and router availability. Pause, focus loss and portrait rotation freeze simulation and clear held input.
6. `win()/lose()` emit `completed` once. The app records profile rewards, submits run scoring, then moves to another round or results.
7. Restart launches a fresh module through the coordinator. The audit also checks same-instance `start()` reset independently.
8. Exit frees the page containing the arena and invalidates outstanding transition callbacks.

The base class guards simulation updates while paused; its public action method is not an independent pause boundary. Callers must use the app's guarded `route_action()`. Tests distinguish direct normalized-action mechanics tests from routed input integration.

## Evidence actually executed

- `services_test.gd`: **170 checks, 0 failures**; save validation/migration, profile rewards, run rules.
- `pack_a_test.gd`: **175 cases, 0 failures**; all 25 entries win at difficulties 1/6 with seeds 17/92, fail unattended at difficulties 1/6, and fail after a deliberate bad input at difficulty 6.
- `pack_b_test.gd`: **75 cases, 0 failures**; all 25 entries win at difficulties 1/6 using seed 1204 and fail unattended at difficulty 1.
- `input_test.gd`: **24 checks, 0 failures**; shared keyboard/touch translation, two-finger acceptance, release/reset and six mechanism integrations.
- `app_test.gd`: **480 checks, 0 failures**; all seven screens, search/favorites, actual Armor Repair win/result/persistence, daily/tournament termination, pause, orientation, board aspect and repeated interrupted launches.
- `catalog_audit_test.gd`: **1052 checks, 50 baseline games, 0 failures**; every ID resolves, instantiates, starts, responds to its primary control, freezes/resumes, resets, terminates exactly once, isolates instances and frees without stray nodes. Every game also launches, pauses/resumes, restarts, fails through simulation into shared results, records one profile result and exits to the menu through the actual app.
- `cabinets_test.gd`: **151 checks, 0 failures**; three restored cabinets complete through actions/physics at difficulties 1/6 with seeds 23/94, then restart and lose through real simulation. Includes touch-button steering, boost/launch actions, non-committing input cancellation and resource cleanup.

All these commands ran using the installed official **Godot 4.7.1** console runtime. The existing five-suite wrapper rejects engine errors and leak diagnostics as well as nonzero exits; it passed. Headless simulation is not a visual-rendering or physical-phone performance measurement.

## Baseline limitations and priorities

- Scripts are instantiated lazily, but the Godot web package still includes the baseline resources together. No claim of downloading each game's assets on demand is justified.
- `game_app.gd` owns both UI and screen coordination; it is a sizeable script. Additional genre modules should remain self-contained rather than adding more simulation branches to it.
- Headless deterministic drivers observe authored state to select inputs. They test reachable gameplay and result conditions; they do not measure human difficulty, enjoyment or reaction latency.
- App lifecycle integration originally exercised one deterministic game; the catalog audit expands component and launcher/pause/restart/results/profile/exit coverage to every baseline entry. Browser launch/result controls for every individual game remain a separate release task.
- Shared touch events are tested, including simultaneous touches. Physical Android/iOS, real gamepad behavior, multi-device latency and sustained frame-time/memory traces have not been measured in this audit.
- Portrait currently deliberately pauses and requests rotation. This is an implemented behavior, not proof that every genre supports portrait play.
