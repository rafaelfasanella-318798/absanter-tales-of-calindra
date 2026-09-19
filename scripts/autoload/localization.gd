class_name LocalizationAutoload
extends Node
## Manages game language settings and text localization.

signal locale_changed(locale: String)

var current_locale: String = "pt_BR"


func set_locale(locale: String) -> void:
	current_locale = locale
	TranslationServer.set_locale(locale)
	locale_changed.emit(locale)


func get_locale() -> String:
	return current_locale
