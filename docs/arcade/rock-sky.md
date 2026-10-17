# Rock Drift and Sky Shield

Two independent Wave B games for OnlyEducation's 480×320 Canvas host. Both use injected seeded randomness, fixed-step updates, existing shared pixel art, and optional sound callbacks. Neither module creates listeners, timers, DOM nodes, storage, network requests, or global state.

## Rock Drift

Experience target: feel in control of a drifting ship by alternating short thrusts, coasting, braking, and aimed fire while deciding between keeping distance and closing for a shot.

- Left/right (A/D): rotate. Up (W): thrust. Down (S) or Z: brake. Action (Space/Enter): fire; holding repeats at a bounded cadence. Touch uses the host D-pad/action controls.
- Momentum persists; thrust and braking change it. The playfield wraps on both axes. Shots also wrap and have limited lifetime.
- Large debris splits into two medium rocks; each medium splits into two smaller, faster fragments. Shots award 25/50/100 points by size. Clearing a field awards 100 points; clearing all three awards 250 per surviving ship.
- Three ships, short invulnerability on respawn, and a deterministic search for open respawn space make collisions recoverable.
- Three fields contain two, three, and four large rocks respectively. A brief intermission separates them. Destroy all debris to win; losing the last ship loses.
- Shared asset IDs: `pieces_ship`, `pieces_rock`. The modules use original HUD, trails, particles, tiny-rock geometry, and deterministic star placement. Sprite fallbacks allow logic and draw testing without image loading.

Historical reference: The Strong National Museum of Play dates *Asteroids* to November 1979 and describes its drifting shooting and rock-splitting lineage. [The Strong: Asteroids](https://www.museumofplay.org/games/asteroids/). The description is historical context; this module is independently written and includes no original game's software, sound, or artwork.

## Sky Shield

Experience target: feel resourceful under pressure by leading incoming flight paths and placing bursts where they can intercept groups, while choosing which threatened cities need the next limited shot.

- Move the pointer to aim; click/tap to launch. Arrow keys/WASD or touch D-pad move the reticle. Action (Space/Enter) fires. Held fire repeats with a cooldown. A stale pointer location does not override later keyboard aiming.
- Interceptors travel from the central battery to the aimed point before creating a growing blast. Place them ahead of incoming missiles; a destroyed missile creates a chain burst.
- Four cities each have two shields. Missiles target living cities; an impact removes a shield. When all cities fall, the run ends.
- Ammo is finite per wave: 14, 17, then 20 shots. Waves contain 10, 14, then 18 missiles, with faster incoming travel and a tighter cadence. Ammo refills between waves; surviving cities carry their damage forward.
- Each interception earns 50 × wave number. A cleared wave adds 100 per surviving city plus 5 per unused shot. Survive all three waves to win.
- Shared asset ID: `pieces_turret`. Pixel-stepped blast fields, cities, missile trails, reticle, and HUD are original procedural drawings. No paid asset-pack content is copied into this game.

Historical reference: The Strong's Atari corporate collection records discuss *Missile Command* (1980) in the original coin-op design lineage. [The Strong: Atari Coin-Op collection](https://www.museumofplay.org/blog/icheg-preserves-atari-coin-op-divisions-collection/). The Museum of the Moving Image also lists *Missile Command* (1980) in its collection exhibition. [Museum of the Moving Image: Spacewar! Video Games Blast Off](https://movingimage.org/archived-events/spacewar-video-games-blast-off/). Sky Shield is an independent interpretation of the defensive interception mechanic, not an authorized remake or affiliate product.

## Verification

Run `rtk proxy node --test tests/arcade/rock-sky.test.mjs`. Deterministic tests exercise momentum/braking, wrap geometry, swept collisions, fragmentation, respawn and invulnerability, fire cadence, wave progression, city damage, finite ammo, burst timing and chain reactions, target input, win/loss, and terminal-state freeze. Specific collision and final-wave tests deliberately set small boundary fixtures; these are not browser-play claims.

Run `rtk proxy node tools/rock_sky_browser.cjs` after root packaging enables both game routes. The browser runner uses real keyboard, mouse, and touch input, reads the host's read-only QA snapshots, captures score/outcome, and checks pause/resume/restart/exit on desktop and mobile. It records screenshots, console/request failures, and resource counts. The runner never assigns game state or advances simulation through private methods. Human feel, difficulty preference, and audible sound review remain separate from automated evidence.
