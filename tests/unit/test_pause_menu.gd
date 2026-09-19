extends GutTest

var pause_menu_scene: PackedScene = preload("res://scenes/ui/pause_menu.tscn")
var _menu: PauseMenu


func before_each() -> void:
	InventoryManager.items.clear()
	InventoryManager.gold = 100
	QuestManager.active_quests.clear()
	QuestManager.completed_quests.clear()

	_menu = pause_menu_scene.instantiate() as PauseMenu
	add_child_autofree(_menu)


func test_menu_toggle_and_open_close() -> void:
	assert_false(_menu.is_active, "Menu should start inactive")

	_menu.open_menu()
	assert_true(_menu.is_active, "Menu should be active when opened")
	assert_true(get_tree().paused, "Tree should be paused when menu is open")

	_menu.close_menu()
	assert_false(_menu.is_active, "Menu should be inactive when closed")
	assert_false(get_tree().paused, "Tree should unpause when menu is closed")


func test_status_tab_shows_stats() -> void:
	_menu.open_menu()
	var ragg_lbl: Label = _menu.get_node_or_null("RootPanel/TabContainer/Status/HBox/RaggInfo")
	assert_not_null(ragg_lbl, "Ragg status label should exist")
	assert_true(ragg_lbl.text.contains("Ragg"), "Label should contain Ragg name")
	assert_true(ragg_lbl.text.contains("HP:"), "Label should contain HP stat")
	_menu.close_menu()


func test_item_tab_displays_and_uses_item() -> void:
	InventoryManager.add_item("pocao_vida", 2)
	_menu.open_menu()

	var item_vbox: VBoxContainer = _menu.get_node_or_null(
		"RootPanel/TabContainer/Itens/Scroll/VBox"
	)
	assert_not_null(item_vbox, "Item VBox should exist")
	assert_gt(item_vbox.get_child_count(), 0, "Item VBox should contain rows")

	_menu._on_use_item_in_menu("pocao_vida")
	assert_eq(
		InventoryManager.items.get("pocao_vida", 0),
		1,
		"Item count should decrement after menu usage"
	)
	_menu.close_menu()


func test_quest_tab_renders_active_quest() -> void:
	QuestManager.start_quest("quest_kakariko")
	QuestManager.set_quest_stage("quest_kakariko", 1)

	_menu.open_menu()
	var q_lbl: Label = _menu.get_node_or_null("RootPanel/TabContainer/Missoes/QuestLabel")
	assert_not_null(q_lbl, "Quest label should exist")
	assert_true(q_lbl.text.contains("O Mistério de Kakariko"), "Should display active quest name")
	_menu.close_menu()
