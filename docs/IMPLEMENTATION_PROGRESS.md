# Implementation and release progress

Updated 2026-10-09. Starting production commit: fa43bea, 50 games. Working branch: codex/arcade-100-audit.

## Implemented

- 105 registered games: preserved 50, puzzles 25, classics 16, chaos 11, restored cabinets 3.
- Real gameplay rules, input, action-driven success and failure, pause, seeded restart, one result and cleanup coverage for every ID.
- Search, category and collection filters, favorites, recent games, record sorting, twelve-card pagination, original rendered previews and control modals.
- Two-finger hold and independent parking controls, cancellation on focus/orientation pause, keyboard/controller puzzle shortcuts, single-command directional input, orphan release protection.
- 46 real Play Store listing references and 24 shortlisted mechanics; no fabricated download or rating figures.
- Supplied extracted asset inventory and license audit. Authored garage composite from licensed LimeZu Modern Interiors. Installers and unverified asset packs excluded.

## Executed evidence

All thirteen suites passed with zero failures: services 170; pack A 175; pack B 75; input 24; native input 91; app 359; catalog 1492; restored cabinets 151; classics A 144; chaos 165; pack C 834; classics B 99; performance 424. Final app rerun after short-pool filtering also passed 359 checks.

Native GL captures cover all 105 boards plus representative desktop/mobile layouts. These are actual rendered boards, not substitute artwork. Physical-phone FPS, browser heap, human fun balancing and complete manual browser loops for every ID remain unverified. Engineering grades remain honest B/C judgments in GAME_AUDIT.md.

## Release gate

Web and Windows exports succeeded. The final exported Windows executable launched headlessly without engine errors. The 40,801,107-byte Windows ZIP passed CRC verification and includes the executable and required PCK.

Local browser evidence: library reports 105 games; search and rendered previews work; new cabinet pause/home navigation works; Disk Delivery solved via fourteen real browser clicks, resulting in seven moves, 187 points and one reward. Replay resets moves/time; pause and menu return work. The final puzzle keyboard cursor was also visibly verified in a fresh-profile Web export.

## Published release

Gameplay release commit **9680927**, preceded by full-catalog checkpoint **4feaab9**. [Final build, all thirteen suites, browser, Windows and deployment jobs passed](https://github.com/Hustlenix/Iron-Mario/actions/runs/37934144241). [GitHub Pages publication passed](https://github.com/Hustlenix/Iron-Mario/actions/runs/37935373544).

[Public arcade](https://hustlenix.github.io/Iron-Mario/) was checked directly after publication: 105-game catalog, rendered previews, search, seven-move Disk Delivery win, result/reward, fresh replay, pause, menu return and retained prior records. The final keyboard puzzle cursor was visibly confirmed on the public site, followed by another complete seven-move win. Browser warning/error logs were empty during the verified loop. Screenshot evidence is stored locally at `build/public-puzzle-win.png`.

The complete release rerun comprises **4203 checks with zero failures**. This does not assert manual browser play of every game or physical-phone performance. Full commercial-readiness/human-fun claims remain withheld; the audit records specific B/C refinement tasks. Existing user checkouts and Hackatime configuration remain preserved.
