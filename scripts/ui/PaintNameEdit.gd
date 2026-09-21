extends LineEdit
const Paint = preload("res://scripts/ui/Paint.gd")

func _ready() -> void:
	max_length = 16
	for state in ["normal","focus","read_only"]:
		add_theme_stylebox_override(state,StyleBoxEmpty.new())
	for color in ["font_color","font_selected_color","caret_color","font_placeholder_color"]:
		add_theme_color_override(color,Color.TRANSPARENT)
	text_changed.connect(func(_value): queue_redraw())
	focus_entered.connect(queue_redraw)
	focus_exited.connect(queue_redraw)

func _process(_delta: float) -> void:
	if has_focus():
		queue_redraw()

func _draw() -> void:
	Paint.rect(self,Rect2(Vector2.ZERO,size),Paint.PAPER)
	Paint.rect(self,Rect2(Vector2.ZERO,size),Paint.BLUE if has_focus() else Paint.INK,false,3)
	Paint.text(self,text.to_upper(),Vector2(14,36),28)
	if has_focus() and Time.get_ticks_msec()%1000 < 600:
		var x := 14+get_caret_column()*28*0.59
		Paint.line(self,Vector2(x,10),Vector2(x,42),Paint.INK,2)
