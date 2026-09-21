extends Node2D

const Paint = preload("res://scripts/ui/Paint.gd")

var sparks: Array[Dictionary] = []
var controls_panel: Control

func _ready() -> void:
	for index in range(26):
		sparks.append({
			"position": Vector2(80 + (index * 149) % 1140, 80 + (index * 83) % 560),
			"speed": 18.0 + float(index % 5) * 7.0
		})
	var hero := preload("res://scripts/ui/IronHero.gd").new()
	hero.position = Vector2(245, 365)
	hero.scale = Vector2(4.0, 4.0)
	hero.pose = "victory"
	add_child(hero)
	_build_ui()
	var music := AudioStreamPlayer.new()
	music.stream = load("res://assets/audio/bgm.wav")
	music.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	music.volume_db = -8.0
	add_child(music)
	music.play()
	queue_redraw()

func _process(delta: float) -> void:
	for spark in sparks:
		var point: Vector2 = spark["position"]
		point.y -= float(spark["speed"]) * delta
		if point.y < 55.0:
			point.y = 680.0
		spark["position"] = point
	queue_redraw()

func _draw() -> void:
	Paint.background(self, "title")
	for spark in sparks:
		var point: Vector2 = spark["position"]
		Paint.rect(self, Rect2(point, Vector2(4, 10)), Color("f6b83c"))
	_draw_city()
	Paint.burst(self, Vector2(245,350), 150, Paint.GOLD)
	Paint.rect(self, Rect2(55,521,230,44), Paint.PAPER)
	Paint.text(self, "HOME-MADE HERO!", Vector2(70,550), 20)
	var font := ThemeDB.fallback_font
	Paint.string(self, font, Vector2(440, 188), "IRON-MARIO", HORIZONTAL_ALIGNMENT_LEFT, -1, 72, Color("ffd13c"))
	Paint.string(self, font, Vector2(443, 232), "MICROGAME GAUNTLET", HORIZONTAL_ALIGNMENT_LEFT, -1, 25, Color("6fe8ff"))
	Paint.string(self, font, Vector2(443, 276), "7 MISSIONS. 5 REACTORS. MOVE FAST.", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("f5f7ff"))
	Paint.rect(self, Rect2(430,586,335,52), Paint.PAPER)
	Paint.string(self, font, Vector2(445, 622), "BEST STREAK  %02d" % Global.best_streak, HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color("a9bbd8"))

func _build_ui() -> void:
	var play := _make_button("PLAY", Vector2(445, 330), Vector2(330, 70), Color("d9363e"))
	play.grab_focus.call_deferred()
	play.pressed.connect(func() -> void: GameManager.start_run(false))
	var controls := _make_button("CONTROLS", Vector2(445, 415), Vector2(330, 56), Color("214a79"))
	controls.pressed.connect(_show_controls)
	var mute_text := "SOUND: OFF" if Global.muted else "SOUND: ON"
	var mute := _make_button(mute_text, Vector2(445, 485), Vector2(330, 56), Color("214a79"))
	mute.pressed.connect(func() -> void:
		var is_muted := Global.toggle_mute()
		mute.text = "SOUND: OFF" if is_muted else "SOUND: ON"
		SoundFX.play_click()
	)

	var profile := _make_button("PROFILE: " + Global.pilot_name, Vector2(825,350),Vector2(335,56),Paint.CYAN)
	profile.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/profile_scene.tscn"))
	var settings := _make_button("SETTINGS", Vector2(825, 420), Vector2(335, 56), Paint.CYAN)
	settings.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/settings_scene.tscn"))
	var bonus := _make_button("BONUS: FLAPPY", Vector2(825, 490), Vector2(335, 56), Paint.CYAN)
	bonus.pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/flappy_bird.tscn"))

	if not OS.has_feature("web"):
		var quit_button := _make_button("QUIT", Vector2(825, 560), Vector2(335, 56), Paint.CYAN)
		quit_button.pressed.connect(func(): get_tree().quit())

func _show_controls() -> void:
	if is_instance_valid(controls_panel):
		controls_panel.queue_free()
		controls_panel = null
		return
	SoundFX.play_click()
	controls_panel = null
	var container := Control.new()
	container.position = Vector2(805, 290)
	container.size = Vector2(410, 325)
	controls_panel = container
	container.draw.connect(func():
		Paint.rect(container, Rect2(0,0,410,325), Paint.PAPER)
		Paint.rect(container, Rect2(0,0,410,325), Paint.INK, false, 3)
	)
	add_child(container)
	var label := preload("res://scripts/ui/PaintLabel.gd").new()
	label.text = "CONTROLS\n\nMOVE    A / D OR LEFT / RIGHT\nJUMP    W / SPACE / UP\nDOWN    S / DOWN (SEQUENCE)\nRESTART R\nMOUSE   CLICK / DRAG\n\nONE MISSION. ONE SHORT ORDER."
	label.position = Vector2(18, 16)
	label.size = Vector2(375, 260)
	container.add_child(label)
	var close := preload("res://scripts/ui/PixelButton.gd").make("CLOSE", Vector2(255,270),Vector2(135,43),Paint.GOLD)
	close.pressed.connect(container.queue_free)
	container.add_child(close)

func _make_button(text_value: String, at: Vector2, size_value: Vector2, _color: Color) -> Button:
	var button := preload("res://scripts/ui/PixelButton.gd").make(text_value, at, size_value, Paint.GOLD if text_value == "PLAY" else Paint.CYAN)
	add_child(button)
	return button

func _draw_city() -> void:
	for index in range(11):
		var width := 74.0 + float(index % 3) * 18.0
		var height := 90.0 + float((index * 47) % 150)
		var x := float(index) * 126.0 - 20.0
		var building := Rect2(x, 720.0 - height, width, height)
		Paint.rect(self, building, Color("92b3b8"))
		Paint.rect(self, building, Color("202022"), false, 4.0)
		for wy in range(int(building.position.y + 18.0), 700, 28):
			for wx in range(int(x + 14.0), int(x + width - 8.0), 24):
				Paint.rect(self, Rect2(wx, wy, 8, 10), Color("f4b942" if (wx + wy) % 3 else "4cdcf4"))

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("action") and not event.is_echo():
		GameManager.start_run(false)
