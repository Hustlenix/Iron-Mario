# CrazyGames — independently reconstructed design notes

Inspected: 2026-10-17. Scope: homepage, Arcade category, Space Waves player and linked public CSS. This is an authored analysis, not CrazyGames' private design file.

## Evidence key

**HTML** means returned page structure; **CSS** means an exact shipped declaration; **Derived** means arithmetic; **Inference** means a design interpretation. CSS is not a screenshot or a computed cascade. Desktop, mobile, game-started, forced-open and hover classes can materially change the result.

## Sources

- [Homepage](https://www.crazygames.com/).
- [Arcade category](https://www.crazygames.com/c/arcade).
- [Space Waves player](https://www.crazygames.com/game/space-waves).
- [Foundation / shell CSS](https://builds.crazygames.com/portal-web/_next/static/css/608124357d51a5d6.css).
- [Shared thumbnail CSS](https://builds.crazygames.com/portal-web/_next/static/css/034d58822652ee3f.css).

Exact requested stylesheet URLs, hashes, selector conditions and capture time are in ../source-evidence.json. The manifest includes route-specific CSS as well as the shared files above. No application scripts or game binaries were downloaded.

## Page structure [HTML]

The shared navigation exposes search, a personal return route and genre links. Home discovery is divided into multiple collections. The player page retains the navigation and includes a separate recommendation region. Game reference information occupies its own section. The category page provides another collection route. This demonstrates the intended navigation hierarchy; actual switching speed was not measured.

## Core tokens [CSS]

| Role | Declaration |
| --- | --- |
| Base unit | 8px |
| Spacing unit | 8px |
| Header height | 60px |
| Expanded sidebar | 200px |
| Collapsed sidebar | 68px |
| Sidebar item height token | 34px; not necessarily final padded hit area |
| Sidebar icon token | 22px |
| Sidebar width transition token | 150ms |
| Medium radius token | 8px |
| Body font token size | 14px |
| Button font token size | 16px |
| H1 token size | 24px |
| Body stack | APK Protocol, APK Protocol Fallback, Arial, sans-serif |
| Display stack | Artex SemiExtended, Artex SemiExtended Fallback, Arial, sans-serif |
| Brand legacy token | #6842ff |
| Deepest shell token | #0c0d14 |
| Raised dark tokens | #13141e, #1a1b28, #212233, #28293d, #2f3148, #373952 |
| Secondary foreground token | #aaadbe |
| Strong foreground token | #f9faff |
| Standard icon size variants | 16, 20, 24, 28, 32px |

The source contains newer semantic aliases and legacy tokens together. A legacy font variable named for Nunito resolves to the current body-family token; its name alone does not establish the active font. Similarly, the presence of a purple token does not mean every active state uses purple.

## Sidebar behavior [CSS]

The main sidebar is fixed at the left edge below the header. Its desktop height subtracts the header from the viewport. It has a one-pixel right divider and its own vertical scrolling container.

| Condition | Declared change |
| --- | --- |
| Default width token | 200px |
| At widths up to 1909.98px | Sidebar width becomes 68px |
| Same collapsed media rule | Links become 48px wide; labels hidden |
| Hover within that media rule | Link width can expand to the full navigation width; labels shown |
| Game-page class without forced-open | Collapsed width and hidden labels also apply |
| Forced-open class | Navigation links and hidden footer material can be revealed |
| Non-desktop class | 200px width with priority; top 0; header-height top padding |
| Hidden class | Left offset equals negative full sidebar width |
| Mobile layer token | z-index 30 |
| Desktop base layer | z-index 5 |

Game-started and forced-open selectors refine hover expansion. Reading just the default 200px token and using a permanently expanded sidebar everywhere would miss an important part of the implementation. Whether a particular device is assigned a desktop class is a runtime question, not established by the media rules alone.

### Link geometry and states [CSS + Derived]

At the 8px unit, the full link-width expression produces 180px: 200 minus two 10px margins. Link padding is 4px vertically and 10px horizontally; the icon-label gap is 6px. The declared link radius resolves through the 8px medium token. Box sizing and line boxes still matter to the final hit region.

Hover uses a translucent light surface; active links have a distinct icon color and heavier text. Disabled links declare opacity 0.3 and a default cursor. These states are component-specific and should not be reduced to one generic button style.

The scrolling container initially hides its scrollbar. Hover-specific rules can reveal a four-pixel scrollbar. OnlyEducation should retain a visible scroll affordance where useful rather than copy every cosmetic behavior.

## Search field and results [CSS]

| Element / condition | Declared value or behavior |
| --- | --- |
| Search form at 1082px+ | Absolute, centered within its positioned ancestor |
| Form through 1081.98px | Relative and flexible |
| Desktop input at 1082px+ | 460px width |
| Input through 1081.98px | 100% width |
| Base field | 40px height; 30px radius |
| Mobile input class | 44px height |
| Field surface | Dark raised token #373952 |
| Input font | Body family, weight 700, size 16px via token |
| Base desktop left/right inset | 16px each |
| Non-desktop left inset | 48px for leading controls |
| Focus | Border changes to brand token |
| Padding transition | 220ms ease |
| Results maximum height | 550px |
| Results positioning | Absolute, full width of container, z-index 99 |
| Results surface | #13141e via token |
| Desktop results radius | 10px |
| Results entrance | 180ms ease animation declaration |
| Outer result inset | 20px at sides and at first/last row edges |
| Tag result padding | 8px |
| Game result padding | 4px |
| Selected result | Raised dark background and pointer cursor |

The styles contain separate mobile search header, mobile overlay, clear/cancel controls, keyboard-visible and selected-option classes. These are evidence of dedicated responsive states. Arrow-key handling, debounce, close-on-Escape and focus restoration require script or runtime observation; they were not tested on the reference website.

A source scrollbar declaration contains the invalid value 7pxpx. Do not replicate it: raw stylesheet presence is not proof that the browser applies a value. This is one concrete reason source copying is not equivalent to reconstruction.

## Cards and recommendations [CSS]

The shared image rules declare 16px corners and cover fitting. Positioned images fill their media region. Desktop related-game hover rules vary with container size: one variant declares scale 1.6, a minimum-300px container overrides to 1.1, and a maximum-150px container supplies 1.35. These are media-element scales, not necessarily outer-card scales.

Do not apply scale 1.6 to every OnlyEducation thumbnail. The reference uses clipping, ancestor classes and container conditions; without those conditions a large transform can obscure adjacent choices. The stylesheet includes dedicated desktop and Originals thumbnail variants, so one universal aspect ratio cannot be inferred from the shared image rule.

Inference: the player and recommendations form separate interaction regions. The game remains visually dominant while other choices stay close enough to discover. The response alone cannot establish how recommendation ranking works or whether the game survives a route change.

## Responsive rules worth preserving as observations

- Search switches layout at the 1082px boundary.
- Sidebar collapse rules use 1910px as a separate boundary.
- Mobile search uses explicit state classes in addition to media queries.
- Related-card media responds to container width, not just viewport width.
- Navigation and search have separate stacking layers.
- The source contains account, premium and other platform-specific UI that OnlyEducation does not need to reproduce.

## Transfer to OnlyEducation [our recommendations]

1. Add a narrow desktop player navigation state, with a deliberate expand control and full keyboard labels.
2. Keep game discovery reachable while playing.
3. Keep search visually stable while results scroll independently.
4. Use one spacing scale, semantic colors and explicit component states.
5. Test recommendation hover effects in their actual container.
6. Make every relevant action available on touch and keyboard, without relying on hover expansion.
7. Keep OnlyEducation fonts and pixel art; the observed font names are not supplied font licenses.

## Unverified

No current reference screenshots, computed geometry, actual keyboard navigation, hover playback, touch behavior, personalized recent list, ranking logic, live game loading, account views, ads or consent variants were tested. There is no zero-pixel-difference claim. Private developer configuration and backend code are outside this public-source inspection.
