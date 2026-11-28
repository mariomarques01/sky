extends Node

const Pickup = preload("res://collectibles/pickup.gd")
const World = preload("res://worlds/world_01/level_01/World_01_Level_01.tscn")
@onready var world := $World
@onready var player := $World/Player as CharacterBody3D
@onready var expansion := $World/Expansion
var failures := 0

func frames(count: int) -> void:
	for i in count:
		await get_tree().physics_frame

func check(condition: bool, label: String) -> bool:
	print(("PASS " if condition else "FAIL ") + label)
	if not condition:
		failures += 1
	return condition

func stop_input() -> void:
	for action in [&"left", &"right", &"jump", &"dash", &"climb", &"crouch"]:
		Input.action_release(action)

func steer(target_x: float) -> void:
	var remaining := target_x - player.position.x
	var braking_distance := player.velocity.x * absf(player.velocity.x) / 49.0
	var side := signf(remaining)
	var still_approaching := signf(braking_distance) == side and absf(remaining) > absf(braking_distance)
	Input.action_release("left")
	Input.action_release("right")
	if absf(remaining) > 0.12 and (still_approaching or absf(player.velocity.x) < 0.25):
		Input.action_press("right" if side > 0 else "left")

func jump_to(target: Node3D, double_jump := false, dash := false, delay := 0) -> bool:
	var left_floor := false
	var used_dash := false
	var start_x := player.position.x
	if dash:
		steer(target.global_position.x)
		await frames(2)
	Input.action_press("jump")
	for frame in 130:
		var goal := target.global_position
		if frame >= delay:
			steer(goal.x)
		if double_jump and frame == 17:
			Input.action_release("jump")
		if double_jump and frame == 19:
			Input.action_press("jump")
		if dash and frame == 6:
			Input.action_press("dash")
		await frames(1)
		used_dash = used_dash or absf(player.velocity.x) > 10.0
		left_floor = left_floor or not player.is_on_floor()
		if left_floor and player.is_on_floor() and absf(player.position.x - goal.x) < 0.55 and absf(player.position.y - goal.y) < 0.2:
			stop_input()
			await frames(9)
			return check(not dash or used_dash, str(target.name))
		if player.get("recovery") > 0:
			break
	stop_input()
	return check(false, "%s de %.2f com chegada %s" % [target.name, start_x, player.position])

func run_to(x: float, limit: int) -> bool:
	for i in limit:
		steer(x)
		await frames(1)
		if absf(player.position.x - x) < .24 or Game.complete:
			stop_input()
			return true
	stop_input()
	return false

func stomp(crate: Node3D) -> bool:
	var target_x := crate.global_position.x
	var meadow := crate.get_parent()
	await frames(2)
	Input.action_press("jump")
	for frame in 75:
		steer(target_x)
		await frames(1)
		if not is_instance_valid(crate):
			stop_input()
			var bounced := player.velocity.y > 0
			var burst := meadow.get_node_or_null("WoodBurst")
			var splinters := burst.get_node("Splinters") as CPUParticles3D if burst else null
			var scattered := is_instance_valid(splinters) and splinters.mesh != null and splinters.emitting
			await frames(50)
			return bounced and scattered and not is_instance_valid(burst)
	stop_input()
	return false

func stomp_patrol(patrol: Area3D) -> bool:
	await frames(2)
	Input.action_press("jump")
	for frame in 75:
		steer(patrol.global_position.x)
		await frames(1)
		if patrol.get("defeated"):
			stop_input()
			await frames(50)
			return true
	stop_input()
	return false

