class_name HeroData
extends Resource

## The Phase 4 roster, as a static table.
##
## This is a plain lookup table rather than nine .tres resources on purpose: it
## has to be readable from a headless test driver with no scene tree and no
## resource-loading side effects, and every entry is immutable for the length
## of a run. The per-hero variation the design calls for -- cooldown length,
## arc shape, range, effect strength -- lives in the columns here, so adding a
## tenth hero is a single row.
##
## Every display name and every power name here is original to this project.
## Each `art` path points at a stand-in design drawn for this game under
## assets/heroes/, and none of them trace a licensed likeness -- see
## assets/heroes/README.md. The names are ours too, so nothing here depends
## on borrowed characters. Name the archetype, draw something that is yours.

## The four power families. There are four handlers per minigame rather than
## one per hero: heroes inside a family differ only by their numbers, so
## this is sixteen behaviours instead of thirty-six.
##
## NONE is a sentinel, not a fifth family: it marks a roster entry that has no
## combat power. It is appended last so DASH..BLAST keep their values 0..3.
enum Family { DASH, REVEAL, REACH, BLAST, NONE }

## The cooldown is shared across every hero, so this is the design's "shared
## three-second cooldown" and a hero's own value is the only rate knob.
const BASE_COOLDOWN := 3.0

## The single documented outlier: Lance's beam runs one second longer,
## because it reaches further than every other blast.
const LANCE_COOLDOWN := 4.0

const FAMILY_NAMES := {
	Family.DASH: "Dash",
	Family.REVEAL: "Reveal",
	Family.REACH: "Reach",
	Family.BLAST: "Blast",
	Family.NONE: "None",
}

## Flappy appears on the roster but deliberately has no combat power. His art
## stays at the pre-existing assets/flappy_hero.svg -- the design keeps that
## file as the Flappy sprite, and the hero swap there is optional polish.
const FLAPPY_ID := "flappy"

