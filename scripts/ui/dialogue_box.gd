class_name DialogueBox
extends Control
## UI display component for dialogue sequences with portraits and speaker names.

@onready var panel_container: PanelContainer = $PanelContainer
@onready var portrait_rect: TextureRect = $PanelContainer/MarginContainer/HBoxContainer/Portrait
@onready
var speaker_label: Label = $PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/SpeakerLabel
@onready
var text_label: Label = $PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/TextLabel
@onready
var prompt_label: Label = $PanelContainer/MarginContainer/HBoxContainer/VBoxContainer/PromptLabel


func _ready() -> void:
	visible = false
	DialogueManager.dialogue_opened.connect(_on_dialogue_opened)
	DialogueManager.line_started.connect(_on_line_started)
	DialogueManager.dialogue_closed.connect(_on_dialogue_closed)


func _unhandled_input(event: InputEvent) -> void:
	if not visible or not DialogueManager.is_active:
		return

	if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		DialogueManager.advance_dialogue()


func _on_dialogue_opened(_id: String) -> void:
	visible = true
	_lock_players(true)


func _on_line_started(speaker: String, text: String, portrait_tile: int) -> void:
	speaker_label.text = speaker
	text_label.text = text

	if portrait_tile >= 0:
		portrait_rect.visible = true
		portrait_rect.texture = TextureLoader.get_kenney_tile(portrait_tile)
	else:
		portrait_rect.visible = false


func _on_dialogue_closed(_id: String) -> void:
	visible = false
	_lock_players(false)


func _lock_players(lock: bool) -> void:
	var players: Array[Node] = get_tree().get_nodes_in_group("player")
	for p in players:
		if p is Player:
			p.lock_movement(lock)
