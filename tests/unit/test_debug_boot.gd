extends GutTest

const DebugBootScript = preload("res://scripts/autoload/debug_boot.gd")

var _debug_boot: Node


func before_each() -> void:
	_debug_boot = DebugBootScript.new()
	_debug_boot.suppress_auto_boot = true
	add_child_autofree(_debug_boot)
	InventoryManager.clear_inventory()
	GameState.flags.clear()
	GameState.encounter_type = "normal"
	Engine.time_scale = 1.0


func test_all_required_scenarios_exist_and_are_valid() -> void:
	var required_scenarios: Array[String] = [
		"kakariko_inicio",
		"batalha_normal",
		"batalha_surpresa",
		"batalha_emboscada",
		"chefe_golem_lv8",
		"camp_party_ferida",
	]

	var available: PackedStringArray = _debug_boot.get_available_scenarios()
	for req in required_scenarios:
		assert_true(
			req in available, "Cenário '%s' deve estar disponível na lista de cenários" % req
		)

		var data: Dictionary = _debug_boot.load_scenario(req)
		assert_false(data.is_empty(), "Cenário '%s' não deve estar vazio" % req)
		assert_eq(data.get("id"), req, "ID no JSON deve coincidir com o nome")
		assert_true(data.has("scene"), "Cenário '%s' deve definir 'scene'" % req)

		var scene_path: String = data.get("scene", "")
		assert_true(
			ResourceLoader.exists(scene_path),
			"Cena '%s' do cenário '%s' deve existir" % [scene_path, req]
		)


func test_apply_scenario_dict_sets_game_state() -> void:
	var scenario_data: Dictionary = {
		"id": "test_scenario",
		"descricao": "Teste de aplicação de cenário",
		"scene": "res://scenes/battle_3d/battle_3d.tscn",
		"gold": 350,
		"inventory":
		{
			"potion": 4,
			"ether": 2,
		},
		"flags":
		{
			"test_flag_a": true,
			"test_flag_num": 99,
		},
		"battle":
		{
			"advantage": "surprise",
		},
		"time_scale": 1.5,
	}

	var result: bool = _debug_boot.apply_scenario_dict(scenario_data, false)
	assert_true(result, "apply_scenario_dict deve retornar true")

	assert_eq(InventoryManager.gold, 350)
	assert_eq(InventoryManager.get_item_count("potion"), 4)
	assert_eq(InventoryManager.get_item_count("ether"), 2)
	assert_true(GameState.get_flag("test_flag_a"))
	assert_eq(GameState.get_flag("test_flag_num"), 99)
	assert_eq(GameState.encounter_type, "surprise")
	assert_almost_eq(Engine.time_scale, 1.5, 0.01)


func test_apply_scenario_with_unsupported_fields_does_not_crash() -> void:
	var scenario_data: Dictionary = {
		"id": "unsupported_fields_test",
		"party":
		{
			"ragg": {"level": 8},
			"calindra": {"level": 8, "hp_ratio": 0.5},
		},
		"battle":
		{
			"encounter_id": "kakariko_golem",
			"advantage": "ambush",
		},
		"unknown_field_xyz": 12345,
	}

	var result: bool = _debug_boot.apply_scenario_dict(scenario_data, false)
	assert_true(result, "Cenário com campos não suportados deve aplicar sem erro")
	assert_eq(GameState.encounter_type, "ambush")


func test_apply_empty_scenario_returns_false() -> void:
	var result: bool = _debug_boot.apply_scenario_dict({}, false)
	assert_false(result, "Dicionário vazio deve retornar false")


func test_load_non_existent_scenario_returns_empty() -> void:
	var data: Dictionary = _debug_boot.load_scenario("cenario_que_nao_existe")
	assert_true(data.is_empty())
