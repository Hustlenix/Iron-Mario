3adb4af feat(flappy): FLAPPY button on title screen
 scenes/title_screen.gd   | 5 +++++
 scenes/title_screen.tscn | 6 ++++++
 2 files changed, 11 insertions(+)
diff --git a/scenes/title_screen.gd b/scenes/title_screen.gd
index 2b4678f..2eb55b3 100644
--- a/scenes/title_screen.gd
+++ b/scenes/title_screen.gd
@@ -1,17 +1,18 @@
 extends Node2D
 
 func _ready() -> void:
 	SceneFade.fade_in(self)
 	$Bgm.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
 	$Bgm.play()
 	$StreakLabel.text = "[center]BEST STREAK: %d[/center]" % Global.best_streak
+	$MenuButtons/FlappyButton.text = "FLAPPY  BEST: %d" % Global.flappy_best
 	_build_hero()
 	_pulse_logo()
 
 func _build_hero() -> void:
 	var hero := TextureRect.new()
 	hero.texture = load("res://assets/hero.svg") as Texture2D
 	hero.position = Vector2(300, 380)
 	hero.custom_minimum_size = Vector2(150, 150)
 	hero.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
 	hero.mouse_filter = Control.MOUSE_FILTER_IGNORE
@@ -35,10 +36,14 @@ func _on_start_button_pressed() -> void:
 	Global.reset()
 	await SceneFade.fade_out(self)
 	get_tree().change_scene_to_file("res://scenes/level_scene.tscn")
 
 func _on_settings_button_pressed() -> void:
 	await SceneFade.fade_out(self)
 	get_tree().change_scene_to_file("res://scenes/settings_scene.tscn")
 
 func _on_quit_button_pressed() -> void:
 	get_tree().quit()
+
+func _on_flappy_button_pressed() -> void:
+	await SceneFade.fade_out(self)
+	get_tree().change_scene_to_file("res://scenes/flappy_bird.tscn")
diff --git a/scenes/title_screen.tscn b/scenes/title_screen.tscn
index 1f44e2b..83cc325 100644
--- a/scenes/title_screen.tscn
+++ b/scenes/title_screen.tscn
@@ -39,31 +39,37 @@ offset_left = 540.0
 offset_top = 340.0
 offset_right = 740.0
 offset_bottom = 560.0
 theme_override_constants/separation = 20
 
 [node name="StartButton" type="Button" parent="MenuButtons"]
 layout_mode = 2
 custom_minimum_size = Vector2(200, 60)
 text = "START"
 
+[node name="FlappyButton" type="Button" parent="MenuButtons"]
+layout_mode = 2
+custom_minimum_size = Vector2(200, 60)
+text = "FLAPPY  BEST: 0"
+
 [node name="SettingsButton" type="Button" parent="MenuButtons"]
 layout_mode = 2
 custom_minimum_size = Vector2(200, 60)
 text = "SETTINGS"
 
 [node name="QuitButton" type="Button" parent="MenuButtons"]
 layout_mode = 2
 custom_minimum_size = Vector2(200, 60)
 text = "QUIT"
 
 [connection signal="pressed" from="MenuButtons/StartButton" to="." method="_on_start_button_pressed"]
+[connection signal="pressed" from="MenuButtons/FlappyButton" to="." method="_on_flappy_button_pressed"]
 [connection signal="pressed" from="MenuButtons/SettingsButton" to="." method="_on_settings_button_pressed"]
 [connection signal="pressed" from="MenuButtons/QuitButton" to="." method="_on_quit_button_pressed"]
 
 [node name="Bgm" type="AudioStreamPlayer" parent="."]
 volume_db = -8.0
 stream = ExtResource("3_bgm")
 
 [node name="StreakLabel" type="RichTextLabel" parent="."]
 layout_mode = 0
 offset_left = 440.0
