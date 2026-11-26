extends CharacterBody3D
signal impact
@export var run_speed := 6.6
@export var acceleration := 21.0
@export var braking := 35.0
@export var air_control := .7
@export var jump_speed := 8.6
@export var gravity := 23.0
@export var grace := .13
@export var buffer_window := .14
var facing := 1.0
var coyote := 0.0
var buffered := 0.0
var jumps := 0
@onready var dash := $Dash as Node
var stun := 0.0
var recovery := 0.0
var landing := 0.0
@onready var states := $State as Node
@onready var health := $Health as Node
func hurt(source_x: float) -> void:
	if recovery == 0 and health.hit():
		impact.emit()
		if Game.health <= 0:
			die()
		else:
			stun = .23
			dash.remaining = 0
			velocity = Vector3(4*signf(position.x-source_x),4,0)
func die() -> void:
	states.enter(&"Death")
	recovery = .35
	velocity = Vector3.ZERO
func bounce() -> void:
	velocity.y = jump_speed*.82
	jumps = 1
	dash.air_available = true
func _physics_process(dt: float) -> void:
	if recovery > 0:
		recovery = maxf(0,recovery-dt)
		$Visual.scale = Vector3.ONE*maxf(.02,recovery/.35)
		if recovery == 0:
			global_position = Game.checkpoint
			health.restore()
			states.enter(&"Respawn")
			dash.reset()
			$Visual.scale = Vector3.ONE
			stun = 0
			jumps = 0
		return
	var floor_before := is_on_floor()
	if floor_before:
		coyote = grace
		jumps = 0
		dash.air_available = true
	else:
		coyote = maxf(0,coyote-dt)
	buffered = buffer_window if Input.is_action_just_pressed("jump") else maxf(0,buffered-dt)
	dash.tick(dt,floor_before)
	stun = maxf(0,stun-dt)
	landing = maxf(0,landing-dt)
	var axis := Input.get_axis("left","right")
	if stun <= 0:
		if absf(axis)>.1 and dash.remaining<=0:
			facing = signf(axis)
		if buffered>0 and (coyote>0 or jumps<2):
			jumps = 1 if coyote>0 else 2
			velocity.y = jump_speed*(1 if jumps==1 else .9)
			buffered = 0
			coyote = 0
			dash.remaining = 0
			Audio.cue(410)
		if Input.is_action_just_released("jump") and velocity.y>2:
			velocity.y *= .52
		if Input.is_action_just_pressed("dash"):
			dash.launch(floor_before)
		if dash.remaining>0:
			velocity.x = facing*dash.speed
			velocity.y = 0
		else:
			var rate := braking if is_zero_approx(axis) else acceleration
			velocity.x = move_toward(velocity.x,axis*run_speed,rate*dt*(1.0 if floor_before else air_control))
	if dash.remaining<=0:
		velocity.y = maxf(-18,velocity.y-gravity*dt)
	velocity.z = 0
	var fall_speed := velocity.y
	move_and_slide()
	if not floor_before and fall_speed < -1.0 and is_on_floor():
		_break_crate_on_landing()
	position.z = 0
	if position.y < -7:
		die()
		return
	if is_on_floor() and not floor_before:
		landing = .08
	var next := &"Idle"
	if stun>0: next = &"Hurt"
	elif dash.remaining>0: next = &"Dash"
	elif not is_on_floor(): next = (&"DoubleJump" if jumps==2 else &"Jump") if velocity.y>0 else &"Fall"
	elif landing>0: next = &"Landing"
	elif absf(velocity.x)>4: next = &"Run"
	elif absf(velocity.x)>.1: next = &"Walk"
	states.enter(next)
	$Visual.update_pose(next,facing,absf(velocity.x),dt,health.shield)


func _break_crate_on_landing() -> void:
	for index in get_slide_collision_count():
		var contact := get_slide_collision(index)
		if contact.get_normal().y < 0.7:
			continue
		var surface := contact.get_collider() as Node
		if surface and surface.is_in_group("surprise_crate") and surface.break_from_above(self):
			bounce()
			return
