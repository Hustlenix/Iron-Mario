extends Node2D
const Paint = preload("res://scripts/ui/Paint.gd")
const Buttons = preload("res://scripts/ui/PixelButton.gd")
var name_edit: LineEdit
var selected_style := 0
var hero: Node2D
var status := "LETTERS, NUMBERS, SPACES - UP TO 16"

func _ready() -> void:
	selected_style = Global.reactor_style
	hero = preload("res://scripts/ui/IronHero.gd").new()
	hero.position = Vector2(245,342)
	hero.scale = Vector2(3.3,3.3)
	hero.pose = "victory"
	add_child(hero)
	name_edit = preload("res://scripts/ui/PaintNameEdit.gd").new()
	name_edit.position = Vector2(470,180)
	name_edit.size = Vector2(520,54)
	name_edit.text = Global.pilot_name
	add_child(name_edit)
	for index in range(3):
		var swatch := Buttons.make(["ARC BLUE","SOLAR GOLD","ION GREEN"][index],Vector2(470+index*190,285),Vector2(180,52),Global.REACTOR_COLORS[index])
		add_child(swatch)
		swatch.pressed.connect(func():
			selected_style = index
			hero.reactor_color = Global.REACTOR_COLORS[index]
			queue_redraw()
		)
	var save_button := Buttons.make("SAVE PROFILE",Vector2(470,588),Vector2(260,56),Paint.GOLD)
	add_child(save_button)
	save_button.pressed.connect(_save_profile)
	name_edit.text_submitted.connect(func(_value): _save_profile())
	var back := Buttons.make("BACK TO TITLE",Vector2(755,588),Vector2(280,56),Paint.CYAN)
	add_child(back)
	back.pressed.connect(GameManager.return_to_title)
	save_button.grab_focus.call_deferred()

func _save_profile() -> void:
	Global.update_profile(name_edit.text,selected_style)
	name_edit.text = Global.pilot_name
	status = "PROFILE SAVED ON THIS DEVICE"
	SoundFX.play_click()
	queue_redraw()

func _draw() -> void:
	Paint.background(self,"workshop")
	Paint.rect(self,Rect2(80,65,1120,600),Paint.INK)
	Paint.rect(self,Rect2(74,59,1120,600),Paint.PAPER)
	Paint.text(self,"PILOT PROFILE",Vector2(120,116),40)
	Paint.text(self,"CALLSIGN",Vector2(470,164),20)
	Paint.text(self,"REACTOR / " + ["ARC BLUE","SOLAR GOLD","ION GREEN"][selected_style],Vector2(470,272),20)
	Paint.text(self,"LOCAL PROFILE",Vector2(128,501),24)
	var rank_name := "CADET" if Global.total_clears < 7 else ("DEFENDER" if Global.total_clears < 21 else "ACE")
	Paint.text(self,rank_name,Vector2(168,544),26)
	var records := ["BEST SCORE   %05d" % Global.high_score,"BEST STREAK  %d" % Global.best_streak,"MISSIONS     %d" % Global.total_clears,"RUNS WON     %d" % Global.total_wins,"HIGHEST LOOP %d" % Global.highest_loop,"FLAPPY BEST  %d" % Global.flappy_best]
	for i in range(records.size()):
		Paint.text(self,records[i],Vector2(470+(i%2)*340,385+(i/2)*46),20)
	Paint.text(self,status,Vector2(470,551),18)
