extends GutTest

## Testes para assets toon, shader cel-shading, contorno e cena vitrine (G0-08).

const TOON_SHADER: Shader = preload("res://assets/shaders/toon.gdshader")
const OUTLINE_SHADER: Shader = preload("res://assets/shaders/outline.gdshader")


func test_shaders_load_successfully() -> void:
	assert_not_null(TOON_SHADER, "O shader toon.gdshader deve existir e carregar")
	assert_true(TOON_SHADER is Shader, "TOON_SHADER deve ser uma instância de Shader")

	assert_not_null(OUTLINE_SHADER, "O shader outline.gdshader deve existir e carregar")
	assert_true(OUTLINE_SHADER is Shader, "OUTLINE_SHADER deve ser uma instância de Shader")


func test_materials_load_and_have_outline_next_pass() -> void:
	var mat_paths: Array[String] = [
		"res://assets/materials/toon_character.tres",
		"res://assets/materials/toon_enemy.tres",
		"res://assets/materials/toon_environment.tres"
	]

	for path in mat_paths:
		var mat = load(path)
		assert_not_null(mat, "Material deve carregar: %s" % path)
		assert_true(mat is ShaderMaterial, "Material deve ser ShaderMaterial: %s" % path)
		assert_eq(mat.shader, TOON_SHADER, "Material deve usar toon.gdshader: %s" % path)

		assert_not_null(mat.next_pass, "Material deve possuir next_pass: %s" % path)
		assert_true(mat.next_pass is ShaderMaterial, "next_pass deve ser ShaderMaterial: %s" % path)
		assert_eq(mat.next_pass.shader, OUTLINE_SHADER, "next_pass usa outline: %s" % path)


func test_material_parameters_are_valid() -> void:
	var mat: ShaderMaterial = load("res://assets/materials/toon_character.tres")
	assert_not_null(mat)

	var bands = mat.get_shader_parameter("bands")
	assert_not_null(bands, "Parâmetro bands deve existir")
	assert_true(bands is int or bands is float)
	assert_gte(float(bands), 1.0)

	var softness = mat.get_shader_parameter("band_softness")
	assert_not_null(softness, "Parâmetro band_softness deve existir")

	var rim = mat.get_shader_parameter("rim_strength")
	assert_not_null(rim, "Parâmetro rim_strength deve existir")

	var outline_mat: ShaderMaterial = mat.next_pass as ShaderMaterial
	assert_not_null(outline_mat)
	var width = outline_mat.get_shader_parameter("outline_width")
	assert_not_null(width, "Parâmetro outline_width deve existir no outline_mat")
	assert_gt(float(width), 0.0)


func test_toon_showcase_instantiates_and_adjusts_parameters() -> void:
	var scene: PackedScene = load("res://scenes/dev/toon_showcase.tscn")
	assert_not_null(scene, "Cena toon_showcase.tscn deve carregar")

	var showcase: ToonShowcase = scene.instantiate() as ToonShowcase
	assert_not_null(showcase, "showcase deve ser ToonShowcase")
	add_child_autofree(showcase)

	assert_not_null(showcase.slider_bands, "slider_bands deve existir na vitrine")
	assert_not_null(showcase.slider_softness, "slider_softness deve existir na vitrine")
	assert_not_null(showcase.slider_rim, "slider_rim deve existir na vitrine")
	assert_not_null(showcase.slider_outline, "slider_outline deve existir na vitrine")
	assert_not_null(showcase.light_pivot, "light_pivot deve existir")

	# Testa ajuste de parâmetros
	showcase.set_bands(4)
	assert_eq(int(showcase.character_material.get_shader_parameter("bands")), 4)

	showcase.set_band_softness(0.12)
	var char_mat: ShaderMaterial = showcase.character_material
	var cur_soft: float = float(char_mat.get_shader_parameter("band_softness"))
	assert_almost_eq(cur_soft, 0.12, 0.001)

	showcase.set_rim_strength(0.55)
	var cur_rim: float = float(char_mat.get_shader_parameter("rim_strength"))
	assert_almost_eq(cur_rim, 0.55, 0.001)

	showcase.set_outline_width(0.035)
	var char_outline: ShaderMaterial = char_mat.next_pass as ShaderMaterial
	assert_not_null(char_outline)
	var cur_out: float = float(char_outline.get_shader_parameter("outline_width"))
	assert_almost_eq(cur_out, 0.035, 0.001)

	# Testa rotação de luz no _process
	var initial_rot_y: float = showcase.light_pivot.rotation.y
	showcase._process(0.1)
	assert_ne(showcase.light_pivot.rotation.y, initial_rot_y, "Luz deve girar no _process")
