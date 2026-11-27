extends Node

@onready var arena := $Arena
@onready var player := $Arena/Player
var failures := 0

func check(condition: bool, label: String) -> void:
	print(("PASS " if condition else "FAIL ") + label)
	if not condition:
		failures += 1

func frames(count: int) -> void:
	for index in count:
		await get_tree().physics_frame

func _ready() -> void:
	await frames(5)
	var barrel := arena.get_node("RollingBarrel") as RigidBody3D
	var top := barrel.position
	await frames(60)
	check(barrel.position.x < top.x and barrel.position.y < top.y and absf(barrel.position.z) < .001,
		"barril desce a inclinação no plano")
	player.set_physics_process(false)
	player.position = barrel.position - Vector3.UP * .35
	player.strike_index = 0
	player.strike_time = .10
	await frames(5)
	check(not is_instance_valid(barrel), "soco ativo quebra o barril")
	player.reset_moves()
	var spike := $Arena/Spiked
	player.position = spike.position + Vector3.UP * .6
	player.velocity.y = -4
	spike.contact_player(player)
	check(Game.health == 2 and not spike.defeated, "stomp normal nos espinhos causa dano")
	player.air_move = &"GroundPound"
	player.ground_pound.emit(spike.position)
	check(spike.defeated, "impacto vertical derrota espinhos")
	player.reset_moves()
	var flyer := $Arena/Flyer
	var start: Vector3 = flyer.position
	await frames(10)
	check(absf(flyer.position.y - start.y) > .001 and absf(flyer.position.x - start.x) > .001, "voo senoidal")
	player.position = flyer.position + Vector3.UP * .6
	player.velocity.y = -4
	flyer.contact_player(player)
	check(flyer.defeated and player.velocity.y > 0, "stomp no voador dá quique")
	player.stun = 0
	player.dash.air_available = false
	player.position = $Arena/Cannon.position
	await frames(5)
	check(player.cannon == $Arena/Cannon, "canhão captura por sobreposição")
	player.set_physics_process(true)
	Input.action_press("jump")
	await frames(2)
	player.set_physics_process(false)
	Input.action_release("jump")
	check(player.cannon == null and player.velocity.y > 0 and player.dash.air_available, "canhão lança e habilita dash")
	var grip := $Arena/Vine/Grip
	player.position = grip.to_global(Vector3.UP)
	Input.action_press("climb")
	player.try_grab_pole()
	Input.action_release("climb")
	check(player.pole == grip, "cipó usa a ação de escalada")
	var height: float = player.pole_height
	await frames(10)
	player.update_pole(0, .016)
	check(player.position.distance_to(grip.to_global(Vector3.UP * height)) < .01, "jogador acompanha o balanço")
	player.reset_moves()
	var boss := $Arena/Guardian
	player.position = boss.position + Vector3.LEFT * 4
	await frames(2)
	var bar: ProgressBar = $Arena/CanvasLayer.boss_bar
	check(bar.visible and bar.value == 3, "HUD anuncia a vida do chefe")
	for expected in [2, 1, 0]:
		player.strike_index = 0
		player.strike_time = .10
		boss.contact_player(player)
		check(boss.health == expected and bar.value == expected, "acerto no chefe resta %d" % expected)
		player.position.x = boss.origin.x - 6
		await frames(54)
		if expected == 2:
			check(boss.position.y > boss.origin.y + .2, "segunda fase salta")
		elif expected == 1:
			check(boss.position.y == boss.origin.y and boss.position.x < boss.origin.x, "terceira fase investe")
	check(not bar.visible, "derrota encerra a barra do chefe")
	get_tree().quit(failures)
