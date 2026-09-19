class_name KakarikoMap
extends BaseMap
## Vila Kakariko overworld map.


func _ready() -> void:
	super._ready()

	# Calindra opening banter and quest start on first visit to Kakariko
	if not GameState.get_flag("visited_kakariko", false):
		GameState.set_flag("visited_kakariko", true)
		var quest_needed: bool = (
			not QuestManager.is_quest_active("quest_kakariko")
			and not QuestManager.is_quest_completed("quest_kakariko")
		)
		if quest_needed:
			QuestManager.start_quest("quest_kakariko")
		get_tree().create_timer(0.8).timeout.connect(_play_intro_banter)


func _play_intro_banter() -> void:
	DialogueManager.start_dialogue_sequence(
		"kakariko_intro",
		[
			{
				"speaker": "Calindra",
				"text":
				"Chegamos a Kakariko, Ragg! Ouvi dizer que há pessoas acolhedoras por aqui.",
				"portrait_tile": 86
			},
			{
				"speaker": "Calindra",
				"text":
				"Aquele aldeão perto da cabana deve ser o Tav. Devíamos falar com ele primeiro!",
				"portrait_tile": 86
			}
		]
	)
