class_name MicrogameBase
extends Node2D

signal completed(won: bool, score: int)
signal impact(point: Vector2, good: bool)
const INK := Color('#242333')
const PAPER := Color('#fff4d7')
const RED := Color('#ef6351')
const BLUE := Color('#4a8de0')
const GREEN := Color('#60b990')
const GOLD := Color('#ffc857')
const PresentationBridge = preload('res://ui/game_presentation.gd')
var spec: Dictionary = {}
var difficulty: float = 1.0
var elapsed: float = 0.0
var duration: float = 8.0
var finished: bool = false
var points: int = 0
var rng := RandomNumberGenerator.new()
var active: bool = false
var hero_id: String = 'dart'
var cosmetic: String = 'classic'
var particles: Array[Dictionary] = []
var font: Font = ThemeDB.fallback_font
var presentation: RefCounted = null
# Passed by the UI owner; this base remains usable without Profile autoloads.
var reduced_motion: bool = false

func start(metadata: Dictionary, level: float = 1.0, seed_value: int = 0) -> void:
	spec = metadata
	presentation = PresentationBridge.load_for_id(String(spec.get('id', '')))
	difficulty = clampf(level, 1.0, 6.0)
	duration = maxf(4.0, float(spec.get('duration', 8.0)) - (difficulty - 1.0) * 0.25)
	elapsed = 0.0
	finished = false
	points = 0
	particles.clear()
	if seed_value == 0:
		rng.randomize()
	else:
		rng.seed = seed_value
	setup()
	active = true
	queue_redraw()

func setup() -> void:
	pass
func tick(_delta: float) -> void:
	pass
func handle_action(_action: String, _point: Vector2, _value: Vector2) -> void:
	pass
func paint() -> void:
	pass
func timeout() -> void:
	lose()
func cancel_input() -> void:
	# Cancellation is separate from release: releasing a charged spring during
	# a focus pause must never fire the spring or complete a puzzle.
	handle_action('cancel',Vector2.ZERO,Vector2.ZERO)

func advance(delta: float) -> void:
	if not active or finished:
		return
	elapsed += delta
	tick(delta)
	if elapsed >= duration and not finished:
		timeout()
	queue_redraw()

func _process(delta: float) -> void:
	advance(delta)
	for p in particles:
		p.life -= delta
		p.pos += p.velocity * delta
		p.velocity.y += 380.0 * delta
	if not particles.is_empty(): particles = particles.filter(func(p: Dictionary) -> bool: return p.life > 0.0)
	if not particles.is_empty():
		queue_redraw()

func win(score: int = 100) -> void:
	if finished: return
	finished = true
	points = score
	completed.emit(true, score)
func lose() -> void:
	if finished: return
	finished = true
	completed.emit(false, 0)
func feedback(point: Vector2, good: bool = true) -> void:
	impact.emit(point, good)
	for i in (18 if cosmetic=='confetti' else 9):
		particles.append({'pos': point, 'velocity': Vector2(rng.randf_range(-150,150),rng.randf_range(-220,-65)), 'life': 0.5, 'good': good})

func _draw() -> void:
	if presentation != null:
		presentation.call('draw_background', self, PresentationBridge.context_for(spec, elapsed, cosmetic, reduced_motion))
		# A worker background cannot leave an accidental transform on gameplay.
		draw_set_transform(Vector2.ZERO)
		if cosmetic=='midnight': draw_rect(PresentationBridge.BOARD_RECT,Color(0.24,0.46,0.79,0.18))
		elif cosmetic=='sunshine': draw_rect(PresentationBridge.BOARD_RECT,Color(1.0,0.78,0.23,0.16))
	else:
		draw_rect(Rect2(0,0,960,480), Color('#cedcf2') if cosmetic=='midnight' else (Color('#ffe5a1') if cosmetic=='sunshine' else PAPER))
		# Retain the previous background exactly until a game owns a presentation.
		for i in 16:
			var x: float = i * 65.0
			var y: float = 330.0 + sin(i * 4.2) * 34.0
			draw_polyline(PackedVector2Array([Vector2(x,480),Vector2(x+2,y),Vector2(x+55,y+3),Vector2(x+60,480)]),Color('#ebdfc4'),3)
	paint()
	for p in particles:
		draw_rect(Rect2(p.pos,Vector2(7,7)),GOLD if p.good else RED)

func text_at(pos: Vector2, value: String, size: int = 28, color: Color = INK) -> void:
	draw_string(font,pos,value,HORIZONTAL_ALIGNMENT_LEFT,-1,size,color)
func box(rect: Rect2, color: Color) -> void:
	var p := PackedVector2Array([rect.position+Vector2(2,0),rect.position+Vector2(rect.size.x,2),rect.end+Vector2(-2,0),rect.position+Vector2(0,rect.size.y-2)])
	draw_colored_polygon(p,color)
	p.append(p[0])
	draw_polyline(p,INK,4.0)
func disc(center: Vector2, radius: float, color: Color) -> void:
	var p := PackedVector2Array()
	for i in 16:
		var a: float = i * TAU / 16.0
		p.append(center+Vector2(cos(a),sin(a))*radius*(1.0+0.025*sin(i*7.0)))
	draw_colored_polygon(p,color)
	p.append(p[0])
	draw_polyline(p,INK,3)
func hero(pos: Vector2, amount: float = 1.0) -> void:
	# Preserve the previous drawing origin and foot position; collisions remain owned by each game.
	texture_filter=CanvasItem.TEXTURE_FILTER_NEAREST
	CharacterVisual.draw(self,hero_id,pos+Vector2(0,53)*amount,3.0*amount,elapsed,active and not finished,3,reduced_motion)
