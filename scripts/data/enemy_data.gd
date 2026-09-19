class_name EnemyData
extends Resource
## Data resource defining an enemy encounter.

@export var id: String = ""
@export var enemy_name: String = ""
@export_multiline var description: String = ""
@export var sprite: Texture2D
@export var element_affinity: Enums.Element = Enums.Element.NONE
@export var element_weakness: Enums.Element = Enums.Element.NONE
@export var skills: Array[Resource] = []
@export var drop_table: Array[Resource] = []
