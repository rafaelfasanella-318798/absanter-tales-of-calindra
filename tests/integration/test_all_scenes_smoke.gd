extends GutTest
## Smoke test que descobre e instancia todas as cenas .tscn do projeto (G0-04).

## Cenas a ignorar (com motivo)
const SKIP: Dictionary = {
# Exemplo: "res://scenes/temp/test.tscn": "Cena temporária de protótipo"
}


func test_all_scenes_instantiate_cleanly() -> void:
	var scenes: Array[String] = _discover_scenes("res://scenes")
	assert_gt(scenes.size(), 0, "Deve encontrar cenas em res://scenes")

	for scene_path in scenes:
		if SKIP.has(scene_path):
			gut.p("Pulando cena %s: %s" % [scene_path, SKIP[scene_path]])
			continue

		assert_true(
			ResourceLoader.exists(scene_path), "Arquivo de cena deve existir: %s" % scene_path
		)
		var packed: PackedScene = load(scene_path) as PackedScene
		assert_not_null(packed, "Falha ao carregar PackedScene: %s" % scene_path)
		if packed != null:
			var node: Node = packed.instantiate()
			assert_not_null(node, "Falha ao instanciar cena: %s" % scene_path)
			if node != null:
				node.free()


func _discover_scenes(path: String) -> Array[String]:
	var result: Array[String] = []
	var dir := DirAccess.open(path)
	if dir == null:
		return result

	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name != "." and file_name != "..":
			var full_path := path.path_join(file_name)
			if dir.current_is_dir():
				result.append_array(_discover_scenes(full_path))
			elif file_name.ends_with(".tscn"):
				result.append(full_path)
		file_name = dir.get_next()
	dir.list_dir_end()
	result.sort()
	return result
