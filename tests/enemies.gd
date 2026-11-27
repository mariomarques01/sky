extends Node

@onready var arena := $Arena
@onready var player := $Arena/Player
var failures := 0
var boss_spores := false

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
	spike.position.x = spike.limits.x
	spike.direction = -1
	spike.turn_remaining = 0.0
	await frames(1)
	check(spike.direction == -1 and is_equal_approx(spike.turn_remaining, .15), "espinhos sinalizam a virada no limite")
	await frames(8)
	check(spike.direction == -1 and spike.visual.scale.y < spike.visual_scale.y, "espinhos mantêm a direção durante a antecipação")
	await frames(1)
	check(spike.direction == 1, "espinhos viram após 150 ms")
	player.position = spike.position + Vector3.UP * .55
	player.velocity.y = -4
	await frames(3)
	check(Game.health == 3 and spike.attack_target == player and not spike.defeated, "stomp normal nos espinhos sinaliza dano")
	player.position.x -= 5.0
	await frames(12)
	check(Game.health == 3 and spike.attack_target == null, "sair do alcance cancela o ataque")
	player.position = spike.position + Vector3.UP * .55
	await frames(3)
	check(spike.attack_target == player, "novo contato inicia outra antecipação")
	await frames(9)
	check(Game.health == 2 and not spike.defeated, "espinhos causam dano após a antecipação")
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
	arena.child_entered_tree.connect(func(child: Node) -> void:
		if child.get_script() == preload("res://environment/effects/sparkles.gd") and child.tint == Color("#ffca83"):
			boss_spores = child.burst_amount == 8
	)
	var phase_loop := preload("res://audio/music/celestial_gardens_loop.wav")
	Audio.play_stage_music(null, phase_loop)
	var boss := $Arena/Guardian
	player.position = boss.position + Vector3.LEFT * 4
	await frames(2)
	var bar: ProgressBar = $Arena/CanvasLayer.boss_bar
	check(bar.visible and bar.value == 3, "HUD anuncia a vida do chefe")
	check(Audio.current_track == boss.GUARDIAN_MUSIC and Audio.spare_music.playing,
		"ativação do Guardião inicia o fade entre as faixas")
	for expected in [2, 1, 0]:
		player.strike_index = 0
		player.strike_time = .10
		boss.contact_player(player)
		check(boss.health == expected and bar.value == expected, "acerto no chefe resta %d" % expected)
		check(Game.is_hit_stopped(), "acerto no chefe pausa a física")
		player.position.x = boss.origin.x - 6
		await frames(58)
		if expected == 2:
			check(boss.position.y > boss.origin.y + .2, "segunda fase salta")
		elif expected == 1:
			check(boss.position.y == boss.origin.y and boss.position.x < boss.origin.x, "terceira fase investe")
	check(not bar.visible, "derrota encerra a barra do chefe")
	check(Audio.current_track == phase_loop and Audio.music.playing and not Audio.spare_music.playing,
		"derrota do chefe completa o fade de volta à música da fase")
	await frames(30)
	check(not is_instance_valid(boss) and boss_spores, "derrota libera partículas independentes do inimigo")
	Audio.stop_all()
	await get_tree().create_timer(.5).timeout
	get_tree().quit(failures)
