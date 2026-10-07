extends Node2D

## Hero select. The grid is built in code from HeroData.selectable() rather than
## laid out as nine hand-placed cards, so adding a tenth hero is one row in
## hero_data.gd and nothing here changes.
##
## A pick is a device preference, not per-run state, so it is written straight
## to Global and saved: the player does not re-pick on every loop of the
## gauntlet. FIGHT then resets per-run state and enters level_scene, exactly as
## the title screen's START does.

const TITLE_TRIM_DB := -8.0

const CARD_SIZE := Vector2(300, 150)
const CARD_GAP := 20
const COLUMNS := 3
const GRID_TOP := 100
const CARD_RADIUS := 6

## A short, quiet entrance: the grid resolves left-to-right rather than popping
## in all at once. Kept under a third of a second in total so a repeat visit
## never feels like it is making the player wait.
const STAGGER := 0.04
const FADE_IN := 0.18

## The title screen's palette, so the two read as one cabinet. Gold is the only
## accent; red is reserved for the press state, matching the menu buttons.
const NAVY := Color(0.043, 0.075, 0.169)
const NAVY_HOVER := Color(0.106, 0.165, 0.369)
const NAVY_PRESSED := Color(0.02, 0.035, 0.08)
const GOLD := Color(1, 0.827, 0.302)
const GOLD_PALE := Color(1, 0.914, 0.765)
const RED := Color(0.851, 0.149, 0.165)
const TEXT_DIM := Color(0.78, 0.82, 0.92)

var _cards: Array[Button] = []
var _details: Array[Dictionary] = []
var _selected := ""
var _hovered := ""
var _returning := false


func _ready() -> void:
	SceneFade.fade_in(self)
	Music.play("title", 1.2, TITLE_TRIM_DB)
	$FightButton.disabled = true
	$RandomButton.disabled = true
	$BackButton.disabled = true
	_build_grid()
	# A save from an older build can name a hero that no longer exists, or none at
	# all. Preselect whatever Global would actually play, so the Fight button is
	# live the moment the screen opens rather than demanding a pointless pick.
	_mark_selected(Global.active_hero_id())
	_unlock()
	_animate_in()


func _build_grid() -> void:
	var heroes := HeroData.selectable()
	var rows := ceili(float(heroes.size()) / float(COLUMNS))
	var grid_width := COLUMNS * CARD_SIZE.x + (COLUMNS - 1) * CARD_GAP
	var left := (1280.0 - grid_width) * 0.5

	_details.clear()
	_cards.clear()
	for i in heroes.size():
		var hero: Dictionary = heroes[i]
		var col := i % COLUMNS
		var row := i / COLUMNS
		var card := _make_card(hero)
		card.position = Vector2(
			left + col * (CARD_SIZE.x + CARD_GAP),
			GRID_TOP + row * (CARD_SIZE.y + CARD_GAP))
		# $Grid, not self: the cards must sit before the buttons in the tree so
		# Tab walks the roster first and only then reaches FIGHT and BACK.
		$Grid.add_child(card)
		_cards.append(card)
		_details.append(hero)

	if rows > 3:
		push_warning("Roster outgrew the %d-column grid at %d rows; cards will "
			% [COLUMNS, rows] + "run past the 720px design height.")


## One hero as a real Button rather than a Panel plus an Area2D: that buys
## focus traversal, the focus ring, and keyboard activation from the engine
## instead of hand-rolling all three. The children sit inside it with the mouse
## filter off so a click anywhere on the card lands on the button.
func _make_card(hero: Dictionary) -> Button:
	var card := Button.new()
	card.custom_minimum_size = CARD_SIZE
	card.size = CARD_SIZE
	card.focus_mode = Control.FOCUS_ALL
	card.text = ""
	card.tooltip_text = "%s -- %s\n%s" % [hero["name"], hero["power"], hero["blurb"]]
	card.pressed.connect(_on_card_pressed.bind(hero["id"]))
	card.mouse_entered.connect(_on_hover_changed.bind(hero["id"], true))
	card.mouse_exited.connect(_on_hover_changed.bind(hero["id"], false))
	card.focus_entered.connect(_refresh_detail)
	card.focus_exited.connect(_refresh_detail)

	var art := TextureRect.new()
	art.texture = load(hero["art"]) as Texture2D
	art.position = Vector2(10, 8)
	art.size = Vector2(CARD_SIZE.x - 20, 84)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	card.add_child(art)

	var name_label := _label(hero["name"], 26, GOLD, Vector2(12, 96),
		Vector2(CARD_SIZE.x - 24, 30), HORIZONTAL_ALIGNMENT_CENTER)
	card.add_child(name_label)

	var subtitle := "%s  ·  %s  ·  %ss" % [
		hero["power"],
		HeroData.family_name(int(hero["family"])),
		int(round(float(hero["cooldown"]))),
	]
	card.add_child(_label(subtitle, 15, TEXT_DIM, Vector2(12, 124),
		Vector2(CARD_SIZE.x - 24, 22), HORIZONTAL_ALIGNMENT_CENTER))

	return card


