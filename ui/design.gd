class_name Design
extends RefCounted
const INK := Color('#242333')
const PAPER := Color('#fff4d7')
const RED := Color('#ef6351')
const BLUE := Color('#4a8de0')
const GREEN := Color('#60b990')
const GOLD := Color('#ffc857')
static func theme() -> Theme:
	var result := Theme.new()
	result.default_font_size = 22
	for kind in ['Label','LineEdit','OptionButton','CheckButton']:
		result.set_color('font_color',kind,INK)
		result.set_color('font_hover_color',kind,INK)
		result.set_color('font_pressed_color',kind,INK)
	var paper := StyleBoxFlat.new()
	paper.bg_color = PAPER
	paper.border_color = INK
	paper.set_border_width_all(3)
	paper.content_margin_left = 12
	paper.content_margin_right = 18
	for kind in ['LineEdit','OptionButton']:
		for state in ['normal','hover','pressed','focus']:
			result.set_stylebox(state,kind,paper)
	result.set_color('font_placeholder_color','LineEdit',Color('#696274'))
	var track := StyleBoxFlat.new()
	track.bg_color = Color('#dbcfae')
	var fill := StyleBoxFlat.new()
	fill.bg_color = GREEN
	result.set_stylebox('background','ProgressBar',track)
	result.set_stylebox('fill','ProgressBar',fill)
	return result
static func label(value: String, size: int = 24, color: Color = INK) -> Label:
	var node := Label.new()
	node.text = value
	node.add_theme_color_override('font_color',color)
	node.add_theme_font_size_override('font_size',size)
	return node
static func button(value: String, callback: Callable, color: Color = PAPER) -> PaintButton:
	var node := PaintButton.new()
	node.text = value
	node.fill = color
	node.pressed.connect(callback)
	return node
static func panel(color: Color = PAPER) -> PanelContainer:
	var node := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = INK
	style.set_border_width_all(3)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 14
	style.content_margin_bottom = 14
	style.shadow_color = INK
	style.shadow_size = 3
	style.shadow_offset = Vector2(3,3)
	node.add_theme_stylebox_override('panel',style)
	return node
static func column(separation: int = 12) -> VBoxContainer:
	var node := VBoxContainer.new()
	node.add_theme_constant_override('separation',separation)
	return node
static func row(separation: int = 12) -> HBoxContainer:
	var node := HBoxContainer.new()
	node.add_theme_constant_override('separation',separation)
	return node
