class_name PauseMenu
extends CanvasLayer
## In-game pause menu with Status, Inventory, Equipment, Quests, Save, and Options tabs.

signal opened
signal closed

@export var is_active: bool = false

var current_equip_char: String = "ragg"
var current_equip_slot: String = "weapon"

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

# Equipment UI references
@onready var char_btn_ragg: Button = (
	$RootPanel/TabContainer/Equipamento/VBox/CharRow/BtnRagg
	if has_node("RootPanel/TabContainer/Equipamento/VBox/CharRow/BtnRagg")
	else null
)
@onready var char_btn_calindra: Button = (
	$RootPanel/TabContainer/Equipamento/VBox/CharRow/BtnCalindra
	if has_node("RootPanel/TabContainer/Equipamento/VBox/CharRow/BtnCalindra")
	else null
)
@onready var weapon_slot_btn: Button = (
	$RootPanel/TabContainer/Equipamento/VBox/HBox/SlotsCol/WeaponRow/SlotBtn
	if has_node("RootPanel/TabContainer/Equipamento/VBox/HBox/SlotsCol/WeaponRow/SlotBtn")
	else null
)
@onready var weapon_unequip_btn: Button = (
	$RootPanel/TabContainer/Equipamento/VBox/HBox/SlotsCol/WeaponRow/UnequipBtn
	if has_node("RootPanel/TabContainer/Equipamento/VBox/HBox/SlotsCol/WeaponRow/UnequipBtn")
	else null
)
@onready var armor_slot_btn: Button = (
	$RootPanel/TabContainer/Equipamento/VBox/HBox/SlotsCol/ArmorRow/SlotBtn
	if has_node("RootPanel/TabContainer/Equipamento/VBox/HBox/SlotsCol/ArmorRow/SlotBtn")
	else null
)
@onready var armor_unequip_btn: Button = (
	$RootPanel/TabContainer/Equipamento/VBox/HBox/SlotsCol/ArmorRow/UnequipBtn
	if has_node("RootPanel/TabContainer/Equipamento/VBox/HBox/SlotsCol/ArmorRow/UnequipBtn")
	else null
)
@onready var accessory_slot_btn: Button = (
	$RootPanel/TabContainer/Equipamento/VBox/HBox/SlotsCol/AccessoryRow/SlotBtn
	if has_node("RootPanel/TabContainer/Equipamento/VBox/HBox/SlotsCol/AccessoryRow/SlotBtn")
	else null
)
@onready var accessory_unequip_btn: Button = (
	$RootPanel/TabContainer/Equipamento/VBox/HBox/SlotsCol/AccessoryRow/UnequipBtn
	if has_node("RootPanel/TabContainer/Equipamento/VBox/HBox/SlotsCol/AccessoryRow/UnequipBtn")
	else null
)
@onready var equip_items_vbox: VBoxContainer = (
	$RootPanel/TabContainer/Equipamento/VBox/HBox/ListCol/Scroll/ItemsVBox
	if has_node("RootPanel/TabContainer/Equipamento/VBox/HBox/ListCol/Scroll/ItemsVBox")
	else null
)
@onready var equip_preview_label: Label = (
	$RootPanel/TabContainer/Equipamento/VBox/PreviewLabel
	if has_node("RootPanel/TabContainer/Equipamento/VBox/PreviewLabel")
	else null
)


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

	# Equipment buttons connections
	if char_btn_ragg != null:
		char_btn_ragg.pressed.connect(_on_equip_char_selected.bind("ragg"))
	if char_btn_calindra != null:
		char_btn_calindra.pressed.connect(_on_equip_char_selected.bind("calindra"))
	if weapon_slot_btn != null:
		weapon_slot_btn.pressed.connect(_on_equip_slot_selected.bind("weapon"))
	if armor_slot_btn != null:
		armor_slot_btn.pressed.connect(_on_equip_slot_selected.bind("armor"))
	if accessory_slot_btn != null:
		accessory_slot_btn.pressed.connect(_on_equip_slot_selected.bind("accessory"))
	if weapon_unequip_btn != null:
		weapon_unequip_btn.pressed.connect(_on_unequip_pressed.bind("weapon"))
	if armor_unequip_btn != null:
		armor_unequip_btn.pressed.connect(_on_unequip_pressed.bind("armor"))
	if accessory_unequip_btn != null:
		accessory_unequip_btn.pressed.connect(_on_unequip_pressed.bind("accessory"))


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
	_refresh_equipment_tab()
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
		var ragg_stats: Dictionary = PartyManager.get_effective_stats("ragg", ragg_data)
		var b: Dictionary = ragg_stats["bonuses"]
		var atk_str: String = (
			"%d (+%d)" % [ragg_stats["attack"], b["attack"]]
			if b["attack"] > 0
			else str(ragg_stats["attack"])
		)
		var def_str: String = (
			"%d (+%d)" % [ragg_stats["defense"], b["defense"]]
			if b["defense"] > 0
			else str(ragg_stats["defense"])
		)
		status_ragg_lbl.text = (
			"%s (Nv. %d)\nHP: %d\nMP: %d\nATK: %s\nDEF: %s\nMAG: %d\nSPD: %d"
			% [
				ragg_data.character_name,
				ragg_data.level,
				ragg_stats["max_hp"],
				ragg_stats["max_mp"],
				atk_str,
				def_str,
				ragg_stats["magic"],
				ragg_stats["speed"]
			]
		)

	if status_calindra_lbl != null and calindra_data != null:
		var cal_stats: Dictionary = PartyManager.get_effective_stats("calindra", calindra_data)
		var b: Dictionary = cal_stats["bonuses"]
		var atk_str: String = (
			"%d (+%d)" % [cal_stats["attack"], b["attack"]]
			if b["attack"] > 0
			else str(cal_stats["attack"])
		)
		var def_str: String = (
			"%d (+%d)" % [cal_stats["defense"], b["defense"]]
			if b["defense"] > 0
			else str(cal_stats["defense"])
		)
		status_calindra_lbl.text = (
			"%s (Nv. %d)\nHP: %d\nMP: %d\nATK: %s\nDEF: %s\nMAG: %d\nSPD: %d"
			% [
				calindra_data.character_name,
				calindra_data.level,
				cal_stats["max_hp"],
				cal_stats["max_mp"],
				atk_str,
				def_str,
				cal_stats["magic"],
				cal_stats["speed"]
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


func _refresh_equipment_tab() -> void:
	if char_btn_ragg == null or char_btn_calindra == null:
		return

	char_btn_ragg.text = "> Ragg <" if current_equip_char == "ragg" else "Ragg"
	char_btn_calindra.text = "> Calindra <" if current_equip_char == "calindra" else "Calindra"

	var w_item: String = PartyManager.get_equipped_item(current_equip_char, "weapon")
	var a_item: String = PartyManager.get_equipped_item(current_equip_char, "armor")
	var acc_item: String = PartyManager.get_equipped_item(current_equip_char, "accessory")

	var w_name: String = _get_item_display_name(w_item)
	var a_name: String = _get_item_display_name(a_item)
	var acc_name: String = _get_item_display_name(acc_item)

	var w_prefix: String = "*" if current_equip_slot == "weapon" else ""
	var a_prefix: String = "*" if current_equip_slot == "armor" else ""
	var acc_prefix: String = "*" if current_equip_slot == "accessory" else ""

	if weapon_slot_btn != null:
		weapon_slot_btn.text = "%sArma: %s" % [w_prefix, w_name]
	if armor_slot_btn != null:
		armor_slot_btn.text = "%sArmadura: %s" % [a_prefix, a_name]
	if accessory_slot_btn != null:
		accessory_slot_btn.text = "%sAcessório: %s" % [acc_prefix, acc_name]

	_populate_equip_items_list()


func _get_item_display_name(item_id: String) -> String:
	if item_id.is_empty():
		return "(Vazio)"
	var path: String = "res://data/items/%s.tres" % item_id
	if ResourceLoader.exists(path):
		var item: ItemData = load(path) as ItemData
		if item != null and not item.item_name.is_empty():
			return item.item_name
	return item_id


func _populate_equip_items_list() -> void:
	if equip_items_vbox == null:
		return

	for c in equip_items_vbox.get_children():
		c.queue_free()

	var matching_items: Array[String] = []
	for item_id in InventoryManager.items.keys():
		var path: String = "res://data/items/%s.tres" % item_id
		if ResourceLoader.exists(path):
			var item: ItemData = load(path) as ItemData
			if item != null and item.equip_slot == current_equip_slot:
				if (
					item.allowed_characters.is_empty()
					or current_equip_char in item.allowed_characters
				):
					matching_items.append(item_id)

	if matching_items.is_empty():
		var empty_lbl: Label = Label.new()
		empty_lbl.text = "Nenhum item compatível no inventário."
		empty_lbl.add_theme_font_size_override("font_size", 8)
		empty_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		equip_items_vbox.add_child(empty_lbl)
		return

	var char_path: String = "res://data/characters/%s.tres" % current_equip_char
	var char_data: CharacterData = load(char_path) as CharacterData

	for item_id in matching_items:
		var path: String = "res://data/items/%s.tres" % item_id
		var item: ItemData = load(path) as ItemData
		var item_name: String = item.item_name if item != null else item_id
		var qty: int = InventoryManager.get_item_count(item_id)

		var row: HBoxContainer = HBoxContainer.new()
		var btn: Button = Button.new()
		btn.text = "%s (x%d)" % [item_name, qty]
		btn.add_theme_font_size_override("font_size", 8)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.pressed.connect(_on_equip_item_clicked.bind(item_id))
		btn.mouse_entered.connect(_on_item_hovered.bind(item_id, char_data))
		btn.focus_entered.connect(_on_item_hovered.bind(item_id, char_data))
		row.add_child(btn)
		equip_items_vbox.add_child(row)


func _on_item_hovered(item_id: String, char_data: CharacterData) -> void:
	if equip_preview_label == null or char_data == null:
		return
	var preview: Dictionary = PartyManager.preview_equipment_change(
		current_equip_char, char_data, item_id, current_equip_slot
	)
	var diff: Dictionary = preview["diff"]
	var item_path: String = "res://data/items/%s.tres" % item_id
	var item: ItemData = load(item_path) as ItemData
	var item_name: String = item.item_name if item != null else item_id

	var preview_str: String = "Comparação: %s\n" % item_name
	preview_str += (
		"ATK: %d -> %d (%+d) | DEF: %d -> %d (%+d)\n"
		% [
			preview["current_stats"]["attack"],
			preview["preview_stats"]["attack"],
			diff["attack"],
			preview["current_stats"]["defense"],
			preview["preview_stats"]["defense"],
			diff["defense"]
		]
	)
	preview_str += (
		"MAG: %d -> %d (%+d) | SPD: %d -> %d (%+d)\n"
		% [
			preview["current_stats"]["magic"],
			preview["preview_stats"]["magic"],
			diff["magic"],
			preview["current_stats"]["speed"],
			preview["preview_stats"]["speed"],
			diff["speed"]
		]
	)
	preview_str += "HP: %+d | MP: %+d" % [diff["hp"], diff["mp"]]
	equip_preview_label.text = preview_str


func _on_equip_item_clicked(item_id: String) -> void:
	var success: bool = PartyManager.equip(current_equip_char, item_id, true)
	if success:
		if equip_preview_label != null:
			var item_name: String = _get_item_display_name(item_id)
			equip_preview_label.text = "%s equipado com sucesso!" % item_name
		_refresh_equipment_tab()
		_refresh_status_tab()
		_refresh_items_tab()


func _on_unequip_pressed(slot: String) -> void:
	var success: bool = PartyManager.unequip(current_equip_char, slot, true)
	if success:
		if equip_preview_label != null:
			equip_preview_label.text = "Item do slot '%s' desequipado." % slot
		_refresh_equipment_tab()
		_refresh_status_tab()
		_refresh_items_tab()


func _on_equip_char_selected(char_id: String) -> void:
	current_equip_char = char_id
	if equip_preview_label != null:
		equip_preview_label.text = "Visualizando equipamento de %s." % char_id.capitalize()
	_refresh_equipment_tab()


func _on_equip_slot_selected(slot: String) -> void:
	current_equip_slot = slot
	if equip_preview_label != null:
		equip_preview_label.text = "Slot selecionado: %s." % slot.capitalize()
	_refresh_equipment_tab()


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
