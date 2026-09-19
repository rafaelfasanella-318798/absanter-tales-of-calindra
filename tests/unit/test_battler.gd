extends GutTest

var battler_scene: PackedScene = preload("res://scenes/battle/battler.tscn")
var ragg_data: CharacterData = preload("res://data/characters/ragg.tres")
var slime_data: EnemyData = preload("res://data/enemies/slime.tres")

var _player_battler: Battler
var _enemy_battler: Battler


func before_each() -> void:
	_player_battler = battler_scene.instantiate() as Battler
	add_child_autofree(_player_battler)
	_player_battler.setup_from_character_data(ragg_data)

	_enemy_battler = battler_scene.instantiate() as Battler
	add_child_autofree(_enemy_battler)
	_enemy_battler.setup_from_enemy_data(slime_data)


func test_battler_initialization() -> void:
	assert_eq(_player_battler.battler_name, "Ragg", "Player name should be Ragg")
	assert_true(_player_battler.is_player, "Should be flagged as player")
	assert_gt(_player_battler.max_hp, 50, "Player should have valid max HP")
	assert_eq(_player_battler.current_hp, _player_battler.max_hp, "HP should start full")

	assert_eq(_enemy_battler.battler_name, "Slime de Kakariko", "Enemy name should match data")
	assert_false(_enemy_battler.is_player, "Should not be player")
	assert_eq(_enemy_battler.element_weakness, 2, "Slime should be weak to Fire (2)")


func test_take_damage_and_death() -> void:
	var initial_hp: int = _enemy_battler.current_hp
	var dealt: int = _enemy_battler.take_damage(20)
	assert_eq(dealt, 20, "Should report 20 damage dealt")
	assert_eq(_enemy_battler.current_hp, initial_hp - 20, "HP should decrease by 20")
	assert_false(_enemy_battler.is_dead, "Enemy should still be alive")

	# Overkill damage
	_enemy_battler.take_damage(9999)
	assert_eq(_enemy_battler.current_hp, 0, "HP should clamp to 0")
	assert_true(_enemy_battler.is_dead, "Enemy should be flagged dead")


func test_healing_clamps_to_max_hp() -> void:
	_player_battler.take_damage(50)
	assert_lt(_player_battler.current_hp, _player_battler.max_hp, "HP should be reduced")

	var healed: int = _player_battler.heal(30)
	assert_eq(healed, 30, "Should heal 30 points")

	var excess_healed: int = _player_battler.heal(999)
	assert_eq(_player_battler.current_hp, _player_battler.max_hp, "HP should clamp to max_hp")
	assert_eq(excess_healed, 20, "Excess heal should only restore remaining missing HP")


func test_mp_consumption_and_restore() -> void:
	var initial_mp: int = _player_battler.current_mp
	var success: bool = _player_battler.use_mp(10)
	assert_true(success, "Should consume 10 MP successfully")
	assert_eq(_player_battler.current_mp, initial_mp - 10, "MP should decrease by 10")

	var failure: bool = _player_battler.use_mp(999)
	assert_false(failure, "Should fail when consuming more MP than available")
	assert_eq(_player_battler.current_mp, initial_mp - 10, "MP should remain unchanged on failure")

	_player_battler.restore_mp(10)
	assert_eq(_player_battler.current_mp, initial_mp, "MP should be restored")


func test_buffs_and_stat_modifiers() -> void:
	var base_def: int = _player_battler.get_effective_defense()
	_player_battler.apply_buff(Enums.StatusEffect.DEF_BUFF, 2)
	var buffed_def: int = _player_battler.get_effective_defense()
	assert_gt(buffed_def, base_def, "DEF_BUFF should increase effective defense")

	_player_battler.tick_turn_effects()  # 1 turn passes
	assert_gt(
		_player_battler.get_effective_defense(), base_def, "Buff should remain active on turn 1"
	)

	_player_battler.tick_turn_effects()  # 2nd turn passes (buff expires)
	assert_eq(_player_battler.get_effective_defense(), base_def, "Buff should expire after 2 turns")
