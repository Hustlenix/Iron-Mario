class_name ArcadeLibrary
extends Control
var app: Control
var scroll: ScrollContainer
var column: VBoxContainer
var grid: GridContainer
var filters: GridContainer
var navigation: GridContainer
var pager: HBoxContainer
var count: Label
var search: LineEdit
var last_width: float=-1
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column=scaffold(self,app,'GAMES')
	scroll=column.get_parent().get_parent()
	column.add_child(HeroDesign.label('THE ARCADE',38))
	column.add_child(HeroDesign.label('Find your next challenge. Every cabinet is playable.',16,HeroDesign.MUTED))
	filters=GridContainer.new(); filters.columns=4; filters.add_theme_constant_override('h_separation',10); filters.add_theme_constant_override('v_separation',10); column.add_child(filters)
	search=LineEdit.new(); search.placeholder_text='Search games'; search.text=app.search_text; search.custom_minimum_size=Vector2(140,48); search.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	search.add_theme_font_size_override('font_size',16); search.add_theme_color_override('font_color',HeroDesign.INK); search.add_theme_stylebox_override('normal',HeroDesign.style(HeroDesign.PANEL)); search.add_theme_stylebox_override('focus',HeroDesign.style(HeroDesign.PANEL,HeroDesign.GOLD)); filters.add_child(search)
	search.add_theme_color_override('font_placeholder_color',HeroDesign.MUTED)
	search.add_theme_color_override('caret_color',HeroDesign.PAPER)
	var categories := OptionButton.new(); style_option(categories); filters.add_child(categories)
	var names: Array=['ALL','FAVORITES','RECENT','NEW','NOSTALGIA','BRAINROT']
	for spec in app.registry.games:
		if not names.has(spec.category): names.append(spec.category)
	for title in names: categories.add_item(String(title))
	categories.select(maxi(0,names.find(app.category)))
	var sorting := OptionButton.new(); style_option(sorting); filters.add_child(sorting)
	for title in ['A-Z','NEW FIRST','YOUR BEST']: sorting.add_item(title)
	sorting.select(maxi(0,['A-Z','NEW FIRST','YOUR BEST'].find(app.library_sort)))
	var difficulty := OptionButton.new(); style_option(difficulty); filters.add_child(difficulty)
	for title in ['RELAXED','QUICK','WILD']: difficulty.add_item(title)
	difficulty.select(clampi(int(app.standalone_difficulty)-1,0,2))
	difficulty.item_selected.connect(func(index:int)->void:app.standalone_difficulty=index+1)
	count=HeroDesign.label('',14,HeroDesign.MUTED); column.add_child(count)
	grid=GridContainer.new(); grid.columns=3; grid.add_theme_constant_override('h_separation',16); grid.add_theme_constant_override('v_separation',16); column.add_child(grid)
	pager=HeroDesign.row(8); column.add_child(pager)
	search.text_changed.connect(func(value:String)->void:app.search_text=value; app.library_page=0; refill())
	categories.item_selected.connect(func(index:int)->void:app.category=names[index]; app.library_page=0; refill())
	sorting.item_selected.connect(func(index:int)->void:app.library_sort=['A-Z','NEW FIRST','YOUR BEST'][index]; app.library_page=0; refill())
	resized.connect(reflow); refill(); reflow()
func reflow() -> void:
	if not is_instance_valid(grid): return
	grid.columns=1 if size.x<600 else (2 if size.x<1000 else 3)
	filters.columns=2 if size.x<800 else 4
	var margin: MarginContainer=column.get_parent()
	for side in ['left','right']: margin.add_theme_constant_override('margin_'+side,16 if size.x<600 else 28)
func refill() -> void:
	for child in grid.get_children(): grid.remove_child(child); child.queue_free()
	var entries: Array=[]
	var pool: Array=app.registry.games
	if app.category=='RECENT':
		pool=[]
		for id in Profile.data.recent:
			if app.registry.lookup.has(id): pool.append(app.registry.get_game(id))
	for spec in pool:
		if app.category=='FAVORITES' and not Profile.data.favorites.has(spec.id): continue
		if app.category in ['NEW','NOSTALGIA','BRAINROT']:
			if app.category=='NEW' and not spec.script.begins_with('res://games/') and spec.script!='res://microgames/pack_c.gd': continue
			if app.category!='NEW' and spec.get('collection','')!=app.category: continue
		elif app.category not in ['ALL','FAVORITES','RECENT'] and spec.category!=app.category: continue
		if not app.search_text.is_empty() and not String(spec.name).to_lower().contains(app.search_text.to_lower()): continue
		entries.append(spec)
	if app.library_sort=='A-Z': entries.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return a.name<b.name)
	elif app.library_sort=='NEW FIRST': entries.reverse()
	else: entries.sort_custom(func(a:Dictionary,b:Dictionary)->bool:return int(Profile.data.records.get(a.id,{}).get('best',0))>int(Profile.data.records.get(b.id,{}).get('best',0)))
	var pages: int=maxi(1,ceili(entries.size()/12.0)); app.library_page=clampi(app.library_page,0,pages-1)
	count.text='%d OF %d GAMES  /  PAGE %d OF %d' % [entries.size(),app.registry.games.size(),app.library_page+1,pages]
	for spec in entries.slice(app.library_page*12,(app.library_page+1)*12): grid.add_child(card(app,spec))
	if entries.is_empty(): grid.add_child(HeroDesign.label('No games match this selection. Try All or clear the search.',20))
	for child in pager.get_children(): pager.remove_child(child); child.queue_free()
	var previous := HeroDesign.button('PREVIOUS',func()->void:app.library_page-=1; refill(); scroll.scroll_vertical=0); previous.disabled=app.library_page==0; previous.size_flags_horizontal=Control.SIZE_EXPAND_FILL; pager.add_child(previous)
	var next := HeroDesign.button('NEXT',func()->void:app.library_page+=1; refill(); scroll.scroll_vertical=0); next.disabled=app.library_page==pages-1; next.size_flags_horizontal=Control.SIZE_EXPAND_FILL; pager.add_child(next)
	reflow()
