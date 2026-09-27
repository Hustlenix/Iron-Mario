extends Control

## The on-screen cooldown ring required by the power system. Every minigame
## instances one of these as a HUD child; it follows PowerBus directly, so a
## hero always shows the real shared cooldown with no per-scene wiring.

const RADIUS := 30.0
const RING_WIDTH := 6.0
const TRACK_COLOR := Color(1, 1, 1, 0.18)
var _glyph: String = ""

func _ready() -> void:
	# Keep the ring honest without each minigame having to forward signals.
	PowerBus.cooldown_changed.connect(_on_cooldown_changed)
	PowerBus.power_used.connect(_on_power_used)
	_refresh()

func _process(_delta: float) -> void:
	_refresh()

func _refresh() -> void:
	var powered := PowerBus.has_power()
	if powered != visible:
		visible = powered
	if powered:
		var family := PowerBus.family()
		var glyph := _family_glyph(family)
		if glyph != _glyph:
			_glyph = glyph
			queue_redraw()
		queue_redraw()

func _on_cooldown_changed(_remaining: float, _ratio: float) -> void:
	queue_redraw()

func _on_power_used(_hero_id: String, _family: int) -> void:
	_glyph = _family_glyph(PowerBus.family())
	queue_redraw()

func _draw() -> void:
	if not visible:
		return
	var center := size * 0.5
	var radius := minf(RADIUS, minf(size.x, size.y) * 0.5 - RING_WIDTH)

	draw_arc(center, radius, 0.0, TAU, 48, TRACK_COLOR, RING_WIDTH, true)

	if PowerBus.has_power():
		# 1.0 = ready, so a ready ring reads as a complete circle.
		var progress := PowerBus.cooldown_ratio()
		if progress >= 1.0:
			draw_arc(center, radius, 0.0, TAU, 48, _accent(), RING_WIDTH, true)
		elif progress > 0.0:
			draw_arc(center, radius, -PI * 0.5, -PI * 0.5 + TAU * progress, 48, _accent(), RING_WIDTH, true)

	var font := ThemeDB.fallback_font
	var glyph_size := font.get_string_size(_glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, 18)
	draw_string(font, center - glyph_size * 0.5, Color(1, 0.92, 0.6, 0.95), _glyph, HORIZONTAL_ALIGNMENT_LEFT, -1, 18)

func _accent() -> Color:
	match PowerBus.family():
		HeroData.Family.DASH:
			return Color(0.45, 0.85, 1.0)
		HeroData.Family.REVEAL:
			return Color(0.75, 0.6, 1.0)
		HeroData.Family.REACH:
			return Color(1.0, 0.75, 0.35)
		HeroData.Family.BLAST:
			return Color(1.0, 0.5, 0.35)
		_:
			return Color(1, 0.85, 0.25)

func _family_glyph(family: int) -> String:
	match family:
		HeroData.Family.DASH:
			return "\u25B6"
		HeroData.Family.REVEAL:
			return "\u25C9"
		HeroData.Family.REACH:
			return "\u27C4"
		HeroData.Family.BLAST:
			return "\u2604"
		_:
			return ""
