extends GutTest

## Testes para modelos CC0 de Ragg e Calindra e CharacterModel3D (G1-01).

const RAGG_MODEL_SCENE: PackedScene = preload("res://assets/models/characters/ragg/ragg_model.tscn")
const CALINDRA_MODEL_SCENE: PackedScene = preload(
	"res://assets/models/characters/calindra/calindra_model.tscn"
)
const PLAYER_SCENE: PackedScene = preload("res://scenes/world_3d/player_3d.tscn")
const FOLLOWER_SCENE: PackedScene = preload("res://scenes/world_3d/follower_3d.tscn")

const REQUIRED_ANIM_KEYS: Array[String] = [
	"idle",
	"walk",
	"run",
	"attack_1",
	"attack_2",
	"cast",
	"hit",
	"ko",
	"victory",
	"defend",
	"launch"
]


func test_party_character_data_has_valid_model_scene() -> void:
	var party_paths: Array[String] = [
		"res://data/characters/ragg.tres", "res://data/characters/calindra.tres"
	]

	for path in party_paths:
		var data: CharacterData = load(path) as CharacterData
		assert_not_null(data, "CharacterData deve existir: %s" % path)
		assert_not_null(data.model_scene, "model_scene deve estar configurado em %s" % path)
		assert_gt(data.ip_marker_color.a, 0.0, "ip_marker_color deve ser visível em %s" % path)

		var model: Node = data.model_scene.instantiate()
		assert_not_null(model, "model_scene deve instanciar: %s" % path)
		add_child_autofree(model)

		var char_model: CharacterModel3D = null
		if model is CharacterModel3D:
			char_model = model
		else:
			char_model = model.find_child("CharacterModel3D", true, false) as CharacterModel3D
			if char_model == null:
				for child in model.get_children():
					if child is CharacterModel3D:
						char_model = child
						break

		assert_not_null(char_model, "model_scene deve ser ou conter um CharacterModel3D: %s" % path)


func test_character_model_3d_standard_animation_keys() -> void:
	for key in REQUIRED_ANIM_KEYS:
		assert_true(
			CharacterModel3D.DEFAULT_ANIM_MAP.has(key),
			"DEFAULT_ANIM_MAP deve conter a chave padrão '%s'" % key
		)


func test_character_models_have_all_mapped_animations() -> void:
	var scenes: Array[PackedScene] = [RAGG_MODEL_SCENE, CALINDRA_MODEL_SCENE]

	for scene in scenes:
		var model: CharacterModel3D = scene.instantiate() as CharacterModel3D
		assert_not_null(model)
		add_child_autofree(model)

		assert_not_null(model.anim_player, "CharacterModel3D deve localizar o AnimationPlayer")
		for key in REQUIRED_ANIM_KEYS:
			var anim_file_name: String = model.anim_map.get(key, "")
			assert_ne(anim_file_name, "", "Mapeamento para '%s' não pode ser vazio" % key)
			assert_true(
				model.anim_player.has_animation(anim_file_name),
				(
					"AnimationPlayer deve conter a animação '%s' (mapeada de '%s')"
					% [anim_file_name, key]
				)
			)


func test_character_model_3d_play_and_loop_settings() -> void:
	var model: CharacterModel3D = RAGG_MODEL_SCENE.instantiate() as CharacterModel3D
	add_child_autofree(model)

	model.play("walk")
	assert_eq(model.get_current_animation(), "walk")
	assert_true(model.is_playing())

	var raw_walk: String = model.anim_map["walk"]
	var anim: Animation = model.anim_player.get_animation(raw_walk)
	assert_eq(anim.loop_mode, Animation.LOOP_LINEAR, "Locomoção deve ter LOOP_LINEAR")

	model.play("attack_1")
	assert_eq(model.get_current_animation(), "attack_1")
	var raw_attack: String = model.anim_map["attack_1"]
	var attack_anim: Animation = model.anim_player.get_animation(raw_attack)
	assert_eq(attack_anim.loop_mode, Animation.LOOP_NONE, "Ataque deve ter LOOP_NONE")

	model.stop()
	assert_false(model.is_playing())
	assert_eq(model.get_current_animation(), "")


func test_player_and_follower_instantiate_model() -> void:
	var player: Player3D = PLAYER_SCENE.instantiate() as Player3D
	add_child_autofree(player)

	assert_not_null(player.model_instance, "Player3D deve instanciar CharacterModel3D")
	assert_not_null(player.model_instance.anim_player)

	var follower: Follower3D = FOLLOWER_SCENE.instantiate() as Follower3D
	add_child_autofree(follower)

	assert_not_null(follower.model_instance, "Follower3D deve instanciar CharacterModel3D")
	assert_not_null(follower.model_instance.anim_player)
