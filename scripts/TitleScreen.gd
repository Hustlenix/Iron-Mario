extends Node2D
const Paint = preload("res://scripts/ui/Paint.gd")
const Card = preload("res://scripts/ui/GameCard.gd")
const HINTS := ["Move + jump. Grab 3 shards.", "Tap the flying targets.", "Jump over the lasers.", "Tap when the marker is green.", "Match the chips and sockets.", "Steer left / right. Catch pods.", "Watch, then tap the arrows."]
var controls_panel: Control

func _ready() -> void:
	var hero := preload("res://scripts/ui/IronHero.gd").new()
	hero.position = Vector2(1190,70)
	hero.scale = Vector2(1.6,1.6)
	hero.pose = "victory"
	add_child(hero)
	for index in range(9):
		var card := Card.new()
		card.name = "Game%d" % index
		card.position = Vector2(35+(index%3)*415,170+(index/3)*152)
		card.size = Vector2(380,136)
		card.paint_color = Paint.PAPER
		if index < 7:
			card.text = GameManager.MINIGAMES[index]["name"]
			card.subtitle = HINTS[index]
			card.badge = str(index+1)
			card.pressed.connect(GameManager.start_single.bind(index))
		elif index == 7:
			card.text = "TOURNAMENT"
			card.subtitle = "All 7 games. 5 lives. One run."
			card.badge = "T"
			card.paint_color = Paint.GOLD
			card.pressed.connect(GameManager.start_run.bind(false))
		else:
			card.text = "BONUS: FLAPPY"
			card.subtitle = "Tap to fly through the gaps."
			card.badge = "+"
			card.paint_color = Paint.CYAN
			card.pressed.connect(GameManager.open_menu.bind("res://scenes/flappy_bird.tscn"))
		add_child(card)
		if index == 0:
			card.focus_when_ready.call_deferred()
	_button("HERO / " + Global.pilot_name,Vector2(35,643),Vector2(380,65),func(): GameManager.open_menu("res://scenes/profile_scene.tscn"))
	_button("CONTROLS",Vector2(450,643),Vector2(185,65),_show_controls)
	_button("SETTINGS",Vector2(650,643),Vector2(180,65),func(): GameManager.open_menu("res://scenes/settings_scene.tscn"))
	var sound := preload("res://scripts/ui/PixelButton.gd").make("SOUND OFF" if Global.muted else "SOUND ON",Vector2(865,643),Vector2(220,65),Paint.CYAN)
	add_child(sound)
	sound.pressed.connect(func():
		Global.toggle_mute()
		sound.text = "SOUND OFF" if Global.muted else "SOUND ON"
	)
	if not OS.has_feature("web"):
		_button("QUIT",Vector2(1100,643),Vector2(145,65),func(): get_tree().quit())
	Music.play_theme(Global.hero_id)

func _button(label: String, at: Vector2, dimensions: Vector2, callback: Callable) -> Button:
	var button := preload("res://scripts/ui/PixelButton.gd").make(label,at,dimensions,Paint.CYAN)
	add_child(button)
	button.pressed.connect(callback)
	return button

func _draw() -> void:
	Paint.background(self,"title")
	Paint.rect(self,Rect2(25,22,1230,118),Paint.PAPER)
	Paint.rect(self,Rect2(25,22,1230,118),Paint.INK,false,3)
	Paint.text(self,"SUPER-MICRO HEROES",Vector2(48,72),42,Paint.INK,1000)
	Paint.text(self,"PICK A GAME  /  OR TRY THE TOURNAMENT",Vector2(48,113),23,Paint.INK,1050)

func _show_controls() -> void:
	if is_instance_valid(controls_panel):
		return
	controls_panel = Control.new()
	controls_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	controls_panel.size = Vector2(1280,720)
	add_child(controls_panel)
	controls_panel.draw.connect(func():
		Paint.rect(controls_panel,Rect2(0,0,1280,720),Color(0,0,0,0.65))
		Paint.rect(controls_panel,Rect2(225,110,830,495),Paint.PAPER)
	)
	var label := preload("res://scripts/ui/PaintLabel.gd").new()
	label.position = Vector2(265,140)
	label.size = Vector2(750,345)
	label.text = "TWO-THUMB CONTROLS\n\nLEFT THUMB: SLIDE THE PAD TO MOVE\nRIGHT THUMB: TAP JUMP\nPARRY: TAP THE BIG BUTTON\nTARGETS / MEMORY: TAP WHAT YOU SEE\nREPAIR: TAP A CHIP, THEN ITS SOCKET\nFLAPPY: TAP ANYWHERE TO FLY\n\nKEYBOARD: A/D, W/SPACE, R TO RETRY"
	controls_panel.add_child(label)
	var close := preload("res://scripts/ui/PixelButton.gd").make("GOT IT",Vector2(460,510),Vector2(360,75),Paint.GOLD)
	controls_panel.add_child(close)
	close.pressed.connect(func(): controls_panel.queue_free())
	close.grab_focus()
