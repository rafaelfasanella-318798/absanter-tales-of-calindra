class_name KakarikoCaveMap
extends BaseMap
## Caverna dos Murmúrios dungeon map containing encounters, puzzles, and boss entrance.


func _ready() -> void:
	map_name = "Caverna dos Murmúrios"
	super._ready()

	if not GameState.get_flag("visited_kakariko_cave", false):
		GameState.set_flag("visited_kakariko_cave", true)
		get_tree().create_timer(0.7).timeout.connect(_play_cave_banter)


func _play_cave_banter() -> void:
	(
		DialogueManager
		. start_dialogue_sequence(
			"cave_intro",
			[
				{
					"speaker": "Calindra",
					"text":
					"A Caverna dos Murmúrios... O ar aqui é gélido e sinto ecos antigos nos observando.",
					"portrait_tile": 86
				},
				{
					"speaker": "Ragg",
					"text":
					"Espada em punho. Qualquer coisa que se mover na escuridão vai provar do meu aço.",
					"portrait_tile": 85
				}
			]
		)
	)
