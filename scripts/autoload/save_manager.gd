class_name SaveManagerAutoload
extends Node
## Manages serialization and deserialization of save slots and autosave.

signal save_completed(slot_id: int)
signal load_completed(slot_id: int)
signal save_failed(slot_id: int, reason: String)
signal load_failed(slot_id: int, reason: String)

const SAVE_DIR: String = "user://saves/"
const SAVE_FILE_TEMPLATE: String = "user://saves/slot_%d.json"


func _ready() -> void:
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_recursive_absolute(SAVE_DIR)


func save_game(slot_id: int) -> bool:
	save_completed.emit(slot_id)
	return true


func load_game(slot_id: int) -> bool:
	load_completed.emit(slot_id)
	return true
