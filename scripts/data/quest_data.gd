class_name QuestData
extends Resource
## Data resource defining a quest and its objectives.

@export var id: String = ""
@export var quest_name: String = ""
@export_multiline var description: String = ""
@export var stages: Array[String] = []
@export var is_main_quest: bool = false
@export var reward_items: Array[Resource] = []
