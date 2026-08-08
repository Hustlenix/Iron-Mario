### Task 5: Difficulty ramp verification

**Files:**
- Modify: `C:\Users\LalithReddy.b\Iron-Mario\test_flappy.gd`

**Interfaces:**
- Consumes: `_ramp_speed()` / `_ramp_gap()` / `_ramp_interval()` (Task 4), `score` var, `_score()`
- Produces: `"ramp"` driver mode asserting the ramp functions actually scale with score

- [ ] **Step 1: Add the failing test**

Extend `_initialize` in `test_flappy.gd`:

```gdscript
	if args.has("ramp"):
		await _test_ramp()
	elif args.has("flap"):
		await _test_flap()
	else:
		...
```

and add:

```gdscript
func _test_ramp() -> void:
	flappy.flap()
	flappy.set("score", 0)
	await process_frame
	var ramp_0 := flappy.call("_ramp_speed")
	flappy.set("score", 25)
	await process_frame
	var ramp_25 := flappy.call("_ramp_speed")
	if ramp_0 == 240.0 and ramp_25 == 330.0:
		flappy.set("score", 0)
		flappy.call("_score")
		flappy.call("_score")
		if flappy.get("score") == 2:
			print("RAMP TEST OK")
			quit(0)
			return
	print("RAMP TEST FAIL: speed %f -> %f" % [ramp_0, ramp_25])
	quit(1)
```

- [ ] **Step 2: Run â€” expect FAIL**

Run: `& "C:\Users\LalithReddy.b\Godot\Godot_v4.7.1-stable_win64.exe" --headless --path C:\Users\LalithReddy.b\Iron-Mario --script res://test_flappy.gd -- --ramp`
Expected: FAIL â€” `_ramp_speed` not defined on the skeleton (boot mode only) or wrong values.

- [ ] **Step 3: No game change needed**

The ramp functions were implemented in Task 4 (`_ramp_factor` / `_ramp_speed` / `_ramp_gap` / `_ramp_interval`). If the FAIL persists after Task 4 is in place, debug the values directly.

- [ ] **Step 4: Run â€” expect PASS**

Run: `... --script res://test_flappy.gd -- --ramp`
Expected: `RAMP TEST OK`.

- [ ] **Step 5: Commit**

```bash
git add test_flappy.gd
git commit -m "test(flappy): ramp verification"
```

---
