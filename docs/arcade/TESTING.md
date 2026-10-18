# Verification

## Commands
```powershell
rtk proxy node --test tests/arcade/*.test.mjs
rtk proxy python tools/validate_history_assets.py
rtk proxy python tools/package_arcade.py
rtk proxy node tools/arcade_wave_a_browser.cjs
rtk proxy node tests/arcade/platform-browser.cjs
rtk proxy node tools/cavern_color_browser.cjs
rtk proxy node tools/court_hop_flag_browser.cjs
rtk proxy node tools/rock_sky_browser.cjs
rtk proxy node tools/fullscreen_touch_browser.cjs
```
Browser commands expect the local server on port 8785. Node and the already installed Playwright are development tools; neither is shipped to players.

## Boundaries
Node tests use seeded input histories, independent level solvers and explicit boundary state fixtures. They verify rules, not enjoyment. Browser tests navigate actual pages and use real keyboard, mouse/touch input with read-only snapshots. Screenshots are actual rendered output. Mobile checks emulate a touch browser, not a physical device. Audio event generation does not establish subjective speaker/headphone quality.

The prior asset check count covers image formats, source provenance and preservation of legacy game/UI hashes. It is not evidence of completed games.

## Release candidate checks
- [ ] All twenty catalog entries have independent working game rules.
- [ ] Each new wave passes rules tests and browser interactions before expansion.
- [ ] Real scoring/progression or a win/loss outcome exercised in each browser game.
- [ ] Keyboard and supported touch controls, pause, restart, exit, mute and storage fallback checked.
- [ ] No browser errors, stale listeners, active RAF or audio after exit.
- [ ] Mobile readability and physical-device input review.
- [ ] Human playtest for difficulty, enjoyment and audio mix.
- [ ] Owner approves public deployment and publication.
- [ ] Owner confirms project licensing and production domain configuration.

Current evidence and remaining work are in STATUS.md.

## Dinosaur and retry checkpoint
144 rule/engine tests now pass. Run rtk proxy node tools/dino_retry_browser.cjs for real desktop/touch jump-and-duck play, collision/replay, scoring, resource cleanup and later-terminal Grid X recovery. The browser suite observes state through read-only snapshots; it never injects outcomes. See dino-retry.md and dino-retry-evidence.json.

## Navigation redesign
Run rtk proxy node tools/navigation_browser.cjs for 14 navigation checks: game search, favorites, recency, focus, fullscreen switching, 28 direct switches, back-scroll restoration and all 14 game layouts at 320/375/768px. The complete rule/engine/library suite now has 149 passing tests. The platform suite retains all 23 checks. Current reports: navigation-evidence.json, navigation-accessibility-evidence.json, platform-evidence.json.

The focused follow-up checks are reproducible with rtk proxy node tools/navigation_accessibility_browser.cjs. The current Dino/terminal suite also passes with immediate real CDP touch events under the redesigned player.


## Playground design verification
Run `rtk proxy node tools/playground_design_browser.cjs` for the 11 responsive shell, mobile drawer, keyboard and player-fit checks. See [the redesign report](PLAYGROUND_REDESIGN.md) for the complete verified scope.
