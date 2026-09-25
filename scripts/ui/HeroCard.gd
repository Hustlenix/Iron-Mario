extends "res://scripts/ui/PaintButton.gd"
var hero_id := "ember"
var selected := false

func _ready() -> void:
	super._ready()
	var avatar := preload("res://scripts/ui/IronHero.gd").new()
	avatar.hero_id = hero_id
	avatar.position = Vector2(43,48)
	avatar.scale = Vector2(0.95,0.95)
	add_child(avatar)

func _draw() -> void:
	Paint.rect(self,Rect2(4,4,size.x-4,size.y-4),Paint.INK)
	Paint.rect(self,Rect2(0,0,size.x-5,size.y-5),Paint.PAPER if selected or is_hovered() else paint_color)
	Paint.rect(self,Rect2(0,0,size.x-5,size.y-5),Paint.INK,false,5 if selected else 2)
	var data := preload("res://scripts/HeroCatalog.gd").get_hero(hero_id)
	Paint.text(self,data["name"],Vector2(80,46),19,Paint.INK,size.x-92)
	if selected or has_focus():
		Paint.line(self,Vector2(80,63),Vector2(size.x-20,63),Paint.INK,3)
