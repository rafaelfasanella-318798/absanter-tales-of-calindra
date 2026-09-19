class_name BattleManager
extends Node2D
## Orchestrates the turn-based JRPG combat, battler turns, UI, and win/loss flow.

signal battle_state_changed(new_state: int)
signal log_message_posted(text: String)
signal turn_started(battler: Battler)
signal battle_finished(victory: bool)

const DEFAULT_SLASH_SKILL_PATH: String = "res://data/skills/slash.tres"
const FLOATING_TEXT_SCENE: PackedScene = preload("res://scenes/battle/floating_text.tscn")
const BATTLER_SCENE: PackedScene = preload("res://scenes/battle/battler.tscn")

@export var return_scene_path: String = "res://scenes/world/kakariko.tscn"
@export var return_player_pos: Vector2 = Vector2(160, 100)
@export var is_boss_battle: bool = false

var battle_state: int = Enums.BattleState.INITIALIZING
var party_battlers: Array[Battler] = []
var enemy_battlers: Array[Battler] = []
var all_battlers: Array[Battler] = []
var turn_queue: Array[Battler] = []
var current_battler: Battler = null

var selected_skill: SkillData = null
var selected_item_id: String = ""
var target_cursor_index: int = 0
var is_targeting_allies: bool = false
var is_targeting_all: bool = false

var total_xp_reward: int = 0
var total_gold_reward: int = 0
var dropped_items: Array[String] = []
var escape_attempts: int = 0

@onready var arena_bg: ColorRect = $ArenaBG
@onready var enemies_container: Node2D = $EnemiesContainer
@onready var party_container: Node2D = $PartyContainer
@onready var floating_texts_container: Node2D = $FloatingTextsContainer
@onready var log_label: Label = $UI/LogPanel/LogLabel
@onready var command_menu: Control = $UI/CommandMenu
@onready var skill_submenu: Control = $UI/SkillSubmenu
@onready var skill_list: VBoxContainer = $UI/SkillSubmenu/Scroll/VBox
@onready var item_submenu: Control = $UI/ItemSubmenu
@onready var item_list: VBoxContainer = $UI/ItemSubmenu/Scroll/VBox
@onready var party_panel: Control = $UI/PartyPanel
@onready var victory_panel: Control = $UI/VictoryPanel
@onready var victory_summary: Label = $UI/VictoryPanel/SummaryLabel
@onready var game_over_panel: Control = $UI/GameOverPanel
@onready var target_cursor: Sprite2D = $TargetCursor


func _ready() -> void:
	GameState.current_mode = "battle"
	_connect_menu_buttons()

	# If started directly or via event without encounter data, start default test battle
	if all_battlers.is_empty():
		call_deferred("_setup_default_battle")


func setup_battle(encounter_data: Dictionary) -> void:
	return_scene_path = encounter_data.get("return_scene", "res://scenes/world/kakariko.tscn")
	return_player_pos = encounter_data.get("return_pos", Vector2(160, 100))
	is_boss_battle = encounter_data.get("is_boss", false)

	_clear_battlers()
	_spawn_party_battlers()

	var enemy_ids: Array = encounter_data.get("enemies", ["slime", "cave_bat"])
	_spawn_enemy_battlers(enemy_ids)

	_init_turn_order()
	_update_party_ui()
	_set_state(Enums.BattleState.TURN_START)


func _setup_default_battle() -> void:
	var default_data: Dictionary = {
		"enemies": ["slime", "cave_bat"],
		"is_boss": false,
		"return_scene": "res://scenes/world/kakariko.tscn",
		"return_pos": Vector2(160, 100)
	}
	setup_battle(default_data)


func _clear_battlers() -> void:
	for b in all_battlers:
		if is_instance_valid(b):
			b.queue_free()
	party_battlers.clear()
	enemy_battlers.clear()
	all_battlers.clear()
	turn_queue.clear()


