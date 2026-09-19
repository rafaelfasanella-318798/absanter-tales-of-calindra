extends GutTest


func before_each() -> void:
	QuestManager.active_quests.clear()
	QuestManager.completed_quests.clear()


func test_quest_lifecycle() -> void:
	assert_false(QuestManager.is_quest_active("quest_kakariko"), "Quest should not start active")
	assert_false(
		QuestManager.is_quest_completed("quest_kakariko"), "Quest should not start completed"
	)

	QuestManager.start_quest("quest_kakariko")
	assert_true(QuestManager.is_quest_active("quest_kakariko"), "Quest should now be active")
	assert_eq(QuestManager.get_quest_stage("quest_kakariko"), 0, "Stage should start at 0")

	QuestManager.set_quest_stage("quest_kakariko", 2)
	assert_eq(QuestManager.get_quest_stage("quest_kakariko"), 2, "Stage should be updated to 2")

	QuestManager.complete_quest("quest_kakariko")
	assert_false(QuestManager.is_quest_active("quest_kakariko"), "Quest should no longer be active")
	assert_true(QuestManager.is_quest_completed("quest_kakariko"), "Quest should be completed")


func test_quest_resource_data() -> void:
	var q_data: QuestData = load("res://data/quests/quest_kakariko.tres") as QuestData
	assert_not_null(q_data, "quest_kakariko.tres should exist and load as QuestData")
	assert_eq(q_data.quest_name, "O Mistério de Kakariko", "Quest name should match")
	assert_true(q_data.is_main_quest, "Should be flagged as main quest")
	assert_gt(q_data.stages.size(), 4, "Should have multiple stages for Chapter 1")
