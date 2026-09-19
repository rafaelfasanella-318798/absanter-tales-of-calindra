class_name FloatingText
extends Node2D
## Visual pop-up text displaying damage numbers, healing, or status alerts in battle.

const FLOAT_DISTANCE: float = 24.0
const DURATION: float = 0.65

@onready var label: Label = $Label


func display(text_val: String, color: Color = Color.WHITE, is_critical: bool = false) -> void:
	if label != null:
		label.text = text_val
		label.modulate = color
		if is_critical:
			label.text = text_val + "!"
			scale = Vector2(1.3, 1.3)

	var tween: Tween = create_tween().set_parallel(true)
	(
		tween
		. tween_property(self, "position:y", position.y - FLOAT_DISTANCE, DURATION)
		. set_trans(Tween.TRANS_QUAD)
		. set_ease(Tween.EASE_OUT)
	)
	tween.tween_property(self, "modulate:a", 0.0, DURATION).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(queue_free)
