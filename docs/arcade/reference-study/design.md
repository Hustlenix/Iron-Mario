# Browser arcade design study

OnlyEducation / Hustlenix · 2026-10-17

This package reconstructs the public design decisions of Poki and CrazyGames from selected HTML responses, shipped CSS declarations and official documentation. It is independently authored research. Neither website supplied an internal design.md, private developer settings or backend source.

## Read the detailed specifications

- [Poki: grid, typography, cards, motion, player and responsive compositions](poki/design.md).
- [CrazyGames: shell, sidebar states, search, cards and responsive conditions](crazygames/design.md).
- [Source evidence: URLs, hashes, exact declared facts and conditions](source-evidence.json).
- [Original reproducible inspection tool](../../../tools/inspect_reference_design.mjs).

## What was actually inspected

The final capture contains six selected public pages and 43 linked stylesheets, all returning HTTP 200. The extractor records 230 token observations and 118 selected geometry observations. Duplicate declarations and alternate bundle variants are retained deliberately; these are not counts of unique visual components.

| Site | Home | Category | Player |
| --- | --- | --- | --- |
| Poki | https://poki.com/ | https://poki.com/en/arcade | https://poki.com/en/g/subway-surfers |
| CrazyGames | https://www.crazygames.com/ | https://www.crazygames.com/c/arcade | https://www.crazygames.com/game/space-waves |

