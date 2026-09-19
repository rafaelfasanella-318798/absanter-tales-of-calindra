class_name PauseMenu
extends CanvasLayer
## In-game pause menu with Status, Inventory, Quests, Save, and Options tabs.

signal opened
signal closed

@export var is_active: bool = false

@onready var root_panel: Control = $RootPanel
@onready var tab_container: TabContainer = $RootPanel/TabContainer
@onready var status_ragg_lbl: Label = $RootPanel/TabContainer/Status/HBox/RaggInfo
@onready var status_calindra_lbl: Label = $RootPanel/TabContainer/Status/HBox/CalindraInfo
@onready var gold_label: Label = $RootPanel/TabContainer/Status/GoldLabel
@onready var item_vbox: VBoxContainer = $RootPanel/TabContainer/Itens/Scroll/VBox
@onready var quest_label: Label = $RootPanel/TabContainer/Missoes/QuestLabel
@onready var save_btn: Button = $RootPanel/TabContainer/Salvar/BtnSave
@onready var save_feedback: Label = $RootPanel/TabContainer/Salvar/SaveFeedback
@onready var quit_btn: Button = $RootPanel/TabContainer/Sair/BtnQuit
@onready var master_slider: HSlider = $RootPanel/TabContainer/Opcoes/VBox/MasterRow/MasterSlider
@onready var music_slider: HSlider = $RootPanel/TabContainer/Opcoes/VBox/MusicRow/MusicSlider
@onready var sfx_slider: HSlider = $RootPanel/TabContainer/Opcoes/VBox/SfxRow/SfxSlider
@onready var lang_btn: Button = $RootPanel/TabContainer/Opcoes/VBox/LangRow/LangBtn


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if root_panel != null:
		root_panel.visible = false

	if save_btn != null:
		save_btn.pressed.connect(_on_save_pressed)
	if quit_btn != null:
		quit_btn.pressed.connect(_on_quit_pressed)
	if master_slider != null:
		master_slider.value = AudioManager.master_volume
		master_slider.value_changed.connect(AudioManager.set_master_volume)
	if music_slider != null:
		music_slider.value = AudioManager.music_volume
		music_slider.value_changed.connect(AudioManager.set_music_volume)
	if sfx_slider != null:
		sfx_slider.value = AudioManager.sfx_volume
		sfx_slider.value_changed.connect(AudioManager.set_sfx_volume)
	if lang_btn != null:
		lang_btn.text = "PT-BR" if Localization.get_locale() == "pt_BR" else "EN"
		lang_btn.pressed.connect(_on_lang_toggled)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("menu"):
		if GameState.current_mode == "exploration":
			toggle_menu()
			get_viewport().set_input_as_handled()


func toggle_menu() -> void:
	if is_active:
		close_menu()
	else:
		open_menu()


func open_menu() -> void:
	is_active = true
	get_tree().paused = true
	if root_panel != null:
		root_panel.visible = true

	_refresh_status_tab()
	_refresh_items_tab()
	_refresh_quests_tab()
	if save_feedback != null:
		save_feedback.text = ""

	opened.emit()


func close_menu() -> void:
	is_active = false
	get_tree().paused = false
	if root_panel != null:
		root_panel.visible = false
	closed.emit()


func _refresh_status_tab() -> void:
	var ragg_data: CharacterData = load("res://data/characters/ragg.tres") as CharacterData
	var calindra_data: CharacterData = load("res://data/characters/calindra.tres") as CharacterData

	if status_ragg_lbl != null and ragg_data != null:
		status_ragg_lbl.text = (
			"%s (Nv. %d)\nHP: %d\nMP: %d\nATK: %d\nDEF: %d\nMAG: %d\nSPD: %d"
			% [
				ragg_data.character_name,
				ragg_data.level,
				ragg_data.max_hp,
				ragg_data.max_mp,
				ragg_data.attack,
				ragg_data.defense,
				ragg_data.magic,
				ragg_data.speed
			]
		)

	if status_calindra_lbl != null and calindra_data != null:
		status_calindra_lbl.text = (
			"%s (Nv. %d)\nHP: %d\nMP: %d\nATK: %d\nDEF: %d\nMAG: %d\nSPD: %d"
			% [
				calindra_data.character_name,
				calindra_data.level,
				calindra_data.max_hp,
				calindra_data.max_mp,
				calindra_data.attack,
				calindra_data.defense,
				calindra_data.magic,
				calindra_data.speed
			]
		)

	if gold_label != null:
		gold_label.text = "Ouro: %d moedas" % InventoryManager.gold


