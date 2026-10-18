# Poki — independently reconstructed design notes

Inspected: 2026-10-17. Scope: homepage, Arcade category, Subway Surfers player and their linked public stylesheets. This is our research document, not an internal Poki file.

## Evidence levels

- **HTML**: directly present in the returned public page.
- **CSS**: exact declaration in a shipped stylesheet; not a computed or screenshot measurement.
- **Derived**: arithmetic using CSS values.
- **Inference**: interpretation that needs a rendered browser check.

The HTTP responses identify an English, left-to-right, desktop page variant. Responsive CSS is available, but that does not establish the actual mobile runtime layout. No authenticated settings were accessed.

## Primary sources

- [Homepage](https://poki.com/), [Arcade category](https://poki.com/en/arcade), [Subway Surfers player](https://poki.com/en/g/subway-surfers).
- [Shared foundation CSS](https://a.poki-cdn.com/assets/client~main-e96e9bea~316fa29527fdfee8aa44.css).
- [Homepage CSS](https://a.poki-cdn.com/assets/client~app-components-PageHome-e96e9bea~e6d583567608f2e1f53b.css).
- [Player layout CSS](https://a.poki-cdn.com/assets/client~app-components-PageGame-63393a95~207145bd22d808618576.css).
- [Player component CSS](https://a.poki-cdn.com/assets/client~app-components-GamePlayer~0ab1cc095d5cc2716d60.css).
- [Official game-page guidance](https://developers.poki.com/guide/your-game-page).

See ../source-evidence.json for exact URL variants, hashes, selector identifiers, enclosing conditions and capture time. Hashed bundle URLs can change between requests.

## Information architecture [HTML]

The home response places search, category navigation and discovery content before its explanatory footer. The category route is a dedicated collection rather than a modal. The player response retains discovery links, game identity, feedback/fullscreen actions, related games, controls and lower-page reference material. That structure is evidence of multiple routes into another game; it does not prove which route users prefer.

## Foundation [CSS]

| Role | Declared value | Qualification |
| --- | --- | --- |
| Grid cell | 94px | --cellSize |
| Maximum fluid cell | 144px | --cellSizeMax |
| Cell gutter | 16px | --cellSpacing |
| Maximum page token | 1860px | Not a guaranteed rendered content width |
| Navigation row token | 343px | A component token, not universal search width |
| Small/medium/large radius | 4 / 8 / 16px | Playground light aliases |
| Pill radius | 9999px | Full-round alias |
| Spacing aliases | 4, 8, 12, 16, 24, 32, 48, 64px | 2xs through 3xl |
| Body font stack begins | Proxima Nova | Fallbacks include Open Sans and Arial |
| Rounded display stack begins | Torus | Font names observed; font files not downloaded |
| Core blue | #009cff | Brand token |
| Deep blue | #002b50 | Text/inverted roles in the light theme |
| Muted blue-grey | #5d6b84 | Legacy grey alias |
| Light surface | #f0f5fc | Subtle background role |
| Pale canvas | #f9fbff | Grey token |
| Accent set | #15c8d1 / #ff7690 / #c977e8 / #ffc500 | Teal, pink, purple, yellow |
| Mid shadow | x0 y7 blur10 spread4, #5d6b844d | Source token; CSS pixels |
| Hover shadow | x0 y12 blur16 spread8, #5d6b844d | Source token |

Do not infer the page's final background from a single palette token. The source also declares background images, theme selectors and component overrides.

## Grid arithmetic [Derived]

For n fixed 94px cells with 16px gutters, occupied width is 94n + 16(n−1). A two-cell square spans 204px, a three-cell square 314px, and a four-cell square 424px. The gutters are part of the larger card's span, so mixed card sizes align to the same grid.

A separate fluid-cell formula subtracts two 16px page margins and all gutters from the viewport, divides by the column count, and clamps each cell between 94px and 144px. The default fluid column token is three, becoming five at 566px. This is a separate rule path from the fixed desktop compositions below.

## Desktop compositions [CSS]

Both category and player composition classes occur in their corresponding returned HTML. The homepage has its own mixed-span composition. This table records declared grid tracks; it does not mean that many full-size cards fit in one row.

| Width condition in CSS | Composition tracks | Fixed grid width, derived |
| --- | ---: | ---: |
| 111–770.9px | 6 | 644px |
| 771–990.9px | 7 | 754px |
| 991–1210.9px | 9 | 974px |
| 1211–1320.9px | 11 | 1194px |
| 1321–1540.9px | 12 | 1304px |
| 1541–1870.9px | 14 | 1524px |
| 1871px+ | 17 | 1854px |

Important: a 644px desktop composition declared under a small width condition is **not** evidence that the real phone page overflows. The server-selected desktop class, alternative fluid paths and runtime classes must be resolved in a browser before making that claim.

The shared grid declares dense row packing, centered tracks, a 16px gap and rows based on the page cell size. The homepage supplies explicit placements and mixed spans. The category and player use different placements at the same width boundaries. Copying only the column count would lose the actual composition.

## Game cards [CSS]

| Property/state | Declared behavior |
| --- | --- |
| Base shape | Square media, inherited image radius, 16px card radius |
| Image fit | Cover, full media width and height |
| Base transform timing | 600ms with cubic-bezier(.25,.1,.25,1) |
| Hover capability guard | Hover rules restricted to hover-capable devices |
| Card hover | Scale 1.04, lift 4px; transition duration becomes 300ms |
| Title | Bottom overlay, white, weight 700, default 12px, line-height 1.3 |
| Title inset | 6px |
| Default title opacity | 0 in the shared rule; inspect variants before assuming every title is hidden |
| Hover title | Opacity 1, transform returns to its resting position |
| Media preview | Video element becomes visible on hover in the shared card rule |
| Readability layer | A bottom gradient fades in over media |

Inference: the artwork carries recognition, while the hover title supplies confirmation. It reduces permanent text density. For OnlyEducation, a visible short title is preferable on touch devices and with unfamiliar original games.

## Player geometry [CSS]

The player wrapper class is .O6aS7QO5ETmydBF0bVB7 in this capture.

| Width condition | Declared wrapper width × height |
| --- | --- |
| 111–1210.9px | 640 × 424px |
| 1211–1320.9px | 836 × 534px |
| 1321–1540.9px | 836 × 534px |
| 1541–1870.9px | 1031 × 644px |
| 1871px+ | 1031 × 644px |

These are wrapper declarations, not proof of the embedded game's pixel size. The same component stylesheet declares a 64px player bar. Treating wrapper height as canvas height would produce an incorrect reconstruction. Fullscreen overrides set width and height to 100% with priority. Embedded iframe/object containers fill their allocated stage.

The bar's title declaration is 700 weight, 16px/20px; its secondary line is 12px/16px. The component contains 36px icon dimensions with 6px padding. Loading progress is a separate 5px-high strip with a 500ms linear width transition. These states should not be conflated with game art.

## Official preview guidance [documentation]

Poki specifies square, muted MP4 hover previews lasting 4–6 seconds, at least 1080×1080 and 50fps, with a 100MB maximum. It recommends showing the game clearly and keeping text light. Its fullscreen policy is selective rather than a universal entitlement. These are Poki submission requirements, not mandatory OnlyEducation specifications.

## Transfer to OnlyEducation [our recommendation]

1. Use predictable spacing and coherent spans, so larger feature cards fit the same rhythm as regular cards.
2. Keep native game art dominant and avoid website screenshots inside thumbnails.
3. Use restrained hover lift with an equivalent focus treatment; never depend on hover for discovery.
4. Put controls and detailed game history below the play area.
5. Preserve OnlyEducation's original pixel art, name, gold/mint palette and readable titles.
6. Avoid importing Poki fonts, branded background images, logos, game artwork or proprietary modules.

## Unverified

No current screenshots, DOM bounding boxes, computed font metrics, device-pixel ratios, video start latency, actual responsive phone page, consent overlays, focus order or game loading interaction were measured. CSS hover declarations demonstrate intent, not observed runtime behavior. Pixel parity remains unmeasured.
