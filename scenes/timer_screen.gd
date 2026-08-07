extends Node2D

const INTERMISSION_TIME := 3.0

@onready var lives_container: HBoxContainer = $LivesContainer
@onready var level_label: RichTextLabel = $LevelLabel
@onready var timer_label: RichTextLabel = $TimerLabel
@onready var sfx_tick: AudioStreamPlayer = $SfxTick
@onready var sfx_go: AudioStreamPlayer = $SfxGo

var progress_row: HBoxContainer
var streak_label: RichTextLabel

func _ready() -> void:
	SceneFade.fade_in(self)
	_build_progress_row()
	_build_streak_label()
	await countdown()

func _process(_delta: float) -> void:
	for i in range(lives_container.get_child_count()):
		lives_container.get_child(i).visible = i < Global.lives
	level_label.text = "LEVEL %d" % (Global.minigames_done + 1)

func _build_progress_row() -> void:
	progress_row = HBoxContainer.new()
	progress_row.position = Vector2(980, 60)
	progress_row.add_theme_constant_override("separation", 14)
	add_child(progress_row)
	var reactor_tex := load("res://assets/reactor.svg") as Texture2D
	for i in range(4):
		var icon := TextureRect.new()
		icon.texture = reactor_tex
		icon.custom_minimum_size = Vector2(40, 40)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.modulate = Color(1, 1, 1) if i < Global.minigames_done else Color(0.35, 0.35, 0.4)
		progress_row.add_child(icon)

func _build_streak_label() -> void:
	streak_label = RichTextLabel.new()
	streak_label.bbcode_enabled = true
	streak_label.scroll_active = false
	streak_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	streak_label.add_theme_font_size_override("font_size", 30)
	streak_label.add_theme_constant_override("outline_size", 12)
	streak_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	streak_label.position = Vector2(20, 60)
	streak_label.size = Vector2(400, 50)
	streak_label.text = "STREAK: %d" % Global.streak
	add_child(streak_label)

func countdown() -> void:
	var seconds_left := INTERMISSION_TIME
	while seconds_left > 0.0:
		timer_label.text = "%d" % int(ceil(seconds_left))
		sfx_tick.play()
		_punch_timer_label()
		await get_tree().create_timer(1.0).timeout
		seconds_left -= 1.0
	timer_label.text = "GO!"
	sfx_go.play()
	Juice.shake(self, 0.2)
	await get_tree().create_timer(0.4).timeout
	if Global.lives <= 0:
		$SfxFail.play()
		await get_tree().create_timer(0.45).timeout
		await SceneFade.fade_out(self)
		get_tree().change_scene_to_file("res://scenes/death_scene.tscn")
	elif Global.minigames_done < 4:
		Global.minigames_done += 1
		await SceneFade.fade_out(self)
		get_tree().change_scene_to_file("res://scenes/minigame_%d.tscn" % Global.minigames_done)
	else:
		$SfxWin.play()
		await get_tree().create_timer(0.5).timeout
		await SceneFade.fade_out(self)
		get_tree().change_scene_to_file("res://scenes/winner_scene.tscn")

func _punch_timer_label() -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(timer_label, "scale", Vector2(1.35, 1.35), 0.12)
	tween.tween_property(timer_label, "modulate:a", 0.0, 0.85).set_delay(0.15)
	tween.chain().tween_property(timer_label, "scale", Vector2.ONE, 0.1)
	tween.parallel().tween_property(timer_label, "modulate:a", 1.0, 0.1)
