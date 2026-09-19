extends GutTest

var battle_scene: PackedScene = preload("res://scenes/battle/battle_scene.tscn")
var _battle: BattleManager


func before_each() -> void:
	InventoryManager.items.clear()
	InventoryManager.gold = 0
	GameState.flags.clear()

	_battle = battle_scene.instantiate() as BattleManager
	add_child_autofree(_battle)


func test_battle_setup_and_spawns() -> void:
	_battle.setup_battle(
		{
			"enemies": ["slime", "cave_bat"],
			"is_boss": false,
			"return_scene": "res://scenes/world/kakariko.tscn"
		}
	)

	assert_eq(_battle.party_battlers.size(), 2, "Party should contain Ragg and Calindra")
	assert_eq(_battle.enemy_battlers.size(), 2, "Enemies should contain Slime and Cave Bat")
	assert_eq(_battle.all_battlers.size(), 4, "Total combatants should be 4")
	assert_gt(_battle.turn_queue.size(), 0, "Turn queue should be populated")


func test_turn_order_by_speed() -> void:
	_battle.setup_battle({"enemies": ["slime", "cave_bat"], "is_boss": false})

	# Speeds: Bat (16), Calindra (15), Ragg (12), Slime (8)
	var first_actor: Battler = _battle.current_battler
	assert_not_null(first_actor, "First actor should be selected")
	assert_eq(first_actor.battler_id, "cave_bat", "Fastest battler (Cave Bat, SPD 16) acts first")


func test_player_attack_damages_enemy() -> void:
	_battle.setup_battle({"enemies": ["slime"], "is_boss": false})

	var slime: Battler = _battle.enemy_battlers[0]
	var initial_hp: int = slime.current_hp
	_battle.current_battler = _battle.party_battlers[0]  # Ragg

	_battle.execute_attack_action(slime)

	assert_lt(slime.current_hp, initial_hp, "Slime HP should be reduced after Ragg's attack")


func test_skill_heal_restores_ally_hp() -> void:
	_battle.setup_battle({"enemies": ["slime"], "is_boss": false})

	var ragg: Battler = _battle.party_battlers[0]
	var calindra: Battler = _battle.party_battlers[1]
	ragg.take_damage(40)
	var damaged_hp: int = ragg.current_hp

	_battle.current_battler = calindra
	var heal_skill: SkillData = load("res://data/skills/heal.tres") as SkillData
	_battle.execute_skill_action(heal_skill, [ragg])

	assert_gt(ragg.current_hp, damaged_hp, "Ragg HP should increase after Heal skill")


func test_item_usage_consumes_inventory_and_heals() -> void:
	InventoryManager.add_item("pocao_vida", 2)
	_battle.setup_battle({"enemies": ["slime"], "is_boss": false})

	var ragg: Battler = _battle.party_battlers[0]
	ragg.take_damage(30)
	var damaged_hp: int = ragg.current_hp

	_battle.current_battler = ragg
	_battle.execute_item_action("pocao_vida", ragg)

	assert_gt(ragg.current_hp, damaged_hp, "Ragg HP should increase after using Potion")
	assert_eq(
		InventoryManager.items.get("pocao_vida", 0),
		1,
		"Potion count in inventory should be decremented"
	)


func test_victory_condition_and_rewards() -> void:
	_battle.setup_battle({"enemies": ["slime"], "is_boss": false})

	var slime: Battler = _battle.enemy_battlers[0]
	slime.take_damage(9999)  # Defeat slime

	_battle._check_end_conditions()

	assert_eq(_battle.battle_state, Enums.BattleState.VICTORY, "State should become VICTORY")
	assert_gt(InventoryManager.gold, 0, "Gold reward should be granted on victory")
