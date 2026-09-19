class_name MainScene
extends Control
## Entry scene for Absanter - Tales of Calindra.

const FONT_PATH: String = "res://assets/fonts/PixelOperator.ttf"
const STARTING_WORLD_SCENE: String = "res://scenes/world/kakariko.tscn"

@onready var hello_label: Label = $CenterContainer/HelloLabel


func _ready() -> void:
	hello_label.text = (
		"Absanter – Tales of Calindra\n"
		+ "[ Hello Ragg ]\n\n"
		+ "Pressione [E / Espaço] para Iniciar"
	)
	_apply_pixel_font()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") or event.is_action_pressed("ui_accept"):
		get_viewport().set_input_as_handled()
		SceneManager.change_scene(STARTING_WORLD_SCENE)


func _apply_pixel_font() -> void:
	if FileAccess.file_exists(FONT_PATH):
		var font: FontFile = FontFile.new()
		var err: Error = font.load_dynamic_font(FONT_PATH)
		if err == OK:
			hello_label.add_theme_font_override("font", font)
			hello_label.add_theme_font_size_override("font_size", 14)
