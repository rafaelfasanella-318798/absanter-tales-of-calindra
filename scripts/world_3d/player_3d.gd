class_name Player3D
extends CharacterBody3D
## 3D player controller for Ragg in modest-PC Grandia style.

signal interacted

const MAX_HISTORY: int = 50

@export var character_name: String = "Ragg"
@export var move_speed: float = 6.0
@export var rotation_speed: float = 12.0

var is_movement_locked: bool = false
var position_history: Array[Vector3] = []

@onready var name_label: Label3D = $NameLabel
@onready var interact_ray: RayCast3D = $InteractRay
@onready var visual_root: Node3D = $Visuals


func _ready() -> void:
	if name_label != null:
		name_label.text = character_name
	position_history.append(global_position)


func _physics_process(delta: float) -> void:
	if is_movement_locked:
		velocity = Vector3.ZERO
		move_and_slide()
		return

	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var move_vector: Vector3 = Vector3(input_dir.x, 0, input_dir.y).normalized()

	if move_vector != Vector3.ZERO:
		velocity.x = move_vector.x * move_speed
		velocity.z = move_vector.z * move_speed

		# Rotate visuals toward movement direction
		var target_angle: float = atan2(move_vector.x, move_vector.z)
		if visual_root != null:
			visual_root.rotation.y = lerp_angle(
				visual_root.rotation.y, target_angle, rotation_speed * delta
			)

		if interact_ray != null:
			interact_ray.target_position = (Vector3(sin(target_angle), 0, cos(target_angle)) * 1.6)

		_record_position_step()
	else:
		velocity.x = move_toward(velocity.x, 0, move_speed)
		velocity.z = move_toward(velocity.z, 0, move_speed)

	# Apply gravity if in the air
	if not is_on_floor():
		velocity.y -= 18.0 * delta
	else:
		velocity.y = 0.0

	move_and_slide()


func _unhandled_input(event: InputEvent) -> void:
	if is_movement_locked:
		return
	if event.is_action_pressed("interact"):
		_try_interact()
		get_viewport().set_input_as_handled()


func _record_position_step() -> void:
	if position_history.is_empty() or global_position.distance_to(position_history[0]) > 0.3:
		position_history.push_front(global_position)
		if position_history.size() > MAX_HISTORY:
			position_history.pop_back()


func _try_interact() -> void:
	if interact_ray != null and interact_ray.is_colliding():
		var col: Object = interact_ray.get_collider()
		if col != null and col.has_method("interact"):
			col.call("interact", self)
			interacted.emit()


func lock_movement(lock: bool) -> void:
	is_movement_locked = lock
