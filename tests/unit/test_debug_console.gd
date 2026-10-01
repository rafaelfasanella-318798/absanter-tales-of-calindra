extends GutTest

var _console: DebugConsoleUI


func before_each() -> void:
	_console = (preload("res://scenes/ui/debug_console.tscn").instantiate() as DebugConsoleUI)
	add_child_autofree(_console)
	InventoryManager.clear_inventory()
	GameState.flags.clear()
	GameState.encounter_type = "normal"
	Engine.time_scale = 1.0


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
	assert_true("scenario" in out)
	assert_true("speed" in out)
	assert_true("fps" in out)
	assert_true("encounter" in out)
	assert_true("restart" in out)
	assert_true("3d" in out)
	assert_true("battle3d" in out)
	assert_true("camp" in out)


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


func test_command_speed() -> void:
	var out: String = _console.execute_command("speed 2.5")
	assert_almost_eq(Engine.time_scale, 2.5, 0.01)
	assert_true("2.50x" in out)

	# Query without args
	var query: String = _console.execute_command("speed")
	assert_true("2.50x" in query)


func test_command_encounter() -> void:
	_console.execute_command("encounter surprise")
	assert_eq(GameState.encounter_type, "surprise")

	_console.execute_command("encounter ambush")
	assert_eq(GameState.encounter_type, "ambush")

	_console.execute_command("encounter surpresa")
	assert_eq(GameState.encounter_type, "surprise")

	_console.execute_command("encounter normal")
	assert_eq(GameState.encounter_type, "normal")


func test_command_fps() -> void:
	var out_on: String = _console.execute_command("fps")
	assert_true("ATIVADO" in out_on)
	assert_true(_console._fps_overlay.visible)

	var out_off: String = _console.execute_command("fps")
	assert_true("DESATIVADO" in out_off)
	assert_false(_console._fps_overlay.visible)


func test_command_scenario_list() -> void:
	var out: String = _console.execute_command("scenario")
	assert_true("Cenários disponíveis:" in out)
	assert_true("kakariko_inicio" in out)
	assert_true("batalha_normal" in out)
