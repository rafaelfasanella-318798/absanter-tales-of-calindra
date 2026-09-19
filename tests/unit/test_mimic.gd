extends GutTest

var chest_scene: PackedScene = preload("res://scenes/world/chest.tscn")
var player_scene: PackedScene = preload("res://scenes/world/player.tscn")

var _chest: Chest
var _player: Player


func before_each() -> void:
	GameState.flags.clear()
	InventoryManager.items.clear()
	InventoryManager.gold = 0
	DialogueManager.end_dialogue(DialogueManager.current_dialogue_id)

	_chest = chest_scene.instantiate() as Chest
	add_child_autofree(_chest)

	_player = player_scene.instantiate() as Player
	add_child_autofree(_player)


func test_mimic_initial_state() -> void:
	assert_false(_chest.is_open, "Chest should start closed")
	assert_true(_chest.is_mimic, "Chest should be configured as a mimic")
	assert_false(GameState.get_flag("mimic_defeated", false), "Mimic should not be defeated yet")


func test_mimic_interaction_and_defeat() -> void:
	_chest.interact(_player)

	assert_true(DialogueManager.is_active, "DialogueManager should start mimic fight dialogue")
	assert_eq(
		DialogueManager.current_dialogue_id, "mimic_fight", "Dialogue ID should be mimic_fight"
	)

	# Finalize mimic defeat
	_chest._finalize_mimic_defeat()

	assert_true(_chest.is_open, "Chest should now be open")
	assert_true(GameState.get_flag("mimic_defeated", false), "Flag mimic_defeated should be true")
	assert_eq(
		InventoryManager.items.get("lamina_kakariko", 0),
		1,
		"Player should have received lamina_kakariko"
	)
	assert_eq(InventoryManager.gold, 50, "Player should have received 50 gold")
