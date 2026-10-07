extends Control

const NAVY := Color(0.043, 0.075, 0.169)
const NAVY_HOVER := Color(0.106, 0.165, 0.369)
const GOLD := Color(1.0, 0.827, 0.302)
const GOLD_PALE := Color(1.0, 0.914, 0.765)
const RED := Color(0.851, 0.149, 0.165)
const TEXT_DIM := Color(0.78, 0.82, 0.92)

var _games_box: VBoxContainer
var _category := ""
var _launching := false

func _ready() -> void:
	SceneFade.fade_in(self)
	Music.play("title", 1.0, -8.0)
	_build_ui()
	_refresh_games()

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

	var categories := HBoxContainer.new()
	categories.position = Vector2(70, 165)
	categories.size = Vector2(800, 56)
	categories.add_theme_constant_override("separation", 10)
	add_child(categories)
	for item in ["ALL", "ACTION", "SKILL", "QUICK", "RECENT"]:
		var category_button := _button(item, Vector2(150, 52), NAVY)
		category_button.pressed.connect(_on_category_pressed.bind(item if item != "ALL" else ""))
		categories.add_child(category_button)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(70, 240)
	scroll.size = Vector2(1140, 365)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	add_child(scroll)
	_games_box = VBoxContainer.new()
	_games_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_games_box.add_theme_constant_override("separation", 12)
	scroll.add_child(_games_box)

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

func _refresh_games() -> void:
	if _games_box == null:
		return
	for child in _games_box.get_children():
		child.queue_free()
	var games: Array = []
	if _category.is_empty():
		games = GameLauncher.registry.all()
	elif _category == "RECENT":
		for id in Global.arcade_recent_games:
			var recent := GameLauncher.registry.get_game(id)
			if recent:
				games.append(recent)
	else:
		games = GameLauncher.registry.get_by_category(_category)
	for game in games:
		var best := Global.arcade_best(game.id)
		var score_text := "BEST %d" % best if best > 0 else "NEW"
		var text := "%s     %s  ·  %ds  ·  DIFFICULTY %d  ·  %s" % [game.display_name.to_upper(), game.category, game.estimated_duration_sec, game.difficulty, score_text]
		var button := _button(text, Vector2(1120, 68), NAVY)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(_on_game_pressed.bind(game.id))
		_games_box.add_child(button)
	$CountLabel.text = "%d CABINET%s" % [games.size(), "" if games.size() == 1 else "S"]

func _on_category_pressed(category: String) -> void:
	_category = category
	_refresh_games()

func _on_random_pressed() -> void:
	var game := GameLauncher.registry.random(_category)
	if game:
		_launch_game(game.id)

func _on_game_pressed(id: String) -> void:
	_launch_game(id)

func _launch_game(id: String) -> void:
	if _launching:
		return
	_launching = true
	await SceneFade.fade_out(self)
	GameLauncher.launch(id, "res://scenes/arcade_menu.tscn")

func _on_back_pressed() -> void:
	if _launching:
		return
	_launching = true
	await SceneFade.fade_out(self)
	get_tree().change_scene_to_file("res://scenes/title_screen.tscn")

func _label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.add_theme_constant_override("outline_size", 8)
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
