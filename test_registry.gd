extends Node

## Smoke coverage for the Godot-native arcade catalogue.
## Run as a scene so the GameLauncher autoload is initialized.

var _checks := 0
var _failures := 0

func _ready() -> void:
	_run()

func _check(label: String, ok: bool, detail: String = "") -> void:
	_checks += 1
	if ok:
		print("  PASS  %s  %s" % [label, detail])
	else:
		_failures += 1
		print("  FAIL  %s  %s" % [label, detail])

func _run() -> void:
	print("\n=== ARCADE REGISTRY VERIFICATION ===")
	_check("launcher autoload exists", is_instance_valid(GameLauncher))
	_check("registry exists", GameLauncher.registry != null)

	if GameLauncher.registry == null:
		print("=== %d FAILURE(S) ===" % _failures)
		get_tree().quit(1)
		return

	var games := GameLauncher.registry.all()
	_check("catalog has current games", games.size() >= 10, "got %d" % games.size())
	_check("hero select is registered", GameLauncher.registry.get_game("hero_select") != null)
	_check("all four numbered minigames are registered", _has_all_minigames())
	_check("Flappy is registered", GameLauncher.registry.get_game("flappy") != null)
	_check("Tower Bounce is registered", GameLauncher.registry.get_game("tower_bounce") != null)
	_check("Brick Reactor is registered", GameLauncher.registry.get_game("brick_reactor") != null)
	_check("Arc Snake is registered", GameLauncher.registry.get_game("arc_snake") != null)
	_check("Arc Break is registered", GameLauncher.registry.get_game("arc_break") != null)
	_check("every definition has an id", _all_have_ids(games))
	_check("every scene path exists", _all_paths_exist(games))
	_check("action category has games", not GameLauncher.registry.get_by_category("ACTION").is_empty())
	_check("skill category has games", not GameLauncher.registry.get_by_category("SKILL").is_empty())
	_check("random selection returns a registered game", _random_is_registered())

	print("\n=== %s ===" % ("ALL PASS" if _failures == 0 else "%d FAILURE(S)" % _failures))
	get_tree().quit(0 if _failures == 0 else 1)

func _has_all_minigames() -> bool:
	for id in ["minigame_1", "minigame_2", "minigame_3", "minigame_4"]:
		if GameLauncher.registry.get_game(id) == null:
			return false
	return true

func _all_have_ids(games: Array) -> bool:
	var ids := {}
	for game in games:
		if game.id.is_empty() or ids.has(game.id):
			return false
		ids[game.id] = true
	return true

func _all_paths_exist(games: Array) -> bool:
	for game in games:
		if not ResourceLoader.exists(game.scene_path):
			return false
	return true

func _random_is_registered() -> bool:
	var game := GameLauncher.registry.random()
	return game != null and GameLauncher.registry.get_game(game.id) == game