func _spawn_party_battlers() -> void:
	var ragg_data: CharacterData = load("res://data/characters/ragg.tres") as CharacterData
	var calindra_data: CharacterData = load("res://data/characters/calindra.tres") as CharacterData

	var ragg: Battler = BATTLER_SCENE.instantiate() as Battler
	ragg.position = Vector2(230, 95)
	party_container.add_child(ragg)
	ragg.setup_from_character_data(ragg_data)
	if ragg.sprite != null:
		ragg.sprite.texture = TextureLoader.get_kenney_tile(85)
	party_battlers.append(ragg)
	all_battlers.append(ragg)

	var calindra: Battler = BATTLER_SCENE.instantiate() as Battler
	calindra.position = Vector2(260, 65)
	party_container.add_child(calindra)
	calindra.setup_from_character_data(calindra_data)
	if calindra.sprite != null:
		calindra.sprite.texture = TextureLoader.get_kenney_tile(86)
	party_battlers.append(calindra)
	all_battlers.append(calindra)


func _spawn_enemy_battlers(enemy_ids: Array) -> void:
	var positions: Array[Vector2] = []
	if enemy_ids.size() == 1:
		positions = [Vector2(85, 80)]
	elif enemy_ids.size() == 2:
		positions = [Vector2(70, 60), Vector2(90, 105)]
	else:
		positions = [Vector2(55, 55), Vector2(85, 80), Vector2(60, 115)]

	for i in range(enemy_ids.size()):
		var e_id: String = str(enemy_ids[i])
		var enemy_res_path: String = "res://data/enemies/%s.tres" % e_id
		if not ResourceLoader.exists(enemy_res_path):
			push_warning("BattleManager: Enemy resource not found: " + enemy_res_path)
			continue

		var enemy_data: EnemyData = load(enemy_res_path) as EnemyData
		var enemy: Battler = BATTLER_SCENE.instantiate() as Battler
		enemy.position = positions[i % positions.size()]
		enemies_container.add_child(enemy)
		enemy.setup_from_enemy_data(enemy_data)
		enemy_battlers.append(enemy)
		all_battlers.append(enemy)

		total_xp_reward += enemy_data.xp_reward
		total_gold_reward += enemy_data.gold_reward
		if not enemy_data.drop_item_id.is_empty() and randf() <= enemy_data.drop_chance:
			dropped_items.append(enemy_data.drop_item_id)


func _init_turn_order() -> void:
	turn_queue.clear()
	for b in all_battlers:
		if is_instance_valid(b) and not b.is_dead:
			turn_queue.append(b)

	# Sort by speed descending
	turn_queue.sort_custom(func(a: Battler, b: Battler) -> bool: return a.speed > b.speed)


func _set_state(new_state: int) -> void:
	battle_state = new_state
	battle_state_changed.emit(new_state)

	match battle_state:
		Enums.BattleState.TURN_START:
			_process_next_turn()
		Enums.BattleState.SELECTING_ACTION:
			_show_command_menu(true)
		Enums.BattleState.EXECUTING_ACTION:
			_show_command_menu(false)
		Enums.BattleState.CHECK_END_CONDITION:
			_check_end_conditions()
		Enums.BattleState.VICTORY:
			_handle_victory()
		Enums.BattleState.DEFEAT:
			_handle_defeat()
		Enums.BattleState.ESCAPE:
			_handle_escape()


func _process_next_turn() -> void:
	# Verify alive status of remaining queue
	while not turn_queue.is_empty() and turn_queue[0].is_dead:
		turn_queue.pop_front()

	if turn_queue.is_empty():
		_init_turn_order()
		if turn_queue.is_empty():
			_check_end_conditions()
			return

	current_battler = turn_queue.pop_front()
	current_battler.tick_turn_effects()
	turn_started.emit(current_battler)

	_post_log("Turno de %s!" % current_battler.battler_name)
	_update_party_ui()

	if current_battler.is_player:
		_set_state(Enums.BattleState.SELECTING_ACTION)
	else:
		_execute_enemy_turn()


