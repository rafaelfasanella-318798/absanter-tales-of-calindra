extends GutTest
## Teste unitário para as configurações de projeto (project.godot) do pivô 3D (G0-03).


func test_rendering_method_is_compatibility() -> void:
	var method = ProjectSettings.get_setting("rendering/renderer/rendering_method")
	assert_eq(method, "gl_compatibility", "Renderer desktop deve ser gl_compatibility")
	var mobile_method = ProjectSettings.get_setting("rendering/renderer/rendering_method.mobile")
	assert_eq(mobile_method, "gl_compatibility", "Renderer mobile deve ser gl_compatibility")


func test_viewport_size_and_stretch() -> void:
	assert_eq(
		ProjectSettings.get_setting("display/window/size/viewport_width"),
		1280,
		"Largura base deve ser 1280"
	)
	assert_eq(
		ProjectSettings.get_setting("display/window/size/viewport_height"),
		720,
		"Altura base deve ser 720"
	)
	assert_eq(
		ProjectSettings.get_setting("display/window/stretch/mode"),
		"canvas_items",
		"Stretch mode deve ser canvas_items"
	)
	assert_eq(
		ProjectSettings.get_setting("display/window/stretch/aspect"),
		"expand",
		"Stretch aspect deve ser expand"
	)


func test_msaa_and_canvas_filter() -> void:
	assert_eq(
		ProjectSettings.get_setting("rendering/anti_aliasing/quality/msaa_3d"),
		1,
		"MSAA 3D deve ser 2x (valor 1)"
	)
	assert_eq(
		ProjectSettings.get_setting("rendering/textures/canvas_textures/default_texture_filter"),
		1,
		"Filtro de textura deve ser Linear (1)"
	)


func test_3d_physics_layer_names() -> void:
	var expected_layers: Dictionary = {
		"layer_names/3d_physics/layer_1": "world",
		"layer_names/3d_physics/layer_2": "player",
		"layer_names/3d_physics/layer_3": "party",
		"layer_names/3d_physics/layer_4": "enemy",
		"layer_names/3d_physics/layer_5": "interactable",
		"layer_names/3d_physics/layer_6": "trigger",
		"layer_names/3d_physics/layer_7": "camera_block",
	}
	for key in expected_layers:
		var val = ProjectSettings.get_setting(key)
		assert_eq(
			val, expected_layers[key], "Camada %s deve ser '%s'" % [key, expected_layers[key]]
		)


func test_input_map_actions_exist() -> void:
	var expected_actions: Array[String] = [
		"move_up",
		"move_down",
		"move_left",
		"move_right",
		"run",
		"interact",
		"cancel",
		"menu",
		"camera_rotate_left",
		"camera_rotate_right",
		"camera_orbit_left",
		"camera_orbit_right",
		"camera_orbit_up",
		"camera_orbit_down",
		"camera_orbit_hold",
		"camera_zoom_in",
		"camera_zoom_out",
		"camera_zoom_cycle",
		"debug_console",
	]
	for action in expected_actions:
		assert_true(InputMap.has_action(action), "InputMap deve conter a ação '%s'" % action)


func test_interact_action_does_not_contain_key_e() -> void:
	assert_true(InputMap.has_action("interact"), "InputMap deve ter 'interact'")
	var events: Array[InputEvent] = InputMap.action_get_events("interact")
	var has_key_e: bool = false
	for event in events:
		if event is InputEventKey:
			var key_ev: InputEventKey = event as InputEventKey
			if key_ev.keycode == KEY_E:
				has_key_e = true
				break
	assert_false(
		has_key_e, "Ação 'interact' NÃO deve conter KEY_E (reservado para rotação de câmera)"
	)
