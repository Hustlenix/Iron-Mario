class_name HeroSelection
extends Control
signal exit_requested
signal play_requested(game_id: String)
var selected: int=0
var stage: HeroStage
var hero_name: Label
var subtitle: Label
var story: Label
var ability: Label
var ability_text: Label
var trait_label: Label
var status: Label
var equip_button: Button
var demo_button: Button
var play_button: Button
var portraits: Array[Button]=[]
var scroll: ScrollContainer
var column: VBoxContainer
var main: BoxContainer
var details: VBoxContainer
var roster: GridContainer
var sound: AudioStreamPlayer
var mobile: bool=false
var last_width: float=-1
var preview_title: Label
var footer: Label
var roster_title: Label
var stage_power: Button
var motion_button: Button
func _ready() -> void:
	restore_browser_preferences()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new(); bg.color=HeroDesign.NIGHT; bg.mouse_filter=Control.MOUSE_FILTER_IGNORE
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); add_child(bg)
	sound=AudioStreamPlayer.new(); add_child(sound)
	scroll=ScrollContainer.new(); scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED; add_child(scroll)
	var margin := MarginContainer.new(); margin.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	for side in ['left','right','top','bottom']: margin.add_theme_constant_override('margin_'+side,24)
	scroll.add_child(margin)
	column=HeroDesign.column(16); column.size_flags_horizontal=Control.SIZE_EXPAND_FILL; margin.add_child(column)
	var header := HeroDesign.row(12); column.add_child(header)
	var brand := HeroDesign.label('IRON-MARIO',18,HeroDesign.GOLD); header.add_child(brand)
	motion_button=HeroDesign.button('MOTION',toggle_motion); motion_button.custom_minimum_size.x=80; header.add_child(motion_button)
	motion_button.tooltip_text='Toggle reduced motion for hero entrances and power effects'
	var back := HeroDesign.button('ARCADE',func()->void:exit_requested.emit())
	back.custom_minimum_size.x=86; header.add_child(back)
	preview_title=HeroDesign.label('CHOOSE YOUR EXTRAORDINARY.',24); column.add_child(preview_title)
	main=BoxContainer.new(); main.add_theme_constant_override('separation',28); column.add_child(main)
	stage=HeroStage.new(); stage.name='HeroStage'; stage.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	main.add_child(stage)
	stage_power=HeroDesign.button('POWER PREVIEW',demonstrate)
	stage.add_child(stage_power); stage_power.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	stage_power.offset_left=-180; stage_power.offset_top=-85; stage_power.offset_right=-18; stage_power.offset_bottom=-37
	details=HeroDesign.column(12); details.size_flags_horizontal=Control.SIZE_EXPAND_FILL; main.add_child(details)
	subtitle=HeroDesign.label('',13,HeroDesign.GOLD); details.add_child(subtitle)
	hero_name=HeroDesign.label('',48); details.add_child(hero_name)
	trait_label=HeroDesign.label('',12,HeroDesign.MUTED); details.add_child(trait_label)
	story=HeroDesign.label('',17); details.add_child(story)
	var separator := HSeparator.new(); details.add_child(separator)
	ability=HeroDesign.label('',16); details.add_child(ability)
	ability_text=HeroDesign.label('',15,HeroDesign.MUTED); details.add_child(ability_text)
	demo_button=HeroDesign.button('DEMONSTRATE POWER',demonstrate); details.add_child(demo_button)
	status=HeroDesign.label('',13,HeroDesign.MUTED); details.add_child(status)
	var actions := HeroDesign.row(8); details.add_child(actions)
	equip_button=HeroDesign.button('EQUIP HERO',equip,HeroDesign.GOLD)
	equip_button.size_flags_horizontal=Control.SIZE_EXPAND_FILL; actions.add_child(equip_button)
	play_button=HeroDesign.button('PLAY  >',launch); play_button.custom_minimum_size.x=102; actions.add_child(play_button)
	details.add_child(HeroDesign.label('Selection is cosmetic. Power demonstrations are previews; PLAY opens a matching arcade game.',12,HeroDesign.MUTED))
	roster_title=HeroDesign.label('THE ORIGINAL FOUR   /   ALL UNLOCKED',12,HeroDesign.MUTED); column.add_child(roster_title)
	roster=GridContainer.new(); roster.columns=4; roster.add_theme_constant_override('h_separation',10)
	roster.add_theme_constant_override('v_separation',10); column.add_child(roster)
	for i in HeroRoster.HEROES.size():
		var spec: Dictionary=HeroRoster.hero(i)
		var b := HeroDesign.button('',func()->void:select_hero(i))
		b.name='Portrait'+str(i); b.custom_minimum_size=Vector2(150,88); b.size_flags_horizontal=Control.SIZE_EXPAND_FILL
		roster.add_child(b); portraits.append(b)
		var atlas := AtlasTexture.new(); atlas.atlas=load(spec.art); atlas.region=Rect2(180,20,664,720)
		var image := TextureRect.new(); image.texture=atlas; image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED; image.mouse_filter=Control.MOUSE_FILTER_IGNORE
		image.position=Vector2(4,4); image.size=Vector2(68,80); image.clip_contents=true; b.add_child(image)
		var name_label := HeroDesign.label(spec.name,14); name_label.mouse_filter=Control.MOUSE_FILTER_IGNORE
		name_label.position=Vector2(78,18); name_label.size=Vector2(105,22); b.add_child(name_label)
		var number := HeroDesign.label('0'+str(i+1),12,Color(spec.color)); number.mouse_filter=Control.MOUSE_FILTER_IGNORE
		number.position=Vector2(78,45); number.size=Vector2(40,22); b.add_child(number)
	footer=HeroDesign.label('LEFT / RIGHT: SWITCH    |    SPACE: POWER    |    ENTER: EQUIP    |    GAMEPAD: D-PAD / X / A',12,HeroDesign.MUTED)
	column.add_child(footer)
	stage.demo_finished.connect(update_selection)
	for i in HeroRoster.HEROES.size():
		if HeroRoster.hero(i).id==Profile.data.hero: selected=i
	select_hero(selected,false); resized.connect(reflow); reflow()
	Music.play_menu(Profile.data.hero)
