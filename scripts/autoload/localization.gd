class_name LocalizationAutoload
extends Node
## Manages game language settings and text localization.

signal locale_changed(locale: String)

const CSV_PATH: String = "res://data/localization/strings.csv"

var current_locale: String = "pt_BR"


func _ready() -> void:
	load_translations()


func load_translations() -> void:
	if not FileAccess.file_exists(CSV_PATH):
		return

	var file: FileAccess = FileAccess.open(CSV_PATH, FileAccess.READ)
	if file == null:
		return

	var pt_trans: Translation = Translation.new()
	pt_trans.locale = "pt_BR"
	var en_trans: Translation = Translation.new()
	en_trans.locale = "en"

	# Read header
	var headers: PackedStringArray = file.get_csv_line()

	while not file.eof_reached():
		var row: PackedStringArray = file.get_csv_line()
		if row.size() < 3 or row[0].is_empty():
			continue
		pt_trans.add_message(row[0], row[1])
		en_trans.add_message(row[0], row[2])

	file.close()

	TranslationServer.add_translation(pt_trans)
	TranslationServer.add_translation(en_trans)
	TranslationServer.set_locale(current_locale)


func set_locale(locale: String) -> void:
	current_locale = locale
	TranslationServer.set_locale(locale)
	locale_changed.emit(locale)


func get_locale() -> String:
	return current_locale


func get_available_locales() -> Array[String]:
	var locales: Array[String] = ["pt_BR", "en"]
	return locales


func translate_key(key: String) -> String:
	return tr(key)
