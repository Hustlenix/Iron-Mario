extends Control

## Arcade hub shell: every registered cabinet renders as a card in a
## two-column wall. Category chips and the search field filter by category,
## name, or tag; the star on each card pins a favorite (persisted by Global);
## RANDOM GAME draws from the currently filtered pool. Launches are guarded so
## a missing cabinet scene shows an inline warning instead of a fade to
## nowhere.

const GameDefinition = preload("res://scripts/game_definition.gd")

const NAVY := Color(0.043, 0.075, 0.169)
const NAVY_HOVER := Color(0.106, 0.165, 0.369)
const GOLD := Color(1.0, 0.827, 0.302)
const GOLD_PALE := Color(1.0, 0.914, 0.765)
const RED := Color(0.851, 0.149, 0.165)
const TEXT_DIM := Color(0.78, 0.82, 0.92)
const WARN := Color(1.0, 0.45, 0.4)

## Filter chips in display order: [label, filter key, width]. "ALL" maps to
## the empty key so _filtered_games can treat it as "no filter".
const CHIP_DEFS := [
	["ALL", "", 145.0],
	["ACTION", "ACTION", 145.0],
	["SKILL", "SKILL", 145.0],
	["QUICK", "QUICK", 145.0],
	["RECENT", "RECENT", 145.0],
	["FAVORITES", "FAVORITES", 160.0],
]

var _games_box: VBoxContainer
var _grid: GridContainer
var _empty_label: Label
var _search_edit: LineEdit
var _status_label: Label
var _chip_buttons: Dictionary = {}
var _star_buttons: Dictionary = {}
var _category := ""
var _launching := false
var _star_on := "★"
var _star_off := "☆"
var _star_glyph_native := true

func _ready() -> void:
	_choose_star_glyphs()
	SceneFade.fade_in(self)
	Music.play("title", 1.0, -8.0)
	_build_ui()
	_refresh_games()

## The star pair only renders if the fallback theme font carries the glyphs.
## A bare project font may not, so fall back to ASCII that every font has.
func _choose_star_glyphs() -> void:
	var font := ThemeDB.fallback_font
	if font != null and font.has_char(0x2605) and font.has_char(0x2606):
		_star_on = "★"
		_star_off = "☆"
		_star_glyph_native = true
	else:
		_star_on = "+"
		_star_off = "-"
		_star_glyph_native = false

func _build_ui() -> void:
	var background := TextureRect.new()
	background.texture = load("res://assets/bg_title.svg") as Texture2D
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var title := _label("THE ARCADE", 54, GOLD)
	title.position = Vector2(64, 36)
	title.size = Vector2(700, 72)
	add_child(title)

	var subtitle := _label("PICK A CABINET. PLAY A ROUND. TRY ONE MORE.", 20, TEXT_DIM)
	subtitle.position = Vector2(70, 108)
	subtitle.size = Vector2(700, 34)
	add_child(subtitle)

	var random := _button("RANDOM GAME", Vector2(290, 64), RED)
	random.position = Vector2(920, 48)
	random.pressed.connect(_on_random_pressed)
	add_child(random)

	_build_chips()
	_build_search()

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(70, 240)
	scroll.size = Vector2(1140, 385)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)

	_games_box = VBoxContainer.new()
	_games_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_games_box.add_theme_constant_override("separation", 12)
	scroll.add_child(_games_box)

	_grid = GridContainer.new()
	_grid.columns = 2
	_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_grid.add_theme_constant_override("h_separation", 16)
	_grid.add_theme_constant_override("v_separation", 14)
	_games_box.add_child(_grid)

	_empty_label = _label("", 20, TEXT_DIM)
	_empty_label.custom_minimum_size = Vector2(0, 120)
	_empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_empty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_empty_label.visible = false
	_games_box.add_child(_empty_label)

	var back := _button("BACK TO TITLE", Vector2(250, 56), NAVY)
	back.position = Vector2(70, 650)
	back.pressed.connect(_on_back_pressed)
	add_child(back)

	var count := _label("", 18, TEXT_DIM)
	count.name = "CountLabel"
	count.position = Vector2(930, 660)
	count.size = Vector2(280, 34)
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(count)

	_status_label = _label("", 18, WARN)
	_status_label.name = "StatusLabel"
	_status_label.position = Vector2(350, 660)
	_status_label.size = Vector2(570, 34)
	_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status_label.visible = false
	add_child(_status_label)

	_apply_chip_styles()

