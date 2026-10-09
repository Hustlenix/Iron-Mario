extends "res://microgames/microgame_base.gd"

var runner := Vector2(165, 365)
var vertical_speed: float = 0.0
var travel: float = 0.0
var speed: float = 260.0
var grounded: bool = true
var jump_buffer: float = 0.0
var obstacles: Array[Dictionary] = []
var passed: int = 0
var last_beat: int = -1
var beat_player: AudioStreamPlayer

func setup() -> void:
	runner = Vector2(165, 365)
	vertical_speed = 0
	travel = 0
	speed = 245 + difficulty * 9
	grounded = true
	jump_buffer = 0
	passed = 0
	last_beat = -1
	if is_instance_valid(beat_player): beat_player.free()
	beat_player = null
	if DisplayServer.get_name()!='headless':
		# Original short synthesized click. It shares the application's Master volume.
		var samples := PackedByteArray()
		samples.resize(880)
		for i in samples.size():
			var envelope: float = pow(1.0-float(i)/samples.size(),3)
			samples[i] = clampi(int(128+sin(i*TAU*1100/22050)*60*envelope),0,255)
		var sound := AudioStreamWAV.new()
		sound.format = AudioStreamWAV.FORMAT_8_BITS
		sound.mix_rate = 22050
		sound.data = samples
		beat_player = AudioStreamPlayer.new()
		beat_player.stream = sound
		beat_player.volume_db = -18
		add_child(beat_player)
	obstacles.clear()
	for i in 14:
		obstacles.append({'x': 600.0 + i * 240, 'kind': 'gap' if i % 4 == 3 else 'spike', 'passed': false})

func handle_action(action: String, _point: Vector2, _value: Vector2) -> void:
	if finished: return
	if action == 'cancel':
		jump_buffer = 0
		if is_instance_valid(beat_player): beat_player.stop()
	if action in ['action', 'press']: jump_buffer = 0.12

func tick(delta: float) -> void:
	var steps: int = maxi(1, int(ceil(delta / 0.008)))
	for _i in steps:
		var dt: float = delta / steps
		travel += speed * dt
		if travel>=350:
			var beat: int = floori((travel-350)/240.0)
			if beat>last_beat:
				last_beat = beat
				if is_instance_valid(beat_player): beat_player.play()
		jump_buffer = maxf(0, jump_buffer - dt)
		if grounded and jump_buffer > 0:
			vertical_speed = -440
			grounded = false
			jump_buffer = 0
			feedback(runner)
		var over_gap: bool = false
		for o in obstacles:
			var x: float = o.x - travel
			if o.kind == 'gap' and runner.x > x + 4 and runner.x < x + 88: over_gap = true
			if o.kind == 'spike' and Rect2(x, 343, 38, 37).grow(-3).intersects(Rect2(runner - Vector2(12, 14), Vector2(24, 28))):
				feedback(runner, false)
				lose()
				return
			if not o.passed and x + (90 if o.kind == 'gap' else 38) < runner.x - 16:
				o.passed = true
				passed += 1
				points += 20
		if over_gap and grounded: grounded = false
		if not grounded:
			vertical_speed += 1100 * dt
			runner.y += vertical_speed * dt
			if runner.y >= 365 and vertical_speed > 0 and not over_gap:
				runner.y = 365
				vertical_speed = 0
				grounded = true
		if runner.y > 450:
			lose()
			return
		if passed == obstacles.size():
			win(points + 100)
			return

func paint() -> void:
	text_at(Vector2(24, 35), 'JUMP THE WAVEFORM   ' + str(passed) + '/14', 26)
	text_at(Vector2(24,66),'Tap / Space on the click. Gold dashes mark the approach.',19)
	box(Rect2(0, 380, 960, 65), BLUE)
	for i in 32:
		var x: float = fposmod(i * 35 - travel, 980)
		draw_line(Vector2(x, 410), Vector2(x, 398 - sin(i * 1.7) * 15), PAPER, 3)
	for o in obstacles:
		var x: float = o.x - travel
		if x < -100 or x > 1000: continue
		draw_line(Vector2(x - 85, 376), Vector2(x - 52, 376), GOLD, 6)
		if o.kind == 'gap':
			box(Rect2(x, 380, 90, 65), PAPER)
		else:
			draw_colored_polygon(PackedVector2Array([Vector2(x,380),Vector2(x+19,343),Vector2(x+38,380)]), RED)
			draw_polyline(PackedVector2Array([Vector2(x,380),Vector2(x+19,343),Vector2(x+38,380)]), INK, 4)
	disc(runner, 15, GOLD)
	draw_line(runner + Vector2(-6, -3), runner + Vector2(6, -3), INK, 5)
	disc(Vector2(882,45),11+cos((travel-350)/240.0*TAU)*4,GOLD)

