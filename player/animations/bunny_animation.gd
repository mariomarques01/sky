extends Node3D
var tree := AnimationTree.new()
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
	playback.travel("Running" if next in [&"Run",&"Dash"] else "Walking")
	tree.active = true
	tree.advance(dt * (clampf(speed/3.5,.6,1.5) if next in [&"Walk",&"Run"] else 0.0))
	rotation.z = lerp_angle(rotation.z,(-.14*facing if next == &"Dash" else 0.0),1-exp(-18*dt))
	visible = shield <= 0 or fmod(shield,.14)<.1