func _build_chips() -> void:
	var x := 70.0
	for def in CHIP_DEFS:
		var label := str(def[0])
		var key := str(def[1])
		var width := float(def[2])
		var chip := _button(label, Vector2(width, 52), NAVY)
		chip.position = Vector2(x, 165)
		chip.pressed.connect(_on_category_pressed.bind(key))
		add_child(chip)
		_chip_buttons[key] = chip
		x += width + 8.0

func _build_search() -> void:
	_search_edit = LineEdit.new()
	_search_edit.name = "SearchEdit"
	_search_edit.position = Vector2(1015, 167)
	_search_edit.size = Vector2(195, 50)
	_search_edit.placeholder_text = "SEARCH"
	_search_edit.clear_button_enabled = true
	_search_edit.add_theme_font_size_override("font_size", 18)
	_search_edit.add_theme_color_override("font_color", GOLD_PALE)
	_search_edit.add_theme_color_override("font_placeholder_color", TEXT_DIM)
	_search_edit.add_theme_color_override("clear_button_color", GOLD)
	_search_edit.add_theme_color_override("clear_button_color_pressed", GOLD_PALE)
	_search_edit.add_theme_stylebox_override("normal", _field_style(NAVY, GOLD.darkened(0.35), 3))
	_search_edit.add_theme_stylebox_override("focus", _field_style(NAVY_HOVER, GOLD, 4))
	_search_edit.text_changed.connect(_on_search_changed)
	add_child(_search_edit)

func _refresh_games() -> void:
	if _grid == null:
		return
	for child in _grid.get_children():
		_grid.remove_child(child)
		child.queue_free()
	_star_buttons.clear()
	var games := _filtered_games()
	for game in games:
		_grid.add_child(_make_card(game))
	_grid.visible = not games.is_empty()
	_empty_label.visible = games.is_empty()
	_empty_label.text = _empty_state_text() if games.is_empty() else ""
	$CountLabel.text = "%d CABINET%s" % [games.size(), "" if games.size() == 1 else "S"]

## The wall's visible cabinets: category or special shelf first, then the
## search query (name, category, or tag), always preserving registry order.
func _filtered_games() -> Array[GameDefinition]:
	var base: Array[GameDefinition] = []
	if _category.is_empty():
		base = GameLauncher.registry.all()
	elif _category == "RECENT":
		for id in Global.arcade_recent_games:
			var recent := GameLauncher.registry.get_game(id)
			if recent != null and not base.has(recent):
				base.append(recent)
	elif _category == "FAVORITES":
		for game in GameLauncher.registry.all():
			if Global.is_favorite(game.id):
				base.append(game)
	else:
		base = GameLauncher.registry.get_by_category(_category)
	var query := _search_edit.text.strip_edges().to_lower()
	if query.is_empty():
		return base
	var filtered: Array[GameDefinition] = []
	for game in base:
		if _matches_query(game, query):
			filtered.append(game)
	return filtered

func _matches_query(game: GameDefinition, query: String) -> bool:
	if game.display_name.to_lower().contains(query):
		return true
	if game.category.to_lower().contains(query):
		return true
	for tag in game.tags:
		if tag.to_lower().contains(query):
			return true
	return false

func _empty_state_text() -> String:
	if not _search_edit.text.strip_edges().is_empty():
		return "NO CABINETS MATCH - TRY ANOTHER SEARCH"
	if _category == "FAVORITES":
		return "NO FAVORITES YET - TAP THE STAR ON A CABINET"
	if _category == "RECENT":
		return "NO RECENT PLAYS YET - PICK A CABINET"
	return "NO CABINETS MATCH - TRY ANOTHER FILTER"

