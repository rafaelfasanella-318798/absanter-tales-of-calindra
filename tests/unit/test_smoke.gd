extends GutTest


func test_autoloads_exist() -> void:
	assert_not_null(EventBus, "EventBus autoload should exist")
	assert_not_null(GameState, "GameState autoload should exist")
	assert_not_null(SaveManager, "SaveManager autoload should exist")
	assert_not_null(AudioManager, "AudioManager autoload should exist")
	assert_not_null(SceneManager, "SceneManager autoload should exist")
	assert_not_null(DialogueManager, "DialogueManager autoload should exist")
	assert_not_null(QuestManager, "QuestManager autoload should exist")
	assert_not_null(InventoryManager, "InventoryManager autoload should exist")
	assert_not_null(PartyManager, "PartyManager autoload should exist")
	assert_not_null(Localization, "Localization autoload should exist")


func test_main_scene_loads() -> void:
	var main_scene: PackedScene = load("res://scenes/main/main.tscn")
	assert_not_null(main_scene, "Main scene should load successfully")
	var instance: Node = main_scene.instantiate()
	assert_not_null(instance, "Main scene should instantiate")
	add_child_autofree(instance)
