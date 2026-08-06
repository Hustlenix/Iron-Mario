extends Node2D

const CLICKS_REQUIRED := 5
const TIME_LIMIT := 10.0
const MARGIN := 48.0

var clicks := 0
var finished := false

@onready var target: TextureRect = $Target
@onready var score_label: RichTextLabel = $HUD/ScoreLabel
@onready var reposition_timer: Timer = $RepositionTimer

func _ready() -> void:
	_reposition_target()
	reposition_timer.timeout.connect(_reposition_target)
	reposition_timer.wait_time = maxf(0.35, 0.6 - 0.05 * Global.loop)
	reposition_timer.start()
	await $ThemedTimer.countdown(_time_limit())
	_finish(false)

func _time_limit() -> float:
	return maxf(5.0, TIME_LIMIT - Global.loop)

func _unhandled_input(event: InputEvent) -> void:
	if finished:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if target.get_global_rect().has_point(event.position):
			clicks += 1
			score_label.text = "HITS: %d / %d" % [clicks, CLICKS_REQUIRED]
			_reposition_target()
			if clicks >= CLICKS_REQUIRED:
				_finish(true)

func _reposition_target() -> void:
	var vp_size: Vector2 = get_viewport_rect().size
	var max_pos := vp_size - target.size - Vector2(MARGIN, MARGIN)
	target.position = Vector2(
		randf_range(MARGIN, max_pos.x),
		randf_range(MARGIN, max_pos.y)
	)

func _finish(win: bool) -> void:
	if finished:
		return
	finished = true
	if win:
		$SfxWin.play()
		await get_tree().create_timer(0.5).timeout
		Global.win()
		get_tree().change_scene_to_file("res://scenes/level_scene.tscn")
	else:
		$SfxFail.play()
		await get_tree().create_timer(0.45).timeout
		Global.lose()
		Global.minigames_done -= 1
		Global.lives -= 1
		if Global.lives <= 0:
			get_tree().change_scene_to_file("res://scenes/death_scene.tscn")
		else:
			get_tree().change_scene_to_file("res://scenes/level_scene.tscn")
