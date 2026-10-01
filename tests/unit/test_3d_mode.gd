# gdlint:disable = max-public-methods
extends GutTest

const PLAYER_3D_SCENE: PackedScene = preload("res://scenes/world_3d/player_3d.tscn")
const FOLLOWER_3D_SCENE: PackedScene = preload("res://scenes/world_3d/follower_3d.tscn")
const NPC_3D_SCENE: PackedScene = preload("res://scenes/world_3d/npc_3d.tscn")
const KAKARIKO_3D_SCENE: PackedScene = preload("res://scenes/world_3d/kakariko_3d.tscn")
const BATTLE_3D_SCENE: PackedScene = preload("res://scenes/battle_3d/battle_3d.tscn")
const WANDERER_SCENE: PackedScene = preload("res://scenes/world_3d/enemy_wanderer_3d.tscn")
const CAMP_SCENE: PackedScene = preload("res://scenes/world_3d/camp_3d.tscn")


func test_player_3d_instantiation() -> void:
	var player: Node3D = PLAYER_3D_SCENE.instantiate() as Node3D
	add_child_autofree(player)
	assert_not_null(player, "Player3D deve instanciar")
	assert_not_null(player.name_label, "Player3D deve ter NameLabel")
	assert_eq(player.name_label.text, "Ragg")
	assert_eq(player.move_speed, 6.0)

	player.lock_movement(true)
	assert_true(player.is_movement_locked)
	player.lock_movement(false)
	assert_false(player.is_movement_locked)


func test_follower_3d_instantiation() -> void:
	var follower: Node3D = FOLLOWER_3D_SCENE.instantiate() as Node3D
	add_child_autofree(follower)
	assert_not_null(follower, "Follower3D deve instanciar")
	assert_not_null(follower.name_label, "Follower3D deve ter NameLabel")
	assert_eq(follower.name_label.text, "Calindra")


func test_npc_3d_instantiation() -> void:
	var npc: Node3D = NPC_3D_SCENE.instantiate() as Node3D
	add_child_autofree(npc)
	assert_not_null(npc, "NPC3D deve instanciar")
	assert_not_null(npc.name_label, "NPC3D deve ter NameLabel")
	assert_eq(npc.name_label.text, "Tav")


func test_kakariko_3d_scene_loads() -> void:
	var village: Node3D = KAKARIKO_3D_SCENE.instantiate() as Node3D
	add_child(village)
	assert_not_null(village, "Cena Kakariko3D deve instanciar")
	assert_not_null(village.player, "Player3D presente em Kakariko3D")
	assert_not_null(village.follower, "Follower3D presente em Kakariko3D")
	assert_not_null(village.camera, "Camera3D (via SpringArm) deve estar presente")
	assert_not_null(village.spring_arm, "SpringArm3D deve estar presente")
	assert_not_null(village.camera_rig, "CameraRig deve estar presente")
	assert_not_null(village.battle_portal, "BattlePortal presente em Kakariko3D")
	assert_true(village.spring_arm.spring_length > 0.0, "SpringArm3D deve ter spring_length > 0")
	remove_child(village)
	village.free()


# ──────────────────────────────────────────────
# Testes do combate 3D Grandia III
# ──────────────────────────────────────────────
func test_battle_3d_scene_loads_with_four_combatants() -> void:
	var battle: Node3D = BATTLE_3D_SCENE.instantiate() as Node3D
	add_child_autofree(battle)
	assert_not_null(battle, "Battle3D deve instanciar")
	assert_eq(battle.combatants.size(), 4, "Deve ter 4 combatentes")
	assert_eq(battle.combatants[0]["name"], "Ragg")
	assert_eq(battle.combatants[1]["name"], "Calindra")
	# Nomes vêm dos EnemyData resources
	assert_eq(battle.combatants[2]["id"], "slime", "3º combatente deve ter id 'slime'")
	assert_eq(
		battle.combatants[3]["id"], "kakariko_golem", "4º combatente deve ter id 'kakariko_golem'"
	)


func test_battle_3d_combatants_have_sp_field() -> void:
	var battle: Node3D = BATTLE_3D_SCENE.instantiate() as Node3D
	add_child_autofree(battle)
	for c in battle.combatants:
		assert_true(c.has("sp"), "Todo combatente deve ter campo 'sp': %s" % c["name"])
		assert_true(c.has("max_sp"), "Todo combatente deve ter campo 'max_sp': %s" % c["name"])
		assert_eq(c["sp"], 0, "%s deve iniciar SP = 0" % c["name"])


