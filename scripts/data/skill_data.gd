class_name SkillData
extends Resource
## Data resource defining an active or passive battle skill.

@export var id: String = ""
@export var skill_name: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D
@export var element: Enums.Element = Enums.Element.NONE
# target_type: self, single_enemy, all_enemies, single_ally, all_allies
@export var target_type: String = "single_enemy"
@export var cost_mp: int = 0
@export var power_multiplier: float = 1.0
@export var base_value: int = 0
@export var is_healing: bool = false
@export var is_buff: bool = false
@export var buff_type: Enums.StatusEffect = Enums.StatusEffect.NONE
@export var buff_duration: int = 3
@export var animation_name: String = ""
