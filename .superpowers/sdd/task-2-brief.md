### Task 2: Title screen FLAPPY button

**Files:**
- Modify: `C:\Users\LalithReddy.b\Iron-Mario\scenes\title_screen.tscn`
- Modify: `C:\Users\LalithReddy.b\Iron-Mario\scenes\title_screen.gd`

**Interfaces:**
- Consumes: `Global.flappy_best` (Task 1), `SceneFade.fade_out(root)`, existing button handler pattern (`_on_start_button_pressed`)
- Produces: `MenuButtons/FlappyButton` (text `FLAPPY  BEST: N`, set in `_ready`), `_on_flappy_button_pressed()` â†’ `res://scenes/flappy_bird.tscn`

- [ ] **Step 1: Add the button to the scene**

In `scenes/title_screen.tscn`, after the `StartButton` node block (line 47), insert:

```
[node name="FlappyButton" type="Button" parent="MenuButtons"]
layout_mode = 2
custom_minimum_size = Vector2(200, 60)
text = "FLAPPY  BEST: 0"
```

After the `StartButton` connection line (line 59) add:

```
[connection signal="pressed" from="MenuButtons/FlappyButton" to="." method="_on_flappy_button_pressed"]
```

- [ ] **Step 2: Wire the handler + best label**

In `scenes/title_screen.gd`, in `_ready()` after line 7 (`$StreakLabel.text = ...`) add:

```gdscript
	$MenuButtons/FlappyButton.text = "FLAPPY  BEST: %d" % Global.flappy_best
```

Add at the end of the file:

```gdscript
func _on_flappy_button_pressed() -> void:
	await SceneFade.fade_out(self)
	get_tree().change_scene_to_file("res://scenes/flappy_bird.tscn")
```

- [ ] **Step 3: Verify boot**

Run: `& "C:\Users\LalithReddy.b\Godot\Godot_v4.7.1-stable_win64.exe" --headless --path C:\Users\LalithReddy.b\Iron-Mario --quit-after 30`
Expected: exits 0, no SCRIPT ERROR. (Scene references `flappy_bird.tscn` only at press time, so it need not exist yet â€” change_scene_to_file is deferred; boot stays clean. If it errors, create an empty `scenes/flappy_bird.tscn` with a Node2D root now and proceed.)

- [ ] **Step 4: Commit**

```bash
git add scenes/title_screen.tscn scenes/title_screen.gd
git commit -m "feat(flappy): FLAPPY button on title screen"
```

---