func test_combo_deals_two_hits_and_pushes_ip() -> void:
	var battle: Node3D = BATTLE_3D_SCENE.instantiate() as Node3D
	add_child_autofree(battle)

	var attacker: Dictionary = battle.combatants[0]  # Ragg
	var target: Dictionary = battle.combatants[2]  # Slime
	var hp_before: int = target["hp"]
	var ip_before: float = target["ip"]

	target["ip"] = 0.5  # Slime na fase WAIT
	target["state"] = "wait"
	battle._resolve_combo(attacker, target)

	# HP deve ter diminuído
	assert_lt(target["hp"], hp_before, "COMBO deve causar dano")
	# IP do Slime deve ter recuado
	assert_lt(target["ip"], 0.5 - 0.01, "COMBO deve empurrar a IP do alvo para trás")
	# Ragg deve ter ganhado SP
	assert_gt(attacker["sp"], 0, "COMBO deve gerar SP para o atacante")


func test_critical_cancels_enemy_in_act_phase() -> void:
	var battle: Node3D = BATTLE_3D_SCENE.instantiate() as Node3D
	add_child_autofree(battle)

	var attacker: Dictionary = battle.combatants[0]  # Ragg
	var target: Dictionary = battle.combatants[2]  # Slime

	var hp_before: int = target["hp"]
	# Simula Slime em fase ACT (janela de cancel)
	target["state"] = "act"
	target["ip"] = 0.88

	battle._resolve_critical(attacker, target)

	# O cancel banner deve estar visível
	assert_true(battle.cancel_banner.visible, "CancelBanner deve aparecer ao aplicar CANCEL")
	# O alvo deve ter voltado para estado wait com IP recuada
	assert_eq(target["state"], "wait", "Alvo cancelado deve voltar ao estado WAIT")
	assert_lt(target["ip"], 0.88 - 0.10, "CRITICAL CANCEL deve recuar bastante a IP do alvo")
	# Dano do CRITICAL deve ser maior que COMBO em HP equivalente
	assert_lt(target["hp"], hp_before, "CRITICAL deve causar dano")


func test_critical_no_cancel_outside_act_phase() -> void:
	var battle: Node3D = BATTLE_3D_SCENE.instantiate() as Node3D
	add_child_autofree(battle)

	var attacker: Dictionary = battle.combatants[0]  # Ragg
	var target: Dictionary = battle.combatants[3]  # Golem

	target["state"] = "wait"
	target["ip"] = 0.3
	var hp_before: int = target["hp"]

	battle._resolve_critical(attacker, target)

	# Sem cancel (estado era wait): banner NÃO deve ter aparecido ainda
	# (pode estar visível de outra vez, mas o teste verifica que o hp diminuiu)
	assert_lt(target["hp"], hp_before, "CRITICAL fora de ACT ainda causa dano")
	# IP não deve ter recuado pelo push de cancel (só pelo combo_push não é aplicado aqui)
	assert_eq(target["ip"], 0.3, "CRITICAL fora de ACT preserva o valor da IP")


func test_combo_does_not_cancel_banner() -> void:
	var battle: Node3D = BATTLE_3D_SCENE.instantiate() as Node3D
	add_child_autofree(battle)

	# Reset o banner
	battle.cancel_banner.visible = false

	var attacker: Dictionary = battle.combatants[0]
	var target: Dictionary = battle.combatants[2]
	target["state"] = "act"  # Mesmo em ACT, COMBO não aciona o banner de CANCEL explícito

	battle._resolve_combo(attacker, target)

	# COMBO não exibe o CANCEL banner (só empurra IP silenciosamente)
	assert_false(battle.cancel_banner.visible, "COMBO não deve exibir o CancelBanner explícito")


func test_debug_console_3d_commands() -> void:
	SceneManager.suppress_transitions = true
	var console: DebugConsole = DebugConsole
	assert_not_null(console)
	var res_3d: String = console.execute_command("3d")
	assert_true(res_3d.contains("Kakariko 3D"))
	var res_bat: String = console.execute_command("battle3d")
	assert_true(res_bat.contains("Batalha 3D Grandia"))
	SceneManager.suppress_transitions = false