func _label(text: String, size: int, color: Color, pos: Vector2, box: Vector2,
		align: int) -> Label:
	var label := Label.new()
	label.text = text
	label.position = pos
	label.size = box
	label.horizontal_alignment = align
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	# The menu's black outline is what keeps light text legible over the busy
	# background art; without it the gold washes out.
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	label.add_theme_constant_override("outline_size", maxi(4, size / 5))
	return label


## Selection and hover are told apart on purpose: gold border means "this is who
## you will play", a paler one means "you are looking at this one". Conflating
## them makes a keyboard user's focus position and their confirmed pick
## indistinguishable.
func _style(border: Color, fill: Color, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.set_border_width_all(width)
	style.border_color = border
	style.set_corner_radius_all(CARD_RADIUS)
	style.content_margin_left = 0.0
	style.content_margin_right = 0.0
	return style


func _apply_style(card: Button, selected: bool) -> void:
	var idle := NAVY_HOVER if selected else NAVY
	var hover := NAVY_HOVER
	card.add_theme_stylebox_override("normal",
		_style(GOLD if selected else GOLD.darkened(0.45), idle, 4 if selected else 3))
	card.add_theme_stylebox_override("hover", _style(GOLD_PALE, hover, 4))
	card.add_theme_stylebox_override("pressed", _style(GOLD, NAVY_PRESSED, 4))
	card.add_theme_stylebox_override("focus", _style(GOLD, hover, 2))
	card.add_theme_stylebox_override("disabled", _style(GOLD.darkened(0.45), idle, 3))


func _mark_selected(id: String) -> void:
	_selected = id
	for i in _cards.size():
		_apply_style(_cards[i], _details[i]["id"] == id)
	_refresh_detail()


func _on_card_pressed(id: String) -> void:
	if id == _selected:
		# Tapping the current pick again is the confirm gesture, so a player can
		# pick and go without hunting for a second button.
		_start_run()
		return
	_mark_selected(id)
	Global.selected_hero = id
	Global.save()


func _on_hover_changed(id: String, entered: bool) -> void:
	_hovered = id if entered else ""
	_refresh_detail()


## The blurb belongs to whichever card the pointer is on, else the one holding
## focus, else the confirmed pick. Printing all nine at once would be a wall of
## text nobody reads.
##
## Recomputed from live state rather than driven by which signal fired last, so
## it does not depend on the order Godot emits focus_exited/focus_entered in when
## focus moves between two cards.
func _refresh_detail() -> void:
	var wanted := _hovered
	if wanted == "":
		var focus_owner := get_viewport().gui_get_focus_owner()
		for i in _cards.size():
			if _cards[i] == focus_owner:
				wanted = _details[i]["id"]
				break
	if wanted == "":
		wanted = _selected
	for i in _cards.size():
		if _details[i]["id"] == wanted:
			_show_detail(_details[i])
			return


func _show_detail(hero: Dictionary) -> void:
	$DetailLabel.text = hero["blurb"]
	$DetailLabel.add_theme_color_override("font_color", hero["accent"])


func _animate_in() -> void:
	for i in _cards.size():
		var card := _cards[i]
		card.modulate.a = 0.0
		var tween := create_tween()
		tween.tween_interval(STAGGER * i)
		tween.tween_property(card, "modulate:a", 1.0, FADE_IN)
	var tween := create_tween()
	tween.tween_interval(STAGGER * _cards.size())
	tween.tween_callback(func() -> void: _cards[0].grab_focus())


func _unlock() -> void:
	$FightButton.disabled = false
	$RandomButton.disabled = false
	$BackButton.disabled = false


func _start_run() -> void:
	if _selected == "":
		return
	# Selecting FIGHT enters the full gauntlet, so a library launch target must
	# not interrupt the normal minigame-to-minigame route.
	GameLauncher.clear_return_scene()
	Global.selected_hero = _selected
	Global.save()
	Global.reset()
	await SceneFade.fade_out(self)
	get_tree().change_scene_to_file("res://scenes/level_scene.tscn")


func _on_fight_pressed() -> void:
	_start_run()


func _on_random_pressed() -> void:
	_mark_selected(HeroData.random_id())
	_start_run()


func _on_back_pressed() -> void:
	if _returning:
		return
	_returning = true
	await SceneFade.fade_out(self)
	if GameLauncher.has_return_scene():
		GameLauncher.return_to_library()
	else:
		get_tree().change_scene_to_file("res://scenes/title_screen.tscn")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_back_pressed()
