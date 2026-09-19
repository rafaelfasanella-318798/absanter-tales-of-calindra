class_name MainScene
extends Control
## Entry scene for Absanter - Tales of Calindra.

const FONT_PATH: String = "res://assets/fonts/PixelOperator.ttf"

@onready var hello_label: Label = $CenterContainer/HelloLabel


func _ready() -> void:
	hello_label.text = "Hello Ragg"
	_apply_pixel_font()


func _apply_pixel_font() -> void:
	if FileAccess.file_exists(FONT_PATH):
		var font: FontFile = FontFile.new()
		var err: Error = font.load_dynamic_font(FONT_PATH)
		if err == OK:
			hello_label.add_theme_font_override("font", font)
			hello_label.add_theme_font_size_override("font_size", 16)
