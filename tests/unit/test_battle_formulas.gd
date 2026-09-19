extends GutTest

var _dummy_physical_skill: SkillData
var _dummy_magical_skill: SkillData


func before_each() -> void:
	_dummy_physical_skill = SkillData.new()
	_dummy_physical_skill.element = Enums.Element.PHYSICAL
	_dummy_physical_skill.power_multiplier = 1.0
	_dummy_physical_skill.base_value = 0

	_dummy_magical_skill = SkillData.new()
	_dummy_magical_skill.element = Enums.Element.LIGHT
	_dummy_magical_skill.power_multiplier = 1.2
	_dummy_magical_skill.base_value = 0


func test_physical_damage_formula() -> void:
	var attacker: Dictionary = {"attack": 20, "magic": 5}
	var target: Dictionary = {"defense": 10, "element_weakness": Enums.Element.NONE}

	# (20 * 2 - 10) * 1.0 = 30
	var result: Dictionary = BattleFormulas.calculate_damage(
		attacker, target, _dummy_physical_skill, 1.0, false, false
	)
	assert_eq(result["damage"], 30, "Physical damage should be (ATK*2 - DEF)")
	assert_false(result["is_critical"], "Should not be critical")
	assert_false(result["is_weakness"], "Should not be weakness")


func test_defense_stance_halves_damage() -> void:
	var attacker: Dictionary = {"attack": 20, "magic": 5}
	var target: Dictionary = {"defense": 10, "element_weakness": Enums.Element.NONE}

	# 30 * 0.5 = 15
	var result: Dictionary = BattleFormulas.calculate_damage(
		attacker, target, _dummy_physical_skill, 1.0, true, false
	)
	assert_eq(result["damage"], 15, "Defending target should take 50% damage")


func test_critical_hit_increases_damage() -> void:
	var attacker: Dictionary = {"attack": 20, "magic": 5}
	var target: Dictionary = {"defense": 10, "element_weakness": Enums.Element.NONE}

	# 30 * 1.5 = 45
	var result: Dictionary = BattleFormulas.calculate_damage(
		attacker, target, _dummy_physical_skill, 1.0, false, true
	)
	assert_eq(result["damage"], 45, "Critical hit should deal 1.5x damage")
	assert_true(result["is_critical"], "Result should flag critical hit")


func test_elemental_weakness_bonus() -> void:
	var attacker: Dictionary = {"attack": 5, "magic": 20}
	var target: Dictionary = {"defense": 10, "element_weakness": Enums.Element.LIGHT}

	# Magical base: (20 * 2.2 - 10 * 0.6) * 1.2 = (44 - 6) * 1.2 = 38 * 1.2 = 45.6
	# Weakness: 45.6 * 1.5 = 68.4 -> 68
	var result: Dictionary = BattleFormulas.calculate_damage(
		attacker, target, _dummy_magical_skill, 1.0, false, false
	)
	assert_gt(result["damage"], 50, "Weakness damage should be increased")
	assert_true(result["is_weakness"], "Result should flag elemental weakness")


func test_healing_formula() -> void:
	var healer: Dictionary = {"magic": 25}
	var heal_skill: SkillData = SkillData.new()
	heal_skill.power_multiplier = 1.5
	heal_skill.base_value = 35

	# (25 * 1.5 + 35) = 37.5 + 35 = 72.5 -> 73 or 72
	var healed: int = BattleFormulas.calculate_healing(healer, heal_skill, 1.0)
	assert_between(healed, 70, 75, "Healing should correctly scale with user's magic")


func test_level_progression_and_stat_gains() -> void:
	assert_eq(BattleFormulas.calculate_xp_for_level(1), 0, "Level 1 requires 0 XP")
	var xp_lvl_2: int = BattleFormulas.calculate_xp_for_level(2)
	assert_gt(xp_lvl_2, 30, "Level 2 should require positive XP")

	var growth: Dictionary = {
		"hp_growth": 15, "mp_growth": 5, "attack_growth": 3, "defense_growth": 2
	}
	var not_enough_xp: Dictionary = BattleFormulas.check_level_up(1, 10, growth)
	assert_false(not_enough_xp["leveled_up"], "Should not level up with insufficient XP")

	var enough_xp: Dictionary = BattleFormulas.check_level_up(1, xp_lvl_2 + 10, growth)
	assert_true(enough_xp["leveled_up"], "Should level up when XP threshold is met")
	assert_eq(enough_xp["new_level"], 2, "New level should be 2")
	assert_eq(enough_xp["stat_gains"]["max_hp"], 15, "HP gain should match growth data")