func _execute_enemy_turn() -> void:
	_set_state(Enums.BattleState.EXECUTING_ACTION)
	var timer: SceneTreeTimer = get_tree().create_timer(0.6)
	await timer.timeout

	var living_players: Array[Battler] = party_battlers.filter(
		func(b: Battler) -> bool: return not b.is_dead
	)
	if living_players.is_empty():
		_check_end_conditions()
		return

	# Target lowest HP or random
	living_players.sort_custom(
		func(a: Battler, b: Battler) -> bool: return a.current_hp < b.current_hp
	)
	var target: Battler = living_players[0]

	# Choose skill or normal attack
	var skill: SkillData = null
	if not current_battler.skills.is_empty():
		skill = current_battler.skills.pick_random()
	if skill == null:
		skill = load(DEFAULT_SLASH_SKILL_PATH) as SkillData

	var dmg_result: Dictionary = BattleFormulas.calculate_damage(
		current_battler.get_stats_dict(),
		target.get_stats_dict(),
		skill,
		randf_range(0.9, 1.1),
		target.is_defending
	)
	var dealt: int = target.take_damage(dmg_result["damage"], dmg_result["is_critical"])
	_spawn_floating_number(
		target.global_position, str(dealt), Color.ORANGE_RED, dmg_result["is_critical"]
	)
	_post_log(
		"%s usou %s e causou %d de dano!" % [current_battler.battler_name, skill.skill_name, dealt]
	)
	_update_party_ui()

	var pause_timer: SceneTreeTimer = get_tree().create_timer(0.5)
	await pause_timer.timeout
	_set_state(Enums.BattleState.CHECK_END_CONDITION)


func execute_attack_action(target: Battler) -> void:
	if current_battler == null or target == null:
		return

	_set_state(Enums.BattleState.EXECUTING_ACTION)
	var skill: SkillData = null
	if not current_battler.skills.is_empty():
		skill = current_battler.skills[0]  # Basic primary skill
	if skill == null:
		skill = load(DEFAULT_SLASH_SKILL_PATH) as SkillData

	var crit_roll: bool = randf() < 0.12
	var dmg_result: Dictionary = BattleFormulas.calculate_damage(
		current_battler.get_stats_dict(),
		target.get_stats_dict(),
		skill,
		randf_range(0.9, 1.1),
		target.is_defending,
		crit_roll
	)
	var dealt: int = target.take_damage(
		dmg_result["damage"], dmg_result["is_critical"], dmg_result["is_weakness"]
	)
	_spawn_floating_number(
		target.global_position,
		str(dealt),
		Color.YELLOW if dmg_result["is_critical"] else Color.WHITE,
		dmg_result["is_critical"]
	)

	var log_txt: String = (
		"%s atacou %s por %d de dano!" % [current_battler.battler_name, target.battler_name, dealt]
	)
	if dmg_result["is_critical"]:
		log_txt += " Golpe Crítico!"
	if dmg_result["is_weakness"]:
		log_txt += " Fraqueza elemental!"
	_post_log(log_txt)

	var timer: SceneTreeTimer = get_tree().create_timer(0.5)
	await timer.timeout
	_set_state(Enums.BattleState.CHECK_END_CONDITION)