func test_meadow() -> void:
	var meadow := expansion.get_node("FlowerMeadow")
	check(await run_to(71.9, 350) and player.is_on_floor() and not Game.complete, "continua pelo templo até o prado")
	var first := meadow.get_node("EntryCrate") as StaticBody3D
	var coins: int = Game.counts[1]
	check(not await run_to(first.position.x, 42) and is_instance_valid(first), "impacto lateral conserva a caixa")
	await run_to(71.95, 55)
	check(await stomp(first) and Game.counts[1] == coins + 1, "aterrissagem anima a caixa, lança estilhaços e libera uma moeda")

	check(await run_to(79.95, 150) and player.position.y > 2.7, "primeira subida gramada a pé")
	var gold: int = Game.counts[0]
	check(await stomp(meadow.get_node("FirstTerraceCrate")) and Game.counts[0] == gold + 1, "caixa do primeiro terraço libera cristal")
	var sentry := meadow.get_node("TerraceSentry") as Area3D
	check(await stomp_patrol(sentry), "sentinela do terraço pode ser derrotada por cima")
	var heart_guard := meadow.get_node("HeartGuardLeft") as Area3D
	var second_approach := heart_guard.position.x
	check(await run_to(84.15, 150) and player.position.y > 3.0, "segunda subida gramada a pé")
	check(absf(heart_guard.position.x - second_approach) > 0.06 and meadow.has_node("HeartGuardRight"), "dois inimigos cercam a caixa do coração")
	check(await stomp_patrol(heart_guard), "salto abre espaço para a caixa escoltada")
	await run_to(85.9, 100)
	Game.health = 2
	check(await stomp(meadow.get_node("SecondTerraceCrate")) and Game.health == 3, "caixa do segundo terraço libera coração")
	var shelf_entry := Marker3D.new()
	shelf_entry.name = "Prateleira de flores"
	meadow.add_child(shelf_entry)
	shelf_entry.position = Vector3(88.85, 5.15, 0)
	await jump_to(shelf_entry, true, false, 14)
	check(await stomp(meadow.get_node("ShelfCrate")), "caixa da saliência opcional pode ser quebrada")
	check(await run_to(96.05, 185) and Game.checkpoint.x > 96.0, "checkpoint do prado após os terraços")
	var hud := world.get_node("CanvasLayer")
	check(hud.notice.is_visible_in_tree(), "HUD anuncia o checkpoint do prado")
	player.position.y = -9
	await frames(45)
	check(absf(player.position.x - Game.checkpoint.x) < 0.12 and not meadow.has_node("EntryCrate"), "respawn do prado mantém as caixas já abertas")
	check(await run_to(101.1, 130) and not Game.complete and player.position.y > 2.6, "mirante dá acesso à trilha final")

	var camera := world.get_node("CameraRig") as Camera3D
	check(camera.position.x > 98.0, "câmera acompanha o mirante")

	var lookout_time := float(world.clock)
	await test_new_sections()
	await test_final_trail(hud, lookout_time)

func jump_toward(x: float, y: float, double_jump := false) -> bool:
	var marker := Marker3D.new()
	marker.name = "Pouso_%s" % x
	world.add_child(marker)
	await frames(1)
	marker.global_position = Vector3(x, y, 0)
	var landed := await jump_to(marker, double_jump)
	marker.queue_free()
	return landed

func ground_pound_enemy(enemy: Area3D) -> bool:
	await frames(3)
	Input.action_press("jump")
	for frame in 85:
		steer(enemy.global_position.x)
		if frame >= 12 and player.air_move in [&"Jump", &"DoubleJump"] and not player.is_on_floor() 			and absf(player.position.x - enemy.global_position.x) < .95:
			Input.action_press("crouch")
		await frames(1)
		if enemy.defeated:
			stop_input()
			await frames(14)
			return true
	stop_input()
	return false

func check_features(section: Node, names: Array[String]) -> void:
	for feature in names:
		check(section.has_node(feature), "%s inclui %s" % [section.name, feature])

