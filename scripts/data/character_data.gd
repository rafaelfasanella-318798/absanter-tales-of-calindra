class_name CharacterData
extends Resource
## Data resource defining a playable character.

@export var id: String = ""
@export var character_name: String = ""
@export var title: String = ""
@export_multiline var description: String = ""
@export var portrait: Texture2D
@export var sprite_frames: SpriteFrames
@export var level: int = 1
@export var max_hp: int = 100
@export var max_mp: int = 20
@export var attack: int = 15
@export var defense: int = 10
@export var magic: int = 5
@export var speed: int = 10
@export var hp_growth: int = 15
@export var mp_growth: int = 5
@export var attack_growth: int = 3
@export var defense_growth: int = 2
@export var magic_growth: int = 1
@export var speed_growth: int = 1
@export var starting_skills: Array[Resource] = []
