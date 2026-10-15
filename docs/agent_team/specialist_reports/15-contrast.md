# Specialist 15: Color contrast QA

Implemented shared secondary-menu styling in `ui/design.gd`. No other application files were edited.

## Caller inspection and resulting behavior

- `game_app.gd` uses `Design.PAPER` for full-page and orientation-cover backgrounds, and explicitly uses `Design.INK` for settings toggle text. Their legacy names now resolve to cinematic navy `#101c28` and warm light text `#faf3df` respectively.
- Missions, shop and profile cards use the new `#1b2c3a` default panel. Existing helper signatures, constants, callbacks and PaintButton return type are preserved. Default theme/helper font size is 16 px; existing caller-specified heading sizes remain supported.
- The legacy compact card passes an explicit cream `#f8e4ab` surface. Panel metadata and a label tree-entered handler preserve that surface and select readable dark text, including when a requested accent would fall below 4.5:1.
- Colored button helpers select light or dark text with actual sRGB relative-luminance calculations. They set PaintButton's existing `ink` property, native font overrides and `design_text_color` metadata. Separate PaintButton ownership was notified of the contract.
- Native buttons, CheckButton/CheckBox and OptionButton receive rounded 1 px borders, dark hover/pressed states and an independent transparent 2 px gold focus overlay. LineEdit caret, placeholder and selected text are explicit. PopupMenu surfaces, disabled labels, HSlider rails and ProgressBar track/fill are themed.
- ProgressBar percentage text has a dark 4 px outline because text can span both a light fill and dark track. Current game/result callers hide percentage text.

## Measured contrast

Calculated independently using the WCAG sRGB linearization formula `(L_lighter + 0.05) / (L_darker + 0.05)`; values below are opaque foreground/background pairs. Ratios validate palette choices, not an executed screen audit.

| Foreground / surface | Ratio |
| --- | ---: |
| Warm light text / page navy | 15.55:1 |
| Warm light text / panel navy | 12.91:1 |
| Warm light text / hover navy | 10.22:1 |
| Muted/placeholder text / panel navy | 6.76:1 |
| Coral label / panel navy | 6.79:1 |
| Blue label / panel navy | 7.93:1 |
| Green label or progress fill / panel navy | 8.27:1 |
| Navy text / gold button | 10.31:1 |
| Navy text / blue button or selection | 9.55:1 |
| Navy text / green button | 9.96:1 |
| Navy text / coral button | 8.18:1 |
| Navy text / explicit cream card | 13.68:1 |
| Gold focus ring / panel navy | 8.56:1 |
| Control border / panel navy | 3.31:1 |

All listed text pairs exceed 4.5:1; the normal control boundary exceeds 3:1. Hover boundaries use gold rather than the normal gray border.

## Validation boundary and risks

- Inspected all Design calls in the UI and confirmed gameplay drawing constants belong to MicrogameBase rather than this shared UI class. No gameplay constants, scene files, games, Git operations, deployment actions or engine processes were changed/run.
- Root owns consolidated Godot parse/runtime/browser validation. These checks still need to exercise MISSIONS, SHOP, PROFILE, SETTINGS, the library dropdown popup, keyboard focus, colored/disabled PaintButtons and gameplay/results chrome.
- The previously existing PaintButton draws its own styles and fades disabled text; native theme overrides alone cannot guarantee its disabled contrast or focus treatment. Its separate owner must keep the new text-on-fill behavior in the custom draw path. No edits were made to `ui/paint_button.gd`.
- Explicit caller font sizes remain large where already specified. Palette ratios do not establish full WCAG conformance, responsive layout correctness, or physical display visibility.
