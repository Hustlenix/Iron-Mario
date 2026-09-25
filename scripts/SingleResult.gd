extends Node2D
const Paint = preload("res://scripts/ui/Paint.gd")
func _ready() -> void:
	var hero := preload("res://scripts/ui/IronHero.gd").new()
	hero.position = Vector2(240,365)
	hero.scale = Vector2(4,4)
	hero.pose = "victory" if GameManager.single_won else "idle"
	add_child(hero)
	for index in range(2):
		var button := preload("res://scripts/ui/PixelButton.gd").make("PLAY AGAIN" if index == 0 else "HOME",Vector2(460+index*385,495),Vector2(355,100),Paint.GOLD if index == 0 else Paint.CYAN)
		add_child(button)
		button.pressed.connect(GameManager.replay_single if index == 0 else GameManager.return_to_title)
		if index == 0:
			button.focus_when_ready.call_deferred()
func _draw() -> void:
	Paint.background(self,"title")
	Paint.rect(self,Rect2(435,180,800,270),Paint.PAPER)
	Paint.rect(self,Rect2(435,180,800,270),Paint.INK,false,4)
	Paint.text(self,"GAME CLEAR!" if GameManager.single_won else "TRY AGAIN!",Vector2(465,255),48)
	Paint.text(self,GameManager.get_upcoming_game()["name"],Vector2(465,320),27,Paint.INK,730)
	Paint.text(self,"SCORE %d  /  SINGLE GAME" % Global.score,Vector2(465,390),23)
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("restart"):
		GameManager.replay_single()
	elif event.is_action_pressed("ui_cancel"):
		GameManager.return_to_title()
