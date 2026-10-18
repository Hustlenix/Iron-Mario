# Twenty-game beta — 18 October 2026

The existing OnlyEducation engine now has 20 playable cabinets, including Dino Dash. Rockfall Mines remains planned; the original history catalog still has 20 entries plus the bonus Dino cabinet. The preserved Godot game tree is unchanged.

## New cabinets

| Cabinet | Complete loop |
| --- | --- |
| Orbit Duel | Turn, thrust and brake around a gravity well; defeat three rival drones with limited hulls. |
| Armored Arena | Face and fire through cover; survive three increasingly crowded tank arenas. |
| Invader Patrol | Dodge and shoot three formations before they cross the defense line; cover degrades and repairs between waves. |
| Soft Landing | Tilt and pulse thrust; reach three pads with limited fuel, low velocity and level feet. Retry the current pad after a crash. |
| Dot Gobbler | Sweep two original mazes, buffer turns, avoid pursuing robots and use temporary power crystals. Collected dots survive a lost hull. |
| Bug Blaster | Clear three garden waves; mushrooms block shots and deflect bugs, while the player dodges in the lower garden. |

All six use original code and original Canvas pixel compositions. No code, art, or runtime from the supplied standalone prototype was copied into these modules. No new Aseprite or Character Generator application export is claimed in this checkpoint.

## Audit changes

- Dino opens after a longer safe interval, followed by three smaller, widely separated ground hazards. One-action retry remains available.
- Color Steps shows animated diagonal control cues before the simulation starts.
- Rock Drift separately demonstrates turning, short thrust and braking on its ready screen.
- Dark Cavern uses distinct walk/aim colors and an action label tied to the actual mode: enter tunnel or fire one bolt.
- Sidecourt marks the reachable swing window and flashes successful contact feedback.
- Flag Run displays the 12-fuel smoke cost beside its action and reports insufficient fuel or recharge.
- A run compares against the best score recorded before that run; its goal does not keep moving as the current score rises.
- End screens offer immediate retry and a next-game link. Tablet navigation labels fit their compact buttons.
- Ready-screen cues have static reduced-motion alternatives and do not consume game time.

## Verified evidence

- 179 Node rule, engine, input and library tests passed.
- 100 browser checks passed against this local build: five per playable cabinet, covering ready/render, keyboard action, pause/resume, restart and emulated touch plus exit cleanup. The browser reads snapshots and sends input; it does not modify game state.
- 23 platform checks passed, including deliberately failed/delayed requests, unavailable storage, fullscreen, keyboard focus and responsive layouts.
- 14 navigation checks passed, including all 20 games at 320/375/768px and 28 consecutive switches with stable listener counts.
- 11 design checks and three focused accessibility checks passed.
- Seven focused retention checks passed: safe first-play cues, reduced motion, mode-aware actions, smoke cost and one-action retry/next-game handoff. Personal-best behavior is asserted in that suite.
- Legal-input simulations won Orbit Duel, Armored Arena, Invader Patrol, Dot Gobbler and Bug Blaster with seeds 1, 2 and 3. Soft Landing reached all three pads with three hulls through legal simulated keyboard input in its rule test. These are simulations, not human or complete browser campaigns.
- Seven existing Sidecourt/Hopway/Flag Run browser checks also passed, including an actual scored court point, flag/fuel collection and mobile controls.
- 891 shared-asset checks passed; all 130 baseline Godot game/UI files retained their hashes.
- All 20 card previews are actual native 480×320 game-canvas captures.

Reports are in [twenty-beta/](twenty-beta/). Screenshots remain in build/arcade/. Browser device checks use Chromium emulation, not physical phones. These counts are automated checks, not player satisfaction results.

## Public release boundary

The public site remains the previous 14-game release. This 20-game checkpoint is a local beta. The audit explicitly requires genuine human playtesting before public release. No completed human observations have been recorded; a general “Yes” to the invitation is not a completed playtest.

The deployment tool now derives the game count from the catalog and checks actual human observations for at least two distinct games before publishing a 20-game release. See [PLAYTESTING.md](PLAYTESTING.md). GitHub source publication and public Pages deployment are separate steps.

## Supplied prototype provenance

OnlyEducation_20_Game_Prototype.zip SHA-256: ec75538641b85a24cb65ff2686dd858c2d4a162bb1c61bd40eaf2189894aa485

The archive was inspected as reference. Its 100-check report concerns a separate engine, with different rules for some similarly named games. Its reported checks and supplied public-site script are not counted among this build’s results. This checkpoint retains the independent module architecture rather than replacing the site with that prototype.

## Reproduce

Run from the authorized IRON-MARIO checkout:

~~~text
rtk proxy node --test tests/arcade/*.test.mjs
rtk proxy python -X utf8 tools/package_arcade.py
rtk proxy python -m http.server 8785 --bind 127.0.0.1 --directory build/web
~~~

With that server running, use a separate terminal:

~~~text
rtk proxy node tools/arcade_100_browser.cjs
rtk proxy node tools/verify_arcade_campaigns.mjs
rtk proxy node tools/retention_browser.cjs
rtk proxy node tests/arcade/platform-browser.cjs
rtk proxy node tools/navigation_browser.cjs
rtk proxy node tools/playground_design_browser.cjs
rtk proxy node tools/navigation_accessibility_browser.cjs
rtk proxy python -X utf8 tools/validate_history_assets.py
rtk proxy python -X utf8 tools/check_arcade_release.py
~~~

The last command intentionally fails while human playtest observations are absent. It makes no network changes. The browser 100-check script accepts ARCADE_URL for a future public build; its local 20-game catalog expectations will correctly reject the older 14-game public build.
