extends Control

## The hero you picked, shown during play.
##
## MG1 and MG3 have clear top-left space, so they get the full portrait. MG2 and
## MG4 keep their action zones close to the top and get the compact badge
## instead. Both read the pick straight from Global rather than being handed it,
## so no minigame carries hero state and a changed pick always shows up.
##
## The cooldown ring (power_ring.tscn) already owns "what can this hero do";
## this only answers "who am I playing", so the two never fight over the HUD.

@export var full := false

## The title's navy, held at partial alpha so the art behind stays visible but
## the name does not fight the background art for legibility.
const NAVY := Color(0.043, 0.075, 0.169)
const BACKDROP_ALPHA := 0.66
const GOLD := Color(1, 0.827, 0.302)
const TEXT_DIM := Color(0.78, 0.82, 0.92)
const OUTLINE := Color(0, 0, 0, 1)
const RADIUS := 8

const FULL_SIZE := Vector2(140, 150)
const BADGE_SIZE := Vector2(168, 56)
const FULL_ART := 88.0
const BADGE_ART := 40.0
## Where the copy starts in badge mode: art is 40 wide with 8px of padding.
const BADGE_TEXT_X := 54.0

var _frame: Panel
var _art: TextureRect
var _name: Label
var _power: Label


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build()
	_show(Global.active_hero_id())


func _build() -> void:
	var box := FULL_SIZE if full else BADGE_SIZE
	size = box
	custom_minimum_size = box

	_frame = Panel.new()
	_frame.name = "Frame"
	_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_frame.size = box
	_frame.add_theme_stylebox_override("panel", _frame_style(GOLD))
	add_child(_frame)

	_art = TextureRect.new()
	_art.name = "Art"
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	if full:
		_art.position = Vector2((box.x - FULL_ART) * 0.5, 8.0)
		_art.size = Vector2(FULL_ART, FULL_ART)
	else:
		_art.position = Vector2(8, 8)
		_art.size = Vector2(BADGE_ART, BADGE_ART)
	add_child(_art)

	# One layout switch, two arrangements: stacked under the art in full mode,
	# beside it in badge mode so the chip stays short enough to stay out of the
	# way of the action.
	var text_x := 0.0 if full else BADGE_TEXT_X
	var text_w := box.x if full else box.x - BADGE_TEXT_X
	var name_y := 100.0 if full else 8.0
	var name_h := 24.0 if full else 20.0
	_name = _label("Hero", 17 if full else 14, GOLD, Vector2(text_x, name_y),
		Vector2(text_w, name_h))
	_name.name = "NameLabel"
	add_child(_name)

	var power_y := 124.0 if full else 28.0
	var power_h := 20.0 if full else 18.0
	_power = _label("Power", 12 if full else 11, TEXT_DIM, Vector2(text_x, power_y),
		Vector2(text_w, power_h))
	_power.name = "PowerLabel"
	add_child(_power)


func _show(id: String) -> void:
	# get_hero() never returns an empty dictionary, so an unknown or missing id
	# degrades to the first hero here exactly as it does everywhere else. A
	# player with a corrupt save still sees who they are playing instead of an
	# empty frame sitting over the level.
	var hero := HeroData.get_hero(id)
	visible = true
	_art.texture = load(str(hero["art"])) as Texture2D
	_name.text = str(hero["name"]).to_upper()
	_power.text = str(hero["power"])
	# The accent ties the chip to the hero the same way the power ring ties its
	# arc to the family.
	_frame.add_theme_stylebox_override("panel", _frame_style(hero["accent"]))


func _frame_style(border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(NAVY.r, NAVY.g, NAVY.b, BACKDROP_ALPHA)
	style.set_corner_radius_all(RADIUS)
	style.set_border_width_all(2)
	style.border_color = border
	return style


func _label(text: String, font_size: int, color: Color, pos: Vector2,
		box: Vector2) -> Label:
	var label := Label.new()
	label.text = text
	label.position = pos
	label.size = box
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	# The black outline is what keeps the gold legible over busy level art.
	label.add_theme_color_override("font_outline_color", OUTLINE)
	label.add_theme_constant_override("outline_size", maxi(3, font_size / 4))
	return label
