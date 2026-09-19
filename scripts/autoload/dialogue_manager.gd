class_name DialogueManagerAutoload
extends Node
## Manages dialogue progression, text typing, portraits, and choices.

signal dialogue_opened(dialogue_id: String)
signal line_started(character_name: String, text: String)
signal line_finished
signal dialogue_closed(dialogue_id: String)

var is_active: bool = false


func start_dialogue(dialogue_id: String) -> void:
	is_active = true
	dialogue_opened.emit(dialogue_id)


func advance_dialogue() -> void:
	pass


func end_dialogue(dialogue_id: String) -> void:
	is_active = false
	dialogue_closed.emit(dialogue_id)
