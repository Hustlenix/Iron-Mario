class_name Design
extends RefCounted

# Callers use PAPER as their page surface and INK as text. Gameplay has its own palette.
const INK := Color('#302b44')
const PAPER := Color('#fff2d4')
const PANEL := Color('#f4e7bf')
const LINE := Color('#665772')
const MUTED := Color('#71636a')
const RED := Color('#d8675b')
const BLUE := Color('#4c79b9')
const GREEN := Color('#42886f')
const GOLD := Color('#b66c24')

static func _style(color: Color, border: Color = LINE, padding: int = 12) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = border
	style.set_border_width_all(1)
	style.set_border_width_all(2)
	style.set_corner_radius_all(0)
	style.content_margin_left = padding
	style.content_margin_right = padding
	style.content_margin_top = padding
	style.content_margin_bottom = padding
	return style

static func _linear_channel(value: float) -> float:
	return value / 12.92 if value <= 0.04045 else pow((value + 0.055) / 1.055, 2.4)

static func _luminance(color: Color) -> float:
	return 0.2126 * _linear_channel(color.r) + 0.7152 * _linear_channel(color.g) + 0.0722 * _linear_channel(color.b)

static func contrast_ratio(first: Color, second: Color) -> float:
	var a: float = _luminance(first)
	var b: float = _luminance(second)
	return (maxf(a, b) + 0.05) / (minf(a, b) + 0.05)

static func text_on(background: Color) -> Color:
	return INK if contrast_ratio(INK, background) >= contrast_ratio(PAPER, background) else PAPER

static func theme() -> Theme:
	var result := Theme.new()
	result.default_font_size = 16
	for kind in ['Label', 'Button', 'LineEdit', 'OptionButton', 'CheckButton', 'CheckBox', 'PopupMenu']:
		for state in ['font_color', 'font_hover_color', 'font_pressed_color', 'font_hover_pressed_color', 'font_focus_color']:
			result.set_color(state, kind, INK)
		result.set_color('font_disabled_color', kind, MUTED)
	for kind in ['Button', 'OptionButton', 'CheckButton', 'CheckBox']:
		result.set_stylebox('normal', kind, _style(PANEL))
		result.set_stylebox('hover', kind, _style(Color('#263d4c'), GOLD))
		result.set_stylebox('pressed', kind, _style(PAPER, GOLD))
		result.set_stylebox('hover_pressed', kind, _style(PANEL, GOLD))
		result.set_stylebox('disabled', kind, _style(PANEL))
		var focus := _style(Color.TRANSPARENT, GOLD, 0)
		focus.set_border_width_all(2)
		result.set_stylebox('focus', kind, focus)
		result.set_constant('h_separation', kind, 10)
	result.set_stylebox('normal', 'LineEdit', _style(PANEL))
	result.set_stylebox('read_only', 'LineEdit', _style(PAPER))
	var edit_focus := _style(Color.TRANSPARENT, GOLD, 0)
	edit_focus.set_border_width_all(2)
	result.set_stylebox('focus', 'LineEdit', edit_focus)
	result.set_color('font_placeholder_color', 'LineEdit', MUTED)
	result.set_color('font_uneditable_color', 'LineEdit', MUTED)
	result.set_color('caret_color', 'LineEdit', INK)
	result.set_color('selection_color', 'LineEdit', BLUE)
	result.set_color('font_selected_color', 'LineEdit', PAPER)
	result.set_stylebox('panel', 'PopupMenu', _style(PANEL))
	result.set_stylebox('hover', 'PopupMenu', _style(Color('#263d4c'), GOLD, 8))
	result.set_color('font_accelerator_color', 'PopupMenu', MUTED)
	result.set_constant('v_separation', 'PopupMenu', 12)
	result.set_stylebox('background', 'ProgressBar', _style(PAPER, LINE, 0))
	result.set_stylebox('fill', 'ProgressBar', _style(GREEN, GREEN, 0))
	# Percent text spans filled and empty regions; an opaque outline keeps it legible.
	result.set_color('font_color', 'ProgressBar', INK)
	result.set_color('font_outline_color', 'ProgressBar', PAPER)
	result.set_constant('outline_size', 'ProgressBar', 4)
	result.set_stylebox('slider', 'HSlider', _style(PAPER, LINE, 0))
	result.set_stylebox('grabber_area', 'HSlider', _style(BLUE, BLUE, 0))
	result.set_stylebox('grabber_area_highlight', 'HSlider', _style(GOLD, GOLD, 0))
	return result

static func _label_surface(node: Label) -> Color:
	var parent: Node = node.get_parent()
	while parent != null:
		if parent.has_meta('design_surface'):
			return parent.get_meta('design_surface')
		parent = parent.get_parent()
	return PAPER

static func label(value: String, size: int = 16, color: Color = INK) -> Label:
	var node := Label.new()
	node.text = value
	node.add_theme_color_override('font_color', color)
	node.add_theme_font_size_override('font_size', size)
	# Explicit cream legacy cards remain supported, including their accent labels.
	node.tree_entered.connect(func() -> void:
		var surface: Color = _label_surface(node)
		var readable: Color = color if contrast_ratio(color, surface) >= 4.5 else text_on(surface)
		node.add_theme_color_override('font_color', readable))
	return node

static func button(value: String, callback: Callable, color: Color = PANEL) -> PaintButton:
	var node := PaintButton.new()
	node.text = value
	node.fill = color
	node.ink = text_on(color)
	node.set_meta('design_text_color', node.ink)
	node.custom_minimum_size.y = 48
	node.add_theme_font_size_override('font_size', 16)
	for state in ['font_color', 'font_hover_color', 'font_pressed_color', 'font_focus_color', 'font_disabled_color']:
		node.add_theme_color_override(state, node.ink)
	node.pressed.connect(callback)
	return node

static func panel(color: Color = PANEL) -> PanelContainer:
	var node := PanelContainer.new()
	var style := _style(color, LINE, 20)
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	style.shadow_color = Color(0, 0, 0, 0.16)
	style.shadow_size = 4
	style.shadow_offset = Vector2(0, 2)
	node.add_theme_stylebox_override('panel', style)
	node.set_meta('design_surface', color)
	return node

static func column(separation: int = 12) -> VBoxContainer:
	var node := VBoxContainer.new()
	node.add_theme_constant_override('separation', separation)
	return node

static func row(separation: int = 12) -> HBoxContainer:
	var node := HBoxContainer.new()
	node.add_theme_constant_override('separation', separation)
	return node
