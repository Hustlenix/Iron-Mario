### Task 9: Full E2E harness + exports + push

**Files:**
- Modify: `C:\Users\LalithReddy.b\Iron-Mario\test_flappy.gd`
- New artifacts: `build\windows\Iron-Mario.exe` + `.pck`, `build\web\`, `exports\Iron-Mario-web.zip`

**Interfaces:**
- Consumes: everything from Tasks 1â€“8
- Produces: green E2E run; fresh exports; commit; push; CI run verified

- [ ] **Step 1: Add the E2E mode (score, game over, retry, ESC, persistence)**

Extend `_initialize`:

```gdscript
	if args.has("e2e"):
		await _test_e2e()
```

and add:

```gdscript
func _test_e2e() -> void:
	flappy.flap()
	flappy.set("best", 0)
	flappy.set("new_best_fired", false)
	flappy.call("_score")
	flappy.call("_score")
	var score_early: int = flappy.get("score")
	flappy.set("bird_y", 700.0)
	flappy.set("velocity", 900.0)
	_run_frames(120)
	if flappy.get_state() != "game_over":
		print("E2E FAIL: no game over")
		quit(1)
		return
	if score_early != 2:
		print("E2E FAIL: score=%d" % score_early)
		quit(1)
		return
	if flappy.get("best") < 2:
		print("E2E FAIL: best not saved (%d)" % flappy.get("best"))
		quit(1)
		return
	Input.action_press("jump")
	_run_frames(2)
	Input.action_release("jump")
	_run_frames(60)
	if flappy.get_state() != "playing":
		print("E2E FAIL: retry did not restart (state=%s)" % flappy.get_state())
		quit(1)
		return
	Input.action_press("ui_cancel")
	_run_frames(30)
	Input.action_release("ui_cancel")
	for i in 300:
		await process_frame
		if current_scene != null and current_scene.name != "FlappyBird":
			print("E2E OK (score=%d best=%d scene=%s)" % [score_early, flappy.get("best"), current_scene.name])
			quit(0)
			return
	print("E2E FAIL: ESC did not return to title")
	quit(1)
```

- [ ] **Step 2: Run full suite**

Run each:

```powershell
& "C:\Users\LalithReddy.b\Godot\Godot_v4.7.1-stable_win64.exe" --headless --path C:\Users\LalithReddy.b\Iron-Mario --script res://test_flappy.gd
& "C:\Users\LalithReddy.b\Godot\Godot_v4.7.1-stable_win64.exe" --headless --path C:\Users\LalithReddy.b\Iron-Mario --script res://test_flappy.gd -- --flap
& "C:\Users\LalithReddy.b\Godot\Godot_v4.7.1-stable_win64.exe" --headless --path C:\Users\LalithReddy.b\Iron-Mario --script res://test_flappy.gd -- --ramp
& "C:\Users\LalithReddy.b\Godot\Godot_v4.7.1-stable_win64.exe" --headless --path C:\Users\LalithReddy.b\Iron-Mario --script res://test_flappy.gd -- --medal
& "C:\Users\LalithReddy.b\Godot\Godot_v4.7.1-stable_win64.exe" --headless --path C:\Users\LalithReddy.b\Iron-Mario --script res://test_flappy.gd -- --feather
& "C:\Users\LalithReddy.b\Godot\Godot_v4.7.1-stable_win64.exe" --headless --path C:\Users\LalithReddy.b\Iron-Mario --script res://test_flappy.gd -- --over
& "C:\Users\LalithReddy.b\Godot\Godot_v4.7.1-stable_win64.exe" --headless --path C:\Users\LalithReddy.b\Iron-Mario --script res://test_flappy.gd -- --e2e
```

Expected: all seven print their `OK` lines, exit 0, no SCRIPT ERROR output.

- [ ] **Step 3: Delete the harness (it did its job)**

Delete `C:\Users\LalithReddy.b\Iron-Mario\test_flappy.gd` (and its auto-generated `test_flappy.gd.uid` if present).

- [ ] **Step 4: Clean import + boot check**

Run: `& "C:\Users\LalithReddy.b\Godot\Godot_v4.7.1-stable_win64.exe" --headless --path C:\Users\LalithReddy.b\Iron-Mario --import`
Expected: completes without errors.
Then: `& "C:\Users\LalithReddy.b\Godot\Godot_v4.7.1-stable_win64.exe" --headless --path C:\Users\LalithReddy.b\Iron-Mario --quit-after 30`
Expected: exits 0, clean boot log.

- [ ] **Step 5: Commit + push**

```bash
git add -A
git status
git commit -m "feat(flappy): standalone Flappy Bird mode"
git push origin main
```

Verify push: `git log --oneline -3` shows the new commit on `origin/main` (or use `git status` showing "up to date").

- [ ] **Step 6: Rebuild exports**

Windows: `& "C:\Users\LalithReddy.b\Godot\Godot_v4.7.1-stable_win64.exe" --headless --path C:\Users\LalithReddy.b\Iron-Mario --export-release "Windows Desktop" build/windows/Iron-Mario.exe`
Web: `& "C:\Users\LalithReddy.b\Godot\Godot_v4.7.1-stable_win64.exe" --headless --path C:\Users\LalithReddy.b\Iron-Mario --export-release "Web" build/web/index.html`
Then re-zip: `Compress-Archive -Path "build\web\*" -DestinationPath "exports\Iron-Mario-web.zip" -Force`
Verify: `Get-Item build\windows\Iron-Mario.exe, build\web\index.wasm, exports\Iron-Mario-web.zip | Select-Object Name, Length, LastWriteTime`

- [ ] **Step 7: CI verify**

Fetch: `https://api.github.com/repos/Hustlenix/Iron-Mario/actions/runs` â€” wait for the Deploy Web run for the new head_sha to show `conclusion=success`. Then `https://hustlenix.github.io/Iron-Mario/` returns 200.

- [ ] **Step 8: Final report**

Summarize: feature list, test results, commit hash, export sizes, live URL, CI status.

---
