extends GutTest

var save_point_scene: PackedScene = preload("res://scenes/world/save_point.tscn")
var player_scene: PackedScene = preload("res://scenes/world/player.tscn")

var _save_point: SavePoint
var _player: Player


func before_each() -> void:
	SaveManager.delete_save(1)
	DialogueManager.end_dialogue(DialogueManager.current_dialogue_id)

	_save_point = save_point_scene.instantiate() as SavePoint
	add_child_autofree(_save_point)

	_player = player_scene.instantiate() as Player
	add_child_autofree(_player)


func after_each() -> void:
	SaveManager.delete_save(1)


func test_save_point_interaction() -> void:
	_player.global_position = Vector2(100, 100)
	_save_point.interact(_player)

	assert_true(SaveManager.has_save(1), "Interacting with SavePoint should write save to Slot 1")
	assert_true(DialogueManager.is_active, "Should trigger recovery dialogue sequence")
	assert_eq(
		DialogueManager.current_dialogue_id, "save_point", "Dialogue sequence should be save_point"
	)
