extends Node2D

const Paint = preload("res://scripts/ui/Paint.gd")

var pose := "idle"
var facing := 1.0
var reactor_color := Color("7bd9df")

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	# Map the handmade 50x88 drawing onto a centered 40x64 gameplay body.
	draw_set_transform(Vector2(0, -15.3), 0.0, Vector2(0.8, 0.727))
	var outline := Color("202022")
	var red := Color("e34838") if pose != "damaged" else Color("7e3742")
	var gold := Color("ffd13c") if pose != "damaged" else Color("8c7445")
	var bob := -3.0 if pose == "jump" else 0.0
	Paint.rect(self, Rect2(-15, 18 + bob, 30, 34), red)
	Paint.rect(self, Rect2(-15, 18 + bob, 30, 34), outline, false, 4.0)
	Paint.polygon(self, PackedVector2Array([Vector2(-19, -23 + bob), Vector2(17, -23 + bob), Vector2(23, -8 + bob), Vector2(14, 14 + bob), Vector2(-14, 14 + bob), Vector2(-23, -8 + bob)]), PackedColorArray([red]))
	Paint.polyline(self, PackedVector2Array([Vector2(-19, -23 + bob), Vector2(17, -23 + bob), Vector2(23, -8 + bob), Vector2(14, 14 + bob), Vector2(-14, 14 + bob), Vector2(-23, -8 + bob), Vector2(-19, -23 + bob)]), outline, 4.0)
	Paint.rect(self, Rect2(-14, -14 + bob, 28, 9), gold)
	Paint.rect(self, Rect2(-10 if facing > 0 else 2, -11 + bob, 8, 4), Color("efffff"))
	Paint.circle(self, Vector2(0, 29 + bob), 8, outline)
	Paint.circle(self, Vector2(0, 29 + bob), 5, reactor_color)
	var arm_angle := -10.0 if pose == "victory" else 22.0
	Paint.rect(self, Rect2(-25, arm_angle + bob, 10, 30), red)
	Paint.rect(self, Rect2(15, arm_angle + bob, 10, 30), red)
	Paint.rect(self, Rect2(-15, 50 + bob, 11, 15), gold)
	Paint.rect(self, Rect2(4, 50 + bob, 11, 15), gold)
	if pose == "damaged":
		Paint.line(self, Vector2(-11, 22), Vector2(8, 39), Color("ff875c"), 3.0)
