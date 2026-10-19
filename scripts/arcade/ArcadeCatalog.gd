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
const CONTROLS = {
	"dino_dash":["SPACE / UP: JUMP   DOWN / Z: DUCK","TAP THE TRAIL TO JUMP. HOLD DUCK FOR FLYERS."],
	"grid_x":["ARROWS: SELECT   SPACE / ENTER: PLACE   OR CLICK A CELL","TAP A CELL TO PLACE X. WIN OR DRAW TO ADVANCE."],
	"sidecourt":["LEFT / RIGHT: MOVE   UP: LOB   DOWN: DRIVE   HOLD SPACE: SWING","LEFT PAD: MOVE / SHOT TYPE. HOLD SWING WITH YOUR OTHER THUMB."],
	"orbit_duel":["LEFT / RIGHT: TURN   UP: THRUST   DOWN / Z: BRAKE   HOLD SPACE: FIRE","LEFT PAD: TURN / THRUST. RIGHT THUMB: FIRE OR BRAKE."],
	"paddle_panic":["UP / DOWN OR MOUSE: PADDLE   SPACE: SERVE","DRAG YOUR PADDLE. AIM WITH ITS EDGES."],
	"dark_cavern":["LEFT / RIGHT: TUNNEL   Z: WALK / AIM   SPACE: ENTER / FIRE","TAP A TUNNEL TO WALK. AIM SWITCHES YOUR NEXT TAP TO A BOLT."],
	"armored_arena":["ARROWS / WASD: MOVE AND FACE   HOLD SPACE: FIRE","LEFT PAD: DRIVE AND FACE. HOLD FIRE WITH YOUR OTHER THUMB."],
	"brick_burst":["LEFT / RIGHT OR MOUSE: PADDLE   SPACE: LAUNCH","DRAG YOUR PADDLE. TAP THE COURT TO LAUNCH."],
	"byte_munch":["ARROWS / WASD: TURN   NO REVERSE TURNS","USE THE DIRECTION PAD OR DRAG TOWARD YOUR NEXT TURN."],
	"invader_patrol":["LEFT / RIGHT: MOVE   HOLD SPACE: FIRE","DRAG TO MOVE. HOLD FIRE WITH YOUR OTHER THUMB."],
	"rock_drift":["LEFT / RIGHT: TURN   UP: THRUST   DOWN / Z: BRAKE   HOLD SPACE: FIRE","LEFT PAD: TURN / THRUST. RIGHT THUMB: FIRE OR BRAKE."],
	"soft_landing":["LEFT / RIGHT: TILT   UP / SPACE: THRUST   DOWN / Z: LEVEL","LEFT PAD: TILT. RIGHT THUMB: THRUST OR LEVEL."],
	"flag_run":["ARROWS / WASD: STEER   SPACE: SMOKE (12 FUEL)","HOLD THE ROAD TOWARD YOUR DESTINATION. OTHER THUMB: SMOKE."],
	"dot_gobbler":["ARROWS / WASD: BUFFER TURNS   SPACE: NEXT MAZE","USE THE PAD OR DRAG IN YOUR NEXT DIRECTION."],
	"sky_shield":["ARROWS: AIM   SPACE: FIRE   OR CLICK TO AIM AND FIRE","TAP AHEAD OF MISSILES TO AIM AND LAUNCH."],
	"bug_blaster":["ARROWS: MOVE   HOLD SPACE: FIRE","DRAG WITH ONE FINGER TO MOVE AND FIRE."],
	"hopway":["ARROWS: HOP   SPACE: HOP FORWARD","TAP TOWARD THE NEXT HOP OR USE THE PAD."],
	"color_steps":["LEFT: DOWN-LEFT   DOWN: DOWN-RIGHT   UP: UP-LEFT   RIGHT: UP-RIGHT","PAD ARROWS FOLLOW THE FOUR SLOPES. RECALL RETURNS TO THE PEAK."],
	"crate_shift":["ARROWS: MOVE / PUSH   Z: UNDO   SPACE: NEXT ROOM","TAP THE PAD TO PUSH. UNDO RESTORES THE LAST MOVE."],
	"stackfall":["LEFT / RIGHT: MOVE   UP: ROTATE   DOWN: DROP   SPACE: SLAM   Z: REVERSE","LEFT PAD: MOVE / ROTATE. RIGHT DROP: SLAM. OTHER BUTTON: REVERSE."]
}
static func get_game(id: String) -> Dictionary:
	for row in GAMES:
		if row[0] == id:
			return {"id":row[0],"name":row[1],"hint":row[2],"category":row[3],"length":row[4],"controls":CONTROLS[id][0],"touch_controls":CONTROLS[id][1]}
	return {"id":"adventure","name":"IRON MARIO","hint":"MOVE, JUMP, AND BLAST YOUR WAY HOME!","category":"Adventure","length":"4 stages"}
