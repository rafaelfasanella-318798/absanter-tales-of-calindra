extends GutTest

var npc_scene: PackedScene = preload("res://scenes/world/npc.tscn")
var player_scene: PackedScene = preload("res://scenes/world/player.tscn")

var _npc: NPC
var _player: Player


func before_each() -> void:
	GameState.flags.clear()
	DialogueManager.end_dialogue(DialogueManager.current_dialogue_id)

	_npc = npc_scene.instantiate() as NPC
	add_child_autofree(_npc)

	_player = player_scene.instantiate() as Player
	add_child_autofree(_player)


func test_npc_name_label() -> void:
	assert_not_null(_npc.name_label, "NPC should have name_label")
	assert_eq(_npc.name_label.text, "Tav", "NPC name_label should be Tav")


func test_tav_interaction_triggers_dialogue() -> void:
	assert_false(GameState.get_flag("talked_to_tav", false), "Flag should initially be false")

	_npc.interact(_player)

	assert_true(GameState.get_flag("talked_to_tav", false), "Flag talked_to_tav should be set")
	assert_true(DialogueManager.is_active, "DialogueManager should be active during conversation")
	assert_eq(
		DialogueManager.current_dialogue_id, "tav_greeting", "Dialogue ID should match greeting"
	)

	DialogueManager.end_dialogue("tav_greeting")
	assert_false(DialogueManager.is_active, "DialogueManager should be inactive after finishing")
