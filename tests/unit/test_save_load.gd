extends GutTest

const TEST_SLOT: int = 99


func before_each() -> void:
	SaveManager.delete_save(TEST_SLOT)
	GameState.flags.clear()
	InventoryManager.items.clear()
	InventoryManager.gold = 0


func after_each() -> void:
	SaveManager.delete_save(TEST_SLOT)


func test_save_and_load_roundtrip() -> void:
	# Set test data
	GameState.set_flag("mimic_defeated", true)
	GameState.set_flag("talked_to_tav", true)
	InventoryManager.add_item("lamina_kakariko", 1)
	InventoryManager.add_gold(150)

	var save_success: bool = SaveManager.save_game(
		TEST_SLOT, "res://scenes/world/kakariko.tscn", Vector2(120, 80)
	)
	assert_true(save_success, "Save should write to disk successfully")
	assert_true(SaveManager.has_save(TEST_SLOT), "Save file should exist on disk")

	# Clear runtime state
	GameState.flags.clear()
	InventoryManager.items.clear()
	InventoryManager.gold = 0

	assert_false(GameState.get_flag("mimic_defeated", false), "Flag should be cleared")
	assert_eq(InventoryManager.gold, 0, "Gold should be cleared")

	# Load back
	var load_success: bool = SaveManager.load_game(TEST_SLOT)
	assert_true(load_success, "Save should load successfully")

	# Verify restored state
	assert_true(
		GameState.get_flag("mimic_defeated", false), "mimic_defeated flag should be restored"
	)
	assert_true(GameState.get_flag("talked_to_tav", false), "talked_to_tav flag should be restored")
	assert_eq(
		InventoryManager.items.get("lamina_kakariko", 0), 1, "Inventory item should be restored"
	)
	assert_eq(InventoryManager.gold, 150, "Gold amount should be restored")