func test_new_sections() -> void:
	var walk := expansion.get_node("WindWalk")
	var ruins := expansion.get_node("CascadeRuins")
	var corridor := expansion.get_node("SpikeCorridor")
	check_features(walk, ["PracticeLift", "GustFerry", "IntroGust", "FerryGust", "ShelfFlyer", "FerryFlyer", "WindTreasure"])
	check_features(ruins, ["ClimbPole", "WestWall", "EastWall", "FallingStep", "WaterfallMain", "CascadeCheckpoint", "RecoveryHeart", "CascadeTreasure"])
	check_features(corridor, ["PracticeSpiked", "PracticeShell", "CorridorSpiked", "CorridorShell", "SurpriseCrate", "HighCache", "CorridorCheckpoint", "CorridorTreasure"])
	check(await run_to(103.4, 95) and player.is_on_floor(), "mirante liga ao Caminho dos Ventos")
	await frames(2)
	await jump_to(walk.get_node("PracticeLift"))
	await jump_to(walk.get_node("WindStep"))
	check(await run_to(111.02, 60), "aproximação segura da primeira rajada")
	await jump_toward(113.1, 3.45)
	check(await run_to(115.08, 100), "alcança a plataforma da rajada")
	await frames(2)
	await jump_to(walk.get_node("GustFerry"), true)
	await jump_to(walk.get_node("WindRest"), true)
	await jump_to(walk.get_node("CloudNook"), true)
	check(Save.data.get_value(Pickup.CLAIMS, "windwalk_cloud", false), "tesouro dos ventos acessível")
	await jump_to(walk.get_node("WindRest"))

	check(await run_to(127.15, 100) and player.is_on_floor(), "chegada ao poste das cascatas")
	Input.action_press("climb")
	await frames(83)
	check(player.pole == ruins.get_node("ClimbPole") and player.position.y > 5.6, "poste permite subir acima da primeira borda")
	Input.action_release("climb")
	Input.action_press("right")
	await jump_to(ruins.get_node("PoleLanding"))
	await jump_to(ruins.get_node("WallStep"))
	await jump_toward(133.1, 7.55)
	await jump_to(ruins.get_node("FallsApproach"))
	await jump_to(ruins.get_node("FallingStep"))
	check(ruins.get_node("FallingStep").timer >= 0, "plataforma das cascatas cede depois do pouso")
	await jump_toward(140.92, 8.9)
	check(await run_to(142.0, 90) and ruins.get_node("CascadeCheckpoint").activated
		and absf(Game.checkpoint.x - 141.7) < .05, "checkpoint intermediário da cascata ativado")
	Game.health = 2
	check(await run_to(144.55, 90) and Game.health == 3, "coração da cascata recupera vida")
	await frames(12)
	await jump_to(ruins.get_node("CascadeAlcove"), true, false, 15)
	check(Save.data.get_value(Pickup.CLAIMS, "cascade_alcove", false), "tesouro da cascata acessível")
	await jump_toward(149.7, 7.45)
	var reached_corridor := await run_to(157.25, 170)
	await frames(8)
	check(reached_corridor and player.is_on_floor(), "descida das cascatas conecta ao corredor")
	check(await ground_pound_enemy(corridor.get_node("PracticeSpiked")), "impacto vertical derrota os espinhos isolados")
	await jump_toward(161.65, 4.85)
	await frames(20)
	check(await ground_pound_enemy(corridor.get_node("PracticeShell")), "impacto vertical derrota o Casco de Pedra isolado")
	check(await run_to(162.55, 100), "rota principal dá acesso à rota alta")
	await frames(12)
	await jump_to(corridor.get_node("HighStep"), true, false, 12)
	await jump_to(corridor.get_node("HighRun"))
	await jump_to(corridor.get_node("HighCache"))
	check(Save.data.get_value(Pickup.CLAIMS, "corridor_high", false), "rota alta rende o tesouro único")
	await jump_toward(176.45, 3.45)
	check(await run_to(176.65, 90) and corridor.get_node("CorridorCheckpoint").activated
		and absf(Game.checkpoint.x - 176.6) < .05, "checkpoint depois dos espinhos ativado")
	# Leave enough runway for an unshortened jump over the crate.
	check(await run_to(177.55, 90) and await stomp(corridor.get_node("SurpriseCrate")),
		"caixa do corredor libera a passagem e entrega o prêmio")
	check(await run_to(187.95, 150) and player.is_on_floor(), "corredor se conecta à trilha final a pé")

func reach_cannon(trail: Node3D) -> bool:
	var cannon := trail.get_node("Cannon")
	var last_jump := -60
	for frame in 350:
		if player.cannon == cannon:
			stop_input()
			return true
		if player.recovery > 0.0:
			break
		steer(cannon.position.x)
		if frame == last_jump + 26:
			Input.action_release("jump")
		if player.is_on_floor() and frame > last_jump + 27:
			for child in trail.get_children():
				if child is RigidBody3D:
					var distance: float = child.global_position.x - player.global_position.x
					if distance > .4 and distance < 3.8:
						last_jump = frame
						Input.action_press("jump")
						break
		await frames(1)
	stop_input()
	return false

