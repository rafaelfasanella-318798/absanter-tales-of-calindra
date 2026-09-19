class_name Player
extends CharacterBody2D
## Top-down player character controller for Ragg.

signal interacted

const MAX_HISTORY_POINTS: int = 100
const RECORD_STEP_DISTANCE: float = 4.0

@export var move_speed: float = 90.0

var facing_direction: Vector2 = Vector2.DOWN
var is_movement_locked: bool = false
var position_history: Array[Vector2] = []

@onready var sprite: Sprite2D = $Sprite2D
@onready var interact_ray: RayCast2D = $InteractRay


func _ready() -> void:
	if sprite != null and sprite.texture == null:
		sprite.texture = TextureLoader.get_kenney_tile(85)
	position_history.append(global_position)


func _physics_process(_delta: float) -> void:
	if is_movement_locked:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var input_vector: Vector2 = Input.get_vector("move_left", "move_right", "move_up", "move_down")

	if input_vector != Vector2.ZERO:
		# Prioritize 4-cardinal directions
		if abs(input_vector.x) > abs(input_vector.y):
			facing_direction = Vector2(sign(input_vector.x), 0)
		else:
			facing_direction = Vector2(0, sign(input_vector.y))

		velocity = input_vector.normalized() * move_speed
		_update_interaction_ray()
		_record_position_step()
	else:
		velocity = Vector2.ZERO

	move_and_slide()

	if Input.is_action_just_pressed("interact"):
		_try_interact()


func _update_interaction_ray() -> void:
	if interact_ray != null:
		interact_ray.target_position = facing_direction * 18.0


func _record_position_step() -> void:
	if position_history.is_empty():
		position_history.append(global_position)
		return

	var last_recorded_pos: Vector2 = position_history[0]
	if global_position.distance_to(last_recorded_pos) >= RECORD_STEP_DISTANCE:
		position_history.push_front(global_position)
		if position_history.size() > MAX_HISTORY_POINTS:
			position_history.pop_back()
		EventBus.player_moved.emit(global_position)


func _try_interact() -> void:
	if interact_ray == null:
		return

	interact_ray.force_raycast_update()
	if interact_ray.is_colliding():
		var collider: Object = interact_ray.get_collider()
		if collider != null and collider.has_method("interact"):
			collider.interact(self)
			interacted.emit()
			return

		# Check parent if collider is an Area2D child
		if (
			collider is Node
			and collider.get_parent() != null
			and collider.get_parent().has_method("interact")
		):
			collider.get_parent().interact(self)
			interacted.emit()


func lock_movement(lock: bool) -> void:
	is_movement_locked = lock
	if lock:
		velocity = Vector2.ZERO
