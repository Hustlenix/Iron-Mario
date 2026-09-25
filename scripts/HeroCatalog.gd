extends RefCounted
## Original cast. Stable IDs are saved; display names can change safely.
const IDS := ["ember", "moon", "sun", "tide", "comet", "thread", "cipher", "prism", "copper"]
const HEROES := {
	"ember": {"name":"EMBER RIG", "place":"SPARK FOUNDRY", "role":"BUILT TO KEEP GOING", "body":"c84b34", "trim":"edb74a", "light":"b7faff", "sky":"f6dfbc", "scenery":"bf8267", "motif":"forge"},
	"moon": {"name":"MOON SCOUT", "place":"LUNAR OBSERVATORY", "role":"FOLLOW THE NIGHT SKY", "body":"364868", "trim":"75b7bb", "light":"c4efff", "sky":"bccbdc", "scenery":"7f93b1", "motif":"moon"},
	"sun": {"name":"SUN COURIER", "place":"FLOATING ISLANDS", "role":"DELIVERY ABOVE THE CLOUDS", "body":"e88339", "trim":"fff1c4", "light":"fff0a6", "sky":"f7e7b8", "scenery":"d7ac78", "motif":"islands"},
	"tide": {"name":"TIDE WARDEN", "place":"SEA CITADEL", "role":"GUARDIAN OF THE HARBOR", "body":"268b8d", "trim":"d6ad75", "light":"aeffe9", "sky":"c1e4dc", "scenery":"71aaa9", "motif":"sea"},
	"comet": {"name":"NEON COMET", "place":"COMET LAUNCH PORT", "role":"NEXT STOP - THE STARS", "body":"714b9a", "trim":"c6e675", "light":"e5ff8c", "sky":"d9cce5", "scenery":"a38ab7", "motif":"port"},
	"thread": {"name":"THREAD RUNNER", "place":"GARDEN ROOFTOPS", "role":"TAKE THE HIGH ROAD", "body":"437f63", "trim":"ec967c", "light":"f7e4b0", "sky":"e0e5c3", "scenery":"94ae80", "motif":"garden"},
	"cipher": {"name":"CIPHER FOX", "place":"MIDNIGHT RAIL YARD", "role":"EVERY CLUE COUNTS", "body":"425363", "trim":"e0a46d", "light":"a7e6e6", "sky":"cedbdd", "scenery":"8ca0a8", "motif":"rail"},
	"prism": {"name":"PRISM WEAVER", "place":"CRYSTAL CAVERNS", "role":"A LITTLE LIGHT GOES FAR", "body":"8d609e", "trim":"99dad2", "light":"fbd4ff", "sky":"e6d7ef", "scenery":"b69bc7", "motif":"crystal"},
	"copper": {"name":"COPPER GUARD", "place":"CLOCKWORK FORTRESS", "role":"HOLD THE LINE", "body":"a96c42", "trim":"70aab2", "light":"ffe3a1", "sky":"e9ddc8", "scenery":"b59b7c", "motif":"fort"}
}

static func valid_id(value: String) -> String:
	return value if HEROES.has(value) else "ember"

static func get_hero(value: String) -> Dictionary:
	return HEROES[valid_id(value)]
