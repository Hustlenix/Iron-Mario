extends Control

var registry := GameRegistry.new()
var router := InputRouter.new()
var run: RunDirector
var page: Control
var body: VBoxContainer
var content: Control
var top: HBoxContainer
var modal: Control
var rotate_cover: Control
var current_game: MicrogameBase
var game_layer: Node2D
var title_label: Label
var time_bar: ProgressBar
var status_label: Label
var hint_label: Label
var profile_label: Label
var input_hint: String = ''
var current_id: String = ''
var current_page: String = 'HOME'
var category: String = 'ALL'
var search_text: String = ''
var run_xp: int = 0
var run_coins: int = 0
var manual_pause: bool = false
var orientation_pause: bool = false
var transitioning: bool = false
var generation: int = 0
var standalone_difficulty: float = 1.0
var sfx: AudioStreamPlayer
var cursor_layer: Node2D
var services := PlatformServices.new()
var library_page: int = 0
var library_sort: String = 'A-Z'
const HERO_IDS := ['dart','bolt','echo','frost','tether','snap','aegis','pulse','lance','flappy']
const HERO_WORLDS := ['Cardboard city','Electric rooftops','Haunted hallway','Notebook snow','Junkyard','Paint factory','Marker desert','Doodle space','Laboratory','Notebook ocean']

func _ready() -> void:
	theme = Design.theme()
	process_mode = Node.PROCESS_MODE_ALWAYS
	RenderingServer.set_default_clear_color(Design.PAPER)
	add_child(router)
	add_child(services)
	router.routed.connect(route_action)
	router.pause_requested.connect(toggle_pause)
	router.device_changed.connect(func(_device: String) -> void: update_hint())
	sfx = AudioStreamPlayer.new()
	add_child(sfx)
	cursor_layer = Node2D.new()
	cursor_layer.z_index = 50
	add_child(cursor_layer)
	cursor_layer.draw.connect(draw_cursor)
	resized.connect(layout_game)
	apply_settings()
	services.log_event('app_open')
	show_page('HOME')
	if not Profile.data.get('onboarded',false):
		show_modal('A TINY WORLD. A BIG HERO.','One command. A few seconds. You have got this.',[
			['LET’S TRY IT',func() -> void:
				Profile.data.onboarded = true
				Profile.save_profile()
				close_modal()
				start_run('single','target_lock')],
			['EXPLORE FIRST',func() -> void:
				Profile.data.onboarded = true
				Profile.save_profile()
				close_modal()]])

func clear_page() -> void:
	generation += 1
	router.enabled = false
	router.reset()
	current_game = null
	game_layer = null
	close_modal()
	if is_instance_valid(page):
		remove_child(page)
		page.queue_free()
	page = Control.new()
	page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(page)
	var background := ColorRect.new()
	background.color = Design.PAPER
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	page.add_child(background)
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for side in ['left','right']: margin.add_theme_constant_override('margin_'+side,32)
	for side in ['top','bottom']: margin.add_theme_constant_override('margin_'+side,18)
	page.add_child(margin)
	body = Design.column(16)
	margin.add_child(body)

func show_page(name: String) -> void:
	manual_pause = false
	transitioning = false
	run = null
	current_page = name
	clear_page()
	Music.play_menu(Profile.data.hero)
	build_top()
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(scroll)
	content = Design.column(18)
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(content)
	match name:
		'HOME': build_home()
		'GAMES': build_games()
		'HEROES': build_heroes()
		'MISSIONS': build_missions()
		'SHOP': build_shop()
		'PROFILE': build_profile()
		'SETTINGS': build_settings()
	var nav := Design.row(10)
	body.add_child(nav)
	for destination in ['HOME','GAMES','HEROES','MISSIONS','SHOP','PROFILE']:
		var btn := Design.button(destination,func() -> void: show_page(destination),Design.GOLD if destination==name else Design.PAPER)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		nav.add_child(btn)
	layout_game()

