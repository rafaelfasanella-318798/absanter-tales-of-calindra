class_name SaveManagerAutoload
extends Node
## Manages serialization and deserialization of save slots and autosave in JSON.

signal save_completed(slot_id: int)
signal load_completed(slot_id: int)
signal save_failed(slot_id: int, reason: String)
signal load_failed(slot_id: int, reason: String)

const SAVE_DIR: String = "user://saves/"
const SAVE_FILE_TEMPLATE: String = "user://saves/slot_%d.json"


func _ready() -> void:
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_recursive_absolute(SAVE_DIR)


func save_game(
	slot_id: int, current_scene_path: String = "", player_pos: Vector2 = Vector2.ZERO
) -> bool:
	var save_data: Dictionary = {
		"version": "1.0",
		"timestamp": Time.get_datetime_string_from_system(),
		"current_scene": current_scene_path,
		"player_position": {"x": player_pos.x, "y": player_pos.y},
		"flags": GameState.flags.duplicate(),
		"playtime_seconds": GameState.playtime_seconds,
		"gold": InventoryManager.gold,
		"items": InventoryManager.items.duplicate(),
		"active_quests": QuestManager.active_quests.duplicate(),
		"completed_quests": QuestManager.completed_quests.duplicate(),
		"active_party": PartyManager.active_members.duplicate()
	}

	var file_path: String = SAVE_FILE_TEMPLATE % slot_id
	var file: FileAccess = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		var err_msg: String = (
			"Could not open %s for writing: %s"
			% [file_path, error_string(FileAccess.get_open_error())]
		)
		save_failed.emit(slot_id, err_msg)
		return false

	var json_string: String = JSON.stringify(save_data, "\t")
	file.store_string(json_string)
	file.close()

	save_completed.emit(slot_id)
	return true


func load_game(slot_id: int) -> bool:
	var file_path: String = SAVE_FILE_TEMPLATE % slot_id
	if not FileAccess.file_exists(file_path):
		var err_msg: String = "Save file not found at " + file_path
		load_failed.emit(slot_id, err_msg)
		return false

	var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		var err_msg: String = "Could not open %s for reading" % file_path
		load_failed.emit(slot_id, err_msg)
		return false

	var content: String = file.get_as_text()
	file.close()

	var json: JSON = JSON.new()
	var parse_result: Error = json.parse(content)
	if parse_result != OK:
		var err_msg: String = "JSON Parse Error on %s: %s" % [file_path, json.get_error_message()]
		load_failed.emit(slot_id, err_msg)
		return false

	var data: Dictionary = json.data
	_apply_save_data(data)

	load_completed.emit(slot_id)
	return true


func _apply_save_data(data: Dictionary) -> void:
	if data.has("flags") and data["flags"] is Dictionary:
		GameState.flags = data["flags"].duplicate()

	if data.has("playtime_seconds"):
		GameState.playtime_seconds = float(data["playtime_seconds"])

	if data.has("gold"):
		InventoryManager.gold = int(data["gold"])
		InventoryManager.currency_updated.emit(InventoryManager.gold)

	if data.has("items") and data["items"] is Dictionary:
		InventoryManager.items.clear()
		for item_id in data["items"]:
			InventoryManager.items[str(item_id)] = int(data["items"][item_id])

	if data.has("active_quests") and data["active_quests"] is Dictionary:
		QuestManager.active_quests = data["active_quests"].duplicate()

	if data.has("completed_quests") and data["completed_quests"] is Array:
		QuestManager.completed_quests.clear()
		for q in data["completed_quests"]:
			QuestManager.completed_quests.append(str(q))

	if data.has("active_party") and data["active_party"] is Array:
		PartyManager.active_members.clear()
		for member in data["active_party"]:
			PartyManager.active_members.append(str(member))


func has_save(slot_id: int) -> bool:
	var file_path: String = SAVE_FILE_TEMPLATE % slot_id
	return FileAccess.file_exists(file_path)


func delete_save(slot_id: int) -> bool:
	var file_path: String = SAVE_FILE_TEMPLATE % slot_id
	if FileAccess.file_exists(file_path):
		var err: Error = DirAccess.remove_absolute(file_path)
		return err == OK
	return false
