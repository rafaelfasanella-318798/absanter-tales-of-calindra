class_name NPC3D
extends StaticBody3D
## 3D NPC entity (Tav / villagers) in Grandia style.

@export var npc_name: String = "Tav"

@onready var name_label: Label3D = $NameLabel


func _ready() -> void:
	if name_label != null:
		name_label.text = npc_name


func interact(_player: Node3D) -> void:
	var lines: Array[Dictionary] = [
		{
			"speaker": npc_name,
			"text": "Ragg! Calindra! Sejam bem-vindos à Kakariko em 3D estilo Grandia!",
			"portrait_tile": 97
		},
		{
			"speaker": "Calindra",
			"text": "O mundo ganhou profundidade e a arena de combate está logo ao norte, Tav!",
			"portrait_tile": 86
		},
		{
			"speaker": npc_name,
			"text":
			"Siga para o portal de batalha ao norte para testar a arena de combate e a barra de IP!",
			"portrait_tile": 97
		}
	]
	DialogueManager.start_dialogue_sequence("tav_3d_greeting", lines)
