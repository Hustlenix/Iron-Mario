extends Node2D

## Menu music sits back so the hero art and logo lead, matching the trim the
## retired Bgm node used.
const TITLE_TRIM_DB := -8.0
## Long enough to cover SceneFade's fade-in, so the focus ring never appears
## on an already-dark screen.
const FOCUS_DELAY := 0.3

func _ready() -> void:
	SceneFade.fade_in(self)
	Music.play("title", 1.2, TITLE_TRIM_DB)
	$StreakLabel.text = "[center]BEST STREAK: %d[/center]" % Global.best_streak
	$MenuButtons/FlappyButton.text = "ARCADE"
	_build_hero()
	_pulse_logo()
	_focus_start_button()

## Every action here is a Button, but Godot does not hand one of them focus on
## its own, and the web export never forwards Tab to the engine while no control
## is focused -- which left the title playable by mouse only. Seeding focus with
## START makes the menu reachable with Tab and fired with Enter/Space.
func _focus_start_button() -> void:
	var button := $MenuButtons/StartButton as Button
	if button == null:
		return
	button.focus_mode = Control.FOCUS_ALL
	var tween := create_tween()
	tween.tween_interval(FOCUS_DELAY)
	tween.tween_callback(button.grab_focus)

## The title art is whoever you last picked, so the menu previews your own hero.
## With nothing picked yet it keeps the original title art, so the front door
## still reads as a title screen rather than as a random character.
func _build_hero() -> void:
	var art := "res://assets/title_hero.svg"
	if Global.selected_hero != "" and HeroData.is_selectable(Global.selected_hero):
		art = str(HeroData.get_hero(Global.selected_hero)["art"])
	var hero := TextureRect.new()
	hero.texture = load(art) as Texture2D
	hero.position = Vector2(120, 276)
	hero.custom_minimum_size = Vector2(240, 360)
	hero.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	hero.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(hero)
	var tween := create_tween()
	tween.set_loops(-1)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(hero, "position:y", 296.0, 1.1)
	tween.tween_property(hero, "position:y", 276.0, 1.1)

func _pulse_logo() -> void:
	# A Control scales around pivot_offset, which defaults to the top-left
	# corner. Without this the centred wordmark drifts right on every beat
	# instead of pulsing in place.
	$TitleLabel.pivot_offset = $TitleLabel.size / 2.0
	var tween := create_tween()
	tween.set_loops(-1)
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property($TitleLabel, "scale", Vector2(1.06, 1.06), 0.9)
	tween.tween_property($TitleLabel, "scale", Vector2.ONE, 0.9)

## Per-run state is reset by the hero select's FIGHT, not here, so backing out of
## the roster and returning leaves the menu feeling like the menu. The pick
## itself is a device preference and lives in Global.selected_hero.
func _on_start_button_pressed() -> void:
	await SceneFade.fade_out(self)
	get_tree().change_scene_to_file("res://scenes/hero_select.tscn")

func _on_settings_button_pressed() -> void:
	await SceneFade.fade_out(self)
	get_tree().change_scene_to_file("res://scenes/settings_scene.tscn")

func _on_quit_button_pressed() -> void:
	get_tree().quit()

func _on_flappy_button_pressed() -> void:
	await SceneFade.fade_out(self)
	GameLauncher.open_library()
