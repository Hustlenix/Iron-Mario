extends Node2D

const Paint = preload("res://scripts/ui/Paint.gd")
var game: Node2D
var hero: Node2D

func _ready() -> void:
	game = get_parent()
	hero = preload("res://scripts/ui/IronHero.gd").new()
	add_child(hero)

func _process(_delta: float) -> void:
	hero.position = Vector2(game.BIRD_X + 35, game.bird_y + 35)
	hero.rotation = game.bird.rotation
	hero.scale = game.bird.scale * Vector2(1.5, 1.0)
	hero.pose = "damaged" if game.state in ["dying", "game_over"] else "jump"
	hero.modulate.a = game.bird.modulate.a
	queue_redraw()

func _draw() -> void:
	if not is_instance_valid(game):
		return
	Paint.background(self, "city")
	for pair in game.pipes_node.get_children():
		if not pair.visible:
			continue
		var meta: Dictionary = game._pipe_meta[pair]
		var top: float = meta.gap_y - meta.gap * 0.5
		var bottom: float = meta.gap_y + meta.gap * 0.5
		var x: float = pair.position.x
		for body in [Rect2(x, 0, game.PIPE_WIDTH, top), Rect2(x, bottom, game.PIPE_WIDTH, 620 - bottom)]:
			Paint.rect(self, body, Paint.CYAN)
			Paint.rect(self, body, Paint.INK, false, 4)
		for y in [top - 16, bottom]:
			Paint.rect(self, Rect2(x - 5, y, game.PIPE_WIDTH + 10, 16), Paint.GOLD)
			Paint.rect(self, Rect2(x - 5, y, game.PIPE_WIDTH + 10, 16), Paint.INK, false, 3)
	for pickup in game.pickups_node.get_children():
		Paint.circle(self, pickup.position + Vector2(20,20), 20, Paint.INK)
		Paint.circle(self, pickup.position + Vector2(20,20), 14, Paint.CYAN)
	for ghost in game.trail_node.get_children():
		if ghost.modulate.a > 0.05:
			Paint.rect(self, Rect2(ghost.position + Vector2(60,60), Vector2(8,12)), Paint.GOLD)
	Paint.rect(self, Rect2(0,620,1280,100), Paint.GOLD)
	Paint.line(self, Vector2(0,620), Vector2(1280,624), Paint.INK, 5)
	Paint.rect(self, Rect2(18,18,385,92), Paint.PAPER)
	Paint.text(self, "FLAPPY  SCORE %d" % game.score, Vector2(35,54), 26)
	Paint.text(self, "BEST %d  SHIELD %d" % [game.best, game.feathers], Vector2(35,88), 20)
	Paint.text(self, game.medal_label.text, Vector2(1010,55), 24)
	Paint.text(self, "SPACE / W / CLICK TO FLY    ESC TO TITLE", Vector2(265,681), 25)
	if game.state in ["title", "game_over"]:
		Paint.rect(self, Rect2(360,270,730,165), Paint.PAPER)
		Paint.rect(self, Rect2(360,270,730,165), Paint.INK, false, 4)
		Paint.text(self, "FLY THROUGH THE GAPS!" if game.state == "title" else "SUIT NEEDS A BREAK!", Vector2(400,325), 33)
		Paint.text(self, "SPACE / W / CLICK TO " + ("START" if game.state == "title" else "RETRY"), Vector2(400,389), 26)
