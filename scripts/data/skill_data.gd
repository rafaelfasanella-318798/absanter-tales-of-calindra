class_name SkillData
extends Resource
## Data resource defining an active or passive battle skill.

@export var id: String = ""
@export var skill_name: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D
@export var element: Enums.Element = Enums.Element.NONE
@export var target_type: String = ""  # self, single_enemy, all_enemies, single_ally, all_allies
@export var animation_name: String = ""
