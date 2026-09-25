extends "res://scripts/ui/PaintButton.gd"
var subtitle := ""
var badge := ""

func _draw() -> void:
	var shift := Vector2(3,3) if is_pressed() else Vector2.ZERO
	Paint.rect(self, Rect2(Vector2(5,5), size-Vector2(5,5)), Paint.INK)
	Paint.rect(self, Rect2(shift, size-Vector2(6,6)), Paint.PAPER if is_hovered() else paint_color)
	Paint.rect(self, Rect2(shift, size-Vector2(6,6)), Paint.INK, false, 3)
	Paint.circle(self,Vector2(34,34)+shift,20,Paint.GOLD)
	Paint.text(self,badge,Vector2(16,41)+shift,19,Paint.INK,36,HORIZONTAL_ALIGNMENT_CENTER)
	Paint.text(self,text,Vector2(66,42)+shift,22,Paint.INK,size.x-82)
	Paint.text(self,subtitle,Vector2(20,83)+shift,18,Paint.INK,size.x-36)
	Paint.text(self,"PLAY >",Vector2(20,115)+shift,18)
	if has_focus():
		Paint.rect(self,Rect2(9,9,size.x-24,size.y-24),Paint.INK,false,2)