func execute_skill_action(skill: SkillData, targets: Array[Battler]) -> void:
	if current_battler == null or skill == null:
		return

	if not current_battler.use_mp(skill.cost_mp):
		_post_log("MP insuficiente para %s!" % skill.skill_name)
		_set_state(Enums.BattleState.SELECTING_ACTION)
		return

	_set_state(Enums.BattleState.EXECUTING_ACTION)
	_update_party_ui()

	if skill.is_healing:
		for t in targets:
			var heal_val: int = BattleFormulas.calculate_healing(
				current_battler.get_stats_dict(), skill, randf_range(0.95, 1.05)
			)
			var restored: int = t.heal(heal_val)
			_spawn_floating_number(t.global_position, "+%d" % restored, Color.LIGHT_GREEN)
			_post_log(
				(
					"%s usou %s curando %d HP em %s!"
					% [current_battler.battler_name, skill.skill_name, restored, t.battler_name]
				)
			)
	elif skill.is_buff:
		for t in targets:
			t.apply_buff(skill.buff_type, skill.buff_duration)
			_spawn_floating_number(t.global_position, "DEF UP!", Color.AQUA)
		_post_log(
			"%s usou %s! Proteção aumentada!" % [current_battler.battler_name, skill.skill_name]
		)
	else:
		for t in targets:
			var crit_roll: bool = randf() < 0.10
			var dmg_result: Dictionary = BattleFormulas.calculate_damage(
				current_battler.get_stats_dict(),
				t.get_stats_dict(),
				skill,
				randf_range(0.95, 1.05),
				t.is_defending,
				crit_roll
			)
			var dealt: int = t.take_damage(
				dmg_result["damage"], dmg_result["is_critical"], dmg_result["is_weakness"]
			)
			_spawn_floating_number(
				t.global_position,
				str(dealt),
				Color.CYAN if skill.element != Enums.Element.PHYSICAL else Color.WHITE,
				dmg_result["is_critical"]
			)
			_post_log(
				(
					"%s usou %s em %s causando %d de dano!"
					% [current_battler.battler_name, skill.skill_name, t.battler_name, dealt]
				)
			)

	_update_party_ui()
	var timer: SceneTreeTimer = get_tree().create_timer(0.6)
	await timer.timeout
	_set_state(Enums.BattleState.CHECK_END_CONDITION)


func execute_item_action(item_id: String, target: Battler) -> void:
	if current_battler == null or target == null:
		return

	if not InventoryManager.remove_item(item_id, 1):
		_post_log("Item não disponível!")
		_set_state(Enums.BattleState.SELECTING_ACTION)
		return

	_set_state(Enums.BattleState.EXECUTING_ACTION)
	if item_id == "pocao_vida":
		var healed: int = target.heal(50)
		_spawn_floating_number(target.global_position, "+%d HP" % healed, Color.LIGHT_GREEN)
		_post_log(
			(
				"%s usou Poção de Vida em %s (+%d HP)!"
				% [current_battler.battler_name, target.battler_name, healed]
			)
		)
	elif item_id == "pocao_mana":
		var restored: int = target.restore_mp(30)
		_spawn_floating_number(target.global_position, "+%d MP" % restored, Color.LIGHT_BLUE)
		_post_log(
			(
				"%s usou Poção de Mana em %s (+%d MP)!"
				% [current_battler.battler_name, target.battler_name, restored]
			)
		)

	_update_party_ui()
	var timer: SceneTreeTimer = get_tree().create_timer(0.5)
	await timer.timeout
	_set_state(Enums.BattleState.CHECK_END_CONDITION)


func execute_defend_action() -> void:
	if current_battler == null:
		return
	_set_state(Enums.BattleState.EXECUTING_ACTION)
	current_battler.is_defending = true
	_spawn_floating_number(current_battler.global_position, "DEFESA", Color.LIGHT_GRAY)
	_post_log("%s assumiu postura defensiva!" % current_battler.battler_name)

	var timer: SceneTreeTimer = get_tree().create_timer(0.4)
	await timer.timeout
	_set_state(Enums.BattleState.CHECK_END_CONDITION)


func execute_escape_action() -> void:
	if is_boss_battle:
		_post_log("Não é possível fugir de uma batalha crucial!")
		_show_command_menu(true)
		return

	_set_state(Enums.BattleState.EXECUTING_ACTION)
	escape_attempts += 1

	var party_spd_sum: float = 0.0
	for p in party_battlers:
		party_spd_sum += float(p.speed)
	var party_avg_spd: float = party_spd_sum / maxf(1.0, float(party_battlers.size()))

	var enemy_spd_sum: float = 0.0
	for e in enemy_battlers:
		enemy_spd_sum += float(e.speed)
	var enemy_avg_spd: float = enemy_spd_sum / maxf(1.0, float(enemy_battlers.size()))

	var escaped: bool = BattleFormulas.calculate_escape_chance(
		party_avg_spd, enemy_avg_spd, escape_attempts
	)
	if escaped:
		_post_log("Fuga bem sucedida!")
		var timer: SceneTreeTimer = get_tree().create_timer(0.6)
		await timer.timeout
		_set_state(Enums.BattleState.ESCAPE)
	else:
		_post_log("Falha ao tentar fugir!")
		var timer: SceneTreeTimer = get_tree().create_timer(0.5)
		await timer.timeout
		_set_state(Enums.BattleState.CHECK_END_CONDITION)