func build_top() -> void:
	top = Design.row(16)
	body.add_child(top)
	profile_label = Design.label('LV %d  /  %d XP' % [1+int(Profile.data.xp)/250,int(Profile.data.xp)%250],22)
	top.add_child(profile_label)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer)
	top.add_child(Design.label('%d COINS' % int(Profile.data.coins),24))
	top.add_child(Design.button('SETTINGS',func() -> void: show_page('SETTINGS')))

func heading(kicker: String, name: String, subtitle: String = '') -> void:
	content.add_child(Design.label(kicker,19,Design.RED))
	content.add_child(Design.label(name,44))
	if subtitle!='': content.add_child(Design.label(subtitle,21))

func build_home() -> void:
	var row := Design.row(26)
	content.add_child(row)
	var left := Design.column(8)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(left)
	left.add_child(Design.label('SMALL GAMES. SUPER ENERGY.',17,Design.RED))
	left.add_child(Design.label('SUPER-MICRO\nHEROES',40))
	left.add_child(Design.label('A whole arcade, drawn by hand.',20))
	var play := Design.button('PLAY  >',func() -> void: start_run('quick'),Design.GOLD)
	play.custom_minimum_size.y = 64
	play.add_theme_font_size_override('font_size',38)
	left.add_child(play)
	var modes := Design.row()
	left.add_child(modes)
	for choice in ['TOURNAMENT','DAILY CHALLENGE']:
		var btn := Design.button(choice,func() -> void: mode_preview('tournament' if choice=='TOURNAMENT' else 'daily'),Design.GREEN if choice=='TOURNAMENT' else Design.BLUE)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		modes.add_child(btn)
	var world := PaintWorld.new()
	world.hero_id = Profile.data.hero
	world.custom_minimum_size = Vector2(340,300)
	world.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(world)
	content.add_child(Design.label('YOUR NEXT LITTLE ADVENTURE',21))
	var recent: Array = Profile.data.recent.duplicate()
	for id in ['arc_dash','reactor_parry','rocket_rescue']:
		if not recent.has(id): recent.append(id)
	var cards := Design.row(15)
	content.add_child(cards)
	for id in recent.slice(0,3):
		if registry.lookup.has(id): cards.add_child(game_card(registry.get_game(id),true))
	for section in [['FEATURED CABINETS',['metro_armor_rush','shadow_armor_duel','scrap_hill_racer']],['NOSTALGIA COLLECTION',['reactor_merge','catapult_chaos','arc_snake']],['BRAINROT ARCADE',['impossible_parking','brainrot_button_panic','chaos_elevator']]]:
		content.add_child(Design.label(section[0],25))
		var shelf := Design.row(15)
		content.add_child(shelf)
		for id in section[1]:
			if registry.lookup.has(id): shelf.add_child(game_card(registry.get_game(id),true))
	content.add_child(Design.button('EXPLORE ALL %d GAMES' % registry.games.size(),func()->void:show_page('GAMES'),Design.BLUE))

func game_card(spec: Dictionary, compact: bool = false) -> Control:
	var panel := Design.panel(Color('#f8e4ab') if compact else Design.PAPER)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var col := Design.column(8)
	panel.add_child(col)
	var cover: Control = load('res://ui/game_thumbnail.gd').new()
	cover.entry=spec
	col.add_child(cover)
	var card_header := Design.row(8)
	col.add_child(card_header)
	var glyph: Control = load('res://ui/game_glyph.gd').new()
	glyph.category = spec.category
	card_header.add_child(glyph)
	card_header.add_child(Design.label(String(spec.category).to_upper()+' / '+String(spec.input),16,Design.RED))
	var card_title := Design.label(spec.name,25)
	card_title.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	col.add_child(card_title)
	if not compact:
		var description := Design.label(spec.get('description',spec.objective),17)
		description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
		col.add_child(description)
	var record: Dictionary = Profile.data.records.get(spec.id,{})
	col.add_child(Design.label('BEST %d   /   %d MEDALS' % [int(record.get('best',0)),int(record.get('stars',0))],17))
	var actions := Design.row(8)
	col.add_child(actions)
	var play := Design.button('PLAY',func() -> void: start_run('single',spec.id),Design.GOLD)
	play.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	actions.add_child(play)
	if not compact:
		var fav := Design.button('SAVED' if Profile.data.favorites.has(spec.id) else '+ SAVE',func() -> void:
			Profile.toggle_favorite(spec.id)
			show_page('GAMES'))
		actions.add_child(fav)
		col.add_child(Design.button('PREVIEW / CONTROLS',func()->void:
			show_modal(spec.name,spec.get('description',spec.objective)+'\n\n'+spec.hint+'\n\n'+str(spec.duration)+' SECOND CHALLENGE',[
				['PLAY',func()->void:start_run('single',spec.id)],['BACK',close_modal]])))
	return panel