const ROSTER: Array[Dictionary] = [
	{
		"id": "dart",
		"name": "Dart",
		"power": "Lunge",
		"family": Family.DASH,
		"cooldown": 3.0,
		"blurb": "Arcs forward and up. Passing through the target resolves it.",
		"art": "res://assets/heroes/dart.svg",
		"accent": Color(0.85, 0.2, 0.25),
		"dash_shape": "arc",
		"dash_speed": 900.0,
		"dash_lift": -420.0,
		"invulnerable": false,
	},
	{
		"id": "bolt",
		"name": "Bolt",
		"power": "Overdrive",
		"family": Family.DASH,
		"cooldown": 3.0,
		"blurb": "A long flat burst, the fastest dash, with brief invincibility.",
		"art": "res://assets/heroes/bolt.svg",
		"accent": Color(0.2, 0.45, 0.95),
		"dash_shape": "flat",
		"dash_speed": 1150.0,
		"dash_lift": 0.0,
		"invulnerable": true,
	},
	{
		"id": "echo",
		"name": "Echo",
		"power": "Sonar",
		"family": Family.REVEAL,
		"cooldown": 3.0,
		"blurb": "Reveals the next shard, the next laser, or the parry zone.",
		"art": "res://assets/heroes/echo.svg",
		"accent": Color(0.25, 0.3, 0.4),
		"reveal_seconds": 2.5,
		"freeze_seconds": 0.0,
	},
	{
		"id": "frost",
		"name": "Frost",
		"power": "Deep Freeze",
		"family": Family.REVEAL,
		"cooldown": BASE_COOLDOWN,
		"blurb": "Freezes moving hazards, the target, or the parry bar for a second.",
		"art": "res://assets/heroes/frost.svg",
		"accent": Color(0.45, 0.8, 0.95),
		"reveal_seconds": 0.0,
		"freeze_seconds": 1.0,
	},
	{
		"id": "tether",
		"name": "Tether",
		"power": "Tether",
		"family": Family.REACH,
		"cooldown": 3.0,
		"blurb": "A long-range auto-hit that also pulls you toward the goal.",
		"art": "res://assets/heroes/tether.svg",
		"accent": Color(0.95, 0.7, 0.2),
		"reach_range": 640.0,
		"reach_pulls_player": true,
		"absorbs_hit": false,
	},
	{
		"id": "snap",
		"name": "Snap",
		"power": "Snap",
		"family": Family.REACH,
		"cooldown": 3.0,
		"blurb": "An instant long-range auto-hit.",
		"art": "res://assets/heroes/snap.svg",
		"accent": Color(0.2, 0.2, 0.25),
		"reach_range": 700.0,
		"reach_pulls_player": false,
		"absorbs_hit": false,
	},
	{
		"id": "aegis",
		"name": "Aegis",
		"power": "Aegis",
		"family": Family.REACH,
		"cooldown": BASE_COOLDOWN,
		"blurb": "Slower than the other reachers, but it absorbs one hit.",
		"art": "res://assets/heroes/aegis.svg",
		"accent": Color(0.25, 0.4, 0.75),
		"reach_range": 520.0,
		"reach_pulls_player": false,
		"absorbs_hit": true,
	},
	{
		"id": "pulse",
		"name": "Pulse",
		"power": "Pulse",
		"family": Family.BLAST,
		"cooldown": 3.0,
		"blurb": "Pulls shards in, vaporises the target, deletes a laser, snaps the parry bar home.",
		"art": "res://assets/heroes/pulse.svg",
		"accent": Color(0.95, 0.55, 0.15),
		"blast_range": 560.0,
		"blast_pulls": true,
	},
	{
		"id": "lance",
		"name": "Lance",
		"power": "Lance",
		"family": Family.BLAST,
		"cooldown": LANCE_COOLDOWN,
		"blurb": "The pulse at longer range, on a longer cooldown.",
		"art": "res://assets/heroes/lance.svg",
		"accent": Color(0.9, 0.1, 0.1),
		"blast_range": 900.0,
		"blast_pulls": true,
	},
	{
		"id": FLAPPY_ID,
		"name": "Flappy",
		"power": "None",
		"family": Family.NONE,
		"cooldown": BASE_COOLDOWN,
		"blurb": "Visual only. Flappy keeps his own sprite and has no combat power.",
		"art": "res://assets/flappy_hero.svg",
		"accent": Color(1.0, 0.8, 0.2),
	},
]

static var _by_id: Dictionary = {}

static func _ensure_index() -> void:
	if not _by_id.is_empty():
		return
	for hero in ROSTER:
		_by_id[hero["id"]] = hero

static func all() -> Array[Dictionary]:
	return ROSTER

## The nine heroes that actually have a power. Flappy is on the roster for the
## art and the completions check, but offering him as a pick would hand the
## player a cooldown ring that can never fire.
static func selectable() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for hero in ROSTER:
		if int(hero["family"]) != Family.NONE:
			out.append(hero)
	return out

static func selectable_ids() -> Array[String]:
	var out: Array[String] = []
	for hero in selectable():
		out.append(hero["id"])
	return out

static func is_selectable(id: String) -> bool:
	return has_hero(id) and int(get_hero(id)["family"]) != Family.NONE

static func ids() -> Array[String]:
	_ensure_index()
	var out: Array[String] = []
	for hero in ROSTER:
		out.append(hero["id"])
	return out

## Never returns an empty dictionary: an unknown or missing id falls back to
## the first hero, so a corrupt save degrades to a playable game rather than a
## null dereference three scenes deep.
static func get_hero(id: String) -> Dictionary:
	_ensure_index()
	if _by_id.has(id):
		return _by_id[id]
	return ROSTER[0]

static func has_hero(id: String) -> bool:
	_ensure_index()
	return _by_id.has(id)

static func random_id() -> String:
	var pool := selectable()
	if pool.is_empty():
		return ROSTER[0]["id"]
	var hero: Dictionary = pool[randi() % pool.size()]
	return hero["id"]

static func family_name(family: int) -> String:
	return FAMILY_NAMES.get(family, "None")
