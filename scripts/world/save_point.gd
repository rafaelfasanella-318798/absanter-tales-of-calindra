class_name SavePoint
extends StaticBody2D
## Interactive recovery crystal that restores party HP/MP and saves game progress.

signal used

const RESTORE_TILE_INDEX: int = 97

@export var point_name: String = "Cristal dos Guardiões"

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	if sprite != null and sprite.texture == null:
		sprite.texture = TextureLoader.get_kenney_tile(RESTORE_TILE_INDEX)


func interact(player: Node2D) -> void:
	# Save progress
	var current_scene: String = (
		get_tree().current_scene.scene_file_path
		if get_tree().current_scene != null
		else "res://scenes/world/kakariko.tscn"
	)
	var player_pos: Vector2 = player.global_position if player != null else Vector2.ZERO
	SaveManager.save_game(1, current_scene, player_pos)

	used.emit()

	# Display recovery dialogue
	var lines: Array[Dictionary] = [
		{
			"speaker": "Cristal Arcano",
			"text": "Uma luz acolhedora envolve Ragg e Calindra. Vitalidade e mana restauradas!",
			"portrait_tile": RESTORE_TILE_INDEX
		},
		{
			"speaker": "Calindra",
			"text":
			"Sinto a energia mística deste solo revigorando nossos corpos. E o progresso foi salvo!",
			"portrait_tile": 86
		}
	]
	DialogueManager.start_dialogue_sequence("save_point", lines)
