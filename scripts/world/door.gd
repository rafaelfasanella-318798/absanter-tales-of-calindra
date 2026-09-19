class_name Door
extends Area2D
## Map transition trigger moving player between scenes via SceneManager.

signal transition_triggered(target_scene: String, spawn_id: String)

@export_file("*.tscn") var target_scene_path: String = ""
@export var target_spawn_id: String = "default"


func _ready() -> void:
	body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body is Player and not target_scene_path.is_empty():
		GameState.set_flag("last_spawn_id", target_spawn_id)
		transition_triggered.emit(target_scene_path, target_spawn_id)
		EventBus.map_transition_requested.emit(target_scene_path, target_spawn_id)
		SceneManager.change_scene(target_scene_path)
