class_name DialogueManagerAutoload
extends Node
## Manages dialogue progression, text display, and choices.

signal dialogue_opened(dialogue_id: String)
signal line_started(speaker_name: String, text: String, portrait_tile: int)
signal dialogue_closed(dialogue_id: String)

var is_active: bool = false
var current_dialogue_id: String = ""
var _dialogue_queue: Array[Dictionary] = []
var _current_line_index: int = -1


func start_dialogue_sequence(dialogue_id: String, lines: Array[Dictionary]) -> void:
	if is_active:
		return

	is_active = true
	current_dialogue_id = dialogue_id
	_dialogue_queue = lines.duplicate()
	_current_line_index = -1

	dialogue_opened.emit(dialogue_id)
	advance_dialogue()


func advance_dialogue() -> void:
	if not is_active:
		return

	_current_line_index += 1
	if _current_line_index < _dialogue_queue.size():
		var line_data: Dictionary = _dialogue_queue[_current_line_index]
		var speaker: String = line_data.get("speaker", "")
		var text: String = line_data.get("text", "")
		var portrait: int = line_data.get("portrait_tile", -1)
		line_started.emit(speaker, text, portrait)
	else:
		end_dialogue(current_dialogue_id)


func end_dialogue(dialogue_id: String) -> void:
	is_active = false
	_dialogue_queue.clear()
	_current_line_index = -1
	current_dialogue_id = ""
	dialogue_closed.emit(dialogue_id)
