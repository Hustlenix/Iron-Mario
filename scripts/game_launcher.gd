extends Node

const GameRegistry = preload("res://scripts/game_registry.gd")
const GameDefinition = preload("res://scripts/game_definition.gd")

var registry: GameRegistry
var return_scene_path := ""

func _ready() -> void:
	registry = GameRegistry.new()
	_populate_registry()

func _populate_registry() -> void:
	var def: GameDefinition

	def = GameDefinition.new()
	def.id = "hero_select"
	def.display_name = "Hero Select"
	def.scene_path = "res://scenes/hero_select.tscn"
	def.category = "ACTION"
	def.difficulty = 2
	def.estimated_duration_sec = 30
	def.supports_touch = true
	def.supports_keyboard = true
	registry.add(def)

	def = GameDefinition.new()
	def.id = "arc_snake"
	def.display_name = "Arc Snake"
	def.scene_path = "res://scenes/arc_snake.tscn"
	def.category = "QUICK"
	def.tags = ["snake", "score", "reaction"]
	def.difficulty = 3
	def.estimated_duration_sec = 90
	def.supports_touch = true
	def.supports_keyboard = true
	registry.add(def)

	def = GameDefinition.new()
	def.id = "brick_reactor"
	def.display_name = "Brick Reactor"
	def.scene_path = "res://scenes/brick_reactor.tscn"
	def.category = "ACTION"
	def.tags = ["breakout", "arcade", "score"]
	def.difficulty = 3
	def.estimated_duration_sec = 90
	def.supports_touch = true
	def.supports_keyboard = true
	registry.add(def)

	def = GameDefinition.new()
	def.id = "tower_bounce"
	def.display_name = "Tower Bounce"
	def.scene_path = "res://scenes/tower_bounce.tscn"
	def.category = "SKILL"
	def.tags = ["vertical", "one-button", "arcade"]
	def.difficulty = 3
	def.estimated_duration_sec = 60
	def.supports_touch = true
	def.supports_keyboard = true
	registry.add(def)

	def = GameDefinition.new()
	def.id = "minigame_1"
	def.display_name = "Platformer Gauntlet"
	def.scene_path = "res://scenes/minigame_1.tscn"
	def.category = "ACTION"
	def.difficulty = 3
	def.estimated_duration_sec = 15
	def.supports_touch = true
	def.supports_keyboard = true
	registry.add(def)

	def = GameDefinition.new()
	def.id = "minigame_2"
	def.display_name = "Target Tag"
	def.scene_path = "res://scenes/minigame_2.tscn"
	def.category = "SKILL"
	def.difficulty = 2
	def.estimated_duration_sec = 15
	def.supports_touch = true
	def.supports_keyboard = true
	registry.add(def)

	def = GameDefinition.new()
	def.id = "minigame_3"
	def.display_name = "Dodge the Lasers"
	def.scene_path = "res://scenes/minigame_3.tscn"
	def.category = "ACTION"
	def.difficulty = 3
	def.estimated_duration_sec = 15
	def.supports_touch = true
	def.supports_keyboard = true
	registry.add(def)

	def = GameDefinition.new()
	def.id = "minigame_4"
	def.display_name = "Gauge Parry"
	def.scene_path = "res://scenes/minigame_4.tscn"
	def.category = "SKILL"
	def.difficulty = 4
	def.estimated_duration_sec = 15
	def.supports_touch = true
	def.supports_keyboard = true
	registry.add(def)

	def = GameDefinition.new()
	def.id = "flappy"
	def.display_name = "Flappy Bonus"
	def.scene_path = "res://scenes/flappy_bird.tscn"
	def.category = "QUICK"
	def.difficulty = 3
	def.estimated_duration_sec = 45
	def.supports_touch = true
	def.supports_keyboard = true
	registry.add(def)

func launch(id: String, return_to: String = "") -> void:
	var def: GameDefinition = registry.get_game(id)
	if def == null:
		push_error("GameLauncher: unknown game id '%s'" % id)
		return
	return_scene_path = return_to
	if not return_to.is_empty():
		Global.record_arcade_start(id)
	get_tree().change_scene_to_file(def.scene_path)

func launch_random(category: String = "") -> void:
	var def := registry.random(category)
	if def:
		Global.unlock_achievement("random_encounter")
		launch(def.id)
	else:
		push_error("GameLauncher: no games in category '%s'" % category)

func open_library() -> void:
	return_scene_path = ""
	get_tree().change_scene_to_file("res://scenes/arcade_menu.tscn")

func has_return_scene() -> bool:
	return not return_scene_path.is_empty()

func return_to_library() -> void:
	if return_scene_path.is_empty():
		return
	var destination := return_scene_path
	return_scene_path = ""
	get_tree().change_scene_to_file(destination)

func clear_return_scene() -> void:
	return_scene_path = ""

func record_result(id: String, score: int, won: bool) -> void:
	Global.record_arcade_result(id, score, won)
