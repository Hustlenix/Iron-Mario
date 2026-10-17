# OnlyEducation Sprint — 5-Day Log

**Project:** Super-Micro Heroes — a nostalgic pixel-art browser arcade (Godot 4.7.1, 1280×720, HTML5).
**Repo:** `Hustlenix/Iron-Mario` · branch `feat/onlyeducation-five-day-sprint` · live: https://hustlenix.github.io/Iron-Mario/
**Sprint goal:** make the game feel like a real product — presentation, stability, and content a stranger can love in ten seconds.

One report per working day: Completed · Files changed · Commits · Tests · Engineering time · Known problems · Next priority.

---

## DAY 1 / 5 — Saturday, October 17, 2026

### Completed

- **Arcade hub rebuilt** — search, category chips (All / Action / Skill / Quick / Recent / Favorites), favorites shelf, recently-played shelf, and launch guards so a cabinet can't be double-launched mid-play. (`2f89e65`)
- **Ten cabinet covers** — pixel-art SVG thumbnails for every cabinet, wired through the registry and enforced by a cover-verification test. (`88f5ab8`)
- **Arc Break escape fix** — every cabinet now honors the "ESC ARCADE" hint; a new source-wiring test catches any regression. (`b79ad55`)
- **Browser smoke harness** — `npm run smoke` drives title → arcade → search → favorites → Arc Break → Arc Snake → Brick Reactor → recent shelf in headless Chromium, and fails on any console error. (`cef7ca0`)
- **Web build diet** — the pck no longer bakes in tooling folders: 28.1 MB → 1.3 MB; stale import cache purged (26.5 MB → 1.9 MB on disk). (`56df2b1`)
- **Repo hygiene** — generated artifacts, node tooling, and the nested `IRON-MARIO` folder are gitignored. (`37f04da`)
- **Branding sweep closed** — audited every tracked file; no player-visible legacy names remain; dev-tooling package renamed to `super-micro-heroes-tools`. (`48bfa35`)

### Files changed

35 files — 10 new cabinet covers (+ their `.import` sidecars), the arcade hub, game launcher registry, Arc Break, three test files, the smoke harness + npm manifests, export presets, `.gitignore`, and docs.

### Commits

`2f89e65` → `37f04da` → `88f5ab8` → `b79ad55` → `cef7ca0` → `56df2b1` → `48bfa35` (+ this log)

### Tests

| Check | Result |
|---|---|
| test_registry | ALL PASS |
| test_arcade_menu | 59 checks, 0 failed |
| test_arcade_cabinets | 48 checks, 0 failed |
| test_heroes | pass — 131 checks |
| test_powers | pass |
| test_touch_controls | ALL PASS |
| verify_music | 25 checks, 0 failed |
| Browser smoke (full arcade flow) | pass — 0 console errors |
| Headless import + web export | exit 0 |

### Engineering time

3h 54m tracked today (Hackatime).

### Known problems

- Title screen still stamps `V1.2 — AUG 8 2026`; needs a version-bump decision.
- Windows `.exe` export has no custom icon (web/PWA icons are branded).
- `test_*.tscn` scenes still ship inside the web pck — harmless, noted for a future slimming pass.

### Next priority

- Ship today's build to the live URL for feedback: push branch + merge to `main` → GitHub Pages (owner approval required).
- Continue sprint days 2–5.
