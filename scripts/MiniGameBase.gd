extends Node2D

const Paint = preload("res://scripts/ui/Paint.gd")

signal minigame_won
signal minigame_lost

@export var game_title := "MICROGAME"
@export var instruction := "MOVE FAST!"
@export var duration := 10.0

var time_left := 10.0
var ended := false
var hud
var touch_controls: Node2D
var pointer_finger := -1

func _ready() -> void:
	GameManager.register_preview(scene_file_path)
	time_left = duration
	minigame_won.connect(func() -> void: GameManager.resolve_round(true))
	minigame_lost.connect(func() -> void: GameManager.resolve_round(false))
	hud = preload("res://scripts/ui/HUD.gd").new()
	add_child(hud)
	hud.configure(game_title, instruction, duration)
	setup_game()
	Music.play_theme(Global.hero_id, "mission")
	touch_controls = preload("res://scripts/ui/TouchControls.gd").new()
	add_child(touch_controls)
	queue_redraw()

func _physics_process(delta: float) -> void:
	if ended:
		return
	time_left = maxf(0.0, time_left - delta)
	hud.update_time(time_left)
	update_game(delta)
	if time_left <= 0.0 and not ended:
		on_time_expired()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo:
		return
	if event.is_action_pressed("ui_cancel"):
		GameManager.return_to_title()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("restart") and not ended:
		GameManager.restart_current_minigame()
		get_viewport().set_input_as_handled()
		return
	if ended:
		return
	# Translate one owned pointer to the existing click/drag mechanics.
	# Other fingers belong to movement buttons or are ignored.
	if event is InputEventScreenTouch:
		if event.pressed and pointer_finger == -1:
			pointer_finger = event.index
		if event.index == pointer_finger:
			var click := InputEventMouseButton.new()
			click.button_index = MOUSE_BUTTON_LEFT
			click.position = event.position
			click.pressed = event.pressed and not event.canceled
			handle_game_input(click)
			if not click.pressed:
				pointer_finger = -1
		get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		if event.index == pointer_finger:
			var motion := InputEventMouseMotion.new()
			motion.position = event.position
			handle_game_input(motion)
		get_viewport().set_input_as_handled()
	elif event is InputEventMouse and event.device == InputEvent.DEVICE_ID_EMULATION:
		return
	else:
		handle_game_input(event)

func setup_game() -> void:
	pass

func update_game(_delta: float) -> void:
	pass

func handle_game_input(_event: InputEvent) -> void:
	pass

func on_time_expired() -> void:
	finish(false)

func finish(won: bool) -> void:
	if ended:
		return
	ended = true
	hud.show_feedback(won)
	if won:
		minigame_won.emit()
		SoundFX.play_success()
	else:
		minigame_lost.emit()
		SoundFX.play_failure()
	queue_redraw()

func penalize_time(seconds: float) -> void:
	time_left = maxf(0.0, time_left - seconds)
	hud.update_time(time_left)

func pixel_text(text_value: String, at: Vector2, font_size: int, color: Color = Color.WHITE, width: float = -1.0, alignment := HORIZONTAL_ALIGNMENT_LEFT) -> void:
	Paint.string(self, ThemeDB.fallback_font, at, text_value, alignment, width, font_size, color)

func draw_pixel_panel(rect: Rect2, fill: Color, outline: Color = Color("202022"), border: float = 5.0) -> void:
	Paint.rect(self, rect, fill)
	Paint.rect(self, rect, outline, false, border)

func draw_reactor(center: Vector2, radius: float, glow: Color = Color("7bd9df")) -> void:
	Paint.burst(self, center, radius + 5, Paint.GOLD)
	Paint.circle(self, center, radius, Color("202022"))
	Paint.circle(self, center, radius - 5.0, glow)
	Paint.line(self, center + Vector2(-radius * 0.55, 0), center + Vector2(radius * 0.55, 0), Color.WHITE, 3.0)
	Paint.line(self, center + Vector2(0, -radius * 0.55), center + Vector2(0, radius * 0.55), Color.WHITE, 3.0)
