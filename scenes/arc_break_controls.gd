extends CanvasLayer

## A four-way, press-and-hold touch pad for Arc Break's top-down movement plus
## one large repulsor button. It stays out of the way for keyboard/mouse players
## and reveals on the first screen touch for hybrid devices.

const ACTIONS := ["left", "right", "arc_up", "arc_down", "power"]
const NAVY := Color(0.035, 0.07, 0.14, 0.82)
const GOLD := Color(1.0, 0.82, 0.28)
const CYAN := Color(0.46, 0.88, 1.0)

var _touch_seen := false
var _buttons: Dictionary = {}
var _root: Control
var _portrait_hint: Label

func _ready() -> void:
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)
	_create_button("left", "◀", Vector2(96, 96), GOLD)
	_create_button("right", "▶", Vector2(96, 96), GOLD)
	_create_button("arc_up", "▲", Vector2(96, 96), GOLD)
	_create_button("arc_down", "▼", Vector2(96, 96), GOLD)
	_create_button("power", "REPULSOR", Vector2(210, 96), CYAN)
	_portrait_hint = Label.new()
	_portrait_hint.text = "ROTATE TO LANDSCAPE"
	_portrait_hint.add_theme_font_size_override("font_size", 30)
	_portrait_hint.add_theme_color_override("font_color", GOLD)
	_portrait_hint.add_theme_color_override("font_outline_color", Color.BLACK)
	_portrait_hint.add_theme_constant_override("outline_size", 8)
	_portrait_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_portrait_hint.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_portrait_hint.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_portrait_hint.visible = false
	_portrait_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_portrait_hint)
	_layout_controls()
	_apply_visibility()
	get_viewport().size_changed.connect(_on_viewport_changed)
	tree_exiting.connect(_release_all)

func _create_button(action: String, text: String, size: Vector2, color: Color) -> void:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = size
	button.size = size
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_font_size_override("font_size", 24 if action != "power" else 19)
	button.add_theme_color_override("font_color", color)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_color_override("font_outline_color", Color.BLACK)
	button.add_theme_constant_override("outline_size", 5)
	button.add_theme_stylebox_override("normal", _style(NAVY, color, 3))
	button.add_theme_stylebox_override("hover", _style(Color(0.1, 0.2, 0.34, 0.94), Color.WHITE, 4))
	button.add_theme_stylebox_override("pressed", _style(Color(0.08, 0.24, 0.35, 0.98), CYAN, 4))
	button.add_theme_stylebox_override("focus", _style(Color(0, 0, 0, 0), color, 2))
	button.button_down.connect(_on_down.bind(action))
	button.button_up.connect(_on_up.bind(action))
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(button)
	_buttons[action] = button

func _style(fill: Color, border: Color, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(18)
	return style

func _layout_controls() -> void:
	var view := get_viewport().get_visible_rect().size
	var center := Vector2(148.0, view.y - 144.0)
	_buttons["left"].position = center + Vector2(-89, -41)
	_buttons["right"].position = center + Vector2(89, -41)
	_buttons["arc_up"].position = center + Vector2(0, -128)
	_buttons["arc_down"].position = center + Vector2(0, 46)
	_buttons["power"].position = Vector2(view.x - 242.0, view.y - 199.0)

func _on_viewport_changed() -> void:
	_layout_controls()
	_apply_visibility()

func _on_down(action: String) -> void:
	_touch_seen = true
	Input.action_press(action)
	_apply_visibility()

func _on_up(action: String) -> void:
	Input.action_release(action)

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch and event.pressed and not _touch_seen:
		_touch_seen = true
		_apply_visibility()

func _apply_visibility() -> void:
	var view_size: Vector2 = get_viewport().get_visible_rect().size
	var portrait: bool = view_size.y / maxf(view_size.x, 1.0) > 1.2
	_portrait_hint.visible = portrait
	var should_show: bool = not portrait and Global.touch_controls_enabled and (DisplayServer.is_touchscreen_available() or _touch_seen)
	for button in _buttons.values():
		button.visible = should_show

func _release_all() -> void:
	for action in ACTIONS:
		Input.action_release(action)