func build_games() -> void:
	heading('PICK YOUR NEXT OBSESSION','THE GAME BOX','%d real games. Tiny challenges and full arcade cabinets.' % registry.games.size())
	var filters := Design.row()
	content.add_child(filters)
	var search := LineEdit.new()
	search.placeholder_text = 'Find a game...'
	search.text = search_text
	search.custom_minimum_size = Vector2(240,52)
	search.add_theme_font_size_override('font_size',22)
	filters.add_child(search)
	var categories := OptionButton.new()
	categories.custom_minimum_size = Vector2(240,52)
	var names: Array = ['ALL','FAVORITES','RECENT','NEW','NOSTALGIA','BRAINROT']
	for game in registry.games:
		if not names.has(game.category): names.append(game.category)
	for name in names: categories.add_item(name)
	categories.select(maxi(0,names.find(category)))
	filters.add_child(categories)
	var diff := OptionButton.new()
	for name in ['RELAXED','QUICK','WILD']: diff.add_item(name)
	diff.select(int(standalone_difficulty)-1)
	diff.custom_minimum_size = Vector2(190,52)
	diff.item_selected.connect(func(index: int) -> void: standalone_difficulty = index+1)
	filters.add_child(diff)
	var sort := OptionButton.new()
	for name in ['A-Z','NEW FIRST','YOUR BEST']: sort.add_item(name)
	sort.select(['A-Z','NEW FIRST','YOUR BEST'].find(library_sort))
	content.add_child(sort)
	var grid := GridContainer.new()
	grid.columns = 2 if size.x < 1100 else 3
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override('h_separation',16)
	grid.add_theme_constant_override('v_separation',16)
	content.add_child(grid)
	var pager := Design.row()
	content.add_child(pager)
	var refill := func() -> void:
		for child in grid.get_children():
			grid.remove_child(child)
			child.queue_free()
		var entries: Array = registry.games
		if category=='RECENT': entries = Profile.data.recent.map(func(id: String) -> Dictionary: return registry.get_game(id))
		var filtered: Array = []
		for spec in entries:
			if spec.is_empty(): continue
			if category=='FAVORITES' and not Profile.data.favorites.has(spec.id): continue
			if category in ['NEW','NOSTALGIA','BRAINROT']:
				if category=='NEW' and not spec.script.begins_with('res://games/') and spec.script!='res://microgames/pack_c.gd': continue
				if category!='NEW' and spec.get('collection','')!=category: continue
			elif category not in ['ALL','FAVORITES','RECENT'] and spec.category!=category: continue
			if search_text!='' and not String(spec.name).to_lower().contains(search_text.to_lower()): continue
			filtered.append(spec)
		if library_sort=='A-Z': filtered.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return a.name<b.name)
		elif library_sort=='NEW FIRST': filtered.reverse()
		else: filtered.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return int(Profile.data.records.get(a.id,{}).get('best',0))>int(Profile.data.records.get(b.id,{}).get('best',0)))
		var pages: int = maxi(1,ceili(filtered.size()/12.0))
		library_page=clampi(library_page,0,pages-1)
		for spec in filtered.slice(library_page*12,(library_page+1)*12): grid.add_child(game_card(spec))
		for child in pager.get_children(): pager.remove_child(child); child.queue_free()
		var previous := Design.button('< PREVIOUS',func()->void:library_page=maxi(0,library_page-1);show_page('GAMES'))
		previous.disabled=library_page==0
		pager.add_child(previous)
		pager.add_child(Design.label('PAGE %d / %d / %d GAMES' % [library_page+1,pages,filtered.size()],20))
		var next := Design.button('NEXT >',func()->void:library_page+=1;show_page('GAMES'))
		next.disabled=library_page>=pages-1
		pager.add_child(next)
		if grid.get_child_count()==0: grid.add_child(Design.label('Nothing here yet. Try another filter.',24))
	search.text_changed.connect(func(value: String) -> void:
		search_text = value
		library_page=0
		refill.call())
	categories.item_selected.connect(func(index: int) -> void:
		category = names[index]
		library_page=0
		refill.call())
	sort.item_selected.connect(func(index:int)->void:library_sort=['A-Z','NEW FIRST','YOUR BEST'][index];library_page=0;refill.call())
	refill.call()

