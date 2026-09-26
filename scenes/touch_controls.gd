extends CanvasLayer

## Phase 2 touch controls.
##
## Emits the existing `left` / `right` / `jump` input actions, so gameplay code
## needs no changes to work with touch. Minigames 3 and 4 poll those actions as
## held state, so every button is press-and-hold capable rather than tap-only.
##
## The `power` button is deliberately absent -- Phase 4 adds it alongside the
## nine playable heroes.

const TOUCHED_ACTIONS := ["jump", "left", "right"]

## height/width above this reads as a portrait phone and we show the rotate hint.
const PORTRAIT_MIN_ASPECT := 1.2

## Physical pixels every button should cover on a real screen. 64 is the
## accessibility floor, but thumbs on a phone are imprecise, so aim higher.
const MIN_TOUCH_PX := 88.0

@onready var left_button: Button = $BottomRow/Controls/LeftButton
@onready var right_button: Button = $BottomRow/Controls/RightButton
@onready var jump_button: Button = $BottomRow/Controls/JumpButton
@onready var portrait_hint: Control = $PortraitHint
@onready var bottom_row: Control = $BottomRow

## Set once the player touches the screen, so hybrid laptops (which report a
## touchscreen but whose players use a keyboard) still get the buttons.
var _touch_seen := false

var _buttons: Array[Button] = []
var _authored_sizes := {}


func _ready() -> void:
	for action in TOUCHED_ACTIONS:
		if not InputMap.has_action(action):
			push_error("touch_controls: missing input action '%s'" % action)
			return

	_bind_held("left", left_button)
	_bind_held("right", right_button)
	_bind_held("jump", jump_button)

	_buttons = [left_button, right_button, jump_button]
	for button in _buttons:
		_authored_sizes[button] = button.custom_minimum_size
	_rescale_buttons()

	_publish_visibility()
	get_viewport().size_changed.connect(_on_viewport_resized)
	tree_exiting.connect(_release_all)


## How far the 1280x720 content is scaled down to fit the real window. The
## project stretches with aspect "keep", so on a short landscape phone (or any
## window smaller than 1280x720) a content pixel is worth less than a physical
## pixel, and an authored button size can fall under the touch target floor.
func _render_scale() -> float:
	var scale: Vector2 = get_viewport().get_screen_transform().get_scale()
	return maxf(minf(absf(scale.x), absf(scale.y)), 0.01)


## Grow the buttons as needed so each one still covers MIN_TOUCH_PX physical
## pixels after stretching. Authored sizes are a floor, never a ceiling, so the
## desktop layout is untouched.
func _rescale_buttons() -> void:
	var needed: float = MIN_TOUCH_PX / _render_scale()
	for button in _buttons:
		var authored: Vector2 = _authored_sizes[button]
		button.custom_minimum_size = Vector2(
			maxf(authored.x, needed),
			maxf(authored.y, needed)
		)


func _on_viewport_resized() -> void:
	_rescale_buttons()
	_publish_visibility()


func _bind_held(action: String, button: Button) -> void:
	button.button_down.connect(_on_button_down.bind(action))
	button.button_up.connect(_on_button_up.bind(action))


func _on_button_down(action: String) -> void:
	_touch_seen = true
	Input.action_press(action)
	_publish_visibility()


func _on_button_up(action: String) -> void:
	Input.action_release(action)


## Devices that under-report the touchscreen (and some hybrid laptops) start
## with the controls hidden, so the first real touch would never be seen by a
## button. Watch raw input events so the buttons can reveal themselves.
func _input(event: InputEvent) -> void:
	if _touch_seen or event is not InputEventScreenTouch:
		return
	_touch_seen = true
	_publish_visibility()


## A held button must never leave an action stuck on across a scene change.
func _release_all() -> void:
	for action in TOUCHED_ACTIONS:
		Input.action_release(action)


func _is_portrait() -> bool:
	return is_portrait_size(get_viewport().get_visible_rect().size)


## Pure rule, kept separate so the portrait threshold can be verified against
## real device sizes without needing a real device.
static func is_portrait_size(size: Vector2) -> bool:
	return size.y / maxf(size.x, 1.0) > PORTRAIT_MIN_ASPECT


func _publish_visibility() -> void:
	_apply_visibility(_is_portrait())


func _apply_visibility(portrait: bool) -> void:
	# The layer itself always stays visible: it also hosts the rotate hint, so
	# hiding the layer in portrait would take the prompt down with it.
	if portrait:
		portrait_hint.show()
		bottom_row.hide()
		return

	portrait_hint.hide()
	if Global.touch_controls_enabled and (DisplayServer.is_touchscreen_available() or _touch_seen):
		bottom_row.show()
	else:
		bottom_row.hide()
