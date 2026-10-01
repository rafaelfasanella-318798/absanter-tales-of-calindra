extends GutTest

const BATTLE_3D_SCENE: PackedScene = preload("res://scenes/battle_3d/battle_3d.tscn")
const KAKARIKO_3D_SCENE: PackedScene = preload("res://scenes/world_3d/kakariko_3d.tscn")
const PLAYER_3D_SCENE: PackedScene = preload("res://scenes/world_3d/player_3d.tscn")
const DIALOGUE_BOX_SCENE: PackedScene = preload("res://scenes/ui/dialogue_box.tscn")


func before_each() -> void:
	GameState.encounter_type = "normal"
	GameState.current_mode = "exploration"
	SceneManager.suppress_transitions = true


func after_each() -> void:
	SceneManager.suppress_transitions = false
	if DialogueManager.is_active:
		DialogueManager.end_dialogue(DialogueManager.current_dialogue_id)


func test_d21_multi_hero_com_queue() -> void:
	GameState.encounter_type = "surprise"
	var battle: Battle3D = BATTLE_3D_SCENE.instantiate() as Battle3D
	add_child_autofree(battle)

	# No início da surpresa, ambos estão em 0.70 IP
	assert_eq(battle.combatants[0]["ip"], 0.70)
	assert_eq(battle.combatants[1]["ip"], 0.70)

	# Processando 0.2s: ambos ultrapassam o limiar COM (0.75) no mesmo frame
	battle._process(0.2)

	# D21: Hero 0 tem o menu aberto e Hero 1 está na fila
	assert_true(battle.command_panel.visible, "Menu deve estar aberto para o primeiro herói")
	assert_eq(battle.active_player_index, 0, "Ragg deve ser o combatente ativo")
	assert_eq(battle.hero_command_queue, [1], "Calindra deve estar na fila de comandos")
	assert_true(battle.is_time_stopped, "Tempo deve parar com menu aberto")

	# Ragg escolhe defender
	battle._on_defend_chosen()

	# Agora Calindra sai da fila e tem seu menu aberto
	assert_true(battle.command_panel.visible, "Menu deve abrir para Calindra")
	assert_eq(battle.active_player_index, 1, "Calindra deve ser a combatente ativa agora")
	assert_true(battle.hero_command_queue.is_empty(), "Fila deve estar vazia")

	# Calindra escolhe defender
	battle._on_defend_chosen()

	# Ambos terminaram; menu fecha e tempo volta a correr
	assert_false(battle.command_panel.visible, "Menu deve fechar após todos escolherem")
	assert_false(battle.is_time_stopped, "Tempo deve voltar a correr")


func test_d22_aerial_partner_filters() -> void:
	var battle: Battle3D = BATTLE_3D_SCENE.instantiate() as Battle3D
	add_child_autofree(battle)

	var ragg: Dictionary = battle.combatants[0]
	var calindra: Dictionary = battle.combatants[1]
	var slime: Dictionary = battle.combatants[2]

	calindra["sp"] = 30
	calindra["ip"] = 0.60

	# 1. Launcher player (Ragg) visando slime: encontra Calindra como parceiro
	var partner: Dictionary = battle._find_aerial_partner(ragg, slime)
	assert_eq(partner.get("id"), "calindra", "Calindra deve ser parceira de Ragg")

	# 2. Launcher inimigo (Slime) visando Ragg: NUNCA gera Aerial com players
	var enemy_launcher: Dictionary = slime
	var enemy_partner: Dictionary = battle._find_aerial_partner(enemy_launcher, ragg)
	assert_true(enemy_partner.is_empty(), "Inimigo não deve encontrar herói como parceiro")

	# 3. Alvo é a própria Calindra: Calindra NÃO pode ser parceira de si mesma
	var target_cal: Dictionary = calindra
	var p_target_cal: Dictionary = battle._find_aerial_partner(ragg, target_cal)
	assert_true(p_target_cal.is_empty(), "Alvo do Aerial não pode ser o parceiro")


func test_d23_defeat_panel_components() -> void:
	var battle: Battle3D = BATTLE_3D_SCENE.instantiate() as Battle3D
	add_child_autofree(battle)

	assert_not_null(battle.defeat_panel, "DefeatPanel deve existir na cena")
	assert_false(battle.defeat_panel.visible, "DefeatPanel deve iniciar invisível")

	# Derrota ambos os heróis
	battle.combatants[0]["hp"] = 0
	battle.combatants[1]["hp"] = 0
	battle._check_battle_end()

	assert_true(battle.is_battle_over, "Batalha deve ser encerrada")
	assert_true(battle.defeat_panel.visible, "DefeatPanel deve ficar visível na derrota")
	assert_false(
		battle.action_banner.text.contains("ESC"), "Texto de derrota não deve mencionar tecla ESC"
	)

	var btn_retry: Button = battle.get_node_or_null("UI/DefeatPanel/VBox/BtnRetry")
	var btn_title: Button = battle.get_node_or_null("UI/DefeatPanel/VBox/BtnTitle")
	assert_not_null(btn_retry, "Botão Tentar de novo deve existir")
	assert_not_null(btn_title, "Botão Título deve existir")


