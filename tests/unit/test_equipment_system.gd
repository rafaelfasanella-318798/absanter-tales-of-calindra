extends GutTest

const BATTLER_SCENE: PackedScene = preload("res://scenes/battle/battler.tscn")

var ragg_data: CharacterData
var calindra_data: CharacterData


func before_each() -> void:
	InventoryManager.clear_inventory()
	PartyManager.reset_party()
	ragg_data = load("res://data/characters/ragg.tres") as CharacterData
	calindra_data = load("res://data/characters/calindra.tres") as CharacterData


func after_each() -> void:
	if SaveManager.has_save(99):
		SaveManager.delete_save(99)


func test_initial_equipment_is_empty() -> void:
	assert_eq(PartyManager.get_equipped_item("ragg", "weapon"), "")
	assert_eq(PartyManager.get_equipped_item("ragg", "armor"), "")
	assert_eq(PartyManager.get_equipped_item("ragg", "accessory"), "")
	var bonuses: Dictionary = PartyManager.get_equipment_bonuses("ragg")
	assert_eq(bonuses["attack"], 0)
	assert_eq(bonuses["defense"], 0)


func test_equip_weapon_and_effective_stats() -> void:
	InventoryManager.add_item("espada_ferro", 1)
	assert_eq(InventoryManager.get_item_count("espada_ferro"), 1)

	var success: bool = PartyManager.equip("ragg", "espada_ferro", true)
	assert_true(success, "Ragg should successfully equip espada_ferro")
	assert_eq(
		InventoryManager.get_item_count("espada_ferro"), 0, "Item should be removed from inventory"
	)
	assert_eq(PartyManager.get_equipped_item("ragg", "weapon"), "espada_ferro")

	var bonuses: Dictionary = PartyManager.get_equipment_bonuses("ragg")
	assert_eq(bonuses["attack"], 5, "Espada de Ferro grants +5 ATK")

	var effective: Dictionary = PartyManager.get_effective_stats("ragg", ragg_data)
	assert_eq(effective["attack"], ragg_data.attack + 5)


func test_character_restriction_allowed_characters() -> void:
	InventoryManager.add_item("cajado_carvalho", 1)
	InventoryManager.add_item("kakariko_blade", 1)

	# cajado_carvalho is for calindra only
	assert_false(PartyManager.can_equip("ragg", "cajado_carvalho"))
	assert_true(PartyManager.can_equip("calindra", "cajado_carvalho"))

	# kakariko_blade is for ragg only
	assert_true(PartyManager.can_equip("ragg", "kakariko_blade"))
	assert_false(PartyManager.can_equip("calindra", "kakariko_blade"))


func test_equipment_swap_returns_old_to_inventory() -> void:
	InventoryManager.add_item("espada_ferro", 1)
	InventoryManager.add_item("kakariko_blade", 1)

	PartyManager.equip("ragg", "espada_ferro", true)
	assert_eq(PartyManager.get_equipped_item("ragg", "weapon"), "espada_ferro")
	assert_eq(InventoryManager.get_item_count("espada_ferro"), 0)

	# Equip kakariko_blade in the same slot
	PartyManager.equip("ragg", "kakariko_blade", true)
	assert_eq(PartyManager.get_equipped_item("ragg", "weapon"), "kakariko_blade")
	assert_eq(
		InventoryManager.get_item_count("espada_ferro"), 1, "Old weapon returned to inventory"
	)
	assert_eq(InventoryManager.get_item_count("kakariko_blade"), 0)

	var bonuses: Dictionary = PartyManager.get_equipment_bonuses("ragg")
	assert_eq(bonuses["attack"], 8, "Kakariko Blade gives +8 ATK")


func test_unequip_item() -> void:
	InventoryManager.add_item("armadura_couro", 1)
	PartyManager.equip("ragg", "armadura_couro", true)
	assert_eq(PartyManager.get_equipped_item("ragg", "armor"), "armadura_couro")

	var unequipped: bool = PartyManager.unequip("ragg", "armor", true)
	assert_true(unequipped)
	assert_eq(PartyManager.get_equipped_item("ragg", "armor"), "")
	assert_eq(InventoryManager.get_item_count("armadura_couro"), 1)

	var bonuses: Dictionary = PartyManager.get_equipment_bonuses("ragg")
	assert_eq(bonuses["defense"], 0)


func test_preview_equipment_change() -> void:
	var preview: Dictionary = PartyManager.preview_equipment_change(
		"ragg", ragg_data, "kakariko_blade", "weapon"
	)
	var diff: Dictionary = preview["diff"]
	assert_eq(diff["attack"], 8)
	assert_eq(preview["preview_stats"]["attack"], preview["current_stats"]["attack"] + 8)


func test_battler_receives_equipment_bonuses() -> void:
	InventoryManager.add_item("armadura_couro", 1)
	PartyManager.equip("ragg", "armadura_couro", true)

	var battler: Battler = BATTLER_SCENE.instantiate() as Battler
	add_child_autofree(battler)

	battler.setup_from_character_data(ragg_data)

	# armadura_couro gives +6 DEF and +15 HP
	assert_eq(battler.defense, ragg_data.defense + 6)
	assert_eq(battler.max_hp, ragg_data.max_hp + 15)


func test_save_load_preserves_equipment() -> void:
	InventoryManager.add_item("espada_ferro", 1)
	PartyManager.equip("ragg", "espada_ferro", true)

	var saved: bool = SaveManager.save_game(99)
	assert_true(saved, "Game should save successfully")

	PartyManager.reset_party()
	assert_eq(PartyManager.get_equipped_item("ragg", "weapon"), "")

	var loaded: bool = SaveManager.load_game(99)
	assert_true(loaded, "Game should load successfully")
	assert_eq(PartyManager.get_equipped_item("ragg", "weapon"), "espada_ferro")
