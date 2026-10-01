class_name CharacterModel3D
extends Node3D

## Componente para personagens 3D baseados em GLB (ex: KayKit Adventurers).
## Mapeia animações padrão do jogo para os nomes dos arquivos e aplica o shader toon.

const DEFAULT_ANIM_MAP: Dictionary = {
	"idle": "Idle",
	"walk": "Walking_A",
	"run": "Running_A",
	"attack_1": "1H_Melee_Attack_Chop",
	"attack_2": "1H_Melee_Attack_Slice_Horizontal",
	"cast": "Spellcasting",
	"hit": "Hit_A",
	"ko": "Death_A",
	"victory": "Cheer",
	"defend": "Block",
	"launch": "Jump_Start"
}

@export var anim_map: Dictionary = DEFAULT_ANIM_MAP.duplicate()
@export var toon_material: Material = preload("res://assets/materials/toon_character.tres")
@export var auto_apply_toon: bool = true

var anim_player: AnimationPlayer = null
var _current_anim: String = ""


func _ready() -> void:
	anim_player = _find_animation_player(self)
	if auto_apply_toon and toon_material != null:
		apply_toon_material(toon_material)
	if anim_player != null and anim_map.has("idle"):
		play("idle")


func play(
	anim_name: String, custom_blend: float = -1.0, custom_speed: float = 1.0, from_end: bool = false
) -> void:
	_current_anim = anim_name
	if anim_player == null:
		return

	var raw_name: String = anim_map.get(anim_name, anim_name)
	if not anim_player.has_animation(raw_name):
		return

	var anim: Animation = anim_player.get_animation(raw_name)
	if anim_name in ["idle", "walk", "run"]:
		anim.loop_mode = Animation.LOOP_LINEAR
	else:
		anim.loop_mode = Animation.LOOP_NONE

	anim_player.play(raw_name, custom_blend, custom_speed, from_end)


func stop() -> void:
	_current_anim = ""
	if anim_player != null:
		anim_player.stop()


func is_playing() -> bool:
	if anim_player != null:
		return anim_player.is_playing()
	return false


func get_current_animation() -> String:
	return _current_anim


func apply_toon_material(mat: Material = null) -> void:
	var target_mat: Material = mat if mat != null else toon_material
	if target_mat == null:
		return
	_apply_mat_recursive(self, target_mat)


func _apply_mat_recursive(node: Node, base_mat: Material) -> void:
	if node is MeshInstance3D:
		var mi: MeshInstance3D = node as MeshInstance3D
		var inst_mat: Material = base_mat.duplicate()
		var orig_mat: Material = mi.get_active_material(0)
		if orig_mat is StandardMaterial3D and orig_mat.albedo_texture != null:
			if inst_mat is ShaderMaterial:
				inst_mat.set_shader_parameter("albedo_texture", orig_mat.albedo_texture)
		mi.material_override = inst_mat

	for child in node.get_children():
		_apply_mat_recursive(child, base_mat)


func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var found: AnimationPlayer = _find_animation_player(child)
		if found != null:
			return found
	return null
