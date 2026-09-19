class_name InventoryManagerAutoload
extends Node
## Manages player inventory, item stacking, and gold.

signal item_changed(item_id: String, count: int)
signal currency_updated(total: int)

var gold: int = 0
var items: Dictionary = {}


func add_item(item_id: String, amount: int = 1) -> void:
	items[item_id] = items.get(item_id, 0) + amount
	item_changed.emit(item_id, items[item_id])


func remove_item(item_id: String, amount: int = 1) -> bool:
	var current: int = items.get(item_id, 0)
	if current < amount:
		return false
	items[item_id] = current - amount
	if items[item_id] <= 0:
		items.erase(item_id)
	item_changed.emit(item_id, items.get(item_id, 0))
	return true


func add_gold(amount: int) -> void:
	gold += amount
	currency_updated.emit(gold)
