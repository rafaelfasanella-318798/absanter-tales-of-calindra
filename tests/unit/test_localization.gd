extends GutTest

var _initial_locale: String = ""


func before_each() -> void:
	_initial_locale = Localization.get_locale()


func after_each() -> void:
	Localization.set_locale(_initial_locale)


func test_localization_translates_keys_pt_br() -> void:
	Localization.set_locale("pt_BR")
	assert_eq(Localization.translate_key("KEY_NEW_GAME"), "Novo Jogo")
	assert_eq(Localization.translate_key("KEY_ATTACK"), "Atacar")
	assert_eq(Localization.translate_key("KEY_SHOP"), "Loja")


func test_localization_translates_keys_en() -> void:
	Localization.set_locale("en")
	assert_eq(Localization.translate_key("KEY_NEW_GAME"), "New Game")
	assert_eq(Localization.translate_key("KEY_ATTACK"), "Attack")
	assert_eq(Localization.translate_key("KEY_SHOP"), "Shop")


func test_get_available_locales() -> void:
	var locales: Array[String] = Localization.get_available_locales()
	assert_true("pt_BR" in locales)
	assert_true("en" in locales)
