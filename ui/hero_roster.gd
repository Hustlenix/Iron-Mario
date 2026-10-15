class_name HeroRoster
extends RefCounted
const HEROES := [
  {
    "id": "dart",
    "name": "MILO",
    "title": "PIXEL TOWN",
    "role": "CURIOUS MECHANIC",
    "color": "#c68652",
    "secondary": "#92cbb4",
    "art": "res://assets/shared_foundation/town_cast/milo.png",
    "power": "town",
    "demo": "Meet the character",
    "story": "Milo, the town’s curious mechanic. Always ready for another little adventure.",
    "ability": "A LITTLE CELEBRATION",
    "ability_text": "A cheerful hop and a burst of confetti.",
    "trait": "SAME GAMES. YOUR OWN STYLE.",
    "game": "skyline_jumper"
  },
  {
    "id": "bolt",
    "name": "JUN",
    "title": "PIXEL TOWN",
    "role": "ENERGETIC COURIER",
    "color": "#6196ab",
    "secondary": "#92cbb4",
    "art": "res://assets/shared_foundation/town_cast/jun.png",
    "power": "town",
    "demo": "Meet the character",
    "story": "Jun, the town’s energetic courier. Always ready for another little adventure.",
    "ability": "A LITTLE CELEBRATION",
    "ability_text": "A cheerful hop and a burst of confetti.",
    "trait": "SAME GAMES. YOUR OWN STYLE.",
    "game": "skyline_jumper"
  },
  {
    "id": "echo",
    "name": "BEA",
    "title": "PIXEL TOWN",
    "role": "CHEERFUL BUILDER",
    "color": "#c6a353",
    "secondary": "#92cbb4",
    "art": "res://assets/shared_foundation/town_cast/bea.png",
    "power": "town",
    "demo": "Meet the character",
    "story": "Bea, the town’s cheerful builder. Always ready for another little adventure.",
    "ability": "A LITTLE CELEBRATION",
    "ability_text": "A cheerful hop and a burst of confetti.",
    "trait": "SAME GAMES. YOUR OWN STYLE.",
    "game": "skyline_jumper"
  },
  {
    "id": "frost",
    "name": "NIA",
    "title": "PIXEL TOWN",
    "role": "INVENTIVE TINKERER",
    "color": "#b381ac",
    "secondary": "#92cbb4",
    "art": "res://assets/shared_foundation/town_cast/nia.png",
    "power": "town",
    "demo": "Meet the character",
    "story": "Nia, the town’s inventive tinkerer. Always ready for another little adventure.",
    "ability": "A LITTLE CELEBRATION",
    "ability_text": "A cheerful hop and a burst of confetti.",
    "trait": "SAME GAMES. YOUR OWN STYLE.",
    "game": "skyline_jumper"
  },
  {
    "id": "tether",
    "name": "ASH",
    "title": "PIXEL TOWN",
    "role": "RELAXED SKATER",
    "color": "#849a9b",
    "secondary": "#92cbb4",
    "art": "res://assets/shared_foundation/town_cast/ash.png",
    "power": "town",
    "demo": "Meet the character",
    "story": "Ash, the town’s relaxed skater. Always ready for another little adventure.",
    "ability": "A LITTLE CELEBRATION",
    "ability_text": "A cheerful hop and a burst of confetti.",
    "trait": "SAME GAMES. YOUR OWN STYLE.",
    "game": "skyline_jumper"
  },
  {
    "id": "snap",
    "name": "PIP",
    "title": "PIXEL TOWN",
    "role": "ARCADE REGULAR",
    "color": "#d58977",
    "secondary": "#92cbb4",
    "art": "res://assets/shared_foundation/town_cast/pip.png",
    "power": "town",
    "demo": "Meet the character",
    "story": "Pip, the town’s arcade regular. Always ready for another little adventure.",
    "ability": "A LITTLE CELEBRATION",
    "ability_text": "A cheerful hop and a burst of confetti.",
    "trait": "SAME GAMES. YOUR OWN STYLE.",
    "game": "skyline_jumper"
  }
]
static func hero(index: int) -> Dictionary: return HEROES[posmod(index,HEROES.size())]
static func by_id(id: String) -> Dictionary:
	for spec: Dictionary in HEROES:
		if spec.id==id: return spec
	return {}
