class_name QuestManagerAutoload
extends Node
## Tracks quest states, active objectives, and completed tasks.

signal quest_state_changed(quest_id: String, new_state: String)

var active_quests: Dictionary = {}
var completed_quests: Array[String] = []


func start_quest(quest_id: String) -> void:
	active_quests[quest_id] = 0
	quest_state_changed.emit(quest_id, "active")


func set_quest_stage(quest_id: String, stage: int) -> void:
	if quest_id in active_quests:
		active_quests[quest_id] = stage
		quest_state_changed.emit(quest_id, "updated")


func complete_quest(quest_id: String) -> void:
	if quest_id in active_quests:
		active_quests.erase(quest_id)
		completed_quests.append(quest_id)
		quest_state_changed.emit(quest_id, "completed")


func is_quest_active(quest_id: String) -> bool:
	return quest_id in active_quests


func is_quest_completed(quest_id: String) -> bool:
	return quest_id in completed_quests


func get_quest_stage(quest_id: String) -> int:
	return active_quests.get(quest_id, -1)
