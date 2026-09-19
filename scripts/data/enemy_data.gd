class_name EnemyData
extends Resource
## Data resource defining an enemy encounter.

@export var id: String = ""
@export var enemy_name: String = ""
@export_multiline var description: String = ""
@export var sprite: Texture2D
@export var element_affinity: Enums.Element = Enums.Element.NONE
@export var element_weakness: Enums.Element = Enums.Element.NONE
@export var max_hp: int = 50
@export var max_mp: int = 10
@export var attack: int = 12
@export var defense: int = 6
@export var magic: int = 5
@export var speed: int = 8
@export var xp_reward: int = 20
@export var gold_reward: int = 15
@export var tile_index: int = 0
@export var drop_item_id: String = ""
@export var drop_chance: float = 0.5
@export var skills: Array[Resource] = []
@export var drop_table: Array[Resource] = []
