extends Node
var failed := 0
@onready var world := $World
@onready var player := $World/Player as CharacterBody3D
func check(condition: bool, label: String) -> void:
	print(("PASS " if condition else "FAIL ")+label)
	if not condition: failed += 1
func frames(count: int) -> void:
	for i in count: await get_tree().physics_frame
func check_stance() -> void:
	var collision := player.get_node("Collision") as CollisionShape3D
	var capsule := collision.shape as CapsuleShape3D
	var standing_height := capsule.height
	Input.action_press("crouch")
	await frames(3)
	check(capsule.height < standing_height and is_equal_approx(collision.position.y, capsule.height * .5), "agachamento mantém os pés no chão")

	var roof := StaticBody3D.new()
	var roof_collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(1.5, .2, 1.5)
	roof_collision.shape = box
	roof.add_child(roof_collision)
	add_child(roof)
	roof.global_position = player.global_position + Vector3.UP * 1.23
	await frames(3)
	Input.action_release("crouch")
	await frames(3)
	check(capsule.height < standing_height, "teto bloqueia retorno à postura em pé")
	roof.queue_free()
	await frames(4)
	check(is_equal_approx(capsule.height, standing_height), "retorno à postura em pé após liberar espaço")

func check_slide() -> void:
	player.global_position = Vector3(1.0, .12, 0)
	player.velocity = Vector3.ZERO
	await frames(15)
	Input.action_press("right")
	await frames(24)
	Input.action_press("crouch")
	await frames(2)
	Input.action_release("crouch")
	Input.action_release("right")
	check(player.get("sliding") and player.velocity.x > 6.6, "deslizada conserva impulso após soltar")
	var wall := StaticBody3D.new()
	var wall_collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(.15, 2, 1.5)
	wall_collision.shape = box
	wall.add_child(wall_collision)
	add_child(wall)
	wall.global_position = player.global_position + Vector3(.65, .6, 0)
	var impacts: Array[bool] = []
	player.connect("impact", func() -> void: impacts.append(true), CONNECT_ONE_SHOT)
	await frames(8)
	check(not player.get("sliding") and impacts.size() == 1, "parede encerra deslizada e registra impacto")
	wall.queue_free()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	world.process_mode = Node.PROCESS_MODE_PAUSABLE
	await frames(20)
	check(player.is_on_floor(),"spawn e chão")
	await check_stance()
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("/tmp/sky-start.png")
	var pad := world.get_node("CanvasLayer").get("pad") as Control
	pad.show()
	for index in [1,3]:
		var down := InputEventScreenTouch.new()
		down.index=index
		down.pressed=true
		down.position=pad.global_position+pad.get("centers")[index]
		get_viewport().push_input(down,true)
	await frames(2)
	check(Input.is_action_pressed("right") and Input.is_action_pressed("jump"),"multitouch simultâneo")
	for index in [1,3]:
		var up := InputEventScreenTouch.new()
		up.index=index
		up.pressed=false
		get_viewport().push_input(up,true)
	await frames(70)
	check(not Input.is_action_pressed("jump") and not Input.is_action_pressed("right"),"liberação dos dedos")
	pad.hide()
	Input.action_press("right")
	await frames(33)
	check(player.velocity.x>5,"aceleração até corrida")
	Input.action_press("jump")
	await frames(7)
	check(player.position.y>.4,"salto")
	Input.action_release("jump")
	await frames(2)
	Input.action_press("jump")
	await frames(3)
	check(player.get_node("State").get("current")==&"DoubleJump","salto duplo")
	Input.action_release("jump")
	Input.action_press("dash")
	await frames(3)
	check(player.velocity.x>10,"dash aéreo")
	Input.action_release("dash")
	Input.action_release("right")
	player.position=Vector3(4.1,.18,0)
	player.velocity=Vector3.ZERO
	await frames(20)
	Input.action_press("right")
	await frames(68)
	Input.action_release("right")
	check(player.position.x>10 and player.position.y>0,"travessia da ponte curva")
	await frames(22)
	check(Game.counts[0]>0,"Area3D de coleta")
	check(Game.checkpoint.x>0,"checkpoint")
	player.position.y=-9
	await frames(32)
	check(absf(player.position.x-Game.checkpoint.x)<.2 and Game.health==3,"respawn no checkpoint")
	await frames(85)
	var enemy := world.get_node("Gameplay/Enemies/Sporeling") as Area3D
	player.position = enemy.position + Vector3(.37,.01,0)
	await frames(4)
	check(Game.health==2,"dano lateral")
	await frames(4)
	check(Game.health==2,"invulnerabilidade")
	player.position = enemy.position + Vector3(0,1.35,0)
	player.velocity = Vector3(0,-5,0)
	await frames(32)
	check(not is_instance_valid(enemy) and Game.counts[1]>0,"impacto e recompensa")
	var hud := world.get_node("CanvasLayer")
	hud.toggle_pause()
	check(get_tree().paused,"menu pausa")
	hud.toggle_pause()
	hud.cycle_profile()
	check(world.quality==int(Save.data.get_value("video","perfil",-1)),"perfil persistido")
	player.position=Vector3(19.7,2,0)
	await frames(25)
	if "--capture" in OS.get_cmdline_user_args():
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png("/tmp/sky-gate.png")
	player.position=Vector3(20.1,3.05,0)
	await frames(5)
	check(not Game.complete and Game.counts[2]==1 and not get_tree().paused,"cristal azul sem concluir a fase")
	get_tree().paused = false
	await check_slide()
	Audio.voice.stop()
	await get_tree().create_timer(.3,true,false,true).timeout
	get_tree().quit(failed)