func build_heroes() -> void:
	heading('YOUR HAND-DRAWN CREW','TEN TINY LEGENDS','Pick a silhouette. Build mastery. Every hero plays fair.')
	var grid := GridContainer.new()
	grid.columns = 2 if size.x < 1100 else 3
	grid.add_theme_constant_override('h_separation',18)
	grid.add_theme_constant_override('v_separation',18)
	content.add_child(grid)
	for i in HERO_IDS.size():
		var id: String = HERO_IDS[i]
		var card := Design.panel()
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		grid.add_child(card)
		var col := Design.column(6)
		card.add_child(col)
		var portrait := PaintWorld.new()
		portrait.hero_id = id
		portrait.custom_minimum_size = Vector2(280,175)
		col.add_child(portrait)
		col.add_child(Design.label(id.to_upper(),29))
		col.add_child(Design.label(HERO_WORLDS[i],18))
		col.add_child(Design.label('MASTERY %d' % (1+int(Profile.data.mastery.get(id,0))/100),19))
		col.add_child(Design.button('EQUIPPED' if Profile.data.hero==id else 'CHOOSE',func() -> void:
			Profile.equip_hero(id)
			show_page('HEROES'),Design.GOLD if Profile.data.hero==id else Design.PAPER))

func build_missions() -> void:
	heading('A LITTLE SOMETHING EXTRA','TODAY’S MISSIONS','Play because it is fun. Pick up a bonus along the way.')
	for mission in Profile.mission_progress():
		var card := Design.panel()
		content.add_child(card)
		var row := Design.row(20)
		card.add_child(row)
		var text := Design.label('%s  /  %d of %d' % [mission.get('title',mission.id),mission.progress,mission.target],25)
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(text)
		var btn := Design.button('CLAIMED' if mission.claimed else '+%d COINS' % mission.reward,func() -> void:
			Profile.claim_mission(mission.id)
			show_page('MISSIONS'),Design.GOLD)
		btn.disabled = mission.claimed or mission.progress < mission.target
		row.add_child(btn)
	content.add_child(Design.label('ACHIEVEMENTS',28))
	for achievement in Profile.data.achievements:
		content.add_child(Design.label(String(achievement).replace('_',' ').to_upper(),22,Design.BLUE))
	if Profile.data.achievements.is_empty(): content.add_child(Design.label('Your first win starts the collection.',22))

func build_shop() -> void:
	heading('EARN IT. WEAR IT.','THE PAINT SHOP','Spend play-earned coins on your finishing touch.')
	for item in [['confetti','CONFETTI CREW',100,'Double paint splashes'],['midnight','MIDNIGHT INK',180,'Blue arena paper'],['sunshine','SUNSHINE PAPER',180,'Yellow arena paper']]:
		var card := Design.panel()
		content.add_child(card)
		var row := Design.row(20)
		card.add_child(row)
		var title := Design.label(item[1]+'  /  '+item[3],25)
		title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(title)
		var owned: bool = Profile.data.owned.has(item[0])
		row.add_child(Design.button('EQUIPPED' if Profile.data.equipped_cosmetic==item[0] else ('EQUIP' if owned else '%d COINS' % item[2]),func() -> void:
			if owned or Profile.buy_cosmetic(item[0],item[2]):
				Profile.data.equipped_cosmetic = item[0]
				Profile.save_profile()
				show_page('SHOP')
			else: show_modal('A FEW MORE COINS','Play a few games and come back.',[['GOT IT',close_modal]]),Design.GOLD))
	content.add_child(Design.button('USE ORIGINAL PAPER',func() -> void:
		Profile.data.equipped_cosmetic = ''
		Profile.save_profile()
		show_page('SHOP')))

