extends Node2D
const Paint = preload("res://scripts/ui/Paint.gd")
const Buttons = preload("res://scripts/ui/PixelButton.gd")
const Catalog = preload("res://scripts/HeroCatalog.gd")
var name_edit: LineEdit
var selected_hero := "ember"
var hero: Node2D
var cards: Array[Button] = []
var status := "PICK A HERO - PREVIEW THEIR WORLD AND MUSIC"

func _ready() -> void:
	selected_hero = Global.hero_id
	set_meta("hero_id",selected_hero)
	hero = preload("res://scripts/ui/IronHero.gd").new()
	hero.position = Vector2(225,337)
	hero.scale = Vector2(3.0,3.0)
	hero.pose = "victory"
	add_child(hero)
	name_edit = preload("res://scripts/ui/PaintNameEdit.gd").new()
	name_edit.position = Vector2(454,134)
	name_edit.size = Vector2(733,56)
	name_edit.text = Global.pilot_name
	add_child(name_edit)
	for index in range(Catalog.IDS.size()):
		var id: String = Catalog.IDS[index]
		var card := preload("res://scripts/ui/HeroCard.gd").new()
		card.hero_id = id
		card.name = "Hero_" + id
		card.text = Catalog.get_hero(id)["name"]
		card.tooltip_text = Catalog.get_hero(id)["place"]
		card.position = Vector2(453+(index%3)*248,221+(index/3)*94)
		card.size = Vector2(237,84)
		card.paint_color = Color(Catalog.get_hero(id)["sky"])
		card.selected = id == selected_hero
		add_child(card)
		card.pressed.connect(func(): _select_hero(id))
		cards.append(card)
	var save_button := Buttons.make("SAVE PROFILE",Vector2(454,604),Vector2(350,70),Paint.GOLD)
	add_child(save_button)
	save_button.pressed.connect(_save_profile)
	name_edit.text_submitted.connect(func(_value): _save_profile())
	var back := Buttons.make("BACK TO TITLE",Vector2(835,604),Vector2(350,70),Paint.CYAN)
	add_child(back)
	back.pressed.connect(GameManager.return_to_title)
	cards[Catalog.IDS.find(selected_hero)].focus_when_ready.call_deferred()
	Music.play_theme(selected_hero)

func _select_hero(id: String) -> void:
	selected_hero = Catalog.valid_id(id)
	set_meta("hero_id",selected_hero)
	hero.set_hero(selected_hero)
	for card in cards:
		card.selected = card.hero_id == selected_hero
		card.queue_redraw()
	status = "PREVIEWING " + Catalog.get_hero(selected_hero)["name"] + " - SAVE TO EQUIP"
	Music.play_theme(selected_hero)
	SoundFX.play_click()
	queue_redraw()

func _save_profile() -> void:
	Global.save_hero_profile(name_edit.text,selected_hero)
	name_edit.text = Global.pilot_name
	status = "HERO AND CALLSIGN SAVED ON THIS DEVICE"
	SoundFX.play_click()
	queue_redraw()

func _exit_tree() -> void:
	Music.play_theme(Global.hero_id)

func _draw() -> void:
	Paint.background(self,"title")
	Paint.rect(self,Rect2(40,30,1194,72),Paint.PAPER)
	Paint.text(self,"CHOOSE YOUR HERO",Vector2(65,79),39)
	Paint.text(self,"9 WORLDS. YOUR ADVENTURE.",Vector2(740,76),24)
	Paint.rect(self,Rect2(431,111,784,581),Paint.PAPER)
	Paint.text(self,"CALLSIGN",Vector2(457,129),18)
	Paint.text(self,"SAME CONTROLS AND STATS FOR EVERY HERO",Vector2(458,211),18)
	var data := Catalog.get_hero(selected_hero)
	Paint.rect(self,Rect2(46,453,369,187),Paint.PAPER)
	Paint.text(self,data["name"],Vector2(62,490),31,Paint.INK,340)
	Paint.text(self,data["place"],Vector2(62,529),21,Paint.INK,338)
	Paint.text(self,data["role"],Vector2(62,567),18,Paint.INK,338)
	var rank_name := "CADET" if Global.total_clears < 7 else ("DEFENDER" if Global.total_clears < 21 else "ACE")
	Paint.text(self,"RANK / " + rank_name,Vector2(62,610),22)
	var records := ["SCORE %05d" % Global.high_score,"STREAK %d" % Global.best_streak,"CLEARS %d" % Global.total_clears,"WINS %d" % Global.total_wins,"LOOP %d" % Global.highest_loop,"FLAPPY %d" % Global.flappy_best]
	for i in range(records.size()):
		Paint.text(self,records[i],Vector2(457+(i%3)*248,528+(i/3)*28),19)
	Paint.text(self,status,Vector2(457,589),17,Paint.INK,720)
