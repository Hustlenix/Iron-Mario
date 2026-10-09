class_name HeroStage
extends Control
signal demo_finished
var entry: Dictionary=HeroRoster.hero(0)
var clock: float=0
var entrance: float=0
var demo_time: float=-1
var demo_count: int=0
var art: TextureRect
var foreground: Node2D
var cloth: ShaderMaterial
var reduced_motion: bool=false
var last_art_path: String=''
func _ready() -> void:
	clip_contents=true; mouse_filter=Control.MOUSE_FILTER_IGNORE
	art=TextureRect.new(); art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.mouse_filter=Control.MOUSE_FILTER_IGNORE; add_child(art)
	cloth=ShaderMaterial.new(); cloth.shader=load('res://ui/hero_cloth.gdshader'); art.material=cloth
	foreground=Node2D.new(); add_child(foreground); foreground.draw.connect(draw_power)
	set_hero(entry)
func set_hero(spec: Dictionary) -> void:
	entry=spec; entrance=0; demo_time=-1; last_art_path=''
	if is_instance_valid(art):
		var path: String=entry.art
		if ResourceLoader.exists(path): art.texture=load(path); last_art_path=path
		else: art.texture=null
	queue_redraw()
func demonstrate() -> void:
	demo_time=0; demo_count+=1; queue_redraw()
func _process(delta: float) -> void:
	reduced_motion=Profile.data.settings.get('reduced_motion',false)
	clock+=delta; entrance=minf(1,entrance+delta*3.2)
	if demo_time>=0:
		demo_time+=delta
		if demo_time>2.2: demo_time=-1; demo_finished.emit()
	if is_instance_valid(art):
		var mobile: bool=size.x<420
		var target_size := Vector2(size.x*0.90,size.y*0.82)
		art.size=target_size; art.pivot_offset=target_size*0.5
		var offset := Vector2.ZERO
		var rotation_amount: float=0
		var alpha: float=1
		if not reduced_motion:
			offset.y=sin(clock*1.7)*4
			offset.x=(1-entrance)*(42 if entry.power!='stealth' else -42)
			alpha=entrance
			if demo_time>=0:
				var p: float=clampf(demo_time/2.2,0,1)
				match entry.power:
					'forge': offset+=Vector2(sin(p*PI)*size.x*0.10,-sin(p*PI)*size.y*0.06); rotation_amount=sin(p*TAU)*0.08
					'tether': offset+=Vector2(sin(p*TAU)*size.x*0.10,-sin(p*PI)*size.y*0.05); rotation_amount=sin(p*TAU)*0.14
					'stealth': alpha=0.15+absf(cos(p*PI))*0.85; offset.x=sin(p*TAU)*size.x*0.08
					'rift': offset.y-=sin(p*PI)*size.y*0.03; rotation_amount=sin(p*TAU)*0.025
		art.position=(size-target_size)*0.5+offset
		art.scale=Vector2.ONE*(1.0 if reduced_motion else (0.96+0.04*entrance+sin(clock*1.7)*0.002))
		art.rotation=rotation_amount; art.modulate=Color(1,1,1,alpha)
		cloth.set_shader_parameter('motion',0.0 if reduced_motion else 1.0)
		cloth.set_shader_parameter('pulse',0.5 if demo_time>=0 else 0.0)
	queue_redraw()
	if is_instance_valid(foreground): foreground.queue_redraw()
func _draw() -> void:
	var accent := Color(entry.color)
	draw_rect(Rect2(Vector2.ZERO,size),HeroDesign.NIGHT)
	var backdrop_time: float=0 if reduced_motion else clock
	# Each archetype gets its own environment and original monumental emblem.
	match entry.power:
		'forge':
			var sun := Vector2(size.x*0.50,size.y*0.39)
			draw_circle(sun,minf(size.x,size.y)*0.34,Color(accent,0.055))
			for side in [-1,1]:
				var turbine := sun+Vector2(side*size.x*0.18,-size.y*0.09)
				draw_arc(turbine,55,0,TAU,48,Color(accent,0.16),2,true)
				for blade in 8:
					var a: float=blade*TAU/8+backdrop_time*0.10
					draw_line(turbine+Vector2(cos(a),sin(a))*43,turbine+Vector2(cos(a+0.25),sin(a+0.25))*52,Color(accent,0.22),2,true)
		'tether':
			for lane in 4:
				var path := PackedVector2Array()
				for segment in 32:
					var p: float=segment/31.0
					path.append(Vector2(p*size.x,size.y*(0.18+lane*0.15)+sin(p*TAU+lane+backdrop_time*0.2)*size.y*0.10))
				draw_polyline(path,Color(accent,0.075),1,true)
		'stealth':
			var moon := Vector2(size.x*0.78,size.y*0.22)
			draw_circle(moon,40,Color(accent,0.10))
			draw_circle(moon+Vector2(14,-8),35,HeroDesign.NIGHT)
			var beam := PackedVector2Array([Vector2(size.x*0.12,size.y*0.66),Vector2(size.x*0.32,0),Vector2(size.x*0.52,0)])
			draw_colored_polygon(beam,Color(accent,0.035))
		'rift':
			var origin := Vector2(size.x*0.5,size.y*0.43)
			for facet in 5:
				var a: float=facet*TAU/5+backdrop_time*0.04
				var center := origin+Vector2(cos(a),sin(a))*minf(size.x,size.y)*0.37
				var polygon := PackedVector2Array([center+Vector2(0,-22),center+Vector2(17,13),center+Vector2(-17,13)])
				draw_colored_polygon(polygon,Color(accent,0.07))
				draw_polyline(PackedVector2Array([polygon[0],polygon[1],polygon[2],polygon[0]]),Color(accent,0.16),1,true)
	# A three-plane city stage, not generic card decoration.
	for layer in 3:
		var color := HeroDesign.PANEL.lightened(layer*0.025)
		for i in 12:
			var width: float=size.x/9
			var x: float=i*width-width
			var height: float=size.y*(0.18+0.04*((i*7+layer*3)%5))
			var y: float=size.y-height+layer*size.y*0.04
			draw_rect(Rect2(x,y,width-3,height),color)
			if layer==2:
				for row in 3: draw_rect(Rect2(x+width*0.3,y+12+row*16,4,5),Color(accent,0.18))
	var center := Vector2(size.x*0.5,size.y*0.49)
	var radius: float=minf(size.x*0.38,size.y*0.40)
	draw_arc(center,radius,PI*0.15,PI*1.25,64,Color(accent,0.20),2)
	draw_arc(center,radius+12,PI*1.1,PI*1.83,40,Color(accent,0.10),1)
	# Halftone print and grounded stage markings.
	for y in 8:
		for x in 11:
			draw_circle(Vector2(size.x-110+x*9,24+y*9),1.1,Color(accent,0.11))
	draw_line(Vector2(24,size.y-38),Vector2(size.x-24,size.y-38),Color(accent,0.42),1)
	draw_string(ThemeDB.fallback_font,Vector2(22,30),String(entry.role),HORIZONTAL_ALIGNMENT_LEFT,size.x-44,12,accent)
	draw_string(ThemeDB.fallback_font,Vector2(22,size.y-18),'POWER PREVIEW',HORIZONTAL_ALIGNMENT_LEFT,size.x-44,11,HeroDesign.MUTED)
	if demo_time>=0 and reduced_motion:
		draw_string(ThemeDB.fallback_font,Vector2(size.x-165,size.y-18),'ABILITY ACTIVATED',HORIZONTAL_ALIGNMENT_LEFT,150,11,accent)
