class_name HeroDesign
extends RefCounted
const NIGHT := Color('#101c28')
const PANEL := Color('#1b2c3a')
const INK := Color('#263d4c')
const PAPER := Color('#faf3df')
const MUTED := Color('#a0b6bd')
const GOLD := Color('#f2c15d')
const LINE := Color('#36505d')
static func style(color: Color, border: Color=LINE, padding: int=16) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color=color; s.border_color=border; s.set_border_width_all(1); s.set_corner_radius_all(10)
	s.content_margin_left=padding; s.content_margin_right=padding; s.content_margin_top=padding; s.content_margin_bottom=padding
	return s
static func label(text: String, font_size: int=16, color: Color=PAPER) -> Label:
	var node := Label.new()
	node.text=text; node.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	node.add_theme_font_size_override('font_size',font_size); node.add_theme_color_override('font_color',color)
	node.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	return node
static func button(text: String, callback: Callable, color: Color=PANEL) -> Button:
	var b := Button.new()
	b.text=text; b.custom_minimum_size.y=48; b.mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
	b.add_theme_font_size_override('font_size',15)
	var text_color: Color=NIGHT if color==GOLD else PAPER
	for key in ['font_color','font_hover_color','font_pressed_color','font_focus_color']: b.add_theme_color_override(key,text_color)
	b.add_theme_color_override('font_disabled_color',MUTED)
	b.add_theme_stylebox_override('normal',style(color,LINE,10))
	b.add_theme_stylebox_override('hover',style(color.lightened(0.12),GOLD,10))
	b.add_theme_stylebox_override('pressed',style(color.darkened(0.12),GOLD,10))
	b.add_theme_stylebox_override('disabled',style(PANEL,LINE,10))
	var focus := style(Color(0,0,0,0),GOLD,0); focus.set_border_width_all(2)
	b.add_theme_stylebox_override('focus',focus)
	b.button_down.connect(func()->void:
		if Profile.data.settings.get('reduced_motion',false): return
		b.pivot_offset=b.size*0.5
		b.create_tween().tween_property(b,'scale',Vector2(0.98,0.96),0.08))
	b.button_up.connect(func()->void:b.create_tween().tween_property(b,'scale',Vector2.ONE,0.10))
	b.pressed.connect(callback)
	return b
static func column(gap: int=12) -> VBoxContainer:
	var c := VBoxContainer.new(); c.add_theme_constant_override('separation',gap); return c
static func row(gap: int=12) -> HBoxContainer:
	var c := HBoxContainer.new(); c.add_theme_constant_override('separation',gap); return c
