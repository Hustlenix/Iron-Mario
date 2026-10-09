extends Control
## Original vector cover illustrations; no external textures or asset downloads.
var entry: Dictionary = {}
var preview: Texture2D
func _ready() -> void:
	custom_minimum_size=Vector2(180,96)
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	var relative: String = 'previews/'+String(entry.get('id',''))+'.png'
	if OS.has_feature('web'):
		var request := HTTPRequest.new()
		request.timeout=8
		add_child(request)
		request.request_completed.connect(func(result:int,code:int,_headers:PackedStringArray,data:PackedByteArray)->void:
			if result==HTTPRequest.RESULT_SUCCESS and code==200:
				var bitmap := Image.new()
				if bitmap.load_png_from_buffer(data)==OK:
					preview=ImageTexture.create_from_image(bitmap); queue_redraw()
			request.queue_free())
		var url: String = str(JavaScriptBridge.eval('new URL('+JSON.stringify(relative)+',window.location.href).href',true))
		request.request(url)
	elif ResourceLoader.exists('res://web/'+relative):
		preview=load('res://web/'+relative)
func _draw() -> void:
	if preview!=null:
		draw_texture_rect(preview,Rect2(Vector2.ZERO,size),false)
		return
	var category: String = String(entry.get('category','')).to_lower()
	var ink := Color('#242333')
	var gold := Color('#ffc857')
	var blue := Color('#4a8de0')
	var red := Color('#ef6351')
	draw_rect(Rect2(Vector2.ZERO,size),Color('#e7e7ce'))
	var center := size*0.5
	if category in ['racing','runner','movement','platformer']:
		draw_line(Vector2(0,75),Vector2(size.x,72),ink,4)
		for i in 5: draw_line(Vector2(i*size.x/5,85),Vector2(i*size.x/5+18,82),blue,3)
		draw_rect(Rect2(center-Vector2(30,13),Vector2(60,27)),red)
		draw_circle(center+Vector2(-20,18),10,ink); draw_circle(center+Vector2(20,18),10,ink)
	elif category in ['puzzle','strategy','sorting','memory']:
		for y in 2:
			for x in 4:
				var rect := Rect2(center+Vector2((x-2)*32,(y-1)*32),Vector2(28,28))
				draw_rect(rect,gold if (x+y)%3==0 else blue); draw_rect(rect,ink,false,2)
	elif category=='fighting':
		for x in [-1,1]:
			var pos := center+Vector2(x*45,0)
			draw_circle(pos-Vector2(0,22),12,ink); draw_line(pos,pos+Vector2(-x*25,-12),red,9); draw_line(pos,pos+Vector2(x*20,29),ink,8)
		draw_line(center-Vector2(10,15),center+Vector2(10,10),gold,5)
	elif category in ['flying','physics']:
		draw_arc(center,29,0,TAU,24,ink,4); draw_line(center,center+Vector2(62,-22),red,6)
		for i in 4: draw_circle(Vector2(25+i*size.x/4,20+sin(i*2)*9),5,gold)
	else:
		draw_circle(center,29,gold); draw_arc(center,33,0,TAU,20,ink,3)
		draw_line(center-Vector2(50,0),center+Vector2(50,0),ink,3); draw_line(center-Vector2(0,43),center+Vector2(0,43),ink,3)
	var seed_value: int = absi(String(entry.get('id','')).hash())
	for i in 3:
		var p := Vector2(15+((seed_value>>(i*4))%15)*size.x/18,14+(seed_value>>(i*7))%55)
		draw_line(p-Vector2(4,0),p+Vector2(4,0),red,2); draw_line(p-Vector2(0,4),p+Vector2(0,4),red,2)
