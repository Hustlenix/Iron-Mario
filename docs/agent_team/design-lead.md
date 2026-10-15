# Design lead: implemented arcade menus

The original four-hero selector remains the visual reference. HOME now uses its dark frame and an actual original HeroStage illustration, quick play, hero selection, tournament/daily entry, recent games and two curated shelves. GAMES displays the registered catalog with actual-board thumbnails, search, category/collection/favorites/recent filters, established difficulty1/2/3, sorting, twelve-card pages, save actions and preview/control dialogs. The existing app fields and launch/profile callbacks remain authoritative.

All menu routes use the same CSS-pixel viewport scaling as the selector, including browser canvas/CSS pixel ratio adjustment. New cards have a reserved2:1 preview area and responsive1/2/3-column layouts. Navigation has six desktop columns or three mobile columns; native actions are48px tall. Mission/shop rows and settings controls stack on narrow viewports; secondary-page labels wrap. Rotation pauses only actual gameplay. Games retain the established960x480 board and960x540 canvas scale. The presentation bridge receives the stored reduced-motion preference.

## Verified evidence

- `APP_CHECKS=324 FAILURES=0`: existing app navigation, search/favorites, deterministic win/rewards, single/quick/tournament/daily lifecycle, pause/rotation, interrupted callbacks and bounded scene children.
- `HERO_UI_CHECKS=274 FAILURES=4`: all four failures are the obsolete assertion that HOME restores a 960x540 viewport. The other 270 hero selection, persistence, input, mobile and save-failure checks pass. QA owns updating that intentional menu-scale expectation.
- `ARCADE_MENU_CHECKS=1744 FAILURES=0`: native GPU probe at1280x900,375x812,390x844,430x932 and844x390. All six menu routes fit horizontally, menu buttons are44px or larger and portrait menus have no rotation cover. Search/favorites and nine catalog pages cover all105 registrations.
- Actual rendered HOME and GAMES screenshots at each size: `build/visual-after/arcade_home_<size>.png` and `arcade_games_<size>.png`. I inspected desktop and390px views at full size. An initial preview-height overflow was found visually despite passing bounds checks, fixed, recaptured and reinspected.
- Probe and report: ignored `build/visual-after/arcade_menu_probe.gd` and `arcade_menu_report.json`; isolated profile is restored on exit.

## Remaining gates

These are native engine captures and state/layout checks. They do not establish deployed browser, physical touchscreen or controller acceptance. Secondary-page paint still depends on the shared Design/PaintButton modernization assigned separately. Thumbnail content depicts the real existing boards; it will refresh as the separate105-game presentation work regenerates previews. This menu change does not establish aesthetic acceptance for105 games. The hero test's HOME-scale assertion needs to reflect the intentional CSS-pixel menu viewport instead of its former960x540 scale. No public deployment or Git mutation was performed by this worker.
