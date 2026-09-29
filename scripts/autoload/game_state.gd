class_name GameStateAutoload
extends Node
## Global game state holder: tracks flags, game mode, playtime, and current context.

signal flag_changed(flag_name: String, value: Variant)
signal game_mode_changed(new_mode: String)

var current_mode: String = "exploration"  # exploration, battle, dialogue, menu, cutscene
var playtime_seconds: float = 0.0
var flags: Dictionary = {}

## Tipo de encontro de campo: "normal" | "surprise" | "ambush"
## Definido pelo EnemyWanderer3D antes de carregar a cena de batalha.
var encounter_type: String = "normal"


func _process(delta: float) -> void:
	playtime_seconds += delta


func set_flag(flag_name: String, value: Variant) -> void:
	flags[flag_name] = value
	flag_changed.emit(flag_name, value)


func get_flag(flag_name: String, default_value: Variant = null) -> Variant:
	return flags.get(flag_name, default_value)
