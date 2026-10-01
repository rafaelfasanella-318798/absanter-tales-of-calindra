class_name ToonShowcase
extends Node3D

## Vitrine de validação do visual Toon (cel shading) e contorno.
## Permite ajustar bandas, suavidade, rim light e largura do contorno em tempo real.

const CHAR_MAT_PATH: String = "res://assets/materials/toon_character.tres"
const ENEMY_MAT_PATH: String = "res://assets/materials/toon_enemy.tres"
const ENV_MAT_PATH: String = "res://assets/materials/toon_environment.tres"

@export var character_material: ShaderMaterial = preload(CHAR_MAT_PATH)
@export var enemy_material: ShaderMaterial = preload(ENEMY_MAT_PATH)
@export var environment_material: ShaderMaterial = preload(ENV_MAT_PATH)

var light_rotating: bool = true
var light_rotation_speed: float = 25.0  # graus/seg

@onready var light_pivot: Node3D = $LightPivot
@onready var slider_bands: HSlider = $UI/Panel/VBox/BandsRow/SliderBands
@onready var slider_softness: HSlider = $UI/Panel/VBox/SoftnessRow/SliderSoftness
@onready var slider_rim: HSlider = $UI/Panel/VBox/RimRow/SliderRim
@onready var slider_outline: HSlider = $UI/Panel/VBox/OutlineRow/SliderOutline

@onready var val_bands: Label = $UI/Panel/VBox/BandsRow/ValBands
@onready var val_softness: Label = $UI/Panel/VBox/SoftnessRow/ValSoftness
@onready var val_rim: Label = $UI/Panel/VBox/RimRow/ValRim
@onready var val_outline: Label = $UI/Panel/VBox/OutlineRow/ValOutline
@onready var check_light_rotate: CheckBox = $UI/Panel/VBox/CheckLightRotate


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	_setup_signals()
	_load_initial_values()


func _process(delta: float) -> void:
	if light_rotating and light_pivot != null:
		light_pivot.rotate_y(deg_to_rad(light_rotation_speed) * delta)


func _setup_signals() -> void:
	if slider_bands != null:
		slider_bands.value_changed.connect(_on_bands_changed)
	if slider_softness != null:
		slider_softness.value_changed.connect(_on_softness_changed)
	if slider_rim != null:
		slider_rim.value_changed.connect(_on_rim_changed)
	if slider_outline != null:
		slider_outline.value_changed.connect(_on_outline_changed)
	if check_light_rotate != null:
		check_light_rotate.toggled.connect(func(toggled: bool) -> void: light_rotating = toggled)


func _load_initial_values() -> void:
	if character_material != null:
		var b: int = int(character_material.get_shader_parameter("bands"))
		var s: float = float(character_material.get_shader_parameter("band_softness"))
		var r: float = float(character_material.get_shader_parameter("rim_strength"))
		var o: float = 0.02
		if character_material.next_pass is ShaderMaterial:
			o = float(character_material.next_pass.get_shader_parameter("outline_width"))

		if slider_bands != null:
			slider_bands.value = b
			val_bands.text = str(b)
		if slider_softness != null:
			slider_softness.value = s
			val_softness.text = "%.2f" % s
		if slider_rim != null:
			slider_rim.value = r
			val_rim.text = "%.2f" % r
		if slider_outline != null:
			slider_outline.value = o
			val_outline.text = "%.3f" % o


func _on_bands_changed(value: float) -> void:
	var int_val: int = int(value)
	set_bands(int_val)


func _on_softness_changed(value: float) -> void:
	set_band_softness(value)


func _on_rim_changed(value: float) -> void:
	set_rim_strength(value)


func _on_outline_changed(value: float) -> void:
	set_outline_width(value)


func set_bands(value: int) -> void:
	if character_material != null:
		character_material.set_shader_parameter("bands", value)
	if enemy_material != null:
		enemy_material.set_shader_parameter("bands", value)
	if environment_material != null:
		environment_material.set_shader_parameter("bands", value)
	if val_bands != null:
		val_bands.text = str(value)


func set_band_softness(value: float) -> void:
	if character_material != null:
		character_material.set_shader_parameter("band_softness", value)
	if enemy_material != null:
		enemy_material.set_shader_parameter("band_softness", value)
	if environment_material != null:
		environment_material.set_shader_parameter("band_softness", value)
	if val_softness != null:
		val_softness.text = "%.2f" % value


func set_rim_strength(value: float) -> void:
	if character_material != null:
		character_material.set_shader_parameter("rim_strength", value)
	if enemy_material != null:
		enemy_material.set_shader_parameter("rim_strength", value)
	if environment_material != null:
		environment_material.set_shader_parameter("rim_strength", value)
	if val_rim != null:
		val_rim.text = "%.2f" % value


func set_outline_width(value: float) -> void:
	if character_material != null and character_material.next_pass is ShaderMaterial:
		character_material.next_pass.set_shader_parameter("outline_width", value)
	if enemy_material != null and enemy_material.next_pass is ShaderMaterial:
		enemy_material.next_pass.set_shader_parameter("outline_width", value)
	if environment_material != null and environment_material.next_pass is ShaderMaterial:
		environment_material.next_pass.set_shader_parameter("outline_width", value * 0.5)
	if val_outline != null:
		val_outline.text = "%.3f" % value
