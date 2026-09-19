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
