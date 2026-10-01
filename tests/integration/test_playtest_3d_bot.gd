extends GutTest

const BATTLE_3D_SCENE: PackedScene = preload("res://scenes/battle_3d/battle_3d.tscn")
const KAKARIKO_3D_SCENE: PackedScene = preload("res://scenes/world_3d/kakariko_3d.tscn")


func before_each() -> void:
	SceneManager.suppress_transitions = true
	GameState.encounter_type = "normal"


func after_each() -> void:
	SceneManager.suppress_transitions = false
	if DialogueManager.is_active:
		DialogueManager.end_dialogue(DialogueManager.current_dialogue_id)


func test_playtest_battle_normal_reaches_conclusion() -> void:
	GameState.encounter_type = "normal"
	var battle: Battle3D = BATTLE_3D_SCENE.instantiate() as Battle3D
	add_child_autofree(battle)

	var bot: PlaytestBot3D = PlaytestBot3D.new()
	var result: Dictionary = bot.play_battle_to_completion(battle, 800)

	assert_true(
		result["success"],
		"Batalha normal jogada pelo bot deve terminar sem softlock: %s" % str(result)
	)
	assert_ne(result["outcome"], "timeout", "Batalha não deve sofrer timeout")
	assert_gt(result["commands_executed"], 0, "Bot deve ter executado comandos na batalha")


func test_playtest_battle_surprise_reaches_conclusion() -> void:
	GameState.encounter_type = "surprise"
	var battle: Battle3D = BATTLE_3D_SCENE.instantiate() as Battle3D
	add_child_autofree(battle)

	var bot: PlaytestBot3D = PlaytestBot3D.new()
	var result: Dictionary = bot.play_battle_to_completion(battle, 800)

	assert_true(
		result["success"],
		"Batalha surpresa jogada pelo bot deve terminar sem softlock: %s" % str(result)
	)
	assert_ne(result["outcome"], "timeout", "Batalha não deve sofrer timeout")


func test_playtest_battle_ambush_reaches_conclusion() -> void:
	GameState.encounter_type = "ambush"
	var battle: Battle3D = BATTLE_3D_SCENE.instantiate() as Battle3D
	add_child_autofree(battle)

	var bot: PlaytestBot3D = PlaytestBot3D.new()
	var result: Dictionary = bot.play_battle_to_completion(battle, 800)

	assert_true(
		result["success"],
		"Batalha emboscada jogada pelo bot deve terminar sem softlock: %s" % str(result)
	)
	assert_ne(result["outcome"], "timeout", "Batalha não deve sofrer timeout")


func test_playtest_kakariko_exploration_and_npc_interaction() -> void:
	var kakariko: Kakariko3D = KAKARIKO_3D_SCENE.instantiate() as Kakariko3D
	add_child_autofree(kakariko)

	# 1. Simula movimento do player
	assert_not_null(kakariko.player, "Player deve existir em Kakariko")
	var start_pos: Vector3 = kakariko.player.global_position

	# Move para frente por alguns frames
	kakariko.player.velocity = Vector3(0, 0, -5.0)
	kakariko.player.move_and_slide()
	kakariko.player._record_position_step()

	# Câmera acompanha
	kakariko._process(0.033)
	assert_gt(
		kakariko.camera.global_position.y,
		kakariko.player.global_position.y + 1.0,
		"Câmera de órbita deve permanecer acima do player durante movimento"
	)

	# 2. Seguidor acompanha histórico
	assert_not_null(kakariko.follower, "Follower deve existir")
	kakariko.follower._physics_process(0.033)

	# 3. Interage com NPC Tav se presente
	var npc: NPC3D = kakariko.get_node_or_null("NPC_Tav") as NPC3D
	if npc != null:
		npc.interact(kakariko.player)
		assert_true(DialogueManager.is_active, "Diálogo deve ser aberto ao interagir com Tav")
		# Avança todas as falas
		while DialogueManager.is_active:
			DialogueManager.advance_dialogue()
		assert_false(DialogueManager.is_active, "Diálogo deve ser concluído")
