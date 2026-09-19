class_name NPC
extends StaticBody2D
## Interactive NPC entity for Tav and villagers in Kakariko.

@export var npc_name: String = "Tav"
@export var portrait_tile: int = 97  # Tav's villager tile

@onready var sprite: Sprite2D = $Sprite2D
@onready var prompt_icon: Sprite2D = $PromptIcon


func _ready() -> void:
	if sprite != null and sprite.texture == null:
		sprite.texture = TextureLoader.get_kenney_tile(portrait_tile)
	if prompt_icon != null:
		prompt_icon.visible = false


func interact(_player: Node2D) -> void:
	var has_defeated_mimic: bool = GameState.get_flag("mimic_defeated", false)
	var lines: Array[Dictionary] = []

	if has_defeated_mimic:
		lines = [
			{
				"speaker": "Tav",
				"text": "Pelas barbas dos deuses! Vocês derrotaram aquela aberração?!",
				"portrait_tile": 97
			},
			{
				"speaker": "Calindra",
				"text": "Foi um confronto tenso, Tav, mas Ragg e eu cuidamos disso!",
				"portrait_tile": 86
			},
			{
				"speaker": "Tav",
				"text": "Kakariko está em dívida com vocês. Cuidem bem da relíquia encontrada!",
				"portrait_tile": 97
			}
		]
	else:
		lines = [
			{
				"speaker": "Tav",
				"text": "Olá, viajantes! Bem-vindos à vila de Kakariko! Eu sou o Tav.",
				"portrait_tile": 97
			},
			{
				"speaker": "Tav",
				"text":
				"Se vocês buscam tesouros, tenham muito cuidado com o baú na clareira norte.",
				"portrait_tile": 97
			},
			{
				"speaker": "Tav",
				"text": "Dizem que ele range sozinho à noite... e parece ter dentes!",
				"portrait_tile": 97
			},
			{
				"speaker": "Calindra",
				"text":
				"Dentes num baú? Ragg, isso tem todo o cheiro de um Mímico. Vamos preparados!",
				"portrait_tile": 86
			}
		]

	GameState.set_flag("talked_to_tav", true)
	DialogueManager.start_dialogue_sequence("tav_greeting", lines)