func test_final_trail(hud: Node, lookout_time: float) -> void:
	var trail := expansion.get_node("LookoutTrail")
	check_features(trail, ["Spiked", "Flyer", "StoneShell", "BarrelSpawner", "Cannon", "Vine", "VineAnchor", "TrailCheckpoint", "Guardian"])
	check(await run_to(188.7, 50), "entrada da trilha deslocada")
	await jump_toward(192.15, 2.73)
	check(await reach_cannon(trail), "atravessa a rampa dos barris e alcança o canhão")
	if player.cannon:
		for frame in 230:
			if player.cannon.launch_velocity().x > 8.5 and player.cannon.launch_velocity().x < 10.4:
				break
			await frames(1)
	Input.action_press("right")
	Input.action_press("touch_attack")
	await frames(2)
	Input.action_release("touch_attack")
	check(player.cannon == null and player.velocity.y > 0, "canhão lança pelo botão Ação")
	check(await run_to(212.45, 160), "lançamento atravessa o vão")
	await frames(28)
	var final_checkpoint: Area3D = trail.get_node("TrailCheckpoint")
	check(final_checkpoint.activated and Game.checkpoint.is_equal_approx(final_checkpoint.global_position + final_checkpoint.respawn_offset),
		"checkpoint anterior ao chefe ativado pela travessia")
	check(await run_to(215.0, 100), "chegada à arena final")
	print("INFO Do mirante à arena com os três tesouros: %.1f s de jogo" % (float(world.clock) - lookout_time))
	var boss := trail.get_node("Guardian")
	check(boss.active and not Game.complete and not trail.has_node("GuardianCrystal"),
		"Guardião deslocado ativa a luta antes da conclusão")
	player.position.y = -9.0
	await frames(42)
	check(player.global_position.distance_to(Game.checkpoint) < .12 and not boss.active,
		"queda na arena devolve o jogador ao último checkpoint")
	check(await run_to(215.0, 100) and boss.active, "arena reativa após respawn")
	player.set_physics_process(false)
	for expected in [2, 1, 0]:
		player.strike_index = 0
		player.strike_time = .10
		boss.contact_player(player)
		player.reset_moves()
		check(boss.health == expected, "Guardião da trilha perde um ponto de vida")
		await frames(58)
	await frames(8)
	var crystal := trail.get_node_or_null("GuardianCrystal") as Area3D
	player.set_physics_process(true)
	if crystal:
		check(await run_to(crystal.global_position.x, 140), "recompensa alcançável a partir da arena")
	check(Game.complete, "cristal do Guardião conclui a fase")
	check(hud.result.is_visible_in_tree() and ("Moedas · %d" % Game.counts[1]) in hud.result.text, "resultado exibe as moedas da partida")