func build_profile() -> void:
	heading('EVERY LITTLE WIN COUNTS','YOUR STORY SO FAR')
	for line in ['LEVEL %d  /  %d XP' % [1+int(Profile.data.xp)/250,Profile.data.xp],'%d GAMES PLAYED  /  %d WINS' % [Profile.data.total_plays,Profile.data.total_wins],'TOURNAMENT BEST  %d' % Profile.data.tournament_best,'BEST STREAK  %d' % Profile.data.best_streak,'TODAY’S BEST  %d' % Profile.data.daily.get('best',0)]:
		var card := Design.panel()
		card.add_child(Design.label(line,29))
		content.add_child(card)
	content.add_child(Design.label('Saved on this device. No account, no energy meter, just play.',22))

func build_settings() -> void:
	heading('MAKE YOURSELF AT HOME','SOUND & COMFORT')
	for setting in [['volume','SOUND EFFECTS'],['music_volume','MUSIC']]:
		var row := Design.row()
		content.add_child(row)
		var label := Design.label(setting[1],25)
		label.custom_minimum_size.x = 260
		row.add_child(label)
		var slider := HSlider.new()
		slider.min_value = 0
		slider.max_value = 100
		slider.value = Profile.data.settings.get(setting[0],70)
		slider.custom_minimum_size = Vector2(450,60)
		slider.value_changed.connect(func(value: float) -> void:
			Profile.data.settings[setting[0]] = value
			apply_settings()
			Profile.save_profile())
		row.add_child(slider)
	for setting in [['shake','SCREEN REACTIONS'],['haptics','TOUCH VIBRATION']]:
		var toggle := CheckButton.new()
		toggle.text = setting[1]
		toggle.button_pressed = Profile.data.settings.get(setting[0],true)
		toggle.custom_minimum_size.y = 58
		toggle.add_theme_font_size_override('font_size',24)
		toggle.add_theme_color_override('font_color',Design.INK)
		toggle.toggled.connect(func(value: bool) -> void:
			Profile.data.settings[setting[0]] = value
			Profile.save_profile())
		content.add_child(toggle)
	content.add_child(Design.button('FULLSCREEN',func() -> void:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if DisplayServer.window_get_mode()!=DisplayServer.WINDOW_MODE_FULLSCREEN else DisplayServer.WINDOW_MODE_WINDOWED)))
	content.add_child(Design.label('Mouse / touch: tap, hold, drag or swipe.\nKeyboard: arrows / WASD, Space. Controller: stick / D-pad, A.\nPause: Escape / Start. Aiming games: move the crosshair, then press.',22))
	content.add_child(Design.label('IRON-MARIO / SUPER-MICRO HEROES / ARCADE 3.0',18,Design.RED))
	var credits := Design.label('Room artwork: Modern Interiors by LimeZu — https://limezu.itch.io/\nOriginal hand-drawn game art and original music. Other supplied packs remain excluded until rights are verified.',18)
	credits.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	content.add_child(credits)

func apply_settings() -> void:
	var music_bus: int = AudioServer.get_bus_index('Music')
	if music_bus>=0: AudioServer.set_bus_volume_db(music_bus,linear_to_db(maxf(0.0001,Profile.data.settings.get('music_volume',70)/100.0)))
	if is_instance_valid(sfx): sfx.volume_db = linear_to_db(maxf(0.0001,Profile.data.settings.get('volume',80)/100.0))

