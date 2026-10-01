class_name Follower3D
extends CharacterBody3D
## 3D companion follower (Calindra) following Player3D in Grandia style.

@export var follower_name: String = "Calindra"
@export var target_player: Player3D
@export var follow_distance_steps: int = 4
@export var follow_speed: float = 6.0
@export var rotation_speed: float = 12.0

@onready var name_label: Label3D = $NameLabel
@onready var visual_root: Node3D = $Visuals


func _ready() -> void:
	if name_label != null:
		name_label.text = follower_name

	if target_player == null:
		var players: Array[Node] = get_tree().get_nodes_in_group("player_3d")
		if not players.is_empty():
			target_player = players[0] as Player3D


func _physics_process(delta: float) -> void:
	if target_player == null:
		var players: Array[Node] = get_tree().get_nodes_in_group("player_3d")
		if not players.is_empty():
			target_player = players[0] as Player3D
		if target_player == null:
			return

	if target_player.position_history.is_empty():
		return

	var target_index: int = mini(follow_distance_steps, target_player.position_history.size() - 1)
	var target_pos: Vector3 = target_player.position_history[target_index]

	var flat_dist: float = (
		Vector2(global_position.x - target_pos.x, global_position.z - target_pos.z).length()
	)

	if flat_dist > 1.2:
		var dir: Vector3 = (target_pos - global_position).normalized()
		velocity.x = dir.x * follow_speed
		velocity.z = dir.z * follow_speed

		var target_angle: float = atan2(dir.x, dir.z)
		if visual_root != null:
			visual_root.rotation.y = lerp_angle(
				visual_root.rotation.y, target_angle, rotation_speed * delta
			)
	else:
		velocity.x = move_toward(velocity.x, 0, follow_speed)
		velocity.z = move_toward(velocity.z, 0, follow_speed)

	if not is_on_floor():
		velocity.y -= 18.0 * delta
	else:
		velocity.y = 0.0

	move_and_slide()