# ──────────────────────────────────────────────
# Testes do Aerial Launch & Aerial Combo
# ──────────────────────────────────────────────
func test_aerial_launch_sets_is_airborne() -> void:
	var battle: Node3D = BATTLE_3D_SCENE.instantiate() as Node3D
	add_child_autofree(battle)

	var launcher: Dictionary = battle.combatants[0]  # Ragg
	var target: Dictionary = battle.combatants[2]  # Slime

	target["is_airborne"] = false
	target["state"] = "act"
	target["ip"] = 0.85
	target["hp"] = 35  # Vivo

	battle._trigger_aerial_launch(target, launcher)

	assert_true(target["is_airborne"], "Alvo deve estar is_airborne após aerial launch")


func test_find_aerial_partner_returns_empty_without_sp() -> void:
	var battle: Node3D = BATTLE_3D_SCENE.instantiate() as Node3D
	add_child_autofree(battle)

	var launcher: Dictionary = battle.combatants[0]  # Ragg

	# Calindra sem SP suficiente
	var calindra: Dictionary = battle.combatants[1]
	calindra["sp"] = 0
	calindra["ip"] = 0.6

	var result: Dictionary = battle._find_aerial_partner(launcher)
	assert_true(result.is_empty(), "_find_aerial_partner deve retornar {} quando SP insuficiente")


func test_find_aerial_partner_returns_calindra_with_enough_sp_and_ip() -> void:
	var battle: Node3D = BATTLE_3D_SCENE.instantiate() as Node3D
	add_child_autofree(battle)

	var launcher: Dictionary = battle.combatants[0]  # Ragg
	var calindra: Dictionary = battle.combatants[1]

	# Dá SP e IP suficientes para Calindra
	calindra["sp"] = battle.SP_COST_AERIAL + 5
	calindra["ip"] = 0.55

	var result: Dictionary = battle._find_aerial_partner(launcher)
	assert_false(result.is_empty(), "_find_aerial_partner deve encontrar Calindra")
	assert_eq(result["id"], "calindra", "O parceiro aéreo deve ser Calindra")


func test_aerial_combo_consumes_partner_sp() -> void:
	var battle: Node3D = BATTLE_3D_SCENE.instantiate() as Node3D
	add_child_autofree(battle)

	var partner: Dictionary = battle.combatants[1]  # Calindra
	var target: Dictionary = battle.combatants[2]  # Slime

	var initial_sp: int = 80
	partner["sp"] = initial_sp
	target["hp"] = 45
	target["is_airborne"] = true

	var land_pos: Vector3 = target["node"].global_position if target["node"] else Vector3.ZERO
	battle._execute_aerial_combo(partner, target, land_pos)

	# SP deve ter diminuído
	assert_lt(partner["sp"], initial_sp, "Aerial Combo deve consumir SP do parceiro")
	assert_true(
		partner["sp"] <= initial_sp - battle.SP_COST_AERIAL,
		"SP consumido deve ser >= SP_COST_AERIAL"
	)


# ──────────────────────────────────────────────
# Testes da Evasão Tática (Evade / Move)
# ──────────────────────────────────────────────
func test_evade_reduces_ip_and_keeps_wait_state() -> void:
	var battle: Node3D = BATTLE_3D_SCENE.instantiate() as Node3D
	add_child_autofree(battle)

	var ragg: Dictionary = battle.combatants[0]
	ragg["ip"] = 0.75  # Estava no ponto COM
	ragg["state"] = "command"

	var ip_before: float = ragg["ip"]
	battle._resolve_evade(ragg)

	# IP deve ter recuado pelo custo de evasão
	assert_lt(ragg["ip"], ip_before, "Evasão deve reduzir a IP do personagem")
	assert_true(
		ragg["ip"] <= ip_before - battle.IP_COST_EVADE + 0.001,
		"IP deve recuar pelo menos IP_COST_EVADE"
	)
	# Estado deve voltar a wait (não consome um turno de ação)
	assert_eq(ragg["state"], "wait", "Após evasão o estado deve ser 'wait'")


func test_evade_updates_home_pos() -> void:
	var battle: Node3D = BATTLE_3D_SCENE.instantiate() as Node3D
	add_child_autofree(battle)

	var ragg: Dictionary = battle.combatants[0]
	var original_home: Vector3 = ragg["home_pos"]

	battle._resolve_evade(ragg)

	# home_pos deve ter mudado após a evasão
	assert_ne(ragg["home_pos"], original_home, "home_pos deve mudar de posição após a evasão")