func mode_preview(mode: String) -> void:
	if mode=='tournament':
		show_modal('FIVE HEARTS. HOW FAR?','The entire game box. Faster every five rounds.\nBuild a streak. Beat your best.',[['LET’S GO',func() -> void: start_run('tournament')],['BACK',close_modal]])
	else:
		var director := RunDirector.new()
		var ids: Array = director.daily_ids(registry.tournament_ids(),Time.get_date_string_from_system(true))
		var names: String = ''
		for id in ids.slice(0,5): names += String(registry.get_game(id).get('name',id))+'  /  '
		show_modal('TODAY’S TEN','Same date. Same games.\n'+RunDirector.daily_modifier(Time.get_date_string_from_system(true)).replace('_',' ').to_upper()+'  /  '+names+'...\nBEST  %d' % Profile.data.daily.get('best',0),[['PLAY TODAY',func() -> void: start_run('daily')],['BACK',close_modal]])

func start_run(mode: String, id: String = '') -> void:
	services.log_event('play_pressed',{'mode':mode})
	clear_page()
	manual_pause = false
	current_page = 'PLAY'
	run = RunDirector.new()
	run.begin(mode,registry.tournament_ids() if mode in ['tournament','daily'] else registry.ids(),Time.get_date_string_from_system(true))
	run_xp = 0
	run_coins = 0
	if mode in ['single','quick']:
		current_id = id if id!='' else String(registry.tournament_ids().pick_random())
		run.current_id = current_id
	else: current_id = run.next_id()
	Music.play('gauntlet',0.3)
	launch_game()

func launch_game() -> void:
	var saved_run: RunDirector = run
	clear_page()
	run = saved_run
	transitioning = true
	var spec: Dictionary = registry.get_game(current_id)
	if spec.is_empty():
		show_page('GAMES')
		return
	top = Design.row()
	body.add_child(top)
	title_label = Design.label(spec.objective,36)
	title_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(title_label)
	status_label = Design.label('READY',22)
	top.add_child(status_label)
	top.add_child(Design.button('II  PAUSE',toggle_pause))
	time_bar = ProgressBar.new()
	time_bar.show_percentage = false
	time_bar.custom_minimum_size.y = 14
	time_bar.max_value = 1
	time_bar.value = 1
	var fill := StyleBoxFlat.new()
	fill.bg_color = Design.RED
	time_bar.add_theme_stylebox_override('fill',fill)
	body.add_child(time_bar)
	var area := Control.new()
	area.name = 'Arena'
	area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(area)
	game_layer = Node2D.new()
	page.add_child(game_layer)
	current_game = registry.create(current_id)
	game_layer.add_child(current_game)
	current_game.completed.connect(game_completed)
	current_game.impact.connect(game_impact)
	var difficulty: float = standalone_difficulty if run.mode in ['single','quick'] else run.difficulty
	var seed_value: int = (Time.get_date_string_from_system(true)+current_id+str(run.round_index)).hash() if run.mode=='daily' else 0
	current_game.start(spec,difficulty,seed_value)
	services.log_event('game_started',{'id':current_id,'mode':run.mode})
	current_game.hero_id = Profile.data.hero
	current_game.cosmetic = Profile.data.equipped_cosmetic
	current_game.active = false
	if run.special_round: title_label.text = 'CHAOS ROUND!  /  '+String(spec.objective)
	elif run.mode=='tournament' and run.round_index>0 and run.round_index%5==0: title_label.text = 'SPEED UP!  /  '+String(spec.objective)
	router.mode = spec.input
	input_hint = spec.get('hint',spec.input)
	hint_label = Design.label('',23)
	hint_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	hint_label.tooltip_text=input_hint
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(hint_label)
	update_hint()
	area.resized.connect(layout_game)
	await get_tree().process_frame
	layout_game()
	var wipe: Control = load('res://ui/paint_wipe.gd').new()
	page.add_child(wipe)
	var token: int = generation
	await get_tree().create_timer(0.7 if run.round_index<5 else 0.4).timeout
	if token!=generation or not is_instance_valid(current_game): return
	transitioning = false
	title_label.text = spec.objective
	refresh_pause()