func _refresh_items_tab() -> void:
	if item_vbox == null:
		return
	for c in item_vbox.get_children():
		c.queue_free()

	if InventoryManager.items.is_empty():
		var empty_lbl: Label = Label.new()
		empty_lbl.text = "Inventário vazio."
		empty_lbl.add_theme_font_size_override("font_size", 8)
		item_vbox.add_child(empty_lbl)
		return

	for item_id in InventoryManager.items.keys():
		var qty: int = InventoryManager.items[item_id]
		var item_res_path: String = "res://data/items/%s.tres" % item_id
		var item_name: String = item_id
		var is_usable: bool = false
		if ResourceLoader.exists(item_res_path):
			var item_data: ItemData = load(item_res_path) as ItemData
			item_name = item_data.item_name
			is_usable = item_data.is_usable_in_menu

		var row: HBoxContainer = HBoxContainer.new()
		var lbl: Label = Label.new()
		lbl.text = "%s x%d" % [item_name, qty]
		lbl.add_theme_font_size_override("font_size", 8)
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(lbl)

		if is_usable:
			var use_btn: Button = Button.new()
			use_btn.text = "Usar"
			use_btn.add_theme_font_size_override("font_size", 8)
			use_btn.pressed.connect(_on_use_item_in_menu.bind(item_id))
			row.add_child(use_btn)

		item_vbox.add_child(row)


func _on_use_item_in_menu(item_id: String) -> void:
	if item_id == "pocao_vida":
		InventoryManager.remove_item(item_id, 1)
		EventBus.item_removed.emit(item_id, 1)
	elif item_id == "pocao_mana":
		InventoryManager.remove_item(item_id, 1)
		EventBus.item_removed.emit(item_id, 1)
	_refresh_items_tab()


func _refresh_quests_tab() -> void:
	if quest_label == null:
		return

	var text_content: String = "MISSÕES ATIVAS:\n"
	if QuestManager.active_quests.is_empty():
		text_content += "Nenhuma missão ativa no momento.\n"
	else:
		for q_id in QuestManager.active_quests.keys():
			var stage_idx: int = QuestManager.active_quests[q_id]
			var q_res_path: String = "res://data/quests/%s.tres" % q_id
			if ResourceLoader.exists(q_res_path):
				var q_data: QuestData = load(q_res_path) as QuestData
				var stage_desc: String = (
					q_data.stages[stage_idx] if stage_idx < q_data.stages.size() else "Em progresso"
				)
				text_content += "• %s\n  Objetivo: %s\n\n" % [q_data.quest_name, stage_desc]

	if not QuestManager.completed_quests.is_empty():
		text_content += "\nCONCLUÍDAS:\n"
		for q_id in QuestManager.completed_quests:
			var q_res_path: String = "res://data/quests/%s.tres" % q_id
			if ResourceLoader.exists(q_res_path):
				var q_data: QuestData = load(q_res_path) as QuestData
				text_content += "✔ %s\n" % q_data.quest_name

	quest_label.text = text_content


func _on_save_pressed() -> void:
	var current_scene: String = (
		get_tree().current_scene.scene_file_path
		if get_tree().current_scene != null
		else "res://scenes/world/kakariko.tscn"
	)
	var success: bool = SaveManager.save_game(1, current_scene)
	if save_feedback != null:
		if success:
			save_feedback.text = "Jogo salvo com sucesso no Slot 1!"
			save_feedback.modulate = Color.LIGHT_GREEN
		else:
			save_feedback.text = "Erro ao salvar o jogo."
			save_feedback.modulate = Color.ORANGE_RED


func _on_quit_pressed() -> void:
	close_menu()
	SceneManager.change_scene("res://scenes/main/main.tscn")


func _on_lang_toggled() -> void:
	var next_locale: String = "en" if Localization.get_locale() == "pt_BR" else "pt_BR"
	Localization.set_locale(next_locale)
	if lang_btn != null:
		lang_btn.text = "PT-BR" if next_locale == "pt_BR" else "EN"
