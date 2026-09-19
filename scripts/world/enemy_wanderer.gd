class_name EnemyWanderer
extends CharacterBody2D
## Overworld roaming enemy that triggers turn-based battle on touch.

signal battle_triggered(encounter_data: Dictionary)

const CHANGE_DIRECTION_TIME: float = 2.0

@export var encounter_enemy_ids: Array[String] = ["slime", "cave_bat"]
@export var is_boss: bool = false
@export var tile_index: int = 109
@export var wander_radius: float = 32.0
@export var move_speed: float = 30.0
@export var persistence_id: String = ""

var _origin_position: Vector2 = Vector2.ZERO
var _move_direction: Vector2 = Vector2.ZERO
var _timer: float = 0.0
var _is_triggered: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var interaction_area: Area2D = $InteractionArea


func _ready() -> void:
	_origin_position = global_position
	if sprite != null and tile_index > 0:
		sprite.texture = TextureLoader.get_kenney_tile(tile_index)

	if not persistence_id.is_empty() and GameState.get_flag(persistence_id + "_defeated", false):
		queue_free()
		return

	if interaction_area != null:
		interaction_area.body_entered.connect(_on_interaction_area_body_entered)


func _physics_process(delta: float) -> void:
	if _is_triggered:
		return

	_timer -= delta
	if _timer <= 0.0:
		_timer = randf_range(1.5, CHANGE_DIRECTION_TIME)
		if randf() < 0.35:
			_move_direction = Vector2.ZERO
		else:
			var angle: float = randf_range(0.0, TAU)
			_move_direction = Vector2(cos(angle), sin(angle)).normalized()

	# Don't wander too far from origin
	if global_position.distance_to(_origin_position) > wander_radius:
		_move_direction = (_origin_position - global_position).normalized()

	velocity = _move_direction * move_speed
	move_and_slide()


func _on_interaction_area_body_entered(body: Node2D) -> void:
	if _is_triggered:
		return

	if body is Player:
		_is_triggered = true
		_trigger_battle(body as Player)


func _trigger_battle(player: Player) -> void:
	var current_scene: String = (
		get_tree().current_scene.scene_file_path
		if get_tree().current_scene != null
		else "res://scenes/world/kakariko.tscn"
	)
	var player_pos: Vector2 = player.global_position

	if not persistence_id.is_empty():
		GameState.set_flag(persistence_id + "_defeated", true)

	var encounter_data: Dictionary = {
		"enemies": encounter_enemy_ids,
		"is_boss": is_boss,
		"return_scene": current_scene,
		"return_pos": player_pos
	}

	battle_triggered.emit(encounter_data)
	EventBus.battle_start_requested.emit(encounter_data)
	SceneManager.change_scene_with_transition(
		"res://scenes/battle/battle_scene.tscn", "", player_pos
	)
