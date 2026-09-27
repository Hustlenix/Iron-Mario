extends Node2D

const COLLECTIBLES_REQUIRED := 3
const TIME_LIMIT := 10.0

var collectible_count := 0
var finished := false

@onready var collectibles: Node2D = $Collectibles

func _ready() -> void:
	SceneFade.fade_in(self)
	PowerBus.register_handler(self)
	for child in collectibles.get_children():
		child.collectible_collected.connect(_on_collectible_collected)
	await $ThemedTimer.countdown(_time_limit())
	_finish(false)

func _exit_tree() -> void:
	PowerBus.unregister_handler(self)

func _physics_process(_delta: float) -> void:
	if not finished and Input.is_action_just_pressed("power"):
		PowerBus.try_activate()

func _time_limit() -> float:
	return maxf(5.0, TIME_LIMIT - Global.loop)

# --- Power handlers: one per family, the shape every minigame follows. ---

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

## Lunge / overdrive: a forward burst that sweeps the player through the
## shard, so the collectible's own overlap check resolves it.
func _power_dash() -> bool:
	var target := _nearest_collectible()
	if target == null:
		return false
	_power_text("LUNGE!", Color(0.45, 0.85, 1.0))
	$Player.burst_toward(target.global_position, 900.0, 0.35, true)
	return true

## Sonar: light up the next shard so it reads instantly.
func _power_reveal() -> bool:
	var target := _nearest_collectible()
	if target == null:
		return false
	_power_text("SONAR", Color(0.75, 0.6, 1.0))
	var tween := create_tween()
	tween.set_loops(3)
	tween.tween_property(target, "modulate", Color(0.75, 0.6, 1.0, 0.3), 0.15)
	tween.tween_property(target, "modulate", Color(1, 1, 1, 1), 0.15)
	return true

## Tether / snap: pull the player all the way onto the shard.
func _power_reach() -> bool:
	var target := _nearest_collectible()
	if target == null:
		return false
	_power_text("TETHER!", Color(1.0, 0.75, 0.35))
	$Player.pull_to(target.global_position, 1050.0, 0.6, true)
	return true

## Pulse / lance: drag the shard into the player and take it.
func _power_blast() -> bool:
	var target := _nearest_collectible()
	if target == null:
		return false
	_power_text("PULSE", Color(1.0, 0.5, 0.35))
	var start := target.global_position
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.tween_method(
		func(v: Vector2) -> void:
			if is_instance_valid(target):
				target.global_position = v,
		start,
		$Player.global_position,
		0.3
	)
	tween.tween_callback(Callable(target, "collect"))
	return true

func _power_text(text: String, color: Color) -> void:
	Juice.text(self, text, $Player.global_position + Vector2(0, -70), color, 32)

func _nearest_collectible() -> Node2D:
	var best: Node2D = null
	var best_dist := INF
	for child in collectibles.get_children():
		if not child.has_method("collect") or child.collected:
			continue
		var dist := global_position.distance_squared_to(child.global_position)
		if dist < best_dist:
			best_dist = dist
			best = child
	return best

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