func _check_end_conditions() -> void:
	var living_enemies: Array[Battler] = enemy_battlers.filter(
		func(b: Battler) -> bool: return not b.is_dead
	)
	if living_enemies.is_empty():
		_set_state(Enums.BattleState.VICTORY)
		return

	var living_party: Array[Battler] = party_battlers.filter(
		func(b: Battler) -> bool: return not b.is_dead
	)
	if living_party.is_empty():
		_set_state(Enums.BattleState.DEFEAT)
		return

	_set_state(Enums.BattleState.TURN_START)


func _handle_victory() -> void:
	_hide_all_menus()
	_post_log("Vitória! Todos os inimigos foram derrotados!")
	battle_finished.emit(true)
	EventBus.battle_ended.emit(true)

	InventoryManager.add_gold(total_gold_reward)
	for item_id in dropped_items:
		InventoryManager.add_item(item_id, 1)

	# Level progression check
	var level_up_texts: Array[String] = []
	for p in party_battlers:
		p.current_xp += total_xp_reward
		var ragg_growth: Dictionary = {
			"hp_growth": 18, "mp_growth": 4, "attack_growth": 4, "defense_growth": 3
		}
		var lvl_result: Dictionary = BattleFormulas.check_level_up(
			p.level, p.current_xp, ragg_growth
		)
		if lvl_result["leveled_up"]:
			p.level = lvl_result["new_level"]
			level_up_texts.append("%s subiu para o Nível %d!" % [p.battler_name, p.level])

	# Check mimic boss victory flag
	for enemy in enemy_battlers:
		if enemy.battler_id == "kakariko_mimic":
			GameState.set_flag("mimic_defeated", true)

	var summary: String = "XP Ganho: +%d\nOuro: +%d" % [total_xp_reward, total_gold_reward]
	if not dropped_items.is_empty():
		summary += "\nItens: " + ", ".join(dropped_items)
	if not level_up_texts.is_empty():
		summary += "\n" + "\n".join(level_up_texts)

	if victory_summary != null:
		victory_summary.text = summary
	if victory_panel != null:
		victory_panel.visible = true


func _handle_defeat() -> void:
	_hide_all_menus()
	_post_log("A party foi derrotada...")
	battle_finished.emit(false)
	EventBus.battle_ended.emit(false)
	if game_over_panel != null:
		game_over_panel.visible = true


func _handle_escape() -> void:
	_hide_all_menus()
	EventBus.battle_ended.emit(false)
	_return_to_world()


func _return_to_world() -> void:
	GameState.current_mode = "exploration"
	SceneManager.change_scene_with_transition(return_scene_path, "", return_player_pos)


func _show_command_menu(show_menu: bool) -> void:
	if command_menu != null:
		command_menu.visible = show_menu
		if show_menu:
			var first_btn: Button = command_menu.get_node_or_null("VBox/BtnAttack")
			if first_btn != null:
				first_btn.grab_focus()


func _hide_all_menus() -> void:
	_show_command_menu(false)
	if skill_submenu != null:
		skill_submenu.visible = false
	if item_submenu != null:
		item_submenu.visible = false
	if target_cursor != null:
		target_cursor.visible = false


func _post_log(msg: String) -> void:
	if log_label != null:
		log_label.text = msg
	log_message_posted.emit(msg)


func _spawn_floating_number(
	pos: Vector2, text_val: String, color: Color, is_crit: bool = false
) -> void:
	var fl: FloatingText = FLOATING_TEXT_SCENE.instantiate() as FloatingText
	fl.position = pos + Vector2(0, -12)
	floating_texts_container.add_child(fl)
	fl.display(text_val, color, is_crit)


