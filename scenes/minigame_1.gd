extends Node2D

const COLLECTIBLES_REQUIRED := 3
const TIME_LIMIT := 10.0

var collectible_count := 0
var finished := false

@onready var collectibles: Node2D = $Collectibles

func _ready() -> void:
	SceneFade.fade_in(self)
	for child in collectibles.get_children():
		child.collectible_collected.connect(_on_collectible_collected)
	await $ThemedTimer.countdown(_time_limit())
	_finish(false)

func _time_limit() -> float:
	return maxf(5.0, TIME_LIMIT - Global.loop)

func _on_collectible_collected() -> void:
	collectible_count += 1
	Juice.shake(self, 0.15)
	if collectible_count >= COLLECTIBLES_REQUIRED:
		_finish(true)

func _finish(win: bool) -> void:
	if finished:
		return
	finished = true
	if win:
		$SfxWin.play()
		Juice.hit_stop(self)
		Juice.shake(self, 0.5)
		Juice.burst(self, $Player.global_position, Color(1, 0.85, 0.25), 26, 320.0)
		await get_tree().create_timer(0.5).timeout
		Global.win()
		await SceneFade.fade_out(self)
		get_tree().change_scene_to_file("res://scenes/level_scene.tscn")
	else:
		$SfxFail.play()
		Juice.hit_stop(self)
		Juice.shake(self, 0.8)
		Juice.burst(self, $Player.global_position, Color(1, 0.3, 0.3), 22, 300.0)
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
