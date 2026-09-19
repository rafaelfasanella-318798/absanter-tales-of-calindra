class_name HUD
extends CanvasLayer
## Minimal HUD displaying location toast, gold count, and quick notifications.

@onready var location_label: Label = $LocationBanner/MarginContainer/LocationLabel
@onready var location_banner: PanelContainer = $LocationBanner
@onready var gold_label: Label = $TopRightPanel/MarginContainer/HBoxContainer/GoldLabel
@onready var notify_label: Label = $NotificationToast/MarginContainer/NotifyLabel
@onready var notify_panel: PanelContainer = $NotificationToast


func _ready() -> void:
	notify_panel.visible = false
	_update_gold(InventoryManager.gold)
	InventoryManager.currency_updated.connect(_update_gold)
	InventoryManager.item_changed.connect(_on_item_received)


func show_location(location_name: String) -> void:
	location_label.text = location_name
	location_banner.visible = true
	location_banner.modulate.a = 0.0
	var tween: Tween = create_tween()
	tween.tween_property(location_banner, "modulate:a", 1.0, 0.4)
	tween.tween_interval(2.0)
	tween.tween_property(location_banner, "modulate:a", 0.0, 0.6)
	await tween.finished
	location_banner.visible = false


func show_notification(message: String) -> void:
	notify_label.text = message
	notify_panel.visible = true
	notify_panel.modulate.a = 1.0
	var tween: Tween = create_tween()
	tween.tween_interval(2.5)
	tween.tween_property(notify_panel, "modulate:a", 0.0, 0.5)
	await tween.finished
	notify_panel.visible = false


func _update_gold(amount: int) -> void:
	gold_label.text = "%d G" % amount


func _on_item_received(item_id: String, _count: int) -> void:
	show_notification("Obtido: %s!" % item_id.replace("_", " ").capitalize())
