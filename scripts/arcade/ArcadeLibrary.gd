extends Node2D
const Paint=preload("res://scripts/ui/Paint.gd")
const Catalog=preload("res://scripts/arcade/ArcadeCatalog.gd")
var page=0
var cards:Node2D
func _ready()->void:
	cards=Node2D.new()
	add_child(cards)
	button("IRON MARIO HOME",Vector2(35,20),Vector2(300,70),func():GameManager.return_to_title())
	button("QUICK GAMES + FLAPPY",Vector2(360,20),Vector2(400,70),func():GameManager.open_menu("res://scenes/quick_games.tscn"))
	button("LARGER ARCADE VAULT",Vector2(785,20),Vector2(460,70),open_vault)
	button("< PREVIOUS",Vector2(295,620),Vector2(280,75),func():page=maxi(0,page-1);build_cards())
	button("NEXT >",Vector2(705,620),Vector2(280,75),func():page=mini(3,page+1);build_cards())
	build_cards()
	Music.play_theme(Global.hero_id)
func button(label:String,at:Vector2,size_value:Vector2,callback:Callable)->void:
	var node=preload("res://scripts/ui/PixelButton.gd").make(label,at,size_value,Paint.CYAN)
	add_child(node)
	node.pressed.connect(callback)
func build_cards()->void:
	for card in cards.get_children():card.free()
	for offset in range(6):
		var index=page*6+offset
		if index>=Catalog.GAMES.size():break
		var data=Catalog.GAMES[index]
		var card=preload("res://scripts/ui/GameCard.gd").new()
		card.name=data[0]
		card.position=Vector2(35+(offset%3)*415,190+(offset/3)*195)
		card.size=Vector2(380,165)
		card.text=data[1]
		card.subtitle=data[2]
		card.badge=str(index+1)
		card.detail=data[4]+" / BEST "+str(Global.arcade_records.get(data[0],{}).get("best",0))
		card.paint_color=Paint.PAPER
		cards.add_child(card)
		card.pressed.connect(func():GameManager.open_menu("res://scenes/arcade/"+data[0]+".tscn"))
	queue_redraw()
	if OS.has_feature("web"): print("LIBRARY_PAGE "+str(page))
func open_vault()->void:
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.location.href = new URL('extended-arcade/', window.location.href).href;")
	else:OS.shell_open("https://hustlenix.github.io/Iron-Mario/extended-arcade/")
func _draw()->void:
	Paint.background(self,"workshop")
	Paint.rect(self,Rect2(30,110,1220,60),Paint.PAPER)
	Paint.text(self,"IRON MARIO'S ARCADE / PAGE %d OF 4" % (page+1),Vector2(50,150),27)
	Paint.rect(self,Rect2(320,555,650,50),Paint.PAPER)
	Paint.rect(self,Rect2(320,555,650,50),Paint.INK,false,2)
	Paint.text(self,"YOUR BEST SCORES ARE SAVED ON THIS DEVICE",Vector2(345,589),19)
