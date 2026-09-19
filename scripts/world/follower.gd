class_name Follower
extends CharacterBody2D
## Companion follower controller (Calindra) following the player in conga-line style.

@export var target_player: Player
@export var follow_distance_steps: int = 5
@export var follow_speed: float = 90.0

var facing_direction: Vector2 = Vector2.DOWN

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	if sprite != null and sprite.texture == null:
		sprite.texture = TextureLoader.get_kenney_tile(86)  # Calindra mage sprite

	if target_player == null:
		var players: Array[Node] = get_tree().get_nodes_in_group("player")
		if not players.is_empty():
			target_player = players[0] as Player


func _physics_process(_delta: float) -> void:
	if target_player == null:
		var players: Array[Node] = get_tree().get_nodes_in_group("player")
		if not players.is_empty():
			target_player = players[0] as Player
		if target_player == null:
			return

	if target_player.position_history.is_empty():
		return

	# Determine target position in player's path history
	var target_index: int = mini(follow_distance_steps, target_player.position_history.size() - 1)
	var target_pos: Vector2 = target_player.position_history[target_index]

	var dist: float = global_position.distance_to(target_pos)
	if dist > 3.0:
		var dir: Vector2 = (target_pos - global_position).normalized()
		velocity = dir * follow_speed
		if abs(dir.x) > abs(dir.y):
			facing_direction = Vector2(sign(dir.x), 0)
		else:
			facing_direction = Vector2(0, sign(dir.y))
	else:
		velocity = Vector2.ZERO

	move_and_slide()