## One cabinet card: cover tile (or initial-letter fallback), name / meta /
## best-score column, and the favorite star pinned top-right.
func _make_card(game: GameDefinition) -> Button:
	var card := _button("", Vector2(548, 132), NAVY)
	card.name = "Card_" + game.id
	card.clip_contents = true
	card.tooltip_text = "PLAY " + game.display_name.to_upper()
	card.set_meta("game_id", game.id)
	card.alignment = HORIZONTAL_ALIGNMENT_LEFT
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card.pressed.connect(_on_game_pressed.bind(game.id))

	var row := HBoxContainer.new()
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 14.0
	row.offset_top = 12.0
	row.offset_right = -70.0
	row.offset_bottom = -12.0
	row.add_theme_constant_override("separation", 14)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	card.add_child(row)

	var thumb_frame := PanelContainer.new()
	thumb_frame.custom_minimum_size = Vector2(96, 96)
	thumb_frame.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	thumb_frame.add_theme_stylebox_override("panel", _frame_style(NAVY_HOVER, GOLD.darkened(0.35), 2))
	thumb_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(thumb_frame)

	var cover_texture: Texture2D = null
	if not game.thumbnail_path.is_empty():
		cover_texture = load(game.thumbnail_path) as Texture2D
	if cover_texture != null:
		var cover := TextureRect.new()
		cover.texture = cover_texture
		cover.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		cover.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		cover.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
		thumb_frame.add_child(cover)
	else:
		var initial := _label(game.display_name.substr(0, 1).to_upper(), 44, GOLD_PALE)
		initial.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		initial.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		initial.mouse_filter = Control.MOUSE_FILTER_IGNORE
		thumb_frame.add_child(initial)

	var info := VBoxContainer.new()
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	info.add_theme_constant_override("separation", 2)
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(info)

	var name_label := _label(game.display_name.to_upper(), 22, GOLD)
	name_label.add_theme_constant_override("outline_size", 6)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_child(name_label)

	var meta := _label("%s  ·  %ds  ·  DIFF %d" % [game.category, game.estimated_duration_sec, game.difficulty], 15, TEXT_DIM)
	meta.add_theme_constant_override("outline_size", 4)
	meta.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_child(meta)

	var best := Global.arcade_best(game.id)
	var best_label := _label("BEST %d" % best if best > 0 else "NEW", 15, GOLD_PALE)
	best_label.add_theme_constant_override("outline_size", 4)
	best_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info.add_child(best_label)

	card.add_child(_make_star(game.id))
	return card

func _make_star(game_id: String) -> Button:
	var star := Button.new()
	star.name = "Star_" + game_id
	star.focus_mode = Control.FOCUS_ALL
	star.custom_minimum_size = Vector2(44, 44)
	star.anchor_left = 1.0
	star.anchor_right = 1.0
	star.offset_left = -58.0
	star.offset_top = 12.0
	star.offset_right = -14.0
	star.offset_bottom = 56.0
	star.add_theme_font_size_override("font_size", 26)
	star.add_theme_color_override("font_color", GOLD)
	star.add_theme_color_override("font_hover_color", Color.WHITE)
	star.add_theme_color_override("font_pressed_color", GOLD_PALE)
	star.add_theme_color_override("font_focus_color", GOLD)
	star.add_theme_color_override("font_outline_color", Color.BLACK)
	star.add_theme_constant_override("outline_size", 5)
	star.add_theme_stylebox_override("normal", _frame_style(NAVY_HOVER, GOLD.darkened(0.35), 2))
	star.add_theme_stylebox_override("hover", _frame_style(NAVY_HOVER.lightened(0.15), GOLD_PALE, 3))
	star.add_theme_stylebox_override("pressed", _frame_style(RED.darkened(0.15), GOLD, 3))
	star.add_theme_stylebox_override("focus", _frame_style(Color(0, 0, 0, 0), RED, 2))
	star.pressed.connect(_on_favorite_pressed.bind(game_id))
	_star_buttons[game_id] = star
	_update_star(game_id)
	return star

func _update_star(game_id: String) -> void:
	var star: Button = _star_buttons.get(game_id)
	if star == null:
		return
	var favorite := Global.is_favorite(game_id)
	star.text = _star_on if favorite else _star_off
	star.tooltip_text = "REMOVE FAVORITE" if favorite else "ADD FAVORITE"