func route_action(action: String, point: Vector2, value: Vector2) -> void:
	if is_instance_valid(current_game) and current_game.active and not current_game.finished:
		current_game.handle_action(action,point,value)

func game_impact(_point: Vector2, good: bool) -> void:
	play_sound('tick' if good else 'fail')
	if Profile.data.settings.get('haptics',true) and router.device=='touch': Input.vibrate_handheld(18 if good else 45)

func play_sound(name: String) -> void:
	sfx.stream = load('res://assets/audio/'+name+'.wav')
	sfx.pitch_scale = randf_range(0.96,1.06)
	sfx.play()

func game_completed(won: bool, score: int) -> void:
	services.log_event('game_completed' if won else 'game_failed',{'id':current_id,'score':score})
	router.enabled = false
	router.reset()
	transitioning = true
	play_sound('win' if won else 'fail')
	title_label.text = 'NICE!' if won else 'OOPS!'
	title_label.add_theme_color_override('font_color',Design.GREEN if won else Design.RED)
	var reward: Dictionary = Profile.record_game(current_id,won,score,registry.get_game(current_id).category)
	run_xp += int(reward.get('xp',0))
	run_coins += int(reward.get('coins',0))
	run.submit(won,score)
	if Profile.data.settings.get('shake',true):
		var tween := create_tween()
		tween.tween_property(game_layer,'rotation',-0.012 if won else 0.018,0.05)
		tween.tween_property(game_layer,'rotation',0.0,0.12)
	var token: int = generation
	await get_tree().create_timer(0.65).timeout
	if token!=generation: return
	if run.mode in ['single','quick'] or run.finished:
		show_results(won)
	else:
		if run.round_index%5==0: Music.play('danger',0.3)
		current_id = run.next_id()
		launch_game()

func show_results(won: bool) -> void:
	var old_run: RunDirector = run
	Profile.finish_run(run.mode,run.score,run.best_streak)
	clear_page()
	run = old_run
	transitioning = false
	build_top()
	var result_scroll := ScrollContainer.new()
	result_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	result_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(result_scroll)
	var row := Design.row(35)
	row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	result_scroll.add_child(row)
	var world := PaintWorld.new()
	world.hero_id = Profile.data.hero
	world.pose = 'victory' if won or run.score>0 else 'defeat'
	world.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	world.custom_minimum_size.x = 300
	row.add_child(world)
	var col := Design.column(14)
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(col)
	col.add_child(Design.label('THAT’S A WRAP!',36))
	col.add_child(Design.label('%d POINTS' % run.score,36,Design.RED))
	col.add_child(Design.label('%d ROUNDS  /  BEST STREAK %d' % [run.round_index,run.best_streak],23))
	var reward_label := Design.label('+%d XP    +%d COINS' % [run_xp,run_coins],25)
	col.add_child(reward_label)
	reward_label.modulate = Color(1,1,1,0.2)
	create_tween().tween_property(reward_label,'modulate',Color.WHITE,0.3)
	col.add_child(Design.label('%s MASTERY  %d' % [String(Profile.data.hero).to_upper(),Profile.data.mastery.get(Profile.data.hero,0)],22))
	var xp := ProgressBar.new()
	xp.max_value = 250
	xp.custom_minimum_size.y = 24
	xp.show_percentage = false
	col.add_child(xp)
	create_tween().tween_property(xp,'value',float(int(Profile.data.xp)%250),0.4)
	col.add_child(Design.button('PLAY AGAIN  >',func() -> void: start_run(old_run.mode,current_id if old_run.mode=='single' else ''),Design.GOLD))
	col.add_child(Design.button('GAME BOX',func() -> void: show_page('GAMES')))
	col.add_child(Design.button('HOME',func() -> void: show_page('HOME')))
	Music.play_menu(Profile.data.hero)

func update_hint() -> void:
	if not is_instance_valid(hint_label): return
	var suffix: String = 'TOUCH' if router.device=='touch' else ('STICK + A' if router.device=='controller' else 'MOUSE / ARROWS + SPACE')
	hint_label.text = input_hint+'   /   '+suffix

