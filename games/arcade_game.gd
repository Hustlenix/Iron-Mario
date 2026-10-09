class_name ArcadeGame
extends MicrogameBase
## Cabinet sessions retain earned score on failure; simulation uses bounded substeps.
var score: int = 0
var health: int = 3
var goal: int = 10
var axis := Vector2.ZERO
var held: bool = false
var accumulator: float = 0.0
var frame_ms: Array[float] = []

func setup() -> void:
	score = 0
	health = 3
	axis = Vector2.ZERO
	held = false
	accumulator = 0.0
	frame_ms.clear()
	configure()

func configure() -> void: pass
func simulate(_dt: float) -> void: pass
func cancel_input() -> void:
	axis=Vector2.ZERO
	held=false
	handle_action('cancel',Vector2.ZERO,Vector2.ZERO)

func tick(delta: float) -> void:
	var before := Time.get_ticks_usec()
	accumulator += minf(delta, 0.1)
	while accumulator >= 1.0 / 120.0 and not finished:
		simulate(1.0 / 120.0)
		accumulator -= 1.0 / 120.0
	if frame_ms.size() < 600: frame_ms.append((Time.get_ticks_usec()-before)/1000.0)
	if not finished: points = score

func lose() -> void:
	if finished: return
	finished = true
	points = score
	completed.emit(false, score)

func damage(point: Vector2) -> void:
	health -= 1
	feedback(point, false)
	if health <= 0: lose()

func earn(amount: int, point: Vector2) -> void:
	score += amount
	feedback(point)

func button_area(index: int, count: int = 4) -> Rect2:
	return Rect2(20 + index * (920.0 / count), 380, 900.0 / count, 90)

func buttons(labels: Array) -> void:
	for index in labels.size():
		var rect := button_area(index, labels.size())
		box(rect, GOLD if index == labels.size()-1 else Color('#c1e2e5'))
		text_at(rect.position+Vector2(12,54), str(labels[index]), 23)

func pressed_button(point: Vector2, count: int = 4) -> int:
	for index in count:
		if button_area(index,count).has_point(point): return index
	return -1

func hud(label: String) -> void:
	text_at(Vector2(22,30),label,18 if label.length()>55 else 22)
	text_at(Vector2(715,30),'%d PTS  /  %d HP' % [score,health],20)

static func segment_distance(point: Vector2, a: Vector2, b: Vector2) -> float:
	var line := b-a
	var ratio := clampf((point-a).dot(line)/maxf(1.0,line.length_squared()),0,1)
	return point.distance_to(a+line*ratio)
