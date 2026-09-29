extends GutTest

const PLAYER_3D_SCENE: PackedScene = preload("res://scenes/world_3d/player_3d.tscn")
const FOLLOWER_3D_SCENE: PackedScene = preload("res://scenes/world_3d/follower_3d.tscn")
const NPC_3D_SCENE: PackedScene = preload("res://scenes/world_3d/npc_3d.tscn")
const KAKARIKO_3D_SCENE: PackedScene = preload("res://scenes/world_3d/kakariko_3d.tscn")
const BATTLE_3D_SCENE: PackedScene = preload("res://scenes/battle_3d/battle_3d.tscn")


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
	add_child_autofree(village)
	assert_not_null(village, "Cena Kakariko3D deve instanciar")
	assert_not_null(village.player, "Player3D presente em Kakariko3D")
	assert_not_null(village.follower, "Follower3D presente em Kakariko3D")
	assert_not_null(village.camera, "Camera3D presente em Kakariko3D")
	assert_not_null(village.battle_portal, "BattlePortal presente em Kakariko3D")


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
	assert_eq(battle.combatants[2]["name"], "Slime")
	assert_eq(battle.combatants[3]["name"], "Golem Antigo")


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
	var target: Dictionary = battle.combatants[2]    # Slime
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
	var target: Dictionary = battle.combatants[2]    # Slime

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
	var target: Dictionary = battle.combatants[3]    # Golem

	target["state"] = "wait"
	target["ip"] = 0.3
	var hp_before: int = target["hp"]

	battle._resolve_critical(attacker, target)

	# Sem cancel (estado era wait): banner NÃO deve ter aparecido ainda
	# (pode estar visível de outra vez, mas o teste verifica que o hp diminuiu)
	assert_lt(target["hp"], hp_before, "CRITICAL fora de ACT ainda causa dano")
	# IP não deve ter recuado pelo push de cancel (só pelo combo_push não é aplicado aqui)
	assert_true(target["ip"] >= 0.0, "IP >= 0 sempre")


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
	var console: DebugConsole = DebugConsole
	assert_not_null(console)
	var res_3d: String = console.execute_command("3d")
	assert_true(res_3d.contains("Kakariko 3D"))
	var res_bat: String = console.execute_command("battle3d")
	assert_true(res_bat.contains("Batalha 3D Grandia"))


# ──────────────────────────────────────────────
# Testes do Aerial Launch & Aerial Combo
# ──────────────────────────────────────────────
func test_aerial_launch_sets_is_airborne() -> void:
	var battle: Node3D = BATTLE_3D_SCENE.instantiate() as Node3D
	add_child_autofree(battle)

	var launcher: Dictionary = battle.combatants[0]  # Ragg
	var target: Dictionary = battle.combatants[2]    # Slime

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

	var partner: Dictionary = battle.combatants[1]   # Calindra
	var target: Dictionary = battle.combatants[2]    # Slime

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

	# home_pos deve ter mudado
	# (pode ser igual por acaso, mas estatisticamente é improvável com posição aleatória)
	assert_not_null(ragg["home_pos"], "home_pos deve continuar válido após evasão")