func _launch_game(id: String) -> void:
	if _launching:
		return
	var game := GameLauncher.registry.get_game(id)
	if game == null:
		_show_error("CABINET MISSING - REGISTRY OUT OF DATE")
		return
	if not ResourceLoader.exists(game.scene_path):
		_show_error("CABINET OFFLINE: " + game.display_name.to_upper())
		return
	_launching = true
	_set_status("LOADING " + game.display_name.to_upper())
	await SceneFade.fade_out(self)
	GameLauncher.launch(id, "res://scenes/arcade_menu.tscn")

func _on_category_pressed(category: String) -> void:
	_category = category
	_apply_chip_styles()
	_refresh_games()

func _on_search_changed(_query: String) -> void:
	_refresh_games()

func _on_random_pressed() -> void:
	var pool := _filtered_games()
	if pool.is_empty():
		_show_error("NO CABINETS MATCH - TRY ANOTHER FILTER")
		return
	Global.unlock_achievement("random_encounter")
	_launch_game(pool[randi() % pool.size()].id)

func _on_favorite_pressed(id: String) -> void:
	Global.toggle_favorite(id)
	if _category == "FAVORITES":
		_refresh_games()
		var star: Button = _star_buttons.get(id)
		if star != null:
			star.grab_focus()
	else:
		_update_star(id)

func _on_game_pressed(id: String) -> void:
	_launch_game(id)

func _on_back_pressed() -> void:
	if _launching:
		return
	_launching = true
	await SceneFade.fade_out(self)
	get_tree().change_scene_to_file("res://scenes/title_screen.tscn")

func _set_status(message: String) -> void:
	if _status_label == null:
		return
	_status_label.text = message
	_status_label.visible = true

func _show_error(message: String) -> void:
	_set_status(message)
	push_warning("ArcadeMenu: " + message)

func _apply_chip_styles() -> void:
	for key in _chip_buttons:
		var chip: Button = _chip_buttons[key]
		if key == _category:
			chip.add_theme_stylebox_override("normal", _style(RED.darkened(0.15), GOLD, 4))
			chip.add_theme_stylebox_override("hover", _style(RED.darkened(0.05), GOLD, 4))
			chip.add_theme_stylebox_override("pressed", _style(RED.darkened(0.3), GOLD_PALE, 4))
			chip.add_theme_color_override("font_color", Color.WHITE)
			chip.add_theme_color_override("font_hover_color", Color.WHITE)
		else:
			chip.add_theme_stylebox_override("normal", _style(NAVY, GOLD.darkened(0.35), 3))
			chip.add_theme_stylebox_override("hover", _style(NAVY_HOVER, GOLD_PALE, 4))
			chip.add_theme_stylebox_override("pressed", _style(RED.darkened(0.15), GOLD, 4))
			chip.add_theme_color_override("font_color", GOLD)
			chip.add_theme_color_override("font_hover_color", Color.WHITE)

func _label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 8)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _button(text: String, minimum: Vector2, fill: Color) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = minimum
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", 21 if minimum.y > 60 else 18)
	button.add_theme_color_override("font_color", GOLD)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", GOLD_PALE)
	button.add_theme_color_override("font_focus_color", GOLD)
	button.add_theme_color_override("font_outline_color", Color.BLACK)
	button.add_theme_constant_override("outline_size", 5)
	button.add_theme_stylebox_override("normal", _style(fill, GOLD.darkened(0.35), 3))
	button.add_theme_stylebox_override("hover", _style(NAVY_HOVER, GOLD_PALE, 4))
	button.add_theme_stylebox_override("pressed", _style(RED.darkened(0.15), GOLD, 4))
	button.add_theme_stylebox_override("focus", _style(Color(0, 0, 0, 0), RED, 2))
	return button

func _style(fill: Color, border: Color, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(6)
	style.content_margin_left = 22.0
	style.content_margin_right = 22.0
	style.content_margin_top = 12.0
	style.content_margin_bottom = 12.0
	return style

## Small-frame style for cover tiles, stars, and other tight boxes: smaller
## margins so a 44px star does not lose its glyph to padding.
func _frame_style(fill: Color, border: Color, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(4)
	style.content_margin_left = 4.0
	style.content_margin_right = 4.0
	style.content_margin_top = 4.0
	style.content_margin_bottom = 4.0
	return style

func _field_style(fill: Color, border: Color, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(6)
	style.content_margin_left = 14.0
	style.content_margin_right = 14.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	return style
