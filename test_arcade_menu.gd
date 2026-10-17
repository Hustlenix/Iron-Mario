extends Node

## Headless verification for the arcade hub menu: card wall, category chips,
## search, recent shelf, favorites, and launch guards. Runs the real scene but
## never triggers a successful launch -- change_scene_to_file would tear the
## test down mid-run -- so happy-path launches are covered by the browser smoke
## test instead.

const ArcadeMenuScene := preload("res://scenes/arcade_menu.tscn")
const GameDefinition = preload("res://scripts/game_definition.gd")

const NAVY := Color(0.043, 0.075, 0.169)
const RED := Color(0.851, 0.149, 0.165)

var _checks := 0
var _failed := 0
var _save_path := ""
var _had_save := false
var _save_backup := ""
var _profile_snapshot: Dictionary = {}
var _menu: Control

func _ready() -> void:
	_save_path = ProjectSettings.globalize_path(Global.SAVE_PATH)
	_had_save = FileAccess.file_exists(_save_path)
	_save_backup = FileAccess.get_file_as_string(_save_path) if _had_save else ""
	_profile_snapshot = _capture_profile()
	await _run()
	_restore_save(_save_path, _had_save, _save_backup)
	_restore_profile(_profile_snapshot)
	print("")
	print("ArcadeMenuVerification: %d checks, %d failed" % [_checks, _failed])
	get_tree().quit(1 if _failed > 0 else 0)

func _run() -> void:
	_menu = ArcadeMenuScene.instantiate() as Control
	add_child(_menu)
	await get_tree().process_frame
	# Deterministic starting state regardless of the player's real save file.
	Global.arcade_favorites = []
	Global.arcade_recent_games = []
	_menu._refresh_games()
	await _verify_card_wall()
	await _verify_covers()
	await _verify_category_chips()
	await _verify_search()
	await _verify_recent()
	await _verify_favorites()
	await _verify_launch_guards()

func _verify_card_wall() -> void:
	print("-- card wall --")
	var ids := _card_ids()
	var expected: Array[String] = ["hero_select", "arc_break", "arc_snake", "brick_reactor", "tower_bounce", "minigame_1", "minigame_2", "minigame_3", "minigame_4", "flappy"]
	_check("registry holds ten cabinets", ids.size() == 10, str(ids.size()))
	_check("card wall mirrors registry order", ids == expected, str(ids))
	_check("count label reports ten cabinets", _count_text() == "10 CABINETS", _count_text())
	_check("empty state hidden with results", not _menu._empty_label.visible)

func _verify_covers() -> void:
	print("-- covers --")
	var missing := PackedStringArray()
	var broken := PackedStringArray()
	for game in GameLauncher.registry.all():
		if game.thumbnail_path.is_empty():
			missing.append(game.id)
			continue
		if not ResourceLoader.exists(game.thumbnail_path):
			broken.append(game.id)
			continue
		if not (load(game.thumbnail_path) is Texture2D):
			broken.append(game.id)
	_check("every cabinet declares a cover", missing.is_empty(), ", ".join(missing))
	_check("every cover loads as a texture", broken.is_empty(), ", ".join(broken))

func _verify_category_chips() -> void:
	print("-- category chips --")
	await _chip_press("ACTION")
	var ids := _card_ids()
	_check("ACTION shows five cabinets", ids.size() == 5, str(ids.size()))
	_check("ACTION order preserved", ids == ["hero_select", "arc_break", "brick_reactor", "minigame_1", "minigame_3"], str(ids))
	var action_chip: Button = _menu._chip_buttons.get("ACTION")
	var all_chip: Button = _menu._chip_buttons.get("")
	_check("active chip switches to red",
		(action_chip.get_theme_stylebox("normal") as StyleBoxFlat).bg_color.is_equal_approx(RED.darkened(0.15)),
		str((action_chip.get_theme_stylebox("normal") as StyleBoxFlat).bg_color))
	_check("inactive chip stays navy",
		(all_chip.get_theme_stylebox("normal") as StyleBoxFlat).bg_color.is_equal_approx(NAVY),
		str((all_chip.get_theme_stylebox("normal") as StyleBoxFlat).bg_color))
	await _chip_press("")
	_check("ALL restores ten cabinets", _card_ids().size() == 10, str(_card_ids().size()))

