extends Node2D

const Paint = preload("res://scripts/ui/Paint.gd")
const Buttons = preload("res://scripts/ui/PixelButton.gd")
var status := ""

func _ready() -> void:
	var slider := preload("res://scripts/ui/PaintSlider.gd").new()
	slider.position = Vector2(450, 220)
	slider.size = Vector2(440, 50)
	slider.max_value = 100
	slider.value = Global.volume
	add_child(slider)
	slider.value_changed.connect(func(value): Global.set_volume(value); queue_redraw())
	slider.focus_when_ready.call_deferred()
	var mute := Buttons.make("SOUND: OFF" if Global.muted else "SOUND: ON", Vector2(450, 295), Vector2(440, 55), Paint.CYAN)
	add_child(mute)
	mute.pressed.connect(func():
		Global.toggle_mute()
		mute.text = "SOUND: OFF" if Global.muted else "SOUND: ON"
		mute.queue_redraw()
	)
	var reset := Buttons.make("RESET PROGRESS", Vector2(450, 390), Vector2(440, 55), Paint.GOLD)
	add_child(reset)
	reset.pressed.connect(func():
		Global.reset_records()
		status = "PROGRESS RESET AND SAVED"
		queue_redraw()
	)
	var back := Buttons.make("BACK TO TITLE", Vector2(450, 575), Vector2(440, 55), Paint.CYAN)
	add_child(back)
	back.pressed.connect(func(): GameManager.return_to_title())
	var touch := Buttons.make("TOUCH: " + ("ON" if Global.touch_controls else "AUTO"),Vector2(450,468),Vector2(440,65),Paint.CYAN)
	add_child(touch)
	touch.pressed.connect(func():
		Global.touch_controls = not Global.touch_controls
		Global.save_data()
		touch.text = "TOUCH: " + ("ON" if Global.touch_controls else "AUTO")
		touch.queue_redraw()
	)

func _draw() -> void:
	Paint.background(self, "workshop")
	Paint.rect(self, Rect2(285, 80, 710, 580), Paint.PAPER)
	Paint.text(self, "SUIT SETTINGS", Vector2(365, 155), 42)
	Paint.text(self, "VOLUME %d" % Global.volume, Vector2(450, 205), 24)
	Paint.text(self, status, Vector2(375, 458), 18)
	Paint.text(self, "R RESTART  ARROWS/TAB SELECT  ENTER CONFIRM", Vector2(325, 560), 16)