func test_cascade_recovery() -> void:
	var ruins := expansion.get_node("CascadeRuins")
	var platform: Node3D = ruins.get_node("FallingStep")
	# Land on the platform and stay on it through its full fall and reset.
	player.position = platform.position + Vector3.UP * .7
	player.velocity = Vector3.ZERO
	await frames(245)
	check(player.is_on_floor() and absf(player.position.y - 6.6) < .18
		and ruins.get_node("FallingStep").timer < 0.0, "plataforma cai sobre a prateleira de recuperação e retorna")
	check(await run_to(139.04, 90), "prateleira dá acesso ao degrau depois que a plataforma retorna")
	await frames(3)
	await jump_to(ruins.get_node("RecoveryStep"))
	await jump_toward(140.92, 8.9)
	check(await run_to(142.0, 90) and ruins.get_node("CascadeCheckpoint").activated,
		"rota de recuperação alcança o checkpoint das cascatas")

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	world.process_mode = Node.PROCESS_MODE_PAUSABLE
	await frames(5)
	# Start at the end of the original continuously tested route.
	player.position = Vector3(20.8, 1.85, 0)
	await frames(18)
	var crossing: Node3D = expansion.get_node("IslandCrossing")
	for island in ["FirstIsland", "LowIsland", "Ferry", "HighIsland"]:
		if not await jump_to(crossing.get_node(island)):
			get_tree().quit(1)
			return
		if island == "Ferry":
			var before := player.position.x
			await frames(30)
			check(player.is_on_floor() and absf(player.position.x - before) > .1, "ferry transporta o jogador")
	var ruins := expansion.get_node("RuinsSection")
	# Approach the ruins from the last crossing island using a full jump.
	var landing := Marker3D.new()
	landing.name = "EntradaDasRuinas"
	ruins.add_child(landing)
	landing.position = Vector3(38.65, 1.54, 0)
	await jump_to(landing)
	await jump_to(ruins.get_node("UpperWalk"))
	await jump_to(ruins.get_node("HiddenShelf"), true, false, 17)
	check(Save.data.get_value(Pickup.CLAIMS, "ruins_alcove", false), "coleta na passagem secreta")
	landing.position = Vector3(47, 1.54, 0)
	check(await run_to(47, 170), "saída da passagem secreta")
	check(Game.checkpoint.x > 46, "checkpoint da ponte")
	player.position.y = -9
	await frames(38)
	check(absf(player.position.x - Game.checkpoint.x) < .12 and player.is_on_floor(), "queda e respawn antes da ponte")
	check(await run_to(55.2, 170) and player.is_on_floor(), "travessia a pé da ponte")
	check(await run_to(62, 145) and player.position.y > 3.0, "escadas e chegada ao templo")
	check(Save.data.get_value(Pickup.CLAIMS, "temple_crystal", false), "cristal lendário")
	stop_input()
	player.position = Vector3(20.8, 1.85, 0)
	player.velocity = Vector3.ZERO
	await frames(18)
	var route := expansion.get_node("TreasureRoute")
	var chest := route.get_node("GoldenChest") as Area3D
	var chest_lid := chest.get_node("Visual/Lid") as Node3D
	for i in range(1, 8):
		# A missing health point makes the heart collectible.
		if i == 3:
			Game.health = 2
		var island := route.get_node("TreasureIsland" + str(i))
		if not await jump_to(island, i != 7, i == 5):
			get_tree().quit(1)
			return
		if i == 3:
			check(Game.health == 3, "coração restaura um ponto")
		if i == 6:
			check(chest_lid.rotation.x < -0.5, "animação de abertura do baú")
	for claim in ["sapphire_route", "amethyst_route", "golden_chest"]:
		check(Save.data.get_value(Pickup.CLAIMS, claim, false), claim)
	var camera := world.get_node("CameraRig") as Camera3D
	check(camera.position.x > 40 and camera.position.y > 6.0, "câmera acompanha a rota elevada")
	check(await run_to(49.25, 130), "saída da rota secreta")
	await frames(42)
	check(player.is_on_floor() and player.position.y < 2.1, "retorno da rota secreta à ponte")
	var rare_count: int = Game.counts[2]
	player.position.y = -9
	await frames(45)
	check(Game.counts[2] == rare_count and not chest.monitoring, "respawn preserva as coletas e o baú aberto")
	await test_meadow()
	get_tree().paused = false
	Audio.stop_all()
	world.queue_free()
	await frames(3)
	var from_disk := ConfigFile.new()
	check(from_disk.load(Save.PATH) == OK, "arquivo de recompensas gravado")
	check(from_disk.get_value("Jardins", "concluido", false)
		and from_disk.get_value("Jardins", "recorde", -1) >= Game.counts[0], "conclusão e recorde persistem em disco")
	for treasure_id in ["windwalk_cloud", "cascade_alcove", "corridor_high"]:
		check(from_disk.get_value(Pickup.CLAIMS, treasure_id, false), "tesouro único gravado: " + treasure_id)
	Save.data = from_disk
	world = World.instantiate()
	add_child(world)
	player = world.get_node("Player")
	expansion = world.get_node("Expansion")
	await frames(3)
	route = world.get_node("Expansion/TreasureRoute")
	check(not route.has_node("Sapphire") and not route.has_node("Amethyst") and not route.has_node("GoldenChest"), "recarregamento não duplica tesouros")
	check(world.get_node("Expansion/FlowerMeadow").has_node("EntryCrate"), "caixas comuns voltam em nova partida")
	for treasure_path in ["WindWalk/WindTreasure", "CascadeRuins/CascadeTreasure", "SpikeCorridor/CorridorTreasure"]:
		check(not world.get_node("Expansion").has_node(treasure_path), "tesouro da expansão não reaparece: " + treasure_path)
	await test_cascade_recovery()
	player.position = Vector3(223.2, 3.91, 0)
	await frames(6)
	var fresh_boss := world.get_node("Expansion/LookoutTrail/Guardian")
	check(fresh_boss.active and fresh_boss.health == 3 and not Game.complete and Game.counts[2] == 0,
		"nova partida disponibiliza outra luta sem conceder a vitória")
	get_tree().paused = false
	Audio.stop_all()
	await get_tree().create_timer(.5).timeout
	get_tree().quit(failures)
