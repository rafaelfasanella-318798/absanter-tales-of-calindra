extends GutTest


func before_each() -> void:
	InventoryManager.clear_inventory()
	PartyManager.active_members = ["ragg", "calindra"]
	PartyManager.reserve_members.clear()


func test_inventory_add_remove_item() -> void:
	InventoryManager.add_item("potion", 3)
	assert_eq(InventoryManager.get_item_count("potion"), 3)
	assert_true(InventoryManager.has_item("potion", 2))
	assert_false(InventoryManager.has_item("potion", 4))

	var removed: bool = InventoryManager.remove_item("potion", 2)
	assert_true(removed)
	assert_eq(InventoryManager.get_item_count("potion"), 1)

	var removed_too_many: bool = InventoryManager.remove_item("potion", 5)
	assert_false(removed_too_many)
	assert_eq(InventoryManager.get_item_count("potion"), 1)


func test_inventory_gold_management() -> void:
	InventoryManager.add_gold(100)
	assert_eq(InventoryManager.gold, 100)
	assert_true(InventoryManager.has_gold(50))
	assert_false(InventoryManager.has_gold(150))

	var spent: bool = InventoryManager.remove_gold(40)
	assert_true(spent)
	assert_eq(InventoryManager.gold, 60)

	var overspent: bool = InventoryManager.remove_gold(100)
	assert_false(overspent)
	assert_eq(InventoryManager.gold, 60)


func test_party_swap_and_formation() -> void:
	assert_eq(PartyManager.get_leader_id(), "ragg")
	PartyManager.swap_members(0, 1)
	assert_eq(PartyManager.get_leader_id(), "calindra")
	assert_eq(PartyManager.active_members, ["calindra", "ragg"])


func test_party_reserve_management() -> void:
	PartyManager.move_to_reserve("calindra")
	assert_eq(PartyManager.active_members, ["ragg"])
	assert_eq(PartyManager.reserve_members, ["calindra"])
	assert_true(PartyManager.is_in_party("calindra"))
	assert_false(PartyManager.is_active("calindra"))

	PartyManager.move_to_active("calindra")
	assert_true(PartyManager.is_active("calindra"))
	assert_eq(PartyManager.reserve_members.size(), 0)