func _update_party_ui() -> void:
	if party_panel == null:
		return
	for i in range(party_battlers.size()):
		var b: Battler = party_battlers[i]
		var member_ui: Control = party_panel.get_node_or_null("VBox/Member%d" % (i + 1))
		if member_ui != null:
			var name_lbl: Label = member_ui.get_node_or_null("HBox/NameLabel")
			var hp_bar: ProgressBar = member_ui.get_node_or_null("HBox/HPBar")
			var hp_lbl: Label = member_ui.get_node_or_null("HBox/HPLabel")
			var mp_lbl: Label = member_ui.get_node_or_null("HBox/MPLabel")

			if name_lbl != null:
				name_lbl.text = "%s Lv.%d" % [b.battler_name, b.level]
				if b == current_battler:
					name_lbl.modulate = Color.YELLOW
				else:
					name_lbl.modulate = Color.WHITE
			if hp_bar != null:
				hp_bar.max_value = b.max_hp
				hp_bar.value = b.current_hp
			if hp_lbl != null:
				hp_lbl.text = "HP %d/%d" % [b.current_hp, b.max_hp]
			if mp_lbl != null:
				mp_lbl.text = "MP %d/%d" % [b.current_mp, b.max_mp]


func _connect_menu_buttons() -> void:
	var btn_atk: Button = $UI/CommandMenu/VBox/BtnAttack
	var btn_skl: Button = $UI/CommandMenu/VBox/BtnSkill
	var btn_itm: Button = $UI/CommandMenu/VBox/BtnItem
	var btn_def: Button = $UI/CommandMenu/VBox/BtnDefend
	var btn_esc: Button = $UI/CommandMenu/VBox/BtnEscape

	if btn_atk != null and not btn_atk.pressed.is_connected(_on_attack_pressed):
		btn_atk.pressed.connect(_on_attack_pressed)
	if btn_skl != null and not btn_skl.pressed.is_connected(_on_skill_pressed):
		btn_skl.pressed.connect(_on_skill_pressed)
	if btn_itm != null and not btn_itm.pressed.is_connected(_on_item_pressed):
		btn_itm.pressed.connect(_on_item_pressed)
	if btn_def != null and not btn_def.pressed.is_connected(_on_defend_pressed):
		btn_def.pressed.connect(_on_defend_pressed)
	if btn_esc != null and not btn_esc.pressed.is_connected(_on_escape_pressed):
		btn_esc.pressed.connect(_on_escape_pressed)

	var btn_vic: Button = $UI/VictoryPanel/BtnConfirm
	if btn_vic != null and not btn_vic.pressed.is_connected(_return_to_world):
		btn_vic.pressed.connect(_return_to_world)

	var btn_retry: Button = $UI/GameOverPanel/BtnRetry
	if btn_retry != null and not btn_retry.pressed.is_connected(_on_retry_pressed):
		btn_retry.pressed.connect(_on_retry_pressed)


func _on_attack_pressed() -> void:
	_start_target_selection(
		false, false, func(target: Battler) -> void: execute_attack_action(target)
	)


func _on_skill_pressed() -> void:
	if current_battler == null:
		return
	_populate_skill_submenu()
	command_menu.visible = false
	skill_submenu.visible = true


func _on_item_pressed() -> void:
	_populate_item_submenu()
	command_menu.visible = false
	item_submenu.visible = true


func _on_defend_pressed() -> void:
	_show_command_menu(false)
	execute_defend_action()


func _on_escape_pressed() -> void:
	_show_command_menu(false)
	execute_escape_action()


func _on_retry_pressed() -> void:
	if SaveManager.has_save(1):
		SaveManager.load_game(1)
	else:
		_setup_default_battle()
	if game_over_panel != null:
		game_over_panel.visible = false


