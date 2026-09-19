class_name MainScene
extends Control
## Title screen for Absanter - Tales of Calindra with New Game, Continue, and Quit options.

const STARTING_WORLD_SCENE: String = "res://scenes/world/kakariko.tscn"

@onready var btn_new_game: Button = $VBoxMenu/BtnNewGame
@onready var btn_continue: Button = $VBoxMenu/BtnContinue
@onready var btn_quit: Button = $VBoxMenu/BtnQuit
@onready var btn_lang: Button = $VBoxMenu/BtnLang


func _ready() -> void:
	GameState.current_mode = "menu"

	if btn_new_game != null:
		btn_new_game.pressed.connect(_on_new_game_pressed)
		btn_new_game.grab_focus()

	if btn_continue != null:
		btn_continue.disabled = not SaveManager.has_save(1)
		btn_continue.pressed.connect(_on_continue_pressed)

	if btn_quit != null:
		btn_quit.pressed.connect(_on_quit_pressed)

	if btn_lang != null:
		btn_lang.pressed.connect(_on_lang_pressed)

	_update_localized_texts()


func _on_new_game_pressed() -> void:
	GameState.flags.clear()
	InventoryManager.items.clear()
	InventoryManager.gold = 0
	QuestManager.active_quests.clear()
	QuestManager.completed_quests.clear()
	PartyManager.active_members = ["ragg", "calindra"]
	SceneManager.change_scene(STARTING_WORLD_SCENE)


func _on_continue_pressed() -> void:
	if SaveManager.has_save(1):
		SaveManager.load_game(1)
		var saved_scene: String = GameState.get_flag("current_scene", STARTING_WORLD_SCENE)
		SceneManager.change_scene(saved_scene)


func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_lang_pressed() -> void:
	var next: String = "en" if Localization.get_locale() == "pt_BR" else "pt_BR"
	Localization.set_locale(next)
	_update_localized_texts()


func _update_localized_texts() -> void:
	if btn_new_game != null:
		btn_new_game.text = Localization.translate_key("KEY_NEW_GAME")
	if btn_continue != null:
		btn_continue.text = Localization.translate_key("KEY_CONTINUE")
	if btn_quit != null:
		btn_quit.text = Localization.translate_key("KEY_QUIT")
	if btn_lang != null:
		btn_lang.text = (
			"Idioma: PT-BR" if Localization.get_locale() == "pt_BR" else "Language: EN"
		)