func restore_browser_preferences() -> void:
	if not OS.has_feature('web') or Profile._future_version: return
	var raw: Variant=JavaScriptBridge.eval("(()=>{try{return JSON.stringify({hero:localStorage.getItem('iron-mario-roster-hero-v1'),motion:localStorage.getItem('iron-mario-roster-motion-v1')});}catch(e){return null;}})()",true)
	if not raw is String: return
	var parsed: Variant=JSON.parse_string(raw)
	if not parsed is Dictionary: return
	for spec: Dictionary in HeroRoster.HEROES:
		if parsed.get('hero')==spec.id: Profile.data.hero=spec.id
	if parsed.get('motion') in ['true','false']:
		Profile.data.settings.reduced_motion=parsed.motion=='true'
func persist_browser_preferences() -> bool:
	if not OS.has_feature('web'): return true
	var hero_value: String=JSON.stringify(String(Profile.data.hero))
	var motion_value: String=JSON.stringify(str(Profile.data.settings.get('reduced_motion',false)))
	return JavaScriptBridge.eval("(()=>{try{localStorage.setItem('iron-mario-roster-hero-v1',"+hero_value+");localStorage.setItem('iron-mario-roster-motion-v1',"+motion_value+");return true;}catch(e){return false;}})()",true)==true
func reflow() -> void:
	if not is_instance_valid(main): return
	mobile=size.x<720
	main.vertical=mobile; roster.columns=2 if size.x<850 else 4
	column.move_child(roster,2 if mobile else 4)
	if not mobile:
		column.move_child(main,2); column.move_child(roster_title,3); column.move_child(roster,4)
	roster_title.visible=not mobile; stage_power.visible=mobile
	var gutter: int=16 if mobile else 28
	var margin: MarginContainer=column.get_parent()
	for side in ['left','right']: margin.add_theme_constant_override('margin_'+side,gutter)
	preview_title.add_theme_font_size_override('font_size',20 if mobile else 26)
	hero_name.add_theme_font_size_override('font_size',38 if mobile else 52)
	stage.custom_minimum_size=Vector2(0,330 if mobile else clampf(size.y-350,350,620))
	stage.size_flags_stretch_ratio=1.55
	details.custom_minimum_size.x=0 if mobile else 290
	details.size_flags_stretch_ratio=1.0
	footer.text='TAP A HERO / DEMONSTRATE THEIR POWER' if mobile else 'LEFT / RIGHT: SWITCH    |    SPACE: POWER    |    ENTER: EQUIP    |    GAMEPAD: D-PAD / X / A'
	last_width=size.x
	if OS.has_feature('web'):
		JavaScriptBridge.eval("document.getElementById('canvas').dataset.selectorWidth="+JSON.stringify(str(size.x))+";",true)
func select_hero(index: int, audible: bool=true) -> void:
	selected=posmod(index,HeroRoster.HEROES.size())
	stage.set_hero(HeroRoster.hero(selected)); update_selection()
	if audible: play_tone(false)
