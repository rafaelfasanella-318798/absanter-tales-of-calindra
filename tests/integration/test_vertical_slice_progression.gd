extends GutTest

var kakariko_scene: PackedScene = preload("res://scenes/world/kakariko.tscn")
var cave_scene: PackedScene = preload("res://scenes/world/kakariko_cave.tscn")
var boss_room_scene: PackedScene = preload("res://scenes/world/kakariko_boss_room.tscn")


func before_each() -> void:
	GameState.flags.clear()
	InventoryManager.items.clear()
	InventoryManager.gold = 0
	QuestManager.active_quests.clear()
	QuestManager.completed_quests.clear()
	DialogueManager.end_dialogue(DialogueManager.current_dialogue_id)


func test_dungeon_and_boss_scenes_load() -> void:
	var cave: KakarikoCaveMap = cave_scene.instantiate() as KakarikoCaveMap
	assert_not_null(cave, "KakarikoCaveMap should instantiate")
	add_child_autofree(cave)
	assert_eq(cave.map_name, "Caverna dos Murmúrios", "Cave map name should match")

	var boss_room: KakarikoBossRoomMap = boss_room_scene.instantiate() as KakarikoBossRoomMap
	assert_not_null(boss_room, "KakarikoBossRoomMap should instantiate")
	add_child_autofree(boss_room)
	assert_eq(boss_room.map_name, "Câmara do Golem Antigo", "Boss room map name should match")


func test_vertical_slice_full_story_progression() -> void:
	# 1. Enter Kakariko
	var kakariko: KakarikoMap = kakariko_scene.instantiate() as KakarikoMap
	add_child_autofree(kakariko)

	assert_true(QuestManager.is_quest_active("quest_kakariko"), "Quest should be active on arrival")
	assert_eq(QuestManager.get_quest_stage("quest_kakariko"), 0, "Stage should be 0 (find Tav)")

	# 2. Talk to Tav
	var tav: NPC = kakariko.get_node_or_null("Entities/Tav") as NPC
	var player: Player = kakariko.get_node_or_null("Entities/Player") as Player
	assert_not_null(tav, "Tav NPC should exist in village")
	tav.interact(player)
	assert_eq(
		QuestManager.get_quest_stage("quest_kakariko"),
		1,
		"Stage should advance to 1 (investigate chest)"
	)

	# 3. Defeat Mimic Chest
	var chest: Chest = kakariko.get_node_or_null("Entities/MimicChest") as Chest
	assert_not_null(chest, "MimicChest should exist in village")
	chest._finalize_mimic_defeat()

	assert_true(GameState.get_flag("mimic_defeated", false), "Mimic should be flagged defeated")
	assert_eq(
		InventoryManager.items.get("lamina_kakariko", 0), 1, "Player should have lamina_kakariko"
	)

	# 4. Talk to Tav with Mimic defeated
	tav.interact(player)
	assert_true(GameState.get_flag("cave_unlocked", false), "Cave should now be unlocked")
	assert_eq(
		QuestManager.get_quest_stage("quest_kakariko"),
		4,
		"Stage should advance to 4 (explore cave)"
	)

	# 5. Defeat Ancient Golem in Boss Room
	GameState.set_flag("golem_defeated", true)
	QuestManager.set_quest_stage("quest_kakariko", 6)

	# 6. Return to Tav after victory
	tav.interact(player)
	assert_true(
		QuestManager.is_quest_completed("quest_kakariko"),
		"Main quest should be completed, finishing Chapter 1 Vertical Slice!"
	)
