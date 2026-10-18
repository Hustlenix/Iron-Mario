extends RefCounted
const GAMES = [
	["dino_dash","DINO DASH","Jump thorns. Duck the flyers.","Reflex","Endless"],
	["grid_x","GRID X","Win or draw three terminals.","Board","3 terminals"],
	["sidecourt","SIDECOURT","Lob or drive. First to five.","Physics","5 points"],
	["orbit_duel","ORBIT DUEL","Fight three drones. Avoid the sun.","Space","3 rivals"],
	["paddle_panic","PADDLE PANIC","Defend your side. First to five.","Reflex","5 points"],
	["dark_cavern","DARK CAVERN","Find two caches. Defeat the creature.","Board","12 rooms"],
	["armored_arena","ARMORED ARENA","Face your shot. Clear three arenas.","Action","3 arenas"],
	["brick_burst","BRICK BURST","Break bricks. Catch helpful chips.","Physics","Endless"],
	["byte_munch","BYTE MUNCH","Grow your train. Plan your turns.","Board","Endless"],
	["invader_patrol","INVADER PATROL","Stop three robot formations.","Action","3 waves"],
	["rock_drift","ROCK DRIFT","Break rocks. Brake to stay safe.","Space","3 fields"],
	["soft_landing","SOFT LANDING","Land gently, level and with fuel.","Space","3 pads"],
	["flag_run","FLAG RUN","Collect six flags, then find the exit.","Action","3 districts"],
	["dot_gobbler","DOT GOBBLER","Clear two mazes. Use the crystals.","Board","2 mazes"],
	["sky_shield","SKY SHIELD","Lead missiles with expanding blasts.","Action","3 waves"],
	["bug_blaster","BUG BLASTER","Carve a lane through the mushrooms.","Action","3 waves"],
	["hopway","HOPWAY","Fill four home bays each round.","Board","3 rounds"],
	["color_steps","COLOR STEPS","Paint the pyramid. Escape the bug.","Board","3 pyramids"],
	["crate_shift","CRATE SHIFT","Push five rooms of crates onto docks.","Board","5 rooms"],
	["stackfall","STACKFALL","Build complete rows. Clear 24 to win.","Board","24 rows"]
]
static func get_game(id: String) -> Dictionary:
	for row in GAMES:
		if row[0] == id:
			return {"id":row[0],"name":row[1],"hint":row[2],"category":row[3],"length":row[4]}
	return {"id":"adventure","name":"IRON MARIO","hint":"MOVE, JUMP, AND BLAST YOUR WAY HOME!","category":"Adventure","length":"4 stages"}
