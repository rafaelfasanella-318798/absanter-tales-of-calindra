class_name ShopMenu
extends CanvasLayer
## Shop interface for purchasing and selling consumables and equipment.

signal opened
signal closed
signal item_bought(item_id: String, cost: int)
signal item_sold(item_id: String, gain: int)

@export var shop_items: Array[String] = ["pocao_vida", "pocao_mana", "antidoto", "pena_fenix"]

var is_active: bool = false
var is_sell_mode: bool = false

@onready var root_panel: Control = $RootPanel
@onready var title_label: Label = $RootPanel/Header/TitleLabel
@onready var gold_label: Label = $RootPanel/Header/GoldLabel
@onready var mode_label: Label = $RootPanel/Header/ModeLabel
@onready var items_vbox: VBoxContainer = $RootPanel/ScrollContainer/ItemsVBox
@onready var feedback_label: Label = $RootPanel/FeedbackLabel
@onready var buy_mode_btn: Button = $RootPanel/Header/BuyModeBtn
@onready var sell_mode_btn: Button = $RootPanel/Header/SellModeBtn
@onready var close_btn: Button = $RootPanel/CloseBtn


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if root_panel != null:
		root_panel.visible = false

	if buy_mode_btn != null:
		buy_mode_btn.pressed.connect(_on_buy_mode_selected)
	if sell_mode_btn != null:
		sell_mode_btn.pressed.connect(_on_sell_mode_selected)
	if close_btn != null:
		close_btn.pressed.connect(close_shop)


func _unhandled_input(event: InputEvent) -> void:
	if is_active and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("menu")):
		close_shop()
		get_viewport().set_input_as_handled()


func open_shop() -> void:
	is_active = true
	is_sell_mode = false
	get_tree().paused = true
	if root_panel != null:
		root_panel.visible = true

	if feedback_label != null:
		feedback_label.text = "Bem-vindo! O que deseja comprar?"
		feedback_label.modulate = Color.WHITE

	_refresh()
	opened.emit()


func close_shop() -> void:
	is_active = false
	get_tree().paused = false
	if root_panel != null:
		root_panel.visible = false
	closed.emit()


func buy_item(item_id: String) -> bool:
	var item_path: String = "res://data/items/%s.tres" % item_id
	if not ResourceLoader.exists(item_path):
		return false
	var item_data: ItemData = load(item_path) as ItemData
	if item_data == null:
		return false

	if InventoryManager.remove_gold(item_data.price):
		InventoryManager.add_item(item_id, 1)
		item_bought.emit(item_id, item_data.price)
		AudioManager.play_sfx("item")
		_show_feedback("%s comprado!" % item_data.item_name, Color.LIGHT_GREEN)
		_refresh()
		return true

	_show_feedback("Ouro insuficiente!", Color.ORANGE_RED)
	return false


func sell_item(item_id: String) -> bool:
	if not InventoryManager.has_item(item_id, 1):
		return false

	var item_path: String = "res://data/items/%s.tres" % item_id
	var sell_price: int = 10
	var item_name: String = item_id
	if ResourceLoader.exists(item_path):
		var item_data: ItemData = load(item_path) as ItemData
		if item_data != null:
			sell_price = maxi(1, int(float(item_data.price) / 2.0))
			item_name = item_data.item_name

	if InventoryManager.remove_item(item_id, 1):
		InventoryManager.add_gold(sell_price)
		item_sold.emit(item_id, sell_price)
		AudioManager.play_sfx("item")
		_show_feedback("%s vendido por %d Ouro!" % [item_name, sell_price], Color.LIGHT_GREEN)
		_refresh()
		return true
	return false


func _refresh() -> void:
	if gold_label != null:
		gold_label.text = "Ouro: %d G" % InventoryManager.gold

	if mode_label != null:
		mode_label.text = "Modo: Venda" if is_sell_mode else "Modo: Compra"

	if items_vbox == null:
		return

	for c in items_vbox.get_children():
		c.queue_free()

	if is_sell_mode:
		_populate_sell_items()
	else:
		_populate_buy_items()


func _populate_buy_items() -> void:
	for item_id in shop_items:
		var item_path: String = "res://data/items/%s.tres" % item_id
		if not ResourceLoader.exists(item_path):
			continue
		var item_data: ItemData = load(item_path) as ItemData
		if item_data == null:
			continue

		var row: HBoxContainer = HBoxContainer.new()
		var lbl: Label = Label.new()
		lbl.text = "%s - %d G" % [item_data.item_name, item_data.price]
		lbl.add_theme_font_size_override("font_size", 8)
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(lbl)

		var btn: Button = Button.new()
		btn.text = "Comprar"
		btn.add_theme_font_size_override("font_size", 8)
		btn.pressed.connect(buy_item.bind(item_id))
		row.add_child(btn)

		items_vbox.add_child(row)


func _populate_sell_items() -> void:
	if InventoryManager.items.is_empty():
		var empty_lbl: Label = Label.new()
		empty_lbl.text = "Sem itens para vender."
		empty_lbl.add_theme_font_size_override("font_size", 8)
		items_vbox.add_child(empty_lbl)
		return

	for item_id in InventoryManager.items.keys():
		var qty: int = InventoryManager.items[item_id]
		var item_path: String = "res://data/items/%s.tres" % item_id
		var item_name: String = item_id
		var price: int = 10
		if ResourceLoader.exists(item_path):
			var item_data: ItemData = load(item_path) as ItemData
			if item_data != null:
				item_name = item_data.item_name
				price = maxi(1, int(float(item_data.price) / 2.0))

		var row: HBoxContainer = HBoxContainer.new()
		var lbl: Label = Label.new()
		lbl.text = "%s x%d (%d G)" % [item_name, qty, price]
		lbl.add_theme_font_size_override("font_size", 8)
		lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(lbl)

		var btn: Button = Button.new()
		btn.text = "Vender"
		btn.add_theme_font_size_override("font_size", 8)
		btn.pressed.connect(sell_item.bind(item_id))
		row.add_child(btn)

		items_vbox.add_child(row)


func _on_buy_mode_selected() -> void:
	is_sell_mode = false
	_show_feedback("Escolha um item para comprar.", Color.WHITE)
	_refresh()


func _on_sell_mode_selected() -> void:
	is_sell_mode = true
	_show_feedback("Escolha um item do inventário para vender.", Color.WHITE)
	_refresh()


func _show_feedback(msg: String, col: Color) -> void:
	if feedback_label != null:
		feedback_label.text = msg
		feedback_label.modulate = col
