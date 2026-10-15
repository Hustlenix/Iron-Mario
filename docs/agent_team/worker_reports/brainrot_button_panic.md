# Brainrot Button Panic presentation

Status: **implemented, awaiting rendered review**.

- Inspected `games/chaos.gd`: configure/next_prompt/pad at lines 7–36, button input at lines 46–57, timeout at lines 125–126, and paint at lines 251–258. Inspected the presentation contract and UI acceptance standard, and viewed `build/visual-before/catalog-qa/brainrot_button_panic_board.png`.
- Active bounds: four pad centers `(170 + 205 * index, 280)` with drawn radius 65 and click radius 70. The prompt starts at `(270, 140)`; progress starts at `(350, 445)`; HUD uses the top strip. No geometry or input changes.
- Baseline: four clearly labeled colored buttons over a cream board and faint generic skyline. The instruction and count are readable, but the environment does not reinforce the instruction/opposite-direction joke.
- New setting: an overloaded instruction desk with an overstuffed paper intake, curling receipt machine, pale desk depth and apron, rim-mounted cables, spilled clipped paperwork, and an oversized eraser. Machine props stay at the outer edges; the prompt wall, pad field, and progress area remain quiet and light.
- All scenery is original deterministic vector drawing. No resources, RNG, transforms, context mutations, gameplay edits, or external assets. The scene is static, so reduced motion and pause retain the same presentation without decorative motion.
- Integration caveat: this game's inspected paint branch does not draw a full-board opaque rectangle. Parent should confirm the shared background bridge ordering and review HUD/long opposite prompts, pad readability, and action feedback in rendered desktop/mobile captures. No engine, Git, or render processes were run by this worker; visual acceptance is pending.

Owned output: `ui/game_presentations/brainrot_button_panic.gd` and this report.