func update_selection() -> void:
	var spec: Dictionary=HeroRoster.hero(selected)
	subtitle.text=spec.title; subtitle.add_theme_color_override('font_color',Color(spec.color))
	hero_name.text=spec.name; trait_label.text=spec.trait; story.text=spec.story
	ability.text=spec.ability; ability.add_theme_color_override('font_color',Color(spec.secondary))
	ability_text.text=spec.ability_text
	var equipped: bool=Profile.data.hero==spec.id
	equip_button.text='EQUIPPED' if equipped else 'EQUIP HERO'; equip_button.disabled=equipped
	demo_button.text='POWER ACTIVE…' if stage.demo_time>=0 else 'DEMONSTRATE POWER'
	stage_power.text='POWER ACTIVE…' if stage.demo_time>=0 else 'POWER PREVIEW'
	motion_button.text='STILL' if Profile.data.settings.get('reduced_motion',false) else 'MOTION'
	status.text=('YOUR ACTIVE HERO  /  ' if equipped else 'READY TO EQUIP  /  ')+'MASTERY '+str(1+int(Profile.data.mastery.get(spec.id,0))/100)
	for i in portraits.size():
		var color := Color(HeroRoster.hero(i).color)
		portraits[i].add_theme_stylebox_override('normal',HeroDesign.style(HeroDesign.PANEL.lightened(0.07) if selected==i else HeroDesign.NIGHT,color if selected==i else HeroDesign.LINE,8))
		portraits[i].tooltip_text=HeroRoster.hero(i).name+' — '+HeroRoster.hero(i).role
	if OS.has_feature('web'):
		var announcement: String='Selected '+spec.name+'. '+spec.role+'. '+('Equipped. ' if equipped else 'Press Enter to equip. ')+('Power demonstration active. ' if stage.demo_time>=0 else 'Press Space for the power demonstration. ')+ 'Use Left and Right to switch heroes.'
		JavaScriptBridge.eval("var live=document.getElementById('hero-a11y'); if(live)live.textContent="+JSON.stringify(announcement)+";",true)
		JavaScriptBridge.eval("document.getElementById('hero-a11y').dataset.saveError="+JSON.stringify(Profile.last_error)+";document.getElementById('hero-a11y').dataset.persistent="+JSON.stringify(str(OS.is_userfs_persistent()))+";",true)
func equip() -> bool:
	if not Profile.equip_hero(HeroRoster.hero(selected).id):
		status.text='Could not save your hero. Please try again.'
		return false
	update_selection(); play_tone(false)
	if not persist_browser_preferences(): status.text='Equipped for this visit. Browser storage is unavailable.'
	Music.play_menu(Profile.data.hero)
	return true
func demonstrate() -> void:
	stage.demonstrate(); update_selection(); play_tone(true)
func toggle_motion() -> void:
	Profile.data.settings.reduced_motion=not Profile.data.settings.get('reduced_motion',false)
	Profile.save_profile(); update_selection(); persist_browser_preferences()
func launch() -> void:
	if Profile.data.hero!=HeroRoster.hero(selected).id and not equip(): return
	play_requested.emit(HeroRoster.hero(selected).game)
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_LEFT: select_hero(selected-1)
			KEY_RIGHT: select_hero(selected+1)
			KEY_SPACE: demonstrate()
			KEY_ENTER: equip()
			_: return
		get_viewport().set_input_as_handled()
	elif event is InputEventJoypadButton and event.pressed:
		match event.button_index:
			JOY_BUTTON_DPAD_LEFT,JOY_BUTTON_LEFT_SHOULDER: select_hero(selected-1)
			JOY_BUTTON_DPAD_RIGHT,JOY_BUTTON_RIGHT_SHOULDER: select_hero(selected+1)
			JOY_BUTTON_X: demonstrate()
			JOY_BUTTON_A: equip()
			_: return
		get_viewport().set_input_as_handled()
func play_tone(power: bool) -> void:
	# Short original synthesized cues. No downloaded or unlicensed audio.
	var stream := AudioStreamWAV.new(); stream.format=AudioStreamWAV.FORMAT_16_BITS; stream.mix_rate=22050
	var length: int=6600 if power else 2200
	var data := PackedByteArray(); data.resize(length*2)
	var base: float=[330.0,520.0,180.0,440.0][selected]
	for i in length:
		var t: float=i/22050.0; var p: float=i/float(length)
		var frequency: float=base*(1.0+p*(1.5 if power else 0.2))
		var envelope: float=sin(p*PI)*pow(1-p,2)
		var sample: float=(sin(t*frequency*TAU)+sin(t*frequency*TAU*1.5)*0.2)*envelope
		data.encode_s16(i*2,int(sample*7500))
	stream.data=data; sound.stream=stream
	var volume: float=float(Profile.data.settings.get('volume',80.0))/100.0
	sound.volume_db=linear_to_db(maxf(0.0001,volume)); sound.play()
