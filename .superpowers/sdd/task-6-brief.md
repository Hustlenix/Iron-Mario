### Task 6: Medals + NEW BEST moment

**Files:**
- Modify: `C:\Users\LalithReddy.b\Iron-Mario\scenes\flappy_bird.gd`
- Modify: `C:\Users\LalithReddy.b\Iron-Mario\test_flappy.gd`

**Interfaces:**
- Consumes: `_score()` (Task 4), `medal_label`, `sfx_win`, `best`, `new_best_fired`, `medals`
- Produces: `_MEDALS` const (ordered array), `_check_medal()` called from `_score()`, `_check_new_best()` called from `_score()`

- [ ] **Step 1: Add the failing test**

Extend `_initialize`:

```gdscript
	if args.has("medal"):
		await _test_medal()
```

and add:

```gdscript
func _test_medal() -> void:
	flappy.flap()
	flappy.set("best", 0)
	flappy.set("new_best_fired", false)
	flappy.set("score", 4)
	flappy.call("_score")
	if flappy.get("medals").size() == 0:
		flappy.set("score", 5)
		flappy.call("_score")
	var medal_text := flappy.get_node("HUD/MedalLabel").text
	if medal_text != "BRONZE":
		print("MEDAL TEST FAIL: label=%s" % medal_text)
		quit(1)
		return
	flappy.set("best", 0)
	flappy.set("new_best_fired", false)
	flappy.set("score", 1)
	flappy.call("_score")
	var fired: bool = flappy.get("new_best_fired")
	var saved: int = Global.flappy_best
	if fired and saved == 2:
		print("MEDAL TEST OK")
		quit(0)
		return
	print("MEDAL TEST FAIL: new_best fired=%s saved=%d" % [fired, saved])
	quit(1)
```

- [ ] **Step 2: Run â€” expect FAIL**

Run: `... --script res://test_flappy.gd -- --medal`
Expected: FAIL â€” `medal_label.text` is `""`.

- [ ] **Step 3: Implement medals + new best**

Add after the consts block in `scenes/flappy_bird.gd`:

```gdscript
const _MEDALS := [
	{"score": 5, "name": "BRONZE", "color": Color(0.72, 0.45, 0.22)},
	{"score": 10, "name": "SILVER", "color": Color(0.8, 0.8, 0.85)},
	{"score": 20, "name": "GOLD", "color": Color(1.0, 0.84, 0.3)},
	{"score": 40, "name": "PLATINUM", "color": Color(0.55, 0.9, 1.0)},
]
```

Add at the end of `_score()`:

```gdscript
	_check_medal()
	_check_new_best()
```

Add methods:

```gdscript
func _check_medal() -> void:
	for medal in _MEDALS:
		if score >= int(medal.score) and not medals.has(medal.name):
			medals[medal.name] = true
			medal_label.text = medal.name
			medal_label.add_theme_color_override("font_color", medal.color)
			Juice.burst(self, Vector2(1100.0, 60.0), medal.color, 16, 260.0)
			Juice.text(self, medal.name, Vector2(1180.0, 90.0), medal.color, 34)
			sfx_score.play()

func _check_new_best() -> void:
	if not new_best_fired and score > best:
		new_best_fired = true
		best = score
		Global.flappy_best = best
		Global.save()
		best_label.text = "BEST: %d" % best
		score_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.3))
		sfx_win.play()
		Juice.burst(self, Vector2(BIRD_X, bird_y), Color(1.0, 0.84, 0.3), 22, 320.0)
		Juice.text(self, "NEW BEST!", Vector2(BIRD_X + 30.0, bird_y - 30.0), Color(1.0, 0.84, 0.3), 38)
```

- [ ] **Step 4: Run â€” expect PASS**

Run: `... --script res://test_flappy.gd -- --medal`
Expected: `MEDAL TEST OK`.

- [ ] **Step 5: Commit**

```bash
git add scenes/flappy_bird.gd test_flappy.gd
git commit -m "feat(flappy): milestone medals + NEW BEST moment"
```

---
