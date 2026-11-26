extends Node3D

@onready var player: CharacterBody3D = $Player
var failures := 0
var impacts := 0

func check(condition: bool, label: String) -> void:
	print(("PASS " if condition else "FAIL ") + label)
	if not condition:
		failures += 1

func frames(count: int) -> void:
	for index in count:
		await get_tree().physics_frame

func reset_at(feet: Vector3) -> void:
	for action in ["left", "right", "jump", "crouch", "dive", "climb"]:
		Input.action_release(action)
	player.reset_moves()
	player.buffered = 0
	player.coyote = 0
	player.jumps = 0
	player.stun = 0
	player.landing = 0
	player.dash.reset()
	player.position = feet
	player.velocity = Vector3.ZERO
	await frames(5)

func wait_for_ground() -> bool:
	for index in 120:
		if player.is_on_floor():
			return true
		await frames(1)
	return false

func jump() -> void:
	Input.action_press("jump")
	await frames(2)

func add_block(center: Vector3, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = size
	collision.shape = box
	body.add_child(collision)
	add_child(body)
	body.position = center
	return body

func _ready() -> void:
	player.ground_pound.connect(func(_point: Vector3) -> void: impacts += 1)
	await reset_at(Vector3.ZERO)

	await jump()
	Input.action_release("jump")
	await frames(3)
	await jump()
	check(player.air_move == &"DoubleJump" and player.velocity.y > 5, "segundo impulso no ar")
	Input.action_release("jump")

	await reset_at(Vector3(-25, 0, 0))
	Input.action_press("right")
	await frames(28)
	for expected in [&"Jump", &"ChainJump", &"TripleJump"]:
		await jump()
		check(player.air_move == expected, String(expected))
		await frames(10)
		Input.action_release("jump")
		check(await wait_for_ground(), "pouso do salto encadeado")

	await reset_at(Vector3.ZERO)
	Input.action_press("crouch")
	await frames(2)
	await jump()
	check(player.air_move == &"Backflip" and player.velocity.y > 9 and player.velocity.x < 0, "mortal para trás")

	await reset_at(Vector3.ZERO)
	Input.action_press("right")
	await frames(25)
	Input.action_press("crouch")
	await frames(2)
	await jump()
	check(player.air_move == &"LongJump" and player.velocity.x > 8, "salto longo")

	await reset_at(Vector3.ZERO)
	Input.action_press("right")
	await frames(25)
	Input.action_release("right")
	Input.action_press("left")
	await frames(2)
	await jump()
	check(player.air_move == &"SideFlip" and player.velocity.x < 0, "mortal lateral")

	await reset_at(Vector3(38.9, 2.4, 0))
	player.velocity.x = 5.2
	Input.action_press("right")
	for index in 20:
		if player.wall_time > 0:
			break
		await frames(1)
	await jump()
	check(player.air_move == &"WallKick" and player.velocity.x < 0, "salto de parede")

	await reset_at(Vector3(0, 1.8, 0))
	Input.action_press("dive")
	await frames(2)
	check(player.air_move == &"AirKick" and player.velocity.y > 0, "chute aéreo")

	await reset_at(Vector3.ZERO)
	Input.action_press("right")
	await frames(28)
	Input.action_press("dive")
	await frames(2)
	check(player.air_move == &"Dive", "mergulho de corrida")
	check(await wait_for_ground(), "pouso após mergulho")
	check(player.belly_slide, "deslizada após mergulho")
	await jump()
	check(player.air_move == &"Rollout", "cambalhota de saída")

	await reset_at(Vector3(0, 2.2, 0))
	Input.action_press("crouch")
	await frames(2)
	check(player.air_move == &"PoundWindup", "preparação do impacto vertical")
	check(await wait_for_ground(), "pouso após impacto vertical")
	check(impacts == 1, "impacto vertical emitido uma vez")

	var ledge := add_block(Vector3(22, .66, 0), Vector3(2, 1.32, 2))
	await reset_at(Vector3(20.35, .75, 0))
	Input.action_press("right")
	player.velocity.x = 5.8
	for index in 15:
		if player.ledge == ledge:
			break
		await frames(1)
	check(player.ledge == ledge, "agarra borda enquanto desce")
	await jump()
	check(player.ledge == null and player.position.y > 1.3, "sobe da borda com salto")

	add_block(Vector3(10, .12, 0), Vector3(1.3, .24, 2))
	await reset_at(Vector3(8.5, 0, 0))
	Input.action_press("right")
	await frames(23)
	check(player.position.x > 9.35 and player.position.y > .22, "sobe degrau baixo sem salto")

	var objects := preload("res://environment/movement/MovementObjects.tscn").instantiate() as Node3D
	add_child(objects)
	await reset_at(Vector3(-4.2, 2.4, 0))
	Input.action_press("crouch")
	await frames(110)
	check(not objects.has_node("Crate"), "impacto quebra a caixa")

	await reset_at(Vector3(-5.95, 1.3, 0))
	for index in 45:
		if player.air_move == &"Bounce":
			break
		await frames(1)
	check(player.air_move == &"Bounce" and player.velocity.y > 8, "trampolim dispara no contato descendente")

	await reset_at(Vector3(-4.95, 0.0, 0))
	Input.action_press("climb")
	await frames(20)
	check(player.pole == objects.get_node("Pole") and player.position.y > .4, "subida pelo poste")
	await jump()
	check(player.air_move == &"PoleJump" and player.pole == null, "salto de saída do poste")

	await reset_at(Vector3(-5.65, 3.64, 0))
	var falling := objects.get_node("FallingPlatform") as Node3D
	await frames(70)
	check(falling.position.y < 2.6, "plataforma cai após contato")
	await reset_at(Vector3.ZERO)
	await frames(170)
	check(is_equal_approx(falling.position.y, 3.5), "plataforma volta após a queda")

	Audio.voice.stop()
	await get_tree().create_timer(.3).timeout
	get_tree().quit(failures)
