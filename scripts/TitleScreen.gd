extends Node2D
const Paint = preload("res://scripts/ui/Paint.gd")
func _ready() -> void:
	var hero=preload("res://scripts/ui/IronHero.gd").new()
	hero.hero_id="ember"
	hero.position=Vector2(245,365)
	hero.scale=Vector2(4.6,4.6)
	hero.pose="idle"
	add_child(hero)
	var play=button("CONTINUE ADVENTURE" if Global.adventure_stage>0 and not Global.adventure_complete else ("REPLAY ADVENTURE" if Global.adventure_complete else "START ADVENTURE"),Vector2(460,315),Vector2(730,100),Paint.GOLD,start_adventure)
	play.name="Adventure"
	play.focus_when_ready.call_deferred()
	var arcade=button("ARCADE / 20 CABINETS",Vector2(460,440),Vector2(355,80),Paint.CYAN,func():GameManager.open_menu("res://scenes/arcade_library.tscn"))
	arcade.name="Arcade"
	var quick=button("QUICK GAMES + TOURNAMENT",Vector2(835,440),Vector2(355,80),Paint.PAPER,func():GameManager.open_menu("res://scenes/quick_games.tscn"))
	quick.name="QuickGames"
	button("SETTINGS",Vector2(460,550),Vector2(225,65),Paint.PAPER,func():GameManager.open_menu("res://scenes/settings_scene.tscn"))
	button("ARCADE PROFILE",Vector2(705,550),Vector2(255,65),Paint.PAPER,func():GameManager.open_menu("res://scenes/profile_scene.tscn"))
	button("NEW ADVENTURE",Vector2(980,550),Vector2(210,65),Paint.PAPER,func():
		Global.adventure_stage=0
		Global.adventure_complete=false
		Global.save_data()
		GameManager.open_menu("res://scenes/adventure/iron_adventure.tscn")
	)
	Music.play_theme("ember")
	if OS.has_feature("web"):print("HOME_READY IRON MARIO")
func button(label:String,at:Vector2,dimensions:Vector2,color:Color,callback:Callable)->Button:
	var node=preload("res://scripts/ui/PixelButton.gd").make(label,at,dimensions,color)
	add_child(node)
	node.pressed.connect(callback)
	return node
func start_adventure()->void:
	if Global.adventure_complete:
		Global.adventure_stage=0
		Global.adventure_complete=false
		Global.save_data()
	GameManager.open_menu("res://scenes/adventure/iron_adventure.tscn")
func _draw()->void:
	Paint.background(self,"title")
	Paint.burst(self,Vector2(245,350),165,Paint.GOLD)
	Paint.rect(self,Rect2(425,55,800,210),Paint.PAPER)
	Paint.text(self,"IRON MARIO",Vector2(450,133),70)
	Paint.text(self,"THE REACTOR RESCUE",Vector2(455,192),30)
	Paint.text(self,"ONE HERO. A CITY TO SAVE.",Vector2(455,237),23)
	Paint.rect(self,Rect2(50,565,315,66),Paint.PAPER)
	Paint.text(self,"BUILT FROM SCRAP.",Vector2(65,593),21)
	Paint.text(self,"POWERED BY COURAGE.",Vector2(65,619),19)
	Paint.text(self,"A HAND-PAINTED ADVENTURE / BONUS ARCADE INCLUDED",Vector2(445,675),19)
