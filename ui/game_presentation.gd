class_name GamePresentation
extends RefCounted

# One presentation file per existing game, never one worker per shared pack.
# File: res://ui/game_presentations/<catalog_id>.gd
# Template:
#   extends RefCounted
#   const TITLE := "Readable game title"
#   const SETTING := "An original place or visual theme"
#   const ACCENT := Color("#e99b65")
#   func draw_background(canvas: Node2D, context: Dictionary) -> void:
#       canvas.draw_rect(context.board_rect, Color("#f6ecd9"))
#
# Backgrounds use the existing 960 x 480 board coordinates. Gameplay owns its
# entire board: keep central decorations low contrast, put scenery at the edges,
# and never draw instructions, action targets, foreground actors or input areas.
# Respect context.reduced_motion; elapsed is gameplay time and stops on pause.
# Do not use random numbers, change canvas state, or modify context/gameplay.
# TITLE/SETTING/ACCENT are optional metadata for selection/HUD consumers.

const DIRECTORY := "res://ui/game_presentations/"
const BOARD_RECT := Rect2(0, 0, 960, 480)

static func load_for_id(game_id: String) -> RefCounted:
	# Catalog IDs are ASCII identifiers. Refuse arbitrary paths before loading.
	if game_id.is_empty():
		return null
	for character in game_id:
		if not (character >= "a" and character <= "z") and not (character >= "0" and character <= "9") and character != "_":
			return null
	var path: String = DIRECTORY + game_id + ".gd"
	if not ResourceLoader.exists(path, "Script"):
		return null
	var script: Script = load(path) as Script
	if script == null or not script.can_instantiate():
		return null
	if script.get_instance_base_type() != "RefCounted":
		return null
	var presentation: RefCounted = script.new() as RefCounted
	if presentation == null or not presentation.has_method("draw_background"):
		return null
	return presentation

static func context_for(metadata: Dictionary, elapsed: float, cosmetic: String, reduced_motion: bool) -> Dictionary:
	return {
		"id": String(metadata.get("id", "")),
		"category": String(metadata.get("category", "")),
		"elapsed": elapsed,
		"cosmetic": cosmetic,
		"reduced_motion": reduced_motion,
		"board_rect": BOARD_RECT,
	}

static func describe(presentation: RefCounted) -> Dictionary:
	if presentation == null:
		return {}
	var script: Script = presentation.get_script() as Script
	if script == null:
		return {}
	var constants: Dictionary = script.get_script_constant_map()
	var result: Dictionary = {}
	for key in ["TITLE", "SETTING", "ACCENT"]:
		if constants.has(key):
			result[key.to_lower()] = constants[key]
	return result