func layout_game() -> void:
	if is_instance_valid(game_layer) and is_instance_valid(body):
		var area: Control = body.get_node_or_null('Arena')
		if area:
			var amount: float = minf(area.size.x/960.0,area.size.y/480.0)
			game_layer.scale = Vector2.ONE*amount
			game_layer.position = area.global_position+(area.size-Vector2(960,480)*amount)/2
			router.board = Rect2(game_layer.position,Vector2(960,480)*amount)
	var portrait: bool = size.y>size.x
	if portrait != orientation_pause:
		orientation_pause = portrait
		if portrait:
			rotate_cover = ColorRect.new()
			rotate_cover.z_index = 100
			rotate_cover.color = Design.PAPER
			rotate_cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			add_child(rotate_cover)
			var center := CenterContainer.new()
			center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			rotate_cover.add_child(center)
			var label := Design.label('TURN YOUR PHONE\n\n<  [ SUPER-MICRO HEROES ]  >\n\nYour game will wait for you.',36)
			label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			center.add_child(label)
			label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			label.custom_minimum_size.x = maxf(260.0,size.x-120)
		else:
			if is_instance_valid(rotate_cover): rotate_cover.queue_free()
		refresh_pause()

func toggle_pause() -> void:
	if not is_instance_valid(current_game) or current_game.finished: return
	manual_pause = not manual_pause
	refresh_pause()
	if manual_pause:
		show_modal('TAKE A BREATHER','Your tiny adventure is waiting.',[['RESUME',func() -> void:
			manual_pause = false
			close_modal()
			refresh_pause()],['RESTART',func() -> void: start_run(run.mode,current_id)],['HOME',func() -> void: show_page('HOME')]])
	else: close_modal()

func refresh_pause() -> void:
	var active: bool = not manual_pause and not orientation_pause and not transitioning
	if is_instance_valid(current_game):
		current_game.active = active
		if not active: current_game.cancel_input()
	router.enabled = active and is_instance_valid(current_game) and not current_game.finished
	if not active: router.reset()

func _notification(what: int) -> void:
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT and is_instance_valid(current_game) and not manual_pause and not current_game.finished:
		toggle_pause()

func _process(_delta: float) -> void:
	if is_instance_valid(current_game) and is_instance_valid(time_bar):
		time_bar.value = maxf(0,1.0-current_game.elapsed/current_game.duration)
		if is_instance_valid(status_label) and run:
			status_label.text = '%d HEARTS  /  %d PTS' % [run.lives,run.score] if run.mode not in ['single','quick'] else '%0.1fs' % maxf(0,current_game.duration-current_game.elapsed)
	if is_instance_valid(cursor_layer): cursor_layer.queue_redraw()

func draw_cursor() -> void:
	if router.enabled and router.device in ['keyboard','controller'] and router.mode in ['TAP','DRAG','HOLD','SWIPE']:
		var p: Vector2 = router.board.position+router.cursor*router.board.size.x/960.0
		cursor_layer.draw_circle(p,16,Design.RED,false,3)
		cursor_layer.draw_line(p-Vector2(24,0),p+Vector2(24,0),Design.INK,2)
		cursor_layer.draw_line(p-Vector2(0,24),p+Vector2(0,24),Design.INK,2)

func show_modal(title: String, detail: String, actions: Array) -> void:
	close_modal()
	modal = ColorRect.new()
	modal.color = Color(0.14,0.13,0.2,0.78)
	modal.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(modal)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	modal.add_child(center)
	var panel := Design.panel()
	panel.custom_minimum_size.x = minf(size.x-64,750)
	center.add_child(panel)
	var col := Design.column(18)
	panel.add_child(col)
	col.add_child(Design.label(title,35))
	var description := Design.label(detail,23)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.custom_minimum_size.x = minf(size.x-120,670)
	col.add_child(description)
	for i in actions.size():
		col.add_child(Design.button(actions[i][0],actions[i][1],Design.GOLD if i==0 else Design.PAPER))

func close_modal() -> void:
	if is_instance_valid(modal):
		remove_child(modal)
		modal.queue_free()
	modal = null