func curve(points: PackedVector2Array, color: Color, width: float) -> void:
	if points.size()>1: foreground.draw_polyline(points,color,width,true)
func draw_power() -> void:
	var c := Color(entry.secondary)
	var center := size*Vector2(0.5,0.5)
	var radius: float=minf(size.x,size.y)*0.3
	var t: float=clock if not reduced_motion else 0
	var boost: float=0.35
	if demo_time>=0: boost=1.0 if reduced_motion else 0.55+sin(clampf(demo_time/2.2,0,1)*PI)*0.45
	match entry.power:
		'forge':
			for side in [-1,1]:
				var origin := center+Vector2(side*radius*0.22,radius*0.63)
				var tail := origin+Vector2(-side*18,24+boost*46)
				foreground.draw_colored_polygon(PackedVector2Array([origin-Vector2(5,0),origin+Vector2(5,0),tail]),Color(c,0.55))
			if demo_time>=0:
				var from := center+Vector2(-radius*0.4,-radius*0.10)
				var end := Vector2(20,size.y*0.28)
				foreground.draw_line(from,end,Color(c,0.12),14,true)
				foreground.draw_line(from,end,Color(c,0.9),3,true)
				foreground.draw_arc(end,12+sin(t*14)*3,0,TAU,20,c,2,true)
		'tether':
			for side in [-1,1]:
				var points := PackedVector2Array()
				for i in 42:
					var p: float=i/41.0
					points.append(center+Vector2(side*(radius*0.2+p*radius*1.0),sin(p*PI*1.6+t*2)*radius*0.35-20*p))
				curve(points,Color(c,0.55 if demo_time>=0 else 0.22),2+boost)
				var anchor: Vector2=points[-1]
				foreground.draw_circle(anchor,4,c)
		'stealth':
			for i in 10:
				var p := center+Vector2(sin(t*1.2+i*2.2)*radius*0.7,radius*0.85-sin(t+i)*radius*0.20)
				foreground.draw_arc(p,14+(i%4)*5,PI*0.3,PI*1.2,20,Color(c,0.18*boost),3,true)
			if demo_time>=0:
				var target := center+Vector2(radius*0.7,-radius*0.3)
				foreground.draw_arc(target,20,0,TAU,24,c,1,true)
				foreground.draw_line(target-Vector2(28,0),target+Vector2(28,0),c,1,true)
				foreground.draw_line(target-Vector2(0,28),target+Vector2(0,28),c,1,true)
		'rift':
			for ring in [1.0,0.78]:
				var points := PackedVector2Array()
				for i in 7:
					var a: float=t*0.25+i*TAU/6
					points.append(center+Vector2(cos(a),sin(a))*radius*ring)
				curve(points,Color(c,0.20+boost*0.28),2)
			for i in 6:
				var a: float=t*0.7+i*TAU/6
				var p := center+Vector2(cos(a),sin(a))*radius*(1.1+boost*0.1)
				foreground.draw_colored_polygon(PackedVector2Array([p+Vector2(0,-5),p+Vector2(4,3),p+Vector2(-4,3)]),Color(c,0.5))
	if demo_time>=0:
		var p: float=0.5 if reduced_motion else clampf(demo_time/2.2,0,1)
		for i in 18:
			var a: float=i*TAU/18
			var point := center+Vector2(cos(a),sin(a))*radius*(0.75+p*0.5)
			foreground.draw_circle(point,1.5,Color(c,sin(p*PI)*0.65))
