# OnlyEducation Playground redesign

Implemented 2026-10-17 from [the design study](reference-study/design.md). Local preview: http://127.0.0.1:8785/arcade/?v=playground3final#collection .

## Result

The collection uses a 64px header, 200px navigation, an 8px spacing rhythm, readable card labels and original pixel artwork for the Dino feature. The player's navigation collapses to 64px, with an explicit expand button and accessible labels. The canvas keeps its original 3:2 composition; its available height accounts for the toolbar and shorter laptop viewports. Recommendations remain next to the player on larger screens and become a horizontal row below it on narrow screens.

The mobile header is one row instead of two. Its search action opens the shared game chooser. Header actions, touch actions and coarse-pointer favorite controls have 44px minimum hit areas. The mobile navigation drawer shows the complete labels, pauses an active game and keeps keyboard focus within its menu cycle. Moving from that drawer to search retains the original pause/resume intent. Escape restores the run and focus appropriately.

OnlyEducation keeps its navy, mint and gold identity and its original games. The feature art is the existing project-original Dino image, not external game artwork. Other preview images remain real native game-canvas captures. Repeated category overlays were removed; the prehistoric date stays visible on Dino cards. No game mechanics or catalog entries changed in this phase.

The initial #collection anchor used to scroll the heading behind the header after the first render. The load handler now restores the intended initial position while normal player-to-collection return still restores the remembered position.

## Verification

- 149 Node engine/rule/library tests passed.
- 23 platform browser checks passed: storage failure/corruption, loading/recovery, keyboard input, fullscreen, reduced motion, cleanup and mobile layouts.
- 14 navigation checks passed, including 28 consecutive in-player switches with one runtime and 33 stable input listeners, plus all fourteen games at 320/375/768px.
- 3 focused accessibility checks passed for home-switcher return, closed mobile navigation and Escape focus restoration.
- 5 actual Dino / Grid X browser checks passed: keyboard/mouse and emulated touch runner play, seven hazards, collision/replay, persistence, later-terminal retry and zero-resource exit.
- 11 new design checks passed: 64px/200px/64px geometry, original feature art, expanded player navigation, keyboard pause/resume, 44px header/touch targets, full player height, and layouts at 320/375/768/960/961/1366/1920px. Includes a mobile drawer tab loop and search handoff check.
- Source syntax, packaging validation and Git whitespace checks passed.

The browser checks use the project's existing independent headless Chromium harness and actual UI inputs, with read-only QA snapshots. They do not control the user's live browser or inject game state. Screenshots were visually inspected. Pixel equality to another website, human enjoyment and physical-phone verification are not claimed. The public reference design study remains a source-based analysis; this implementation is original.

## Review files

- [Home](screenshots/playground-home.png)
- [Player](screenshots/playground-player.png)
- [Mobile home](screenshots/playground-mobile-home.png)
- [Mobile player](screenshots/playground-mobile-player.png)
- [Mobile drawer](screenshots/playground-mobile-drawer.png)
- [New design evidence](playground-design-evidence.json)
- [Navigation evidence](navigation-evidence.json)
- [Platform evidence](platform-evidence.json)
- [Dino and retry evidence](dino-retry-evidence.json)

## Local source and reproducibility

Source lives under onlyeducation/arcade/; tools/package_arcade.py copies it to build/web/arcade/. The existing local server serves build/web on port 8785. Cache version: playground3final.

~~~powershell
rtk proxy python tools/package_arcade.py
rtk proxy node --test tests/arcade/*.test.mjs
rtk proxy node tests/arcade/platform-browser.cjs
rtk proxy node tools/navigation_browser.cjs
rtk proxy node tools/navigation_accessibility_browser.cjs
rtk proxy node tools/playground_design_browser.cjs
rtk proxy node tools/dino_retry_browser.cjs
~~~

No Git push or public deployment was performed for this local redesign.
