### Task 7: Feather pickups

**Files:**
- Modify: `C:\Users\LalithReddy.b\Iron-Mario\scenes\flappy_bird.gd`
- Modify: `C:\Users\LalithReddy.b\Iron-Mario\test_flappy.gd`

**Interfaces:**
- Consumes: `_spawn_pair` (calls `_spawn_pickup_if_due`), `_move_pickups`, `_collides` (shield-pop branch), `pickups_node`, `feather_icon`, `feather_next_spawn`, `feather_every_min/max`, `_spawned`
- Produces: full `_spawn_pickup_if_due(center, use_gap)` that spawns a 40x40 `shard.svg` TextureRect at the gap center when `_spawned > 3 and _spawned == feather_next_spawn`, then sets `feather_next_spawn = _spawned + randi_range(min,max)`

- [ ] **Step 1: Add the failing test**

Extend `_initialize`:

```gdscript
	if args.has("feather"):
		await _test_feather()
```

and add:

```gdscript
func _test_feather() -> void:
	flappy.flap()
	flappy.set("_spawned", 4)
	flappy.set("feather_next_spawn", 5)
	flappy.call("_spawn_pair")
	await process_frame
	var pickup_count := flappy.get_node("Pickups").get_child_count()
	if pickup_count == 0:
		print("FEATHER TEST FAIL: pickup did not spawn")
		quit(1)
		return
	flappy.set("bird_y", 250.0)
	flappy.set("velocity", 0.0)
	var pickup := flappy.get_node("Pickups").get_child(0)
	pickup.position = Vector2(220.0, 230.0)
	_run_frames(10)
	if flappy.get("feathers") != 1:
		print("FEATHER TEST FAIL: not collected")
		quit(1)
		return
	flappy.set("invuln_timer", 0.0)
	flappy.set("bird_y", 700.0)
	flappy.set("velocity", 900.0)
	_run_frames(30)
	if flappy.get_state() == "game_over":
		print("FEATHER TEST FAIL: shield did not save")
		quit(1)
		return
	flappy.set("invuln_timer", 0.0)
	flappy.set("bird_y", 700.0)
	flappy.set("velocity", 900.0)
	_run_frames(120)
	if flappy.get_state() == "game_over":
		print("FEATHER TEST OK")
		quit(0)
		return
	print("FEATHER TEST FAIL: second hit did not kill (state=%s)" % flappy.get_state())
	quit(1)
```

- [ ] **Step 2: Run â€” expect FAIL**

Run: `... --script res://test_flappy.gd -- --feather`
Expected: FAIL â€” pickup did not spawn (no-op).

- [ ] **Step 3: Implement**

Replace the `_spawn_pickup_if_due` no-op in `scenes/flappy_bird.gd`:

```gdscript
func _spawn_pickup_if_due(center: float, use_gap: float) -> void:
	if _spawned <= 3 or _spawned != feather_next_spawn:
		return
	var pickup := TextureRect.new()
	pickup.texture = load("res://assets/shard.svg") as Texture2D
	pickup.custom_minimum_size = Vector2(40.0, 40.0)
	pickup.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	pickup.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pickup.position = Vector2(1400.0, center - 20.0)
	pickups_node.add_child(pickup)
	feather_next_spawn = _spawned + randi_range(feather_every_min, feather_every_max)
```

- [ ] **Step 4: Run â€” expect PASS**

Run: `... --script res://test_flappy.gd -- --feather`
Expected: `FEATHER TEST OK`.

- [ ] **Step 5: Commit**

```bash
git add scenes/flappy_bird.gd test_flappy.gd
git commit -m "feat(flappy): feather shield pickup"
```

---
