class_name ItemData
extends Resource
## Data resource defining an item, equipment, or consumable.

@export var id: String = ""
@export var item_name: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D
@export var item_type: Enums.ItemType = Enums.ItemType.CONSUMABLE
@export var is_usable_in_battle: bool = true
@export var is_usable_in_menu: bool = true
@export var heal_hp: int = 0
@export var heal_mp: int = 0
@export var target_type: String = "single_ally"  # single_ally, all_allies, single_enemy
@export var price: int = 20
@export var equip_slot: String = ""  # "weapon", "armor", "accessory"
@export var bonus_hp: int = 0
@export var bonus_mp: int = 0
@export var bonus_attack: int = 0
@export var bonus_defense: int = 0
@export var bonus_magic: int = 0
@export var bonus_speed: int = 0
@export var allowed_characters: Array[String] = []  # Empty means all characters can equip
