### Task 1: Persist `flappy_best` in Global

**Files:**
- Modify: `C:\Users\LalithReddy.b\Iron-Mario\scripts\Global.gd` (lines 3-8 add var; lines 37, 48 add key)

**Interfaces:**
- Consumes: existing `Global.save()` / `Global.load_save()` JSON round-trip (`SAVE_PATH = "user://save.dat"`, keys `best_streak`, `volume`)
- Produces: `Global.flappy_best: int` (loaded in `_ready` via `load_save()`, persisted by `save()`)

- [ ] **Step 1: Add the field and persist it**

In `scripts/Global.gd`, after line 7 (`var best_streak: int = 0`) add:

```gdscript
var flappy_best: int = 0
```

In `save()` change `{"best_streak": best_streak, "volume": volume}` to:

```gdscript
	file.store_string(JSON.stringify({"best_streak": best_streak, "volume": volume, "flappy_best": flappy_best}))
```

In `load_save()` after `volume = float(data.get("volume", 80.0))` add:

```gdscript
		flappy_best = int(data.get("flappy_best", 0))
```

- [ ] **Step 2: Verify parse + boot**

Run: `& "C:\Users\LalithReddy.b\Godot\Godot_v4.7.1-stable_win64.exe" --headless --path C:\Users\LalithReddy.b\Iron-Mario --quit-after 30`
Expected: exits 0, no SCRIPT ERROR in output. (Main scene `title_screen.tscn` boots; Global is an autoload so its script parses on boot.)

- [ ] **Step 3: Commit**

```bash
git add scripts/Global.gd
git commit -m "feat(flappy): persist flappy_best in Global save"
```

---