func _verify_search() -> void:
	print("-- search --")
	await _apply_search("snake")
	_check("search matches one cabinet", _card_ids() == ["arc_snake"], str(_card_ids()))
	_check("singular count label", _count_text() == "1 CABINET", _count_text())
	await _apply_search("tower")
	_check("search matches by name", _card_ids() == ["tower_bounce"], str(_card_ids()))
	await _apply_search("pixel-comic")
	_check("search matches by tag", _card_ids() == ["arc_break"], str(_card_ids()))
	await _apply_search("zzz")
	_check("no matches empties the wall", _card_ids().is_empty(), str(_card_ids()))
	_check("search empty state shown",
		_menu._empty_label.visible and _menu._empty_label.text.begins_with("NO CABINETS MATCH"),
		_menu._empty_label.text)
	await _chip_press("ACTION")
	_check("search and category compose", _card_ids().is_empty(), str(_card_ids()))
	await _apply_search("")
	_check("clearing search restores ACTION five", _card_ids().size() == 5, str(_card_ids().size()))
	await _chip_press("")
	_check("ALL restores ten after search tour", _card_ids().size() == 10, str(_card_ids().size()))

func _verify_recent() -> void:
	print("-- recent --")
	Global.arcade_recent_games = ["arc_snake", "flappy"]
	await _chip_press("RECENT")
	_check("RECENT mirrors recent list order", _card_ids() == ["arc_snake", "flappy"], str(_card_ids()))
	Global.arcade_recent_games = []
	_menu._refresh_games()
	await get_tree().process_frame
	_check("RECENT empty state",
		_menu._empty_label.visible and _menu._empty_label.text.begins_with("NO RECENT"),
		_menu._empty_label.text)
	await _chip_press("")

func _verify_favorites() -> void:
	print("-- favorites --")
	await _chip_press("")
	_check("star exists on every card", _menu._star_buttons.size() == 10, str(_menu._star_buttons.size()))
	_check("unpinned star uses the outline glyph", _star_text("arc_snake") == _menu._star_off, _star_text("arc_snake"))
	print("  INFO  star glyphs: on=%s off=%s native=%s" % [_menu._star_on, _menu._star_off, _menu._star_glyph_native])
	var star: Button = _menu._star_buttons.get("arc_snake")
	star.pressed.emit()
	await get_tree().process_frame
	_check("toggling star sets favorite", Global.is_favorite("arc_snake"))
	_check("pinned star uses the filled glyph", _star_text("arc_snake") == _menu._star_on, _star_text("arc_snake"))
	_check("favorite persists to the save file", _favorite_in_saved_file("arc_snake"))
	Global.load_save()
	_check("favorite reloads from the save file", Global.is_favorite("arc_snake"))
	await _chip_press("FAVORITES")
	_check("FAVORITES shelf shows only pinned", _card_ids() == ["arc_snake"], str(_card_ids()))
	var shelf_star: Button = _menu._star_buttons.get("arc_snake")
	shelf_star.pressed.emit()
	await get_tree().process_frame
	_check("unpin clears the favorite", not Global.is_favorite("arc_snake"))
	_check("FAVORITES empty state",
		_menu._empty_label.visible and _menu._empty_label.text.begins_with("NO FAVORITES"),
		_menu._empty_label.text)
	await _chip_press("")
	_check("fresh star is back to outline in ALL", _star_text("arc_snake") == _menu._star_off, _star_text("arc_snake"))

func _verify_launch_guards() -> void:
	print("-- launch guards --")
	await _chip_press("")
	for game in GameLauncher.registry.all():
		_check("scene exists: " + game.id, ResourceLoader.exists(game.scene_path), game.scene_path)
	var ghost := GameDefinition.new()
	ghost.id = "ghost_cabinet"
	ghost.display_name = "Ghost Cabinet"
	ghost.scene_path = "res://scenes/ghost_cabinet.tscn"
	ghost.category = "QUICK"
	GameLauncher.registry.add(ghost)
	_menu._refresh_games()
	await get_tree().process_frame
	_check("ghost cabinet joins the wall", _card_ids().size() == 11, str(_card_ids().size()))
	_menu._launch_game("ghost_cabinet")
	await get_tree().process_frame
	_check("missing scene is blocked", _status_text().begins_with("CABINET OFFLINE"), _status_text())
	_check("blocked launch does not lock the shell", not _menu._launching)
	_menu._launch_game("not_a_game")
	await get_tree().process_frame
	_check("unknown id is reported", _status_text().begins_with("CABINET MISSING"), _status_text())
	await _apply_search("zzz")
	_menu._on_random_pressed()
	await get_tree().process_frame
	_check("random with no matches is blocked", _status_text().begins_with("NO CABINETS MATCH"), _status_text())
	_check("blocked random keeps the shell idle", not _menu._launching)
	await _apply_search("")
	GameLauncher.registry.games.erase(ghost)
	_menu._refresh_games()
	await get_tree().process_frame
	_check("wall returns to ten after cleanup", _card_ids().size() == 10, str(_card_ids().size()))

