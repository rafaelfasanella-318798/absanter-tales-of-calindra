class_name SceneManagerAutoload
extends Node
## Manages scene transitions with visual fade effects.

signal scene_transition_started(target_scene_path: String)
signal scene_transition_finished(target_scene_path: String)

var _fade_layer: CanvasLayer
var _fade_rect: ColorRect
var _is_transitioning: bool = false


func _ready() -> void:
	_setup_fade_overlay()


func _setup_fade_overlay() -> void:
	_fade_layer = CanvasLayer.new()
	_fade_layer.layer = 128
	add_child(_fade_layer)

	_fade_rect = ColorRect.new()
	_fade_rect.color = Color(0.0, 0.0, 0.0, 0.0)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fade_layer.add_child(_fade_rect)


func change_scene(scene_path: String, fade_duration: float = 0.5) -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	scene_transition_started.emit(scene_path)

	var tween: Tween = create_tween()
	tween.tween_property(_fade_rect, "color:a", 1.0, fade_duration)
	await tween.finished

	get_tree().change_scene_to_file(scene_path)

	tween = create_tween()
	tween.tween_property(_fade_rect, "color:a", 0.0, fade_duration)
	await tween.finished

	_is_transitioning = false
	scene_transition_finished.emit(scene_path)
