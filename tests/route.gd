extends Node
func _ready() -> void:
	var player := $World/Player as CharacterBody3D
	await get_tree().physics_frame
	Input.action_press("right")
	var last_jump := -40
	for frame in 530:
		await get_tree().physics_frame
		if Game.counts[2] == 1 and not Game.complete:
			print("PASS percurso contínuo do início até o arco sem encerrar a fase; vida ",Game.health," coletas ",Game.counts)
			Input.action_release("right")
			Input.action_release("left")
			get_tree().paused = false
			Audio.voice.stop()
			await get_tree().create_timer(.35).timeout
			get_tree().quit()
			return
		if frame-last_jump==16: Input.action_release("jump")
		if player.position.x>11.6 and player.position.x<19.3 and player.is_on_floor() and frame-last_jump>22:
			Input.action_press("jump")
			last_jump=frame
		if player.position.x > 20.2:
			Input.action_release("right")
		if player.is_on_floor() and player.position.x > 20.65:
			Input.action_press("left")
		elif Input.is_action_pressed("left") and player.position.x < 20.38:
			Input.action_release("left")
	print("FAIL percurso em ",player.position)
	get_tree().quit(1)
