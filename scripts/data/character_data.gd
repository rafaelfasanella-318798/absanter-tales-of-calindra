class_name CharacterData
extends Resource
## Data resource defining a playable character.

@export var id: String = ""
@export var character_name: String = ""
@export var title: String = ""
@export_multiline var description: String = ""
@export var portrait: Texture2D
@export var sprite_frames: SpriteFrames
@export var starting_skills: Array[Resource] = []
