# Task 1 Report: Persist `flappy_best` in Global

**Status:** DONE

## What I implemented

Added the persistent best-score field to `scripts/Global.gd`, exactly per the brief:

1. Added `var flappy_best: int = 0` after `var best_streak: int = 0`.
2. In `save()`, extended the JSON payload to `{"best_streak": best_streak, "volume": volume, "flappy_best": flappy_best}`.
3. In `load_save()`, added `flappy_best = int(data.get("flappy_best", 0))` after the volume line — the default 0 keeps existing save files (which lack the key) loading cleanly.

No other changes. No comments added. Tabs/snake_case per project style.

## Test / verification results

- Ran: `& "C:\Users\LalithReddy.b\Godot\Godot_v4.7.1-stable_win64.exe" --headless --path C:\Users\LalithReddy.b\Iron-Mario --quit-after 30`
- Result: EXIT_CODE=0, stdout shows only the Godot version banner, stderr empty. No SCRIPT ERROR — Global (autoload) parses and `_ready()` → `load_save()` runs on boot.

## Files changed

- `scripts/Global.gd` (+3/-1)

## Commits

- `718570d` feat(flappy): persist flappy_best in Global save

## Self-review findings

- **Complete?** Yes. The field is declared, persisted by `save()`, and restored by `load_save()` on boot. Round-trip coverage is identical to the existing `best_streak`/`volume` keys.
- **Minimal?** Yes. 3 insertions, 1 deletion; no scope creep (e.g., `reset()` intentionally left untouched — a best score should survive resets).
- **Backward compatible?** Yes. `data.get("flappy_best", 0)` defaults to 0 for pre-existing `save.dat` files.

## Concerns

None.