func test_d24_mouse_mode_and_focus() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	var battle: Battle3D = BATTLE_3D_SCENE.instantiate() as Battle3D
	add_child_autofree(battle)
	assert_eq(
		Input.get_mouse_mode(),
		Input.MOUSE_MODE_VISIBLE,
		"Battle3D deve deixar mouse visível no _ready"
	)

	# Kakariko libera mouse no _exit_tree
	var kakariko: Kakariko3D = KAKARIKO_3D_SCENE.instantiate() as Kakariko3D
	add_child_autofree(kakariko)
	kakariko._exit_tree()
	assert_eq(
		Input.get_mouse_mode(),
		Input.MOUSE_MODE_VISIBLE,
		"Kakariko3D deve liberar mouse no _exit_tree"
	)


func test_d25_kakariko_camera_pitch_and_elevation() -> void:
	var kakariko: Kakariko3D = KAKARIKO_3D_SCENE.instantiate() as Kakariko3D
	add_child_autofree(kakariko)

	# Simula frames de física para a câmera seguir o player
	kakariko._process(0.016)
	kakariko._process(0.016)

	assert_gt(
		kakariko.camera.global_position.y,
		kakariko.player.global_position.y + 1.0,
		"Câmera deve estar mais de 1m acima do player"
	)

	# Verifica limites da órbita: pitch mínimo e máximo nunca levam a câmera para o chão
	kakariko._orbit_pitch = kakariko.orbit_pitch_min
	kakariko._process(0.016)
	assert_gt(
		kakariko.camera.global_position.y,
		0.5,
		"Pitch mínimo não deve levar a câmera para dentro do chão"
	)

	kakariko._orbit_pitch = kakariko.orbit_pitch_max
	kakariko._process(0.016)
	assert_gt(
		kakariko.camera.global_position.y,
		kakariko.player.global_position.y + 1.0,
		"Pitch máximo deve manter a câmera acima do player"
	)


func test_d26_dialogue_locks_player_3d_and_scene_change_resets() -> void:
	var player3d: Player3D = PLAYER_3D_SCENE.instantiate() as Player3D
	player3d.add_to_group("player")
	add_child_autofree(player3d)

	var dialogue_box: DialogueBox = DIALOGUE_BOX_SCENE.instantiate() as DialogueBox
	add_child_autofree(dialogue_box)

	assert_false(player3d.is_movement_locked)

	DialogueManager.start_dialogue_sequence(
		"test_seq", [{"speaker": "Tav", "text": "Linha 1"}, {"speaker": "Tav", "text": "Linha 2"}]
	)
	assert_true(player3d.is_movement_locked, "Player3D deve ser travado durante diálogo")

	DialogueManager.advance_dialogue()
	DialogueManager.advance_dialogue()
	assert_false(player3d.is_movement_locked, "Player3D deve ser destravado após fim do diálogo")

	# Trocar de cena com diálogo ativo encerra o diálogo
	DialogueManager.start_dialogue_sequence(
		"test_seq2", [{"speaker": "Tav", "text": "Interrompido"}]
	)
	assert_true(DialogueManager.is_active)
	SceneManager.change_scene("res://scenes/world_3d/kakariko_3d.tscn")
	assert_false(
		DialogueManager.is_active, "Trocar de cena com diálogo aberto deve encerrar o diálogo"
	)


func test_d27_music_track_names() -> void:
	watch_signals(AudioManager)
	AudioManager.play_music("title_theme", 0.5)
	assert_signal_emitted_with_parameters(AudioManager, "music_started", ["title_theme"])

	AudioManager.play_music("battle_theme", 0.3)
	assert_signal_emitted_with_parameters(AudioManager, "music_started", ["battle_theme"])


func test_d28_surprise_and_ambush_banner_visible_on_ready() -> void:
	GameState.encounter_type = "surprise"
	var b_surp: Battle3D = BATTLE_3D_SCENE.instantiate() as Battle3D
	add_child_autofree(b_surp)
	assert_true(
		b_surp.action_banner.text.contains("SURPRISE ATTACK"),
		"Banner de surpresa deve estar visível após _ready"
	)

	GameState.encounter_type = "ambush"
	var b_amb: Battle3D = BATTLE_3D_SCENE.instantiate() as Battle3D
	add_child_autofree(b_amb)
	assert_true(
		b_amb.action_banner.text.contains("AMBUSH"),
		"Banner de emboscada deve estar visível após _ready"
	)


func test_d19_combo_does_not_cancel_act() -> void:
	var battle: Battle3D = BATTLE_3D_SCENE.instantiate() as Battle3D
	add_child_autofree(battle)

	var attacker: Dictionary = battle.combatants[0]
	var target: Dictionary = battle.combatants[2]
	target["state"] = "act"
	target["ip"] = 0.90

	battle._resolve_combo(attacker, target)

	assert_eq(target["state"], "act", "COMBO não cancela o estado ACT")
	assert_lt(target["ip"], 0.90, "COMBO deve empurrar a barra de IP do alvo")


func test_battle_over_prevents_command_menu() -> void:
	var battle: Battle3D = BATTLE_3D_SCENE.instantiate() as Battle3D
	add_child_autofree(battle)

	battle.is_battle_over = true
	battle._open_hero_command(0)

	assert_false(
		battle.command_panel.visible, "Com a batalha terminada, menu de comandos não deve abrir"
	)