# ──────────────────────────────────────────────
# Testes de carregamento de EnemyData (Item 5)
# ──────────────────────────────────────────────
func test_slime_stats_loaded_from_enemy_data_resource() -> void:
	var battle: Node3D = BATTLE_3D_SCENE.instantiate() as Node3D
	add_child_autofree(battle)

	var slime: Dictionary = battle.combatants[2]
	# slime.tres: max_hp=45, attack=12, defense=6, magic=5, speed=8
	assert_eq(slime["max_hp"], 45, "Slime: max_hp deve vir do resource (45)")
	assert_eq(slime["attack"], 12, "Slime: attack deve vir do resource (12)")
	assert_eq(slime["defense"], 6, "Slime: defense deve vir do resource (6)")
	assert_not_null(slime.get("enemy_data"), "Slime: campo enemy_data deve estar preenchido")


func test_golem_stats_loaded_from_enemy_data_resource() -> void:
	var battle: Node3D = BATTLE_3D_SCENE.instantiate() as Node3D
	add_child_autofree(battle)

	var golem: Dictionary = battle.combatants[3]
	# kakariko_golem.tres: max_hp=260, attack=24, defense=16
	assert_eq(golem["max_hp"], 260, "Golem: max_hp deve vir do resource (260)")
	assert_eq(golem["attack"], 24, "Golem: attack deve vir do resource (24)")
	assert_eq(golem["defense"], 16, "Golem: defense deve vir do resource (16)")
	assert_not_null(golem.get("enemy_data"), "Golem: campo enemy_data deve estar preenchido")


func test_enemy_data_to_dict_fallback_when_null() -> void:
	var battle: Node3D = BATTLE_3D_SCENE.instantiate() as Node3D
	add_child_autofree(battle)

	# Chama com null para testar o caminho de fallback
	var result: Dictionary = battle._enemy_data_to_dict(
		null, "test_enemy", "Test Enemy", null, Vector3.ZERO, Color.WHITE, "?", 0.1
	)
	assert_eq(result["id"], "test_enemy", "Fallback: id deve ser o fornecido")
	assert_eq(result["name"], "Test Enemy", "Fallback: name deve ser o fornecido")
	assert_eq(result["hp"], 45, "Fallback: hp deve ser 45")
	assert_null(result["enemy_data"], "Fallback: enemy_data deve ser null")


# ──────────────────────────────────────────────
# Testes do EnemyWanderer3D e Sistema de Encontro (Item 7)
# ──────────────────────────────────────────────
func test_enemy_wanderer_3d_instantiation() -> void:
	var wanderer: Node3D = WANDERER_SCENE.instantiate() as Node3D
	add_child_autofree(wanderer)
	assert_not_null(wanderer, "EnemyWanderer3D deve instanciar")
	assert_true(wanderer.wander_radius > 0.0, "wander_radius deve ser positivo")
	assert_true(wanderer.wander_speed > 0.0, "wander_speed deve ser positivo")
	assert_true(wanderer.backstab_angle_deg > 0.0, "backstab_angle_deg deve ser positivo")


func test_encounter_classify_normal_when_facing_each_other() -> void:
	## Inimigo olha para o player que está na frente = encontro NORMAL
	var wanderer: EnemyWanderer3D = WANDERER_SCENE.instantiate() as EnemyWanderer3D
	add_child_autofree(wanderer)

	var player: Player3D = PLAYER_3D_SCENE.instantiate() as Player3D
	add_child_autofree(player)

	# Posiciona player à frente do inimigo (ambos olham um para o outro)
	wanderer.global_position = Vector3(0, 0, 0)
	# Inimigo aponta para +Z (forward = -Z no Godot basis = -Z negativo de basis.z)
	# Para simular frente em +Z, rotacionamos 180°
	wanderer.rotation.y = PI
	player.global_position = Vector3(0, 0, 2.0)

	var result: String = wanderer._classify_encounter(player)
	assert_eq(result, "normal", "Encontro frontal deve ser 'normal'")


