extends GutTest

var player_scene: PackedScene = preload("res://scenes/world/player.tscn")
var _player: Player


func before_each() -> void:
	_player = player_scene.instantiate() as Player
	add_child_autofree(_player)


func test_player_initial_state() -> void:
	assert_not_null(_player, "Player instance should not be null")
	assert_eq(_player.move_speed, 90.0, "Default speed should be 90")
	assert_eq(
		_player.position_history.size(), 1, "Initial position history should contain 1 element"
	)


func test_movement_lock() -> void:
	_player.lock_movement(true)
	assert_true(_player.is_movement_locked, "Player movement should be locked")
	_player.lock_movement(false)
	assert_false(_player.is_movement_locked, "Player movement should be unlocked")


func test_record_position_step() -> void:
	var initial_pos: Vector2 = _player.global_position
	_player.global_position += Vector2(10, 0)
	_player._record_position_step()
	assert_eq(_player.position_history.size(), 2, "History should have recorded new step")
	assert_eq(
		_player.position_history[0],
		_player.global_position,
		"Latest recorded pos should match current"
	)
