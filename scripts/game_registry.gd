extends RefCounted

const GameDefinition = preload("res://scripts/game_definition.gd")

var games: Array[GameDefinition] = []

func all() -> Array[GameDefinition]:
	return games.duplicate()

func get_game(id: String) -> GameDefinition:
	for g in games:
		if g.id == id:
			return g
	return null

func get_by_category(cat: String) -> Array[GameDefinition]:
	var out: Array[GameDefinition] = []
	for g in games:
		if g.category == cat:
			out.append(g)
	return out

func random(cat: String = "") -> GameDefinition:
	var pool: Array[GameDefinition] = games if cat == "" else get_by_category(cat)
	if pool.is_empty():
		return null
	return pool[randi() % pool.size()]

func add(def: GameDefinition) -> void:
	games.append(def)
