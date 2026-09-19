extends GutTest

var _console: DebugConsoleUI


func before_each() -> void:
	_console = preload("res://scenes/ui/debug_console.tscn").instantiate() as DebugConsoleUI
	add_child_autofree(_console)
	InventoryManager.clear_inventory()


func test_console_toggle() -> void:
	assert_false(_console.is_open)
	assert_false(_console.panel.visible)

	_console.toggle_console()
	assert_true(_console.is_open)
	assert_true(_console.panel.visible)

	_console.toggle_console()
	assert_false(_console.is_open)
	assert_false(_console.panel.visible)


func test_command_help() -> void:
	var out: String = _console.execute_command("help")
	assert_true("Comandos disponíveis:" in out)


func test_command_gold() -> void:
	assert_eq(InventoryManager.gold, 0)
	var out: String = _console.execute_command("gold 500")
	assert_eq(InventoryManager.gold, 500)
	assert_true("500 G" in out)


func test_command_item() -> void:
	assert_eq(InventoryManager.get_item_count("pocao_vida"), 0)
	_console.execute_command("item pocao_vida 3")
	assert_eq(InventoryManager.get_item_count("pocao_vida"), 3)


func test_command_god() -> void:
	GameState.set_flag("god_mode", false)
	_console.execute_command("god")
	assert_true(GameState.get_flag("god_mode"))
	_console.execute_command("god")
	assert_false(GameState.get_flag("god_mode"))


func test_command_flag() -> void:
	_console.execute_command("flag test_unlocked true")
	assert_true(GameState.get_flag("test_unlocked"))

	_console.execute_command("flag test_number 42")
	assert_eq(GameState.get_flag("test_number"), 42)


func test_command_heal() -> void:
	GameState.set_flag("party_healed", false)
	var out: String = _console.execute_command("heal")
	assert_true(GameState.get_flag("party_healed"))
	assert_true("Party totalmente curada!" in out)
