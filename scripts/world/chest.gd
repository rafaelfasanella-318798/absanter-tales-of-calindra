class_name Chest
extends StaticBody2D
## Interactive chest entity that turns out to be a hostile Mimic.

signal opened
signal mimic_defeated(reward_item_id: String)

@export var reward_item_id: String = "lamina_kakariko"
@export var reward_gold: int = 50

var is_open: bool = false
var is_mimic: bool = true

@onready var sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	if sprite != null and sprite.texture == null:
		sprite.texture = TextureLoader.get_kenney_tile(89)  # Closed chest

	if GameState.get_flag("mimic_defeated", false):
		_set_as_opened()


func interact(_player: Node2D) -> void:
	if is_open or GameState.get_flag("mimic_defeated", false):
		DialogueManager.start_dialogue_sequence(
			"mimic_empty",
			[
				{
					"speaker": "Ragg",
					"text": "A carcaça do Mímico jaz inerte. Não há mais nada aqui.",
					"portrait_tile": 85
				}
			]
		)
		return

	# Trigger the Mimic reveal and combat encounter!
	_trigger_mimic_encounter()


func _trigger_mimic_encounter() -> void:
	# Reveal mimic monster texture
	if sprite != null:
		sprite.texture = TextureLoader.get_kenney_tile(109)  # Monster form

	var lines: Array[Dictionary] = [
		{
			"speaker": "Narração",
			"text": "O baú treme com violência, revelando presas pontiagudas e uma língua viscosa!",
			"portrait_tile": 109
		},
		{"speaker": "Mímico", "text": "GHRRRRAAARRRGH! *CRUNCH!*", "portrait_tile": 109},
		{
			"speaker": "Calindra",
			"text": "Cuidado, Ragg! É uma emboscada! Prepare-se para atacar!",
			"portrait_tile": 86
		},
		{
			"speaker": "Narração",
			"text":
			"Ragg golpeia com bravura enquanto Calindra atinge o monstro com um feixe arcano!",
			"portrait_tile": 85
		},
		{
			"speaker": "Narração",
			"text":
			"O Mímico foi destruído! De suas entranhas caiu um item reluzente: Lâmina de Kakariko!",
			"portrait_tile": 89
		},
		{
			"speaker": "Calindra",
			"text": "Excelente trabalho em equipe, Ragg! Essa lâmina parece afiada e poderosa.",
			"portrait_tile": 86
		}
	]

	# Connect to dialogue finished to grant rewards and finalize chest state
	var on_dialogue_finished: Callable
	on_dialogue_finished = func(dialogue_id: String) -> void:
		if dialogue_id == "mimic_fight":
			DialogueManager.dialogue_closed.disconnect(on_dialogue_finished)
			_finalize_mimic_defeat()

	DialogueManager.dialogue_closed.connect(on_dialogue_finished)
	DialogueManager.start_dialogue_sequence("mimic_fight", lines)


func _finalize_mimic_defeat() -> void:
	is_open = true
	GameState.set_flag("mimic_defeated", true)
	InventoryManager.add_item(reward_item_id, 1)
	InventoryManager.add_gold(reward_gold)
	_set_as_opened()
	opened.emit()
	mimic_defeated.emit(reward_item_id)


func _set_as_opened() -> void:
	is_open = true
	if sprite != null:
		sprite.texture = TextureLoader.get_kenney_tile(90)  # Open chest
