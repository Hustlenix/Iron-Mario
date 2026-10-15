class_name CharacterVisual
extends RefCounted
## Shared foot-anchored pixel character renderer. IDs retain profile compatibility.
const NAMES := {'dart':'milo','bolt':'jun','echo':'bea','frost':'nia','tether':'ash','snap':'pip'}
static var sheets: Dictionary = {}
static var animations: Dictionary = {}
static func sheet(id: String) -> Texture2D:
	var name: String = NAMES.get(id,'milo')
	if not sheets.has(name): sheets[name]=load('res://assets/shared_foundation/town_cast/'+name+'_motion.png')
	return sheets[name]
static func draw(canvas: CanvasItem, id: String, feet: Vector2, zoom: float=1.0, elapsed: float=0.0, moving: bool=false, facing: int=3, reduced_motion: bool=false) -> void:
	draw_action(canvas,id,feet,'walk' if moving else 'idle_animated',zoom,elapsed,facing,reduced_motion)
static func frames(id: String) -> SpriteFrames:
	var name: String=NAMES.get(id,'milo')
	if not animations.has(name): animations[name]=load('res://assets/shared_foundation/town_cast/'+name+'_frames.tres')
	return animations[name]
static func draw_action(canvas: CanvasItem,id: String,feet: Vector2,action: String='idle',zoom: float=1.0,elapsed: float=0.0,facing: int=3,reduced_motion: bool=false) -> void:
	var resource: SpriteFrames=frames(id)
	var animation: StringName=StringName(action+'_'+['left','up','right','down'][clampi(facing,0,3)])
	if not resource.has_animation(animation): animation=&'idle_down'
	var count: int=resource.get_frame_count(animation)
	var index: int=0 if reduced_motion else int(maxf(0,elapsed)*resource.get_animation_speed(animation))
	index=posmod(index,count) if resource.get_animation_loop(animation) else mini(index,count-1)
	canvas.draw_texture_rect(resource.get_frame_texture(animation,index),Rect2((feet-Vector2(8,32)*zoom).round(),Vector2(16,32)*zoom),false)
