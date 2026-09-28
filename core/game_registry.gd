class_name GameRegistry
extends RefCounted
var games: Array[Dictionary] = []
var lookup: Dictionary = {}
var cache: Dictionary = {}
const COMMANDS := {'target_lock':'TAG!','reactor_parry':'PARRY!','power_sequence':'REMEMBER!','stop_bar':'STOP!','odd_one':'FIND THE FAKE!','rhythm_knock':'KNOCK!','whack_mole':'BONK!','coin_catch':'CATCH!','shield_turn':'BLOCK!','trace_wire':'CONNECT!','balloon_pump':'PUMP!','hold_balance':'CHARGE!','color_switch':'MATCH THE INK!','number_order':'COUNT!','mirror_match':'MIRROR!','orbit_snap':'SNAP!','light_out':'LIGHTS OUT!','safe_dial':'TURN!','fuse_cut':'CUT THE WIRE!','pixel_repair':'COPY!','maze_runner':'ESCAPE!','gravity_flip':'FLIP!','word_sort':'SORT!','echo_taps':'ECHO!','door_peek':'WAIT... TAP!','arc_dash':'SWITCH!','laser_tunnel':'DUCK!','armor_repair':'REPAIR!','rocket_rescue':'RESCUE!','flappy_bonus':'FLAP!','swing_rescue':'LEAP!','meteor_dodge':'DODGE!','parcel_catch':'CATCH!','ice_slide':'SLIDE!','rail_grind':'JUMP!','balloon_lift':'FLOAT!','magnet_haul':'HAUL!','rope_bridge':'FOLLOW!','paint_skate':'SKATE!','shield_surf':'DEFLECT!','boulder_push':'PUSH!','river_hop':'HOP!','glider_gust':'SOAR!','orbit_escape':'LAUNCH!','spring_vault':'VAULT!','cloud_ferry':'FERRY!','parachute_drop':'LAND!','pinball_rescue':'BOUNCE!','conveyor_sort':'DELIVER!','comet_curl':'BANK SHOT!'}

func _init() -> void:
	for path in ['res://microgames/pack_a.json','res://microgames/pack_b.json']:
		if not FileAccess.file_exists(path): continue
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
		if parsed is Array:
			for item in parsed:
				if item is Dictionary:
					item['description'] = item.objective
					item.objective = COMMANDS.get(item.id,item.objective)
					item.category = String(item.category).capitalize()
					item['tournament_enabled'] = true
					games.append(item)
					lookup[item.id] = item
func ids() -> Array:
	return games.map(func(g: Dictionary) -> String: return g.id)
func get_game(id: String) -> Dictionary:
	return lookup.get(id,{})
func create(id: String) -> MicrogameBase:
	var entry: Dictionary = get_game(id)
	if entry.is_empty(): return null
	var path: String = entry.script
	if not cache.has(path): cache[path] = load(path)
	return cache[path].new() as MicrogameBase
