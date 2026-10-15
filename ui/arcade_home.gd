class_name ArcadeHome
extends Control
var app: Control
var column: VBoxContainer
var feature: BoxContainer
var stage: HeroStage
var shelves: Array[GridContainer]=[]
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column=ArcadeLibrary.scaffold(self,app,'HOME')
	feature=BoxContainer.new(); feature.add_theme_constant_override('separation',24); column.add_child(feature)
	var intro := HeroDesign.column(12); intro.size_flags_horizontal=Control.SIZE_EXPAND_FILL; feature.add_child(intro)
	intro.add_child(HeroDesign.label('105 GAMES. SIX TOWN REGULARS.',12,HeroDesign.GOLD))
	intro.add_child(HeroDesign.label('A LITTLE GAME.\nA BIG MOMENT.',40))
	intro.add_child(HeroDesign.label('Fly, fight, solve and race through an arcade of bite-sized challenges.',17,HeroDesign.MUTED))
	intro.add_child(HeroDesign.button('PLAY A QUICK GAME',func()->void:app.start_run('quick'),HeroDesign.GOLD))
	intro.add_child(HeroDesign.button('CHOOSE YOUR CHARACTER',func()->void:app.show_page('HEROES')))
	stage=HeroStage.new(); stage.custom_minimum_size=Vector2(260,330); stage.size_flags_horizontal=Control.SIZE_EXPAND_FILL; feature.add_child(stage)
	for index in HeroRoster.HEROES.size():
		if HeroRoster.hero(index).id==Profile.data.hero: stage.set_hero(HeroRoster.hero(index)); break
	stage.reduced_motion=Profile.data.settings.get('reduced_motion',false)
	var modes := GridContainer.new(); modes.columns=2; modes.add_theme_constant_override('h_separation',10); column.add_child(modes)
	for mode in ['TOURNAMENT','DAILY CHALLENGE']:
		var b := HeroDesign.button(mode,func()->void:app.mode_preview('tournament' if mode=='TOURNAMENT' else 'daily')); b.size_flags_horizontal=Control.SIZE_EXPAND_FILL; modes.add_child(b)
	var recent: Array=Profile.data.recent.duplicate()
	for id in ['metro_armor_rush','shadow_armor_duel','scrap_hill_racer']:
		if not recent.has(id): recent.append(id)
	add_shelf('PICK UP AND PLAY',recent.slice(0,3))
	add_shelf('OLD-SCHOOL ENERGY',['reactor_merge','catapult_chaos','arc_snake'])
	add_shelf('COMIC CHAOS',['impossible_parking','brainrot_button_panic','chaos_elevator'])
	column.add_child(HeroDesign.button('EXPLORE ALL %d GAMES' % app.registry.games.size(),func()->void:app.show_page('GAMES'),HeroDesign.GOLD))
	resized.connect(reflow); reflow()
func add_shelf(title: String, ids: Array) -> void:
	column.add_child(HeroDesign.label(title,20))
	var shelf := GridContainer.new(); shelf.columns=3; shelf.add_theme_constant_override('h_separation',16); shelf.add_theme_constant_override('v_separation',16); column.add_child(shelf); shelves.append(shelf)
	for id in ids:
		if app.registry.lookup.has(id): shelf.add_child(ArcadeLibrary.card(app,app.registry.get_game(id),true))
func reflow() -> void:
	if not is_instance_valid(feature): return
	feature.vertical=size.x<700; stage.custom_minimum_size=Vector2(0 if size.x<700 else 260,300 if size.x<700 else 360)
	for shelf in shelves: shelf.columns=1 if size.x<600 else (2 if size.x<1000 else 3)
	var margin: MarginContainer=column.get_parent()
	for side in ['left','right']: margin.add_theme_constant_override('margin_'+side,16 if size.x<600 else 28)