func test_battle_3d_surprise_boosts_player_ip() -> void:
	GameState.encounter_type = "surprise"
	var battle: Node3D = BATTLE_3D_SCENE.instantiate() as Node3D
	add_child_autofree(battle)

	# Verifica que a party tem IP elevada após surprise
	for c in battle.combatants:
		if c["is_player"]:
			assert_true(
				c["ip"] >= 0.65, "Surprise Attack: party deve ter IP >= 0.65 (era: %s)" % c["ip"]
			)
	# Reseta o GameState
	assert_eq(GameState.encounter_type, "normal", "encounter_type deve ser resetado após uso")


func test_battle_3d_ambush_boosts_enemy_ip() -> void:
	GameState.encounter_type = "ambush"
	var battle: Node3D = BATTLE_3D_SCENE.instantiate() as Node3D
	add_child_autofree(battle)

	# Verifica que os inimigos têm IP elevada após ambush
	for c in battle.combatants:
		if not c["is_player"]:
			assert_true(
				c["ip"] >= 0.65, "Ambush: inimigos devem ter IP >= 0.65 (era: %s)" % c["ip"]
			)


func test_battle_3d_normal_encounter_preserves_initial_ip() -> void:
	GameState.encounter_type = "normal"
	var battle: Node3D = BATTLE_3D_SCENE.instantiate() as Node3D
	add_child_autofree(battle)

	# Ragg começa com IP = 0.1 (definido em _init_combatants)
	var ragg: Dictionary = battle.combatants[0]
	assert_eq(ragg["ip"], 0.1, "Encontro normal: Ragg deve ter IP inicial 0.1")


# ──────────────────────────────────────────────
# Testes do Camp3D — Sistema de Acampamento (Item 8)
# ──────────────────────────────────────────────
func test_camp_3d_instantiation() -> void:
	var camp: Node3D = CAMP_SCENE.instantiate() as Node3D
	add_child_autofree(camp)
	assert_not_null(camp, "Camp3D deve instanciar")
	assert_not_null(camp.speaker_label, "Camp3D deve ter SpeakerLabel")
	assert_not_null(camp.dialogue_label, "Camp3D deve ter DialogueLabel")
	assert_not_null(camp.btn_next, "Camp3D deve ter BtnNext")
	assert_not_null(camp.btn_skip, "Camp3D deve ter BtnSkip")
	assert_not_null(camp.btn_leave, "Camp3D deve ter BtnLeave (inicialmente oculto)")
	assert_false(camp.btn_leave.visible, "BtnLeave deve começar invisível")


func test_camp_increments_flag_on_ready() -> void:
	var before: int = GameState.get_flag("camp_count", 0)
	var camp: Node3D = CAMP_SCENE.instantiate() as Node3D
	add_child_autofree(camp)
	var after: int = GameState.get_flag("camp_count", 0)
	assert_eq(after, before + 1, "camp_count deve incrementar em 1 a cada acampamento")


func test_camp_first_dialogue_line_shown_on_ready() -> void:
	var camp: Camp3D = CAMP_SCENE.instantiate() as Camp3D
	add_child_autofree(camp)
	# Após _ready, algum texto de diálogo deve estar visível
	assert_true(
		camp.dialogue_label.text.length() > 0,
		"Deve haver texto de diálogo após inicializar o Camp3D"
	)
	assert_true(
		camp.speaker_label.text.length() > 0,
		"SpeakerLabel deve ter nome de personagem após inicializar"
	)


func test_camp_next_advances_dialogue() -> void:
	var camp: Camp3D = CAMP_SCENE.instantiate() as Camp3D
	add_child_autofree(camp)

	var first_text: String = camp.dialogue_label.text
	camp._on_next_pressed()
	var second_text: String = camp.dialogue_label.text

	# Linha 2 deve ser diferente da linha 1 (há pelo menos 2 linhas em todo acampamento)
	# (a menos que o camp tenha apenas 1 linha — improvável pela definição)
	if camp._dialogue_lines.size() > 1:
		assert_ne(second_text, first_text, "Avançar deve mudar o texto de diálogo")


func test_camp_skip_ends_dialogue_and_shows_leave_btn() -> void:
	var camp: Camp3D = CAMP_SCENE.instantiate() as Camp3D
	add_child_autofree(camp)

	camp._on_skip_pressed()

	assert_true(camp._is_finished, "Pular deve marcar o diálogo como terminado")
	assert_true(camp.btn_leave.visible, "BtnLeave deve ficar visível após pular o diálogo")
	assert_false(camp.btn_next.visible, "BtnNext deve sumir após o diálogo terminar")