Also consulted: [Poki's official game-page guidance](https://developers.poki.com/guide/your-game-page).

The crawl is bounded to those six HTML documents and their directly linked CSS on known first-party CDNs. It does not recursively crawl the whole sites, fetch game implementations, download art or fonts, inspect accounts, or search for private source maps. Requests are processed in batches of four with per-request timeouts and file-size limits. The saved evidence contains facts and provenance, not mirrors of complete proprietary source files.

Re-run from the authorized project root:

~~~powershell
rtk proxy node tools/inspect_reference_design.mjs
~~~

The extractor is a lightweight stylesheet scanner. It preserves enclosing media/container conditions, including nested CSS declarations, but does not evaluate the browser cascade or claim a complete CSS parser. Any subsequent reconstruction needs computed-style and screenshot verification.

## Evidence and confidence

| Evidence label | Means | Does not mean |
| --- | --- | --- |
| HTML | Present in the initial HTTP response | Visible or interactive in the final hydrated page |
| CSS | Exact declaration in a shipped file | Applied after specificity, inheritance, runtime classes and overrides |
| Derived | Arithmetic from stated CSS inputs | Measured DOM rectangle |
| Inference | Our interpretation of a design choice | Proven user preference or retention benefit |
| Recommendation | Original proposed OnlyEducation implementation | Already implemented or a copied website requirement |

Browser control returned **Local browser use is disabled in Work settings** during this task. Therefore current DevTools inspection, reference screenshots, mouse interactions and computed geometry were not available. No alternate browser-control route was used. Public HTTP source inspection remains useful, but is a different form of evidence.

## Most consequential differences

| Topic | Poki evidence | CrazyGames evidence | OnlyEducation implication |
| --- | --- | --- | --- |
| Composition | 94px base cells, 16px gutters, mixed spans | Persistent shell with narrow/expanded navigation states | Use coherent spacing; separate collection and playing modes |
| Page chrome | Grid-aligned discovery and game wrapper | 60px header, 200px expanded / 68px collapsed sidebar | Our current 72px header and wide player sidebar consume more room |
| Search | Shared discovery input in returned routes | 460px desktop input, responsive form at 1082px | Keep search reachable without letting it dominate the play surface |
| Card presentation | Square media and conditional hover title/video | Shared 16px image radius plus multiple thumbnail variants | Game images should carry recognition; retain labels for original unfamiliar games |
| Hover | Scale 1.04 and 4px lift in shared card CSS | Container-conditioned media scales | Keep effects restrained and scoped to hover-capable devices |
| Player | Explicit wrapper sizes and a separate 64px bar | Player page retains discovery and recommendations | Treat canvas, toolbar and recommendations as separate layout regions |
| Phone behavior | Fluid rules plus desktop compositions coexist | Dedicated mobile classes and search states | Do not shrink desktop coordinates and call the result mobile |
| Typography | Proxima Nova / Torus declarations | APK Protocol / Artex SemiExtended declarations | Record roles; use OnlyEducation's available fonts rather than importing theirs |

Sources for these numeric facts are linked in each site document and keyed in source-evidence.json. Actual computed rectangles and visual outcomes are still unmeasured.

## Current OnlyEducation comparison [local source inspection]

Inspected onlyeducation/arcade/style.css and the existing UI review. This section records source state, not a fresh gameplay test.

| Element | Current declared state | Design issue to evaluate |
| --- | --- | --- |
| Desktop header | 72px | Could be reduced during gameplay |
| Phone header | 112px, two rows | Search takes a permanent second row; may crowd short screens |
| Desktop sidebar | 208px, then 184px / 168px at smaller breakpoints | Remains comparatively wide while playing |
| Home grid | Five columns base, six wide, four/three/two responsive | Clear but mechanically uniform; native previews may need stronger focal composition |
| Card artwork | Original 480×320 gameplay images | Preserve pixel readability; avoid cropping the player/action out |
| Feature card | Two-column/two-row desktop; single tile on phone | Needs deliberate artwork layout instead of just scaling a capture |
| Search | Up to 500px wide, 42px high | Home search and in-game switching currently have different presentation |
| Player discovery | Games dialog, previous/next and Play next rail | Keep these reachable while reducing duplicated chrome |
| Pixel identity | Gold/mint/navy, original sprites, pixelated image rendering | Express character through artwork and limited accents, not tiny body text |

The prior redesign remains intact. This research task did not change game mechanics, routes, assets or styles, and did not deploy anything.

## Proposed original implementation specification

The following numbers are **our proposed targets**, not measurements of the reference sites and not changes already applied.

### 1. Two deliberate shell modes

Collection mode: 64px desktop header, 200px expanded navigation, 24px content inset. Player mode: 60–64px header, a 64px navigation rail with an explicit expand button, and discovery next to the canvas where width permits. On a narrow screen, use one compact header row and open search on demand rather than reserve a second row permanently.

Keep a visible Games action in the player toolbar. Keyboard labels and accessible names remain available when the sidebar text is hidden. Use click/focus controls for expansion; hover can supplement them but must not be the only way to use navigation.

### 2. Shared spacing and readable scale

Use a 4px fine unit and an 8px primary rhythm. Preferred gaps: 8, 12, 16 and 24px. Prefer 14–16px body/control text and 12px secondary text; avoid 8–10px essential labels. Keep title weight and size consistent within each card role. Use a small number of radii: 6px compact, 12px card, full-round optional chips.

OnlyEducation's existing navy, mint and gold remain the identity. Use gold for the primary action/current choice, mint for secondary progress, and muted grey-blue for metadata. Avoid making every outline, badge and heading an accent.

### 3. Artwork and catalog

Use original covers composed from our pixel assets, with a clear player silhouette, one obvious action and readable environment contrast. The current native canvas captures are honest previews, but a raw screenshot does not automatically make an effective cover. Keep an uncropped action-safe region. Keep a short visible title on touch; show secondary metadata only where it adds a decision.

Do not import Poki/CrazyGames logos, characters, proprietary font files, game covers, background artwork or runtime bundles. Reimplement common layout and navigation patterns in our own components.

### 4. Player and switching

The canvas keeps its native 3:2 composition and nearest-neighbor presentation. Allocate space to the stage before instructions or game history. Keep the controls readable at low laptop heights. Put a stable recommendation region beside the player when it fits; use a horizontal strip below on narrow screens.

Opening discovery must pause the current run and hold focus inside the chooser. Dismissal restores focus and resumes only a previously playing run. Selecting another game destroys the old runtime and opens the destination ready screen. Loading failure keeps Retry and Games available. Preserve these existing OnlyEducation behaviors during any shell rewrite.

### 5. Motion and input

Use a 120–180ms focus/hover response with a maximum 2–4px lift as an initial target. Avoid moving neighboring layout boxes. Respect reduced motion. Touch actions should target at least 44px; a compact visible icon may sit inside a larger hit area. All essential discovery actions must work with keyboard and touch without relying on hover text or media playback.

### 6. Content honesty

Favorites and recent lists should reflect actual local activity. Empty states should explain how to populate them. Planned games stay separate from playable games. Do not introduce invented player counts, ratings, live activity, leaderboard positions or third-party accounts merely to resemble a large portal.

## Pixel verification protocol — still to be executed

A statement such as 'does not vary by a pixel' requires a frozen reference state. Dynamic pages can differ by experiment, locale, login, ads, consent, viewport and font loading. CSS values alone cannot establish parity.

For a precise comparison, collect the following for each agreed reference state:

1. Exact URL, timestamp, viewport in CSS pixels, device scale, browser/version, zoom, locale, account and consent state.
2. Full-page screenshot plus viewport screenshot, before scrolling and after fonts/images settle.
3. Element rectangles for header, navigation, search, first tile, gaps, player wrapper, actual iframe/canvas, toolbar and recommendation region.
4. Computed font family/size/weight/line-height, colors, border, radius, shadow, object fit and overflow for those elements.
5. Separate captures for hover, keyboard focus, open search, empty search, mobile navigation, loading, paused and error states.
6. At least 375×812, 768×1024, 1366×768, 1440×900 and 1920×1080 viewports; boundaries should also be checked immediately above and below the documented breakpoints.
7. Overlay and image-difference artifacts using a deterministic local reconstruction. Mask only genuinely dynamic content and record every mask. Report pixel-difference counts, changed area and rectangle deltas instead of declaring a visual match from memory.
8. For OnlyEducation, compare the original implementation against its approved targets; record intentional brand/art differences separately from accidental layout drift.

No step above has been falsely marked complete. This package is ready for source-based implementation work; reference screenshot parity is an outstanding verification step.

## Deliverables and validation

- Two site-specific design.md documents with source links and exact declared numbers.
- This combined design.md with comparison, original implementation targets and a pixel-verification method.
- A bounded, rerunnable source-inspection script.
- A JSON evidence manifest with response status, byte size, SHA-256 hashes, extracted tokens, selector conditions and limitations.

The script was executed successfully against the public sites. Basic integrity checks verify that the evidence contains the headline values cited above and all referenced local files exist. No OnlyEducation game tests were rerun because no game code changed in this research task.


## Implementation follow-up
The source-state comparison above is the pre-implementation research snapshot. The resulting original OnlyEducation redesign is now implemented and documented in [Playground redesign](../PLAYGROUND_REDESIGN.md), with rendered screenshots and local browser evidence.
