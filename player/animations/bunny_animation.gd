extends Node3D
var tree := AnimationTree.new()
var previous_pose: StringName
var pose_time := 0.0
var playback: AnimationNodeStateMachinePlayback
func _ready() -> void:
	var library := find_children("*","AnimationPlayer",true,false)[0] as AnimationPlayer
	add_child(tree)
	tree.anim_player = tree.get_path_to(library)
	var graph := AnimationNodeStateMachine.new()
	for clip: String in ["Walking","Running"]:
		library.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
		var node := AnimationNodeAnimation.new()
		node.animation = clip
		graph.add_node(clip,node)
	var walk := AnimationNodeStateMachineTransition.new()
	walk.xfade_time = 0.14
	graph.add_transition("Walking","Running",walk)
	graph.add_transition("Running","Walking",walk.duplicate())
	tree.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	tree.tree_root = graph
	tree.active = true
	playback = tree.get("parameters/playback")
	playback.start("Walking")
	tree.advance(0.01)
func update_pose(next: StringName, facing: float, speed: float, dt: float, shield: float) -> void:
	rotation.y = lerp_angle(rotation.y,facing*PI/2,1-exp(-18*dt))
	playback.travel("Running" if next in [&"Run",&"Dash",&"Slide"] else "Walking")
	tree.active = true
	tree.advance(dt * (clampf(speed/3.5,.6,1.5) if next in [&"Walk",&"Run",&"Crouch"] else 0.0))
	if next != previous_pose:
		pose_time = 0
		previous_pose = next
	pose_time += dt
	var low_pose := next in [&"Crouch", &"Slide", &"BellySlide", &"SlopeSlide"]
	$Explorer.scale.y = lerpf($Explorer.scale.y, .63 if low_pose else 1.0, 1-exp(-18*dt))
	var tilt := 0.0
	match next:
		&"Dash", &"Slide", &"Skid", &"SlopeSlide", &"LongJump": tilt = -.19 * facing
		&"Punch": tilt = -.31 * facing
		&"Dive", &"BellySlide": tilt = -.85 * facing
		&"AirKick", &"Kick": tilt = .34 * facing
		&"WallSlide", &"LedgeHang", &"Bonk": tilt = .18 * facing
		&"TripleJump", &"SideFlip": tilt = -TAU * smoothstep(0.0, .65, pose_time) * facing
		&"Backflip": tilt = TAU * smoothstep(0.0, .65, pose_time) * facing
		&"PoundWindup": tilt = -TAU * smoothstep(0.0, .5, pose_time) * facing
	rotation.z = lerpf(rotation.z, tilt, 1-exp(-18*dt)) if absf(tilt) < PI and absf(rotation.z) < PI else tilt
	visible = shield <= 0 or fmod(shield,.14)<.1
