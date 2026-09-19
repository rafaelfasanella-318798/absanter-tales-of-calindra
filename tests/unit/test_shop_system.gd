extends GutTest

var _shop: ShopMenu


func before_each() -> void:
	InventoryManager.clear_inventory()
	_shop = preload("res://scenes/ui/shop_menu.tscn").instantiate() as ShopMenu
	add_child_autofree(_shop)


func test_shop_initial_state() -> void:
	assert_false(_shop.is_active)
	assert_false(_shop.root_panel.visible)


func test_shop_open_and_close() -> void:
	_shop.open_shop()
	assert_true(_shop.is_active)
	assert_true(_shop.root_panel.visible)

	_shop.close_shop()
	assert_false(_shop.is_active)
	assert_false(_shop.root_panel.visible)


func test_buy_item_success() -> void:
	InventoryManager.add_gold(100)
	var bought: bool = _shop.buy_item("pocao_vida")
	assert_true(bought)
	assert_eq(InventoryManager.get_item_count("pocao_vida"), 1)
	assert_eq(InventoryManager.gold, 75)


func test_buy_item_insufficient_gold() -> void:
	InventoryManager.add_gold(10)
	var bought: bool = _shop.buy_item("pocao_vida")
	assert_false(bought)
	assert_eq(InventoryManager.get_item_count("pocao_vida"), 0)
	assert_eq(InventoryManager.gold, 10)


func test_sell_item_success() -> void:
	InventoryManager.add_item("pocao_vida", 2)
	assert_eq(InventoryManager.gold, 0)

	var sold: bool = _shop.sell_item("pocao_vida")
	assert_true(sold)
	assert_eq(InventoryManager.get_item_count("pocao_vida"), 1)
	# pocao_vida price is 25, half rounded is 12
	assert_eq(InventoryManager.gold, 12)


func test_sell_item_not_in_inventory() -> void:
	var sold: bool = _shop.sell_item("pena_fenix")
	assert_false(sold)
	assert_eq(InventoryManager.gold, 0)
