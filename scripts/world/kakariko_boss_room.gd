class_name KakarikoBossRoomMap
extends BaseMap
## Ancient chamber where the Chapter 1 Boss (Golem de Pedra) is confronted.

@onready var boss_sprite: Sprite2D = $Entities/BossEntity/Sprite2D
@onready var boss_col: CollisionShape2D = $Entities/BossEntity/CollisionShape2D
@onready var boss_trigger: Area2D = $Entities/BossEntity/BossTriggerArea


func _ready() -> void:
	map_name = "Câmara do Golem Antigo"
	super._ready()

	if GameState.get_flag("golem_defeated", false):
		_setup_dormant_boss()
	else:
		if boss_sprite != null:
			boss_sprite.texture = TextureLoader.get_kenney_tile(90)
		if boss_trigger != null:
			boss_trigger.body_entered.connect(_on_boss_trigger_entered)


func _setup_dormant_boss() -> void:
	if boss_sprite != null:
		boss_sprite.texture = TextureLoader.get_kenney_tile(70)  # Rubble / stone
	if boss_trigger != null:
		boss_trigger.monitoring = false


func _on_boss_trigger_entered(body: Node2D) -> void:
	if GameState.get_flag("golem_defeated", false):
		return

	if body is Player:
		boss_trigger.set_deferred("monitoring", false)
		_play_boss_intro_sequence()


func _play_boss_intro_sequence() -> void:
	var lines: Array[Dictionary] = [
		{
			"speaker": "Voz Ancestral",
			"text": "RUUUUMBLE... QUEM PERTURBA O SONO DO GUARDIÃO DAS PROFUNDEZAS?!",
			"portrait_tile": 90
		},
		{
			"speaker": "Calindra",
			"text":
			"Ragg! A Lâmina de Kakariko está ressoando com o núcleo do Golem! Ele despertou!",
			"portrait_tile": 86
		},
		{
			"speaker": "Ragg",
			"text": "Se ele quer lutar, vai provar do nosso poder! Firme na magia, Calindra!",
			"portrait_tile": 85
		}
	]

	var on_dialogue_finished: Callable
	on_dialogue_finished = func(dialogue_id: String) -> void:
		if dialogue_id == "golem_intro":
			DialogueManager.dialogue_closed.disconnect(on_dialogue_finished)
			_start_boss_battle()

	DialogueManager.dialogue_closed.connect(on_dialogue_finished)
	DialogueManager.start_dialogue_sequence("golem_intro", lines)


func _start_boss_battle() -> void:
	var encounter_data: Dictionary = {
		"enemies": ["kakariko_golem"],
		"is_boss": true,
		"return_scene": scene_file_path,
		"return_pos": player.global_position if player != null else Vector2(160, 140)
	}
	EventBus.battle_start_requested.emit(encounter_data)
	SceneManager.change_scene_with_transition(
		"res://scenes/battle/battle_scene.tscn", "", encounter_data["return_pos"]
	)
