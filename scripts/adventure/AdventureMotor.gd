extends RefCounted
var position = Vector2(80,430)
var velocity = Vector2.ZERO
var size = Vector2(40,60)
var grounded = false
var buffer = 0.0
var coyote = 0.0
var facing = 1.0
func jump() -> void: buffer = 0.14
func step(delta: float,axis: float,jump_held: bool,platforms: Array[Rect2],width: float) -> void:
	var target = axis*335.0
	velocity.x = move_toward(velocity.x,target,(2350.0 if grounded else 1400.0)*delta)
	if absf(axis)>0.01: facing = signf(axis)
	coyote = 0.11 if grounded else maxf(0,coyote-delta)
	if buffer>0 and coyote>0:
		velocity.y = -645
		buffer = 0
		coyote = 0
		grounded = false
	buffer = maxf(0,buffer-delta)
	if not jump_held and velocity.y < -235: velocity.y = -235
	velocity.y = minf(900,velocity.y+1550*delta)
	var previous = position
	position += velocity*delta
	position.x = clampf(position.x,8,width-size.x-8)
	grounded = false
	for surface in platforms:
		if velocity.y >= 0 and previous.y+size.y <= surface.position.y+5 and position.y+size.y >= surface.position.y and position.x+size.x>surface.position.x and position.x<surface.end.x:
			position.y = surface.position.y-size.y
			velocity.y = 0
			grounded = true
			break
func rect() -> Rect2: return Rect2(position,size)
