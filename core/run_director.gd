class_name RunDirector
extends RefCounted
## Scene-independent run state. next_id is safe to query repeatedly until a result arrives.

var mode: String = "quick"
var lives: int = 5
var round_index: int = 0
var score: int = 0
var streak: int = 0
var best_streak: int = 0
var finished: bool = false
var difficulty: float = 1.0
var modifier: String = "standard"
var special_round: bool = false
var current_id: String = ""
var date_key: String = ""
var _ids: Array = []
var _queue: Array = []
var _last_id: String = ""
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

func begin(new_mode: String, ids: Array, new_date_key: String = "") -> void:
	mode = new_mode.to_lower()
	lives = 5
	round_index = 0
	score = 0
	streak = 0
	best_streak = 0
	finished = false
	difficulty = 1.0
	modifier = "standard"
	special_round = false
	current_id = ""
	_last_id = ""
	_ids = []
	_queue = []
	date_key = new_date_key if not new_date_key.is_empty() else Time.get_date_string_from_system(true)
	for item: Variant in ids:
		if item is String and not item.is_empty() and item not in _ids:
			_ids.append(item)
	_rng.randomize()
	if mode == "daily":
		_queue = daily_ids(_ids, date_key)
		modifier = daily_modifier(date_key)
	finished = _ids.is_empty()

static func daily_ids(ids: Array, date: String) -> Array:
	var pool: Array = []
	for item: Variant in ids:
		if item is String and not item.is_empty() and item not in pool:
			pool.append(item)
	pool.sort()
	var result: Array = []
	if pool.is_empty():
		return result
	var random: RandomNumberGenerator = RandomNumberGenerator.new()
	random.seed = _date_seed(date)
	var bag: Array = []
	while result.size() < 10:
		if bag.is_empty():
			bag = pool.duplicate()
			_shuffle(bag, random)
			if not result.is_empty() and bag.size() > 1 and bag.back() == result.back():
				var saved: Variant = bag[0]
				bag[0] = bag[-1]
				bag[-1] = saved
		result.append(bag.pop_back())
	return result

static func _date_seed(date: String) -> int:
	# Stable integer seed, independent of global RNG, input ordering, and hash implementation.
	var seed_value: int = 2166136261
	for byte: int in date.to_utf8_buffer():
		seed_value = ((seed_value ^ byte) * 16777619) & 0xffffffff
	return seed_value

static func daily_modifier(date: String) -> String:
	var modifiers: Array[String] = ["standard", "fast_forward", "precision"]
	return modifiers[_date_seed(date) % modifiers.size()]

static func _shuffle(items: Array, random: RandomNumberGenerator) -> void:
	for index: int in range(items.size() - 1, 0, -1):
		var other: int = random.randi_range(0, index)
		var saved: Variant = items[index]
		items[index] = items[other]
		items[other] = saved

func next_id() -> String:
	if finished:
		return ""
	if not current_id.is_empty():
		return current_id
	if _queue.is_empty():
		if mode == "daily":
			finished = true
			return ""
		_queue = _ids.duplicate()
		_shuffle(_queue, _rng)
		if _queue.size() > 1 and _queue.back() == _last_id:
			var saved: Variant = _queue[0]
			_queue[0] = _queue[-1]
			_queue[-1] = saved
	current_id = str(_queue.pop_front()) if mode == "daily" else str(_queue.pop_back())
	special_round = mode == "tournament" and (round_index + 1) % 10 == 0
	difficulty = minf(6.0, 1.0 + floorf(float(round_index) / 5.0) * 0.4) if mode == "tournament" else 1.0
	if mode == "daily" and modifier == "fast_forward":
		difficulty = 1.2
	if mode == "daily" and modifier == "precision": difficulty = 1.5
	if special_round:
		difficulty = minf(6.0,difficulty+0.5)
	return current_id

func submit(won: bool, points: int) -> void:
	if finished or current_id.is_empty():
		return
	score += maxi(0, points) * (mini(4,1+streak/5) if mode == "tournament" else 1)
	if won:
		streak += 1
		best_streak = maxi(best_streak, streak)
	else:
		streak = 0
		lives = maxi(0, lives - 1)
	round_index += 1
	_last_id = current_id
	current_id = ""
	finished = lives <= 0 or (mode == "daily" and round_index >= 10) or mode in ["practice", "quick", "single"]
