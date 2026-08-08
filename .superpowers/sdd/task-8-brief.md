### Task 8: Game over polish + audio synthesis

**Files:**
- Modify: `C:\Users\LalithReddy.b\Iron-Mario\scenes\flappy_bird.gd`
- Modify: `C:\Users\LalithReddy.b\Iron-Mario\test_flappy.gd`

**Interfaces:**
- Consumes: `build_sounds()` skeleton (Task 3), `_die()`, `_show_game_over()`
- Produces: `build_sounds()` fills `sfx_*` streams with synthesized `AudioStreamWAV` beeps; `_make_beep(freq, duration, volume, wobble) -> AudioStreamWAV`

- [ ] **Step 1: Add the failing test**

Extend `_initialize`:

```gdscript
	if args.has("over"):
		await _test_over()
```

and add:

```gdscript
func _test_over() -> void:
	flappy.flap()
	_run_frames(60)
	flappy.set("bird_y", 700.0)
	flappy.set("velocity", 900.0)
	_run_frames(120)
	if flappy.get_state() == "game_over":
		var flap_stream := flappy.get_node("SfxFlap").stream
		if flap_stream != null and flap_stream is AudioStreamWAV:
			print("GAME OVER TEST OK")
			quit(0)
			return
		print("GAME OVER TEST FAIL: no synthesized flap stream")
		quit(1)
	print("GAME OVER TEST FAIL: state=%s" % flappy.get_state())
	quit(1)
```

- [ ] **Step 2: Run â€” expect FAIL**

Run: `... --script res://test_flappy.gd -- --over`
Expected: FAIL â€” `SfxFlap.stream` is null (game-over may already work, but the stream assertion fails).

- [ ] **Step 3: Implement audio synthesis**

Replace `build_sounds()` no-op in `scenes/flappy_bird.gd`:

```gdscript
func build_sounds() -> void:
	sfx_flap.stream = _make_beep(620.0, 0.07, 0.5)
	sfx_score.stream = _make_beep(880.0, 0.09, 0.45)
	sfx_hit.stream = _make_beep(160.0, 0.3, 0.7, 1.2)
	sfx_pickup.stream = _make_beep(1040.0, 0.1, 0.5)
	sfx_win.stream = _make_beep(660.0, 0.4, 0.6, 0.4)

func _make_beep(freq: float, duration: float, volume: float, wobble := 0.0) -> AudioStreamWAV:
	var sr := 22050
	var n := int(sr * duration)
	var data := PackedByteArray()
	data.resize(n * 2)
	var slide := 1.0 + wobble
	for i in n:
		var t := float(i) / float(sr)
		var env := minf(t / 0.01, 1.0) * maxf(1.0 - t / duration, 0.0)
		var f := freq * (1.0 + (slide - 1.0) * t / duration)
		var s := sin(TAU * f * t) * env * volume
		data.encode_s16(i * 2, int(clampf(s, -1.0, 1.0) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sr
	wav.stereo = false
	wav.data = data
	return wav
```

- [ ] **Step 4: Run â€” expect PASS**

Run: `... --script res://test_flappy.gd -- --over`
Expected: `GAME OVER TEST OK`.

Also run all modes so far to confirm no regressions: `--boot`, `--flap`, `--ramp`, `--medal`, `--feather`.

- [ ] **Step 5: Commit**

```bash
git add scenes/flappy_bird.gd test_flappy.gd
git commit -m "feat(flappy): synthesized SFX"
```

---
