class_name NPC
extends StaticBody2D
## Interactive NPC entity for Tav and villagers in Kakariko.

@export var npc_name: String = "Tav"
@export var portrait_tile: int = 97  # Tav's villager tile
@export var is_merchant: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var prompt_icon: Sprite2D = $PromptIcon


func _ready() -> void:
	if sprite != null and sprite.texture == null:
		sprite.texture = TextureLoader.get_kenney_tile(portrait_tile)
	if prompt_icon != null:
		prompt_icon.visible = false


func interact(_player: Node2D) -> void:
	if is_merchant or npc_name == "Barnaby":
		_handle_merchant_interaction()
		return

	var has_defeated_mimic: bool = GameState.get_flag("mimic_defeated", false)
	var has_defeated_golem: bool = GameState.get_flag("golem_defeated", false)
	var lines: Array[Dictionary] = []

	if has_defeated_golem:
		lines = [
			{
				"speaker": "Tav",
				"text": "Ragg! Calindra! A terra parou de tremer! O Golem Antigo foi pacificado!",
				"portrait_tile": 97
			},
			{
				"speaker": "Calindra",
				"text": "O selo da caverna foi purificado, Tav. Kakariko está finalmente a salvo.",
				"portrait_tile": 86
			},
			{
				"speaker": "Tav",
				"text": "Vocês são verdadeiros heróis! Kakariko sempre honrará seus nomes!",
				"portrait_tile": 97
			}
		]
		if QuestManager.is_quest_active("quest_kakariko"):
			QuestManager.complete_quest("quest_kakariko")
	elif has_defeated_mimic:
		lines = [
			{
				"speaker": "Tav",
				"text": "Pelas barbas dos deuses! Vocês derrotaram o Mímico e acharam a Lâmina?!",
				"portrait_tile": 97
			},
			{
				"speaker": "Calindra",
				"text": "Sim! A relíquia reluzia no interior daquela carcaça.",
				"portrait_tile": 86
			},
			{
				"speaker": "Tav",
				"text":
				"Essa lâmina abre a Caverna dos Murmúrios a leste! O Guardião espera por ela!",
				"portrait_tile": 97
			},
			{
				"speaker": "Ragg",
				"text": "Então a caverna a leste é nosso próximo destino. Vamos lá, Calindra!",
				"portrait_tile": 85
			}
		]
		GameState.set_flag("cave_unlocked", true)
		if QuestManager.is_quest_active("quest_kakariko"):
			QuestManager.set_quest_stage("quest_kakariko", 4)
	else:
		lines = [
			{
				"speaker": "Tav",
				"text": "Olá, viajantes! Bem-vindos à vila de Kakariko! Eu sou o Tav.",
				"portrait_tile": 97
			},
			{
				"speaker": "Tav",
				"text": "Se buscam tesouros, tenham muito cuidado com o baú na clareira norte.",
				"portrait_tile": 97
			},
			{
				"speaker": "Tav",
				"text": "Dizem que ele range sozinho à noite... e parece ter dentes afiados!",
				"portrait_tile": 97
			},
			{
				"speaker": "Calindra",
				"text": "Dentes num baú? Ragg, isso parece um Mímico. Vamos com cautela!",
				"portrait_tile": 86
			}
		]
		if QuestManager.is_quest_active("quest_kakariko"):
			if QuestManager.get_quest_stage("quest_kakariko") == 0:
				QuestManager.set_quest_stage("quest_kakariko", 1)

	GameState.set_flag("talked_to_tav", true)
	DialogueManager.start_dialogue_sequence("tav_greeting", lines)


func _handle_merchant_interaction() -> void:
	var merchant_lines: Array[Dictionary] = [
		{
			"speaker": npc_name,
			"text": "Saudações, viajantes! Trago poções e itens úteis para a jornada.",
			"portrait_tile": portrait_tile
		},
		{
			"speaker": npc_name,
			"text": "Dê uma olhada em minhas mercadorias antes de entrar na caverna!",
			"portrait_tile": portrait_tile
		}
	]
	DialogueManager.start_dialogue_sequence("barnaby_shop", merchant_lines)

	var callable: Callable
	callable = func(seq_id: String) -> void:
		if seq_id == "barnaby_shop":
			DialogueManager.dialogue_closed.disconnect(callable)
			var shop: ShopMenu = get_tree().root.find_child("ShopMenu", true, false) as ShopMenu
			if shop != null:
				shop.open_shop()

	DialogueManager.dialogue_closed.connect(callable)
