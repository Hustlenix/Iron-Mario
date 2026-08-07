extends Node2D

const PARS_REQUIRED := 3
const TIME_LIMIT := 10.0
const BAR_WIDTH := 200.0
const BAR_SWEEP_MIN_X := 80.0
const BAR_SWEEP_MAX_X := 1000.0
const BAR_SWEEP_DURATION := 0.9
const ZONE_WIDTH := 120.0
const ZONE_MIN_X := 80.0
const ZONE_MAX_X := 1080.0

var parries := 0
var finished := false

@onready var parry_bar: TextureRect = $ParryBar
@onready var parry_zone: TextureRect = $ParryZone
@onready var parry_label: RichTextLabel = $HUD/ParryLabel

var zone_arrow: Label

var sweep_tween: Tween
var flash_tween: Tween

func _ready() -> void:
	SceneFade.fade_in(self)
	_build_zone_arrow()
	_place_zone()
	_start_sweep()
	await $ThemedTimer.countdown(_time_limit())
	_finish(false)

func _build_zone_arrow() -> void:
	zone_arrow = Label.new()
	zone_arrow.text = "▼"
	zone_arrow.add_theme_font_size_override("font_size", 48)
	zone_arrow.add_theme_color_override("font_color", Color(1, 0.85, 0.25))
	zone_arrow.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	zone_arrow.add_theme_constant_override("outline_size", 8)
	zone_arrow.visible = false
	zone_arrow.z_index = 55
	add_child(zone_arrow)

func _process(_delta: float) -> void:
	if zone_arrow == null:
		return
	var bar_center_x: float = parry_bar.position.x + BAR_WIDTH * 0.5
	var zone_center_x: float = parry_zone.position.x + ZONE_WIDTH * 0.5
	if absf(bar_center_x - zone_center_x) <= 150.0:
		zone_arrow.visible = true
		zone_arrow.position = Vector2(
			parry_zone.position.x + ZONE_WIDTH * 0.5 - 20.0,
			parry_zone.position.y - 62.0
		)
	else:
		zone_arrow.visible = false

func _time_limit() -> float:
	return maxf(5.0, TIME_LIMIT - Global.loop)

func _unhandled_input(event: InputEvent) -> void:
	if finished:
		return
	if event.is_action_pressed("jump"):
		_attempt_parry()

func _attempt_parry() -> void:
	var bar_center_x: float = parry_bar.position.x + BAR_WIDTH * 0.5
	var zone_rect := Rect2(parry_zone.position, parry_zone.size)
	if zone_rect.has_point(Vector2(bar_center_x, parry_zone.position.y + parry_zone.size.y * 0.5)):
		_parry_success()
	else:
		_parry_miss()

func _parry_success() -> void:
	parries += 1
	parry_label.text = "PARS: %d / %d" % [parries, PARS_REQUIRED]
	_flash_zone(Color(0.5, 1, 0.6))
	Juice.shake(self, 0.3)
	Juice.burst(self, parry_zone.position + parry_zone.size * 0.5, Color(0.5, 1, 0.6), 12, 240.0)
	Juice.text(self, "PARRY!", parry_zone.position + Vector2(parry_zone.size.x * 0.5, -40), Color(0.6, 1, 0.65), 38)
	_place_zone()
	_start_sweep()
	if parries >= PARS_REQUIRED:
		_finish(true)

func _parry_miss() -> void:
	_flash_zone(Color(1, 0.3, 0.3))
	Juice.text(self, "MISS", parry_bar.position + Vector2(parry_bar.size.x * 0.5, -40), Color(1, 0.4, 0.4), 30)
	_start_sweep()

func _flash_zone(color: Color) -> void:
	if flash_tween:
		flash_tween.kill()
	flash_tween = create_tween()
	flash_tween.tween_property(parry_zone, "modulate", color, 0.08)
	flash_tween.tween_property(parry_zone, "modulate", Color.WHITE, 0.18)

func _place_zone() -> void:
	parry_zone.position.x = randf_range(ZONE_MIN_X, ZONE_MAX_X)

func _start_sweep() -> void:
	if sweep_tween:
		sweep_tween.kill()
	parry_bar.position.x = BAR_SWEEP_MIN_X
	sweep_tween = create_tween()
	sweep_tween.set_loops(-1)
	sweep_tween.set_trans(Tween.TRANS_SINE)
	sweep_tween.set_ease(Tween.EASE_IN_OUT)
	sweep_tween.tween_property(parry_bar, "position:x", BAR_SWEEP_MAX_X, BAR_SWEEP_DURATION)
	sweep_tween.tween_property(parry_bar, "position:x", BAR_SWEEP_MIN_X, BAR_SWEEP_DURATION)

func _finish(win: bool) -> void:
	if finished:
		return
	finished = true
	if win:
		$SfxWin.play()
		Juice.hit_stop(self)
		Juice.shake(self, 0.5)
		Juice.burst(self, parry_zone.position + parry_zone.size * 0.5, Color(1, 0.85, 0.25), 26, 320.0)
		await get_tree().create_timer(0.5).timeout
		Global.win()
		await SceneFade.fade_out(self)
		get_tree().change_scene_to_file("res://scenes/level_scene.tscn")
	else:
		$SfxFail.play()
		Juice.shake(self, 0.6)
		Juice.burst(self, parry_bar.position + parry_bar.size * 0.5, Color(1, 0.3, 0.3), 18, 280.0)
		await get_tree().create_timer(0.45).timeout
		Global.lose()
		Global.minigames_done -= 1
		Global.lives -= 1
		if Global.lives <= 0:
			await SceneFade.fade_out(self)
			get_tree().change_scene_to_file("res://scenes/death_scene.tscn")
		else:
			await SceneFade.fade_out(self)
			get_tree().change_scene_to_file("res://scenes/level_scene.tscn")
