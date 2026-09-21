extends RefCounted
const Paint = preload("res://scripts/ui/Paint.gd")

static func draw(canvas: CanvasItem, mission: String, time: float) -> void:
	var styles := {"arc_reactor_dash":"city","target_lock":"sky","laser_tunnel":"tunnel","reactor_parry":"space","armor_repair":"workshop","rocket_rescue":"sky","power_core_sequence":"space"}
	Paint.background(canvas,styles.get(mission,"city"))
	match mission:
		"arc_reactor_dash":
			for i in range(10):
				var h := 130+(i*53)%170
				Paint.rect(canvas,Rect2(i*138,720-h,112,h),Paint.BLUE)
				Paint.rect(canvas,Rect2(i*138,720-h,112,h),Paint.INK,false,4)
				for y in range(740-h,700,30):
					Paint.rect(canvas,Rect2(i*138+15,y,17,12),Paint.GOLD)
			for i in range(3):
				Paint.burst(canvas,Vector2(80+i*145,160+i*45),21,Paint.GOLD)
		"target_lock":
			Paint.circle(canvas,Vector2(215,365),180,Color("6796ae"))
			Paint.circle(canvas,Vector2(215,365),145,Paint.CYAN)
			for i in range(4):
				var p := Vector2(110+i*310,150+sin(time+i)*32)
				Paint.line(canvas,p-Vector2(28,0),p+Vector2(28,0),Paint.INK,5)
				Paint.rect(canvas,Rect2(p-Vector2(16,10),Vector2(32,23)),Paint.RED)
				Paint.circle(canvas,p,6,Paint.GOLD)
		"laser_tunnel":
			for i in range(7):
				Paint.line(canvas,Vector2(i*210,95),Vector2(i*210-150,720),Paint.INK,8)
			for y in [155,470,645]:
				Paint.rect(canvas,Rect2(0,y,1280,10),Paint.RED)
				Paint.line(canvas,Vector2(0,y),Vector2(1280,y+3),Color.WHITE,2)
		"reactor_parry":
			Paint.circle(canvas,Vector2(220,340),173,Paint.INK)
			Paint.circle(canvas,Vector2(220,340),155,Paint.GOLD)
			Paint.circle(canvas,Vector2(220,340),122,Paint.BLUE)
			for i in range(10):
				var a := TAU*i/10.0+time*.25
				Paint.line(canvas,Vector2(220,340)+Vector2.RIGHT.rotated(a)*130,Vector2(220,340)+Vector2.RIGHT.rotated(a)*165,Paint.INK,5)
		"armor_repair":
			for i in range(4):
				var p := Vector2(95+i*330,150)
				Paint.rect(canvas,Rect2(p,Vector2(70,55)),[Paint.RED,Paint.GOLD,Paint.CYAN,Paint.BLUE][i])
				Paint.rect(canvas,Rect2(p,Vector2(70,55)),Paint.INK,false,4)
			Paint.rect(canvas,Rect2(15,550,385,30),Paint.BLUE)
			for x in [40,345]:
				Paint.line(canvas,Vector2(x,580),Vector2(x,720),Paint.INK,12)
		"rocket_rescue":
			for i in range(12):
				Paint.rect(canvas,Rect2(i*120,620-(i%3)*25,100,130),Paint.BLUE)
			for i in range(5):
				var p := Vector2(80+i*260,125+fmod(time*25+i*27,90))
				Paint.circle(canvas,p,22,Paint.PAPER)
				Paint.polyline(canvas,PackedVector2Array([p-Vector2(22,0),p+Vector2(0,45),p+Vector2(22,0)]),Paint.INK,2)
				Paint.rect(canvas,Rect2(p+Vector2(-12,34),Vector2(24,20)),Paint.RED)
		"power_core_sequence":
			for i in range(8):
				var p := Vector2(55+i*167,135)
				Paint.line(canvas,p,Vector2(640,700),Paint.BLUE,2)
				Paint.rect(canvas,Rect2(p,Vector2(65,60)),Paint.GOLD if i==int(time*3)%8 else Paint.CYAN)
				Paint.text(canvas,["W","A","S","D"][i%4],p+Vector2(20,42),32)