static func style_option(option: OptionButton) -> void:
	option.custom_minimum_size=Vector2(140,48); option.size_flags_horizontal=Control.SIZE_EXPAND_FILL; option.add_theme_font_size_override('font_size',14)
	for state in ['normal','hover','pressed']: option.add_theme_stylebox_override(state,HeroDesign.style(HeroDesign.PANEL,HeroDesign.LINE,10))
	for state in ['font_color','font_hover_color','font_pressed_color']: option.add_theme_color_override(state,HeroDesign.INK)
	option.add_theme_stylebox_override('focus',HeroDesign.style(Color.TRANSPARENT,HeroDesign.GOLD,0))
static func scaffold(owner: Control, host: Control, destination: String) -> VBoxContainer:
	var bg := ColorRect.new(); bg.color=HeroDesign.PAPER; bg.mouse_filter=Control.MOUSE_FILTER_IGNORE; bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); owner.add_child(bg)
	var sc := ScrollContainer.new(); sc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT); sc.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED; owner.add_child(sc)
	var margin := MarginContainer.new(); margin.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	for side in ['left','right','top','bottom']: margin.add_theme_constant_override('margin_'+side,24)
	sc.add_child(margin)
	var col := HeroDesign.column(18); col.size_flags_horizontal=Control.SIZE_EXPAND_FILL; margin.add_child(col)
	var header := HeroDesign.row(8); col.add_child(header); header.add_child(HeroDesign.label('IRON-MARIO',20,HeroDesign.GOLD))
	var settings := HeroDesign.button('SETTINGS',func()->void:host.show_page('SETTINGS')); header.add_child(settings)
	var nav := GridContainer.new(); nav.columns=3; nav.add_theme_constant_override('h_separation',6); nav.add_theme_constant_override('v_separation',6); col.add_child(nav)
	for target in ['HOME','GAMES','HEROES','MISSIONS','SHOP','PROFILE']:
		var b := HeroDesign.button(target,func()->void:host.show_page(target),HeroDesign.GOLD if target==destination else HeroDesign.PANEL); b.size_flags_horizontal=Control.SIZE_EXPAND_FILL; nav.add_child(b)
	owner.resized.connect(func()->void:nav.columns=3 if owner.size.x<800 else 6)
	nav.columns=3 if owner.size.x<800 else 6
	col.add_child(HeroDesign.label('LEVEL %d   /   %d COINS' % [1+int(Profile.data.xp)/250,int(Profile.data.coins)],12,HeroDesign.MUTED))
	return col
static func card(host: Control, spec: Dictionary, compact: bool=false) -> Control:
	var panel := PanelContainer.new(); panel.size_flags_horizontal=Control.SIZE_EXPAND_FILL; panel.add_theme_stylebox_override('panel',HeroDesign.style(HeroDesign.PANEL,HeroDesign.LINE,14))
	var col := HeroDesign.column(10); panel.add_child(col)
	var aspect := AspectRatioContainer.new(); aspect.ratio=2.0; aspect.stretch_mode=AspectRatioContainer.STRETCH_FIT; aspect.size_flags_horizontal=Control.SIZE_EXPAND_FILL; col.add_child(aspect)
	aspect.resized.connect(func()->void:
		var desired: float=aspect.size.x/2.0
		if absf(aspect.custom_minimum_size.y-desired)>0.5: aspect.custom_minimum_size.y=desired)
	var cover: Control=load('res://ui/game_thumbnail.gd').new(); cover.entry=spec; aspect.add_child(cover)
	col.add_child(HeroDesign.label(String(spec.category).to_upper()+'  /  '+String(spec.input),12,HeroDesign.GOLD))
	col.add_child(HeroDesign.label(spec.name,24))
	if not compact: col.add_child(HeroDesign.label(spec.get('description',spec.objective),15,HeroDesign.MUTED))
	var record: Dictionary=Profile.data.records.get(spec.id,{})
	col.add_child(HeroDesign.label('BEST %d  /  %d MEDALS' % [int(record.get('best',0)),int(record.get('stars',0))],12,HeroDesign.MUTED))
	var actions := HeroDesign.row(8); col.add_child(actions)
	var play := HeroDesign.button('PLAY',func()->void:host.start_run('single',spec.id),HeroDesign.GOLD); play.size_flags_horizontal=Control.SIZE_EXPAND_FILL; actions.add_child(play)
	if not compact:
		var favorite := HeroDesign.button('SAVED' if Profile.data.favorites.has(spec.id) else '+ SAVE',func()->void:Profile.toggle_favorite(spec.id); host.show_page('GAMES')); favorite.tooltip_text='Save this game to Favorites'; actions.add_child(favorite)
		col.add_child(HeroDesign.button('PREVIEW / CONTROLS',func()->void:host.show_modal(spec.name,spec.get('description',spec.objective)+'\n\n'+spec.hint+'\n\n'+str(spec.duration)+' SECOND CHALLENGE',[['PLAY',func()->void:host.start_run('single',spec.id)],['BACK',host.close_modal]])))
	return panel
