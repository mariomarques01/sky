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
	await check_stone_shell()
	var phase_loop := preload("res://audio/music/celestial_gardens_loop.wav")
	Audio.play_stage_music(null, phase_loop)
	await check_boss(phase_loop)
	Audio.stop_all()
	await get_tree().create_timer(.5).timeout
	get_tree().quit(failures)

func hit_boss(boss: Area3D) -> void:
	player.strike_index = 0
	player.strike_time = .10
	boss.contact_player(player)
	player.reset_moves()

func wait_for_impact() -> void:
	for frame in 8:
		if not Game.is_hit_stopped():
			break
		await frames(1)

func check_boss(phase_loop: AudioStreamWAV) -> void:
	var boss := $Arena/Guardian
	var camera := $Arena/CameraRig
	var bar: ProgressBar = $Arena/CanvasLayer.boss_bar
	var checkpoint: Vector3 = boss.position + Vector3.LEFT * 9.0
	Game.activate_checkpoint(checkpoint)
	player.position = boss.position + Vector3.LEFT * 4
	await frames(2)
	check(camera.arena_locked and bar.visible and bar.value == 3, "ativação fixa a câmera e mostra três pontos de vida")
	check(Audio.current_track == boss.GUARDIAN_MUSIC and Audio.spare_music.playing,
		"ativação do Guardião inicia o fade entre as faixas")
	hit_boss(boss)
	check(boss.health == 2 and bar.value == 2 and Game.is_hit_stopped(), "golpe no chefe atualiza o HUD e pausa a física")
	var attack_start: Vector3 = boss.position
	await wait_for_impact()
	await frames(22)
	check(boss.action == boss.Action.WINDUP and boss.position.is_equal_approx(attack_start),
		"chefe fica parado durante a antecipação do salto")
	await frames(12)
	check(boss.position.y > boss.origin.y + .2 and not boss.flashing, "segunda fase salta só depois da antecipação")
	for frame in 70:
		if boss.action == boss.Action.WINDUP:
			break
		await frames(1)
	check(boss.action == boss.Action.WINDUP and boss.flashing and boss.position.y == boss.origin.y,
		"cada salto começa com uma nova antecipação")
	player.position = boss.position
	player.velocity = Vector3.ZERO
	player.health.shield = 0.0
	Game.health = 1
	boss.contact_player(player)
	check(Game.health == 0 and not boss.active and not camera.arena_locked
		and boss.health == 3 and boss.position.is_equal_approx(boss.origin) and not bar.visible,
		"dano via hurt aciona morte e reinicia o mesmo chefe")
	check(Audio.current_track == phase_loop, "morte restaura a faixa da fase")
	player.set_physics_process(true)
	await frames(25)
	player.set_physics_process(false)
	check(player.global_position.distance_to(checkpoint) < .2 and Game.health == 3 and not boss.active,
		"respawn no checkpoint deixa a arena inativa")

	player.position = boss.origin + Vector3.LEFT * 4
	await frames(2)
	check(boss.active and bar.visible and bar.value == 3, "voltar à arena inicia outra luta com vida cheia")
	hit_boss(boss)
	await frames(60)
	hit_boss(boss)
	check(boss.health == 1 and bar.value == 1 and boss.flashing, "terceira fase inicia com flash de investida")
	attack_start = boss.position
	await wait_for_impact()
	await frames(22)
	check(boss.position.is_equal_approx(attack_start) and boss.action == boss.Action.WINDUP,
		"chefe fica parado durante a antecipação da investida")
	await frames(10)
	check(boss.position.x < attack_start.x and boss.position.y == boss.origin.y, "terceira fase investe após a antecipação")
	await frames(26)
	hit_boss(boss)
	check(boss.defeated and not bar.visible and camera.defeat_target == boss.visual
		and not arena.has_node("GuardianCrystal") and not Game.complete,
		"derrota enquadra o chefe e aguarda os efeitos antes da recompensa")
	await frames(34)
	check(boss_spores and not arena.has_node("GuardianCrystal"), "partículas da derrota aparecem antes do cristal")
	await frames(32)
	var crystal := arena.get_node_or_null("GuardianCrystal") as Area3D
	check(not is_instance_valid(boss) and is_instance_valid(crystal) and not camera.arena_locked
		and Audio.current_track == phase_loop and not Game.complete,
		"cristal aparece, câmera volta ao jogador e música da fase retorna")
	if crystal:
		player.position = crystal.position
		await frames(4)
	var victory_playing := false
	for voice in Audio.voices:
		victory_playing = victory_playing or (voice.stream == Audio.EFFECTS[&"victory"] and voice.playing)
	check(Game.complete and victory_playing and not Audio.music.playing, "coletar o cristal conclui a fase antes do jingle")

func check_stone_shell() -> void:
	var shell := $Arena/StoneShell
	player.position = shell.position + Vector3.UP * .55
	player.velocity.y = -4
	shell.contact_player(player)
	player.strike_index = 0
	player.strike_time = .10
	shell.contact_player(player)
	check(shell.is_in_group("slam_target") and not shell.defeated, "casco resiste a stomp e soco")
	player.reset_moves()
	player.position = shell.position + Vector3.UP * 1.55
	player.air_move = &"GroundPound"
	player.velocity.y = -9.0
	player.set_physics_process(true)
	await frames(16)
	player.set_physics_process(false)
	check(shell.defeated, "ground pound no chão derrota o casco")
