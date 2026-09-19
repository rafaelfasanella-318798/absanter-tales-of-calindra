extends GutTest

var follower_scene: PackedScene = preload("res://scenes/world/follower.tscn")
var player_scene: PackedScene = preload("res://scenes/world/player.tscn")

var _player: Player
var _follower: Follower


func before_each() -> void:
	_player = player_scene.instantiate() as Player
	add_child_autofree(_player)

	_follower = follower_scene.instantiate() as Follower
	_follower.target_player = _player
	add_child_autofree(_follower)


func test_follower_initializes() -> void:
	assert_not_null(_follower, "Follower instance should exist")
	assert_eq(_follower.target_player, _player, "Follower target should be set to player")


func test_follower_tracks_history() -> void:
	# Add steps to player history
	_follower.follow_distance_steps = 1
	_player.global_position = Vector2(50, 0)
	_player.position_history.clear()
	_player.position_history.append(Vector2(50, 0))
	_player.position_history.append(Vector2(25, 0))
	_player.position_history.append(Vector2(0, 0))

	_follower.global_position = Vector2(0, 0)
	_follower._physics_process(0.016)

	assert_gt(_follower.velocity.x, 0.0, "Follower should move toward target step in history")
