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
var _freeze_token := 0

@onready var parry_bar: TextureRect = $ParryBar
@onready var parry_zone: TextureRect = $ParryZone
@onready var parry_label: RichTextLabel = $HUD/ParryLabel

var zone_arrow: Label

var sweep_tween: Tween
var flash_tween: Tween

func _ready() -> void:
	SceneFade.fade_in(self)
	PowerBus.register_handler(self)
	_build_zone_arrow()
	_place_zone()
	_start_sweep()
	await $ThemedTimer.countdown(_time_limit())
	_finish(false)

func _exit_tree() -> void:
	PowerBus.unregister_handler(self)

func _physics_process(_delta: float) -> void:
	if not finished and Input.is_action_just_pressed("power"):
		PowerBus.try_activate()

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
	if _aligned():
		_parry_success()
	else:
		_parry_miss()

## One definition of "is the bar in the zone", shared by the jump, the dash, and
## the blast, so no power can resolve a parry the normal timing would refuse.
func _aligned() -> bool:
	var zone_rect := Rect2(parry_zone.position, parry_zone.size)
	return zone_rect.has_point(Vector2(_bar_center_x(), parry_zone.position.y + parry_zone.size.y * 0.5))

func _bar_center_x() -> float:
	return parry_bar.position.x + BAR_WIDTH * 0.5

func _zone_center_x() -> float:
	return parry_zone.position.x + ZONE_WIDTH * 0.5

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

# --- Power handlers: one per family. ---

func on_power(family: int) -> bool:
	if finished:
		return false
	match family:
		HeroData.Family.DASH:
			return _power_dash()
		HeroData.Family.REVEAL:
			return _power_reveal()
		HeroData.Family.REACH:
			return _power_reach()
		HeroData.Family.BLAST:
			return _power_blast()
	return false

## Lunge / overdrive: cross the zone and take the parry, but only if the timing is
## already good. A miss costs no cooldown, because nothing resolved.
func _power_dash() -> bool:
	if not _aligned():
		_power_text("LUNGE! MISS", Color(0.45, 0.85, 1.0))
		return false
	_power_text("LUNGE!", Color(0.45, 0.85, 1.0))
	_parry_success()
	return true

## Sonar / freeze: stop the bar dead for a second and light the zone.
func _power_reveal() -> bool:
	_power_text("SONAR", Color(0.75, 0.6, 1.0))
	_freeze_token += 1
	var token := _freeze_token
	if sweep_tween:
		sweep_tween.pause()
	var tween := create_tween()
	tween.set_loops(3)
	tween.tween_property(parry_zone, "modulate", Color(0.75, 0.6, 1.0, 0.35), 0.15)
	tween.tween_property(parry_zone, "modulate", Color.WHITE, 0.15)
	get_tree().create_timer(1.0).timeout.connect(_unfreeze_sweep.bind(token))
	return true

func _unfreeze_sweep(token: int) -> void:
	# A stale timer from an earlier reveal must not restart a later sweep early.
	if token != _freeze_token:
		return
	if sweep_tween and is_instance_valid(sweep_tween):
		sweep_tween.play()

## Tether / snap / aegis: reaches the bar from anywhere, so the parry lands.
func _power_reach() -> bool:
	_power_text("TETHER!", Color(1.0, 0.75, 0.35))
	_parry_success()
	return true

## Pulse / lance: drag the bar into the zone, then parry it.
func _power_blast() -> bool:
	_power_text("PULSE!", Color(1.0, 0.5, 0.35))
	# Kill the sweep first, or it fights the tween for the bar's position.
	if sweep_tween:
		sweep_tween.kill()
		sweep_tween = null
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(parry_bar, "position:x", _zone_center_x() - BAR_WIDTH * 0.5, 0.25)
	tween.tween_callback(_parry_success)
	return true

func _power_text(text: String, color: Color) -> void:
	Juice.text(self, text, parry_zone.position + Vector2(parry_zone.size.x * 0.5, -74), color, 32)

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
