extends Node
## Central power dispatcher (autoload `PowerBus`).
##
## Every minigame asks this node whether a power is ready, and hands the actual
## effect back to its own handler. The bus deliberately knows nothing about any
## individual minigame: it owns the cooldown clock, resolves the active hero,
## and routes to whichever scene registered itself. That is what keeps the
## power system at sixteen behaviours rather than thirty-six -- the bus cannot
## grow a per-hero special case without a minigame knowing about it.
##
## The cooldown is SHARED, exactly as the design specifies. It starts only when
## a handler actually resolves something, so pressing a power with nothing in
## range never costs the player the real cooldown.

## Emitted every tick while the cooldown runs, so the HUD can drive a ring
## without polling. `ratio` is 1.0 when ready and falls to 0.0 at the moment of
## use, which is the shape a radial fill wants.
signal cooldown_changed(remaining: float, ratio: float)
signal power_used(hero_id: String, family: int)
signal power_rejected(reason: String)

const DEFAULT_HERO := "dart"

var _hero_id: String = ""
var _hero: Dictionary = {}
var _cooldown_remaining: float = 0.0
var _cooldown_total: float = 0.0
var _handler: Node = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_resolve_hero()

## The cooldown must keep running even while a minigame has paused the tree or
## the player is on a menu, otherwise a scene change would hand the player a
## free cast.
func _process(delta: float) -> void:
	if _cooldown_remaining <= 0.0:
		return
	_cooldown_remaining = maxf(0.0, _cooldown_remaining - delta)
	cooldown_changed.emit(_cooldown_remaining, cooldown_ratio())

## Re-resolve on demand. Global.selected_hero can change while the game is
## running (hero select, or a settings reset), so this is not a _ready-only read.
func _resolve_hero() -> void:
	_hero_id = Global.active_hero_id()
	_hero = HeroData.get_hero(_hero_id)

func hero() -> Dictionary:
	return _hero

func hero_id() -> String:
	return _hero_id

func family() -> int:
	return _hero.get("family", HeroData.Family.NONE)

## False for a hero with no combat power. The HUD uses this to hide the ring
## rather than showing one that can never reach zero.
func has_power() -> bool:
	return family() != HeroData.Family.NONE

func family_name() -> String:
	return HeroData.family_name(family())

func cooldown_total() -> float:
	return float(_hero.get("cooldown", HeroData.BASE_COOLDOWN))

func ready_to_use() -> bool:
	return _cooldown_remaining <= 0.0

func cooldown_remaining() -> float:
	return _cooldown_remaining

## 1.0 = ready, 0.0 = just used. Clamped because a ratio slightly above 1 looks
## like a bug in the ring animation.
func cooldown_ratio() -> float:
	if ready_to_use():
		return 1.0
	if _cooldown_total <= 0.0:
		return 0.0
	return clampf(1.0 - (_cooldown_remaining / _cooldown_total), 0.0, 1.0)

## A minigame registers itself on entry. Passing the hero id lets the bus pin a
## hero for a whole scene even if the player changes their mind mid-round, so
## the power you see on the cooldown ring is the power that will actually fire.
func register_handler(node: Node, hero_id: String = "") -> void:
	_handler = node
	if hero_id != "":
		_hero_id = hero_id
		_hero = HeroData.get_hero(hero_id)
	else:
		_resolve_hero()
	# A new minigame starts with the power READY. Carrying a running cooldown
	# across a scene change would make the player open each round already
	# waiting, with nothing to do while the ring drains.
	force_ready()

func unregister_handler(node: Node) -> void:
	if _handler == node:
		_handler = null

func has_handler() -> bool:
	return _handler != null and is_instance_valid(_handler)

## The single entry point. Returns true only when a handler consumed the press.
func try_activate() -> bool:
	if not ready_to_use():
		power_rejected.emit("cooling down")
		return false
	if not has_handler():
		power_rejected.emit("no target")
		return false
	if not has_power():
		power_rejected.emit("this hero has no power")
		return false

	var used: bool = bool(_handler.on_power(family()))
	if not used:
		power_rejected.emit("nothing in range")
		return false

	_start_cooldown(cooldown_total())
	power_used.emit(_hero_id, family())
	return true

## For handlers that want to check the gate themselves before doing work.
func can_activate() -> bool:
	return ready_to_use() and has_handler() and has_power()

func _start_cooldown(seconds: float) -> void:
	_cooldown_total = maxf(0.0, seconds)
	_cooldown_remaining = _cooldown_total
	cooldown_changed.emit(_cooldown_remaining, cooldown_ratio())

## Debug / test affordance: skip the wait without faking a use.
func force_ready() -> void:
	_cooldown_remaining = 0.0
	cooldown_changed.emit(0.0, 1.0)