func _chip_press(key: String) -> void:
	var chip: Button = _menu._chip_buttons.get(key)
	_check("chip present: " + ("ALL" if key.is_empty() else key), chip != null)
	if chip == null:
		return
	chip.pressed.emit()
	await get_tree().process_frame

func _apply_search(query: String) -> void:
	_menu._search_edit.text = query
	_menu._on_search_changed(query)
	await get_tree().process_frame

func _card_ids() -> Array:
	var ids := []
	for card in _menu._grid.get_children():
		ids.append(str(card.get_meta("game_id", "")))
	return ids

func _star_text(id: String) -> String:
	var star: Button = _menu._star_buttons.get(id)
	return star.text if star != null else ""

func _count_text() -> String:
	return str((_menu.get_node("CountLabel") as Label).text)

func _status_text() -> String:
	return str(_menu._status_label.text)

func _favorite_in_saved_file(id: String) -> bool:
	if not FileAccess.file_exists(_save_path):
		return false
	var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(_save_path))
	if not data is Dictionary:
		return false
	var favorites: Variant = data.get("arcade_favorites", [])
	return favorites is Array and favorites.has(id)

func _check(label: String, ok: bool, detail: String = "") -> void:
	_checks += 1
	if ok:
		print("  PASS  %s" % label)
	else:
		_failed += 1
		print("  FAIL  %s  (%s)" % [label, detail])

func _capture_profile() -> Dictionary:
	return {
		"best_streak": Global.best_streak,
		"volume": Global.volume,
		"music_volume": Global.music_volume,
		"flappy_best": Global.flappy_best,
		"tower_bounce_best": Global.tower_bounce_best,
		"brick_reactor_best": Global.brick_reactor_best,
		"arc_snake_best": Global.arc_snake_best,
		"arc_break_best": Global.arc_break_best,
		"arcade_games_played": Global.arcade_games_played,
		"arcade_total_wins": Global.arcade_total_wins,
		"arcade_bests": Global.arcade_bests.duplicate(true),
		"arcade_recent_games": Global.arcade_recent_games.duplicate(),
		"arcade_unique_games": Global.arcade_unique_games.duplicate(),
		"arcade_favorites": Global.arcade_favorites.duplicate(),
		"achievements_unlocked": Global.achievements_unlocked.duplicate(),
		"touch_controls_enabled": Global.touch_controls_enabled,
		"low_quality": Global.low_quality,
		"selected_hero": Global.selected_hero,
	}

func _restore_profile(snapshot: Dictionary) -> void:
	Global.best_streak = snapshot["best_streak"]
	Global.volume = snapshot["volume"]
	Global.music_volume = snapshot["music_volume"]
	Global.flappy_best = snapshot["flappy_best"]
	Global.tower_bounce_best = snapshot["tower_bounce_best"]
	Global.brick_reactor_best = snapshot["brick_reactor_best"]
	Global.arc_snake_best = snapshot["arc_snake_best"]
	Global.arc_break_best = snapshot["arc_break_best"]
	Global.arcade_games_played = snapshot["arcade_games_played"]
	Global.arcade_total_wins = snapshot["arcade_total_wins"]
	Global.arcade_bests = snapshot["arcade_bests"]
	Global.arcade_recent_games = snapshot["arcade_recent_games"]
	Global.arcade_unique_games = snapshot["arcade_unique_games"]
	Global.arcade_favorites = snapshot["arcade_favorites"]
	Global.achievements_unlocked = snapshot["achievements_unlocked"]
	Global.touch_controls_enabled = snapshot["touch_controls_enabled"]
	Global.low_quality = snapshot["low_quality"]
	Global.selected_hero = snapshot["selected_hero"]

func _restore_save(path: String, had_save: bool, backup: String) -> void:
	if had_save:
		var file := FileAccess.open(path, FileAccess.WRITE)
		if file != null:
			file.store_string(backup)
	else:
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(path)
