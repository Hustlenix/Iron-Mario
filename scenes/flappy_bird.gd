extends Node2D

const GRAVITY := 1400.0
const MAX_FALL := 900.0
const FLAP_VELOCITY := -420.0
const BIRD_X := 200.0
const BIRD_SIZE := 70.0
const GROUND_Y := 620.0
const PIPE_WIDTH := 110.0
const PIPE_RIM := 16.0
const GAP_MIN_CENTER := 200.0
const GAP_MAX_CENTER := 560.0
const PIPE_POOL := 6
const TRAIL_COUNT := 10
const HITBOX_SHRINK := 0.075

var state := "title"
var score := 0
var velocity := 0.0
var bird_y := 300.0
var best := 0
var new_best_fired := false
var medals := {}
var feathers := 0
var invuln_timer := 0.0
var feather_next_spawn := 8

var feather_every_min := 8
var feather_every_max := 12

var _pipe_meta := {}
var _spawn_timer := 0.0
var _spawned := 0
var _first_delay := 0.0
var _score_flash := 0.0
var _trail_index := 0
var _trail_timer := 0.0

@onready var pipes_node: Node2D = $Pipes
@onready var pickups_node: Node2D = $Pickups
@onready var trail_node: Node2D = $Trail
@onready var bird: TextureRect = $Bird
@onready var score_label: RichTextLabel = $HUD/ScoreLabel
@onready var best_label: RichTextLabel = $HUD/BestLabel
@onready var medal_label: RichTextLabel = $HUD/MedalLabel
@onready var medal_icon: TextureRect = $HUD/MedalIcon
@onready var feather_icon: TextureRect = $HUD/FeatherIcon
@onready var hint_label: RichTextLabel = $HUD/HintLabel
@onready var sfx_flap: AudioStreamPlayer = $SfxFlap
@onready var sfx_score: AudioStreamPlayer = $SfxScore
@onready var sfx_hit: AudioStreamPlayer = $SfxHit
@onready var sfx_pickup: AudioStreamPlayer = $SfxPickup
@onready var sfx_win: AudioStreamPlayer = $SfxWin
@onready var bgm: AudioStreamPlayer = $Bgm

func _ready() -> void:
	SceneFade.fade_in(self)
	best = Global.flappy_best
	best_label.text = "BEST: %d" % best
	build_sounds()
	_build_pipe_pool()
	_build_trail()
	bgm.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	bgm.play()

func get_state() -> String:
	return state

func flap() -> void:
	pass

func build_sounds() -> void:
	pass

func _build_pipe_pool() -> void:
	pass

func _build_trail() -> void:
	pass

func _process(delta: float) -> void:
	pass

func _unhandled_input(event: InputEvent) -> void:
	pass
