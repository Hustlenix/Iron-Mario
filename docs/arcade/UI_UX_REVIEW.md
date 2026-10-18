# Arcade navigation and interface review — 2026-10-17

## Reference study
The current official [CrazyGames homepage](https://www.crazygames.com/) exposes search, recently played and genre navigation. Its [Space Waves game page](https://www.crazygames.com/game/space-waves) retains discovery navigation and a Play next section alongside the game.
The official [Poki homepage](https://poki.com/) emphasizes instant entry through a collection of games and categories. [Poki's game-page documentation](https://developers.poki.com/guide/your-game-page) recommends gameplay-focused promotional imagery and minimal text in previews.

These observations informed the structure. They are not evidence that this redesign improves retention; human feedback is still needed. OnlyEducation uses its own brand, original artwork and original game implementations.

## Problems in the previous interface
- Switching usually required leaving the player, returning to a long collection page and finding another tile.
- The tall introductory section and history material preceded the main task.
- Instructions, oversized headings and always-visible desktop touch controls reduced the visible play area.
- Several old thumbnail exports contained the surrounding webpage, making them poor previews.
- There were no personal recent or favorite lists.

## Implemented
- Persistent search and category navigation; the playable collection is the main home content.
- Searchable native game-switch dialog, reachable from Games, the header or G.
- Opening the switcher pauses an active run. Dismissal resumes only a run that was playing. An already-paused game stays paused.
- Direct Play next thumbnails and previous/next links. Selecting a game opens its ready screen; Play remains deliberate.
- Return to the collection retains the previous scroll position and selected tile focus.
- Local favorites and a deduplicated ten-game recent list, with safe session fallback if storage is unavailable.
- Larger play surface, compact toolbar and optional desktop touch controls. Coarse-pointer devices show touch controls automatically.
- A mobile navigation drawer, horizontally scrolling recommendations and larger action targets.
- All fourteen thumbnails are native 480x320 captures of the rendered game canvas. No third-party artwork was imported.
- Historical context and planned games remain available in collapsed sections.
- Existing ready/pause/retry/error states and game modules remain in place.

## QA
149 rules/engine/library checks pass. Browser navigation tests cover dialog focus and pause/resume, filtered favorites, recently played, search, 28 consecutive switches, fullscreen switching, returning to the collection and all fourteen game layouts at 320/375/768px.
The platform suite separately checks storage/network failures, keyboard actions, fullscreen and 320/375/430/768px layouts. Reports accompany the completed checkpoint.
Actual Chromium automation uses UI input and read-only observations; it does not inject game state. Physical phone and human enjoyment review remain open.

Final follow-up: all 23 platform checks, 14 navigation checks and three focused keyboard/mobile checks pass. The Dino/terminal suite also passes desktop and real emulated touch gameplay, with score persistence and zero-resource exit.