func _populate_skill_submenu() -> void:
	if skill_list == null or current_battler == null:
		return
	for child in skill_list.get_children():
		child.queue_free()

	for skill in current_battler.skills:
		var btn: Button = Button.new()
		btn.text = "%s (%d MP)" % [skill.skill_name, skill.cost_mp]
		btn.add_theme_font_size_override("font_size", 8)
		btn.disabled = current_battler.current_mp < skill.cost_mp
		btn.pressed.connect(_on_skill_item_selected.bind(skill))
		skill_list.add_child(btn)

	var back_btn: Button = Button.new()
	back_btn.text = "< Voltar"
	back_btn.add_theme_font_size_override("font_size", 8)
	back_btn.pressed.connect(
		func() -> void:
			skill_submenu.visible = false
			_show_command_menu(true)
	)
	skill_list.add_child(back_btn)


func _on_skill_item_selected(skill: SkillData) -> void:
	skill_submenu.visible = false
	if skill.target_type == "all_enemies":
		var living_enemies: Array[Battler] = enemy_battlers.filter(
			func(b: Battler) -> bool: return not b.is_dead
		)
		execute_skill_action(skill, living_enemies)
	elif skill.target_type == "all_allies":
		var living_allies: Array[Battler] = party_battlers.filter(
			func(b: Battler) -> bool: return not b.is_dead
		)
		execute_skill_action(skill, living_allies)
	elif skill.target_type == "single_ally":
		_start_target_selection(
			true, false, func(t: Battler) -> void: execute_skill_action(skill, [t])
		)
	else:
		_start_target_selection(
			false, false, func(t: Battler) -> void: execute_skill_action(skill, [t])
		)


func _populate_item_submenu() -> void:
	if item_list == null:
		return
	for child in item_list.get_children():
		child.queue_free()

	var usable_items: Array[String] = ["pocao_vida", "pocao_mana"]
	var count_any: int = 0
	for item_id in usable_items:
		var qty: int = InventoryManager.items.get(item_id, 0)
		if qty > 0:
			count_any += 1
			var btn: Button = Button.new()
			var item_name: String = "Poção de Vida" if item_id == "pocao_vida" else "Poção de Mana"
			btn.text = "%s (x%d)" % [item_name, qty]
			btn.add_theme_font_size_override("font_size", 8)
			btn.pressed.connect(_on_item_chosen.bind(item_id))
			item_list.add_child(btn)

	if count_any == 0:
		var empty_lbl: Label = Label.new()
		empty_lbl.text = "Sem itens utilizáveis"
		empty_lbl.add_theme_font_size_override("font_size", 8)
		item_list.add_child(empty_lbl)

	var back_btn: Button = Button.new()
	back_btn.text = "< Voltar"
	back_btn.add_theme_font_size_override("font_size", 8)
	back_btn.pressed.connect(
		func() -> void:
			item_submenu.visible = false
			_show_command_menu(true)
	)
	item_list.add_child(back_btn)


func _on_item_chosen(item_id: String) -> void:
	item_submenu.visible = false
	_start_target_selection(true, false, func(t: Battler) -> void: execute_item_action(item_id, t))


func _start_target_selection(target_allies: bool, target_all: bool, callback: Callable) -> void:
	is_targeting_allies = target_allies
	is_targeting_all = target_all

	var pool: Array[Battler] = (
		party_battlers.filter(func(b: Battler) -> bool: return not b.is_dead)
		if target_allies
		else enemy_battlers.filter(func(b: Battler) -> bool: return not b.is_dead)
	)

	if pool.is_empty():
		_show_command_menu(true)
		return

	target_cursor_index = 0
	_update_target_cursor(pool)
	_hide_all_menus()

	# Listen for selection
	var on_select: Callable
	on_select = func() -> void:
		if target_cursor != null:
			target_cursor.visible = false
		var chosen: Battler = pool[target_cursor_index]
		callback.call(chosen)

	# Execute directly for now or hook to quick click
	on_select.call()


func _update_target_cursor(pool: Array[Battler]) -> void:
	if target_cursor == null or pool.is_empty():
		return
	var t: Battler = pool[target_cursor_index]
	target_cursor.global_position = t.global_position + Vector2(0, -22)
	target_cursor.visible = true
