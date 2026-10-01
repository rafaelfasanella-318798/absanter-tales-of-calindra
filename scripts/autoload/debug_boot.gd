class_name DebugBootAutoload
extends Node
## Debug scenario boot loader: parses --scenario=<id> and sets game state.

signal scenario_applied(scenario_id: String)

const SCENARIOS_PATH: String = "res://data/debug/scenarios/"
const KNOWN_KEYS: Array[String] = [
	"id",
	"descricao",
	"scene",
	"party",
	"inventory",
	"gold",
	"flags",
	"battle",
	"time_scale",
]

var suppress_auto_boot: bool = false


func _ready() -> void:
	if not OS.is_debug_build() or suppress_auto_boot:
		return

	var scenario_to_load: String = _parse_scenario_arg()
	if not scenario_to_load.is_empty():
		call_deferred("_boot_scenario", scenario_to_load)


func get_available_scenarios() -> PackedStringArray:
	var result: PackedStringArray = []
	var dir: DirAccess = DirAccess.open(SCENARIOS_PATH)
	if dir != null:
		dir.list_dir_begin()
		var file_name: String = dir.get_next()
		while not file_name.is_empty():
			if not dir.current_is_dir() and file_name.ends_with(".json"):
				result.append(file_name.trim_suffix(".json"))
			file_name = dir.get_next()
		dir.list_dir_end()
	result.sort()
	return result


func load_scenario(scenario_id: String) -> Dictionary:
	var path: String = SCENARIOS_PATH + scenario_id + ".json"
	if not FileAccess.file_exists(path):
		push_warning("DebugBoot: Cenário '%s' não encontrado em '%s'" % [scenario_id, path])
		return {}

	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("DebugBoot: Falha ao abrir arquivo '%s'" % path)
		return {}

	var text: String = file.get_as_text()
	var json: Variant = JSON.parse_string(text)
	if not (json is Dictionary):
		push_warning("DebugBoot: JSON inválido em '%s'" % path)
		return {}

	return json as Dictionary


func load_and_apply_scenario(scenario_id: String, change_scene: bool = true) -> bool:
	var data: Dictionary = load_scenario(scenario_id)
	if data.is_empty():
		return false
	var success: bool = apply_scenario_dict(data, change_scene)
	if success:
		scenario_applied.emit(scenario_id)
	return success


func apply_scenario_dict(data: Dictionary, change_scene: bool = false) -> bool:
	if data.is_empty():
		return false

	# Avisa sobre campos desconhecidos
	for key in data.keys():
		if key not in KNOWN_KEYS:
			push_warning("DebugBoot: Campo desconhecido '%s' no cenário" % key)

	# 1. Gold
	if data.has("gold"):
		var gold_val: int = int(data["gold"])
		if InventoryManager != null:
			InventoryManager.gold = gold_val
			InventoryManager.currency_updated.emit(gold_val)

	# 2. Inventory
	if data.has("inventory") and (data["inventory"] is Dictionary):
		if InventoryManager != null:
			InventoryManager.items.clear()
			var inv_dict: Dictionary = data["inventory"]
			for item_id in inv_dict.keys():
				var count: int = int(inv_dict[item_id])
				InventoryManager.add_item(item_id, count)

	# 3. Flags
	if data.has("flags") and (data["flags"] is Dictionary):
		if GameState != null:
			var flags_dict: Dictionary = data["flags"]
			for flag_name in flags_dict.keys():
				GameState.set_flag(flag_name, flags_dict[flag_name])

	# 4. Battle context
	if data.has("battle") and (data["battle"] is Dictionary):
		var b_dict: Dictionary = data["battle"]
		if b_dict.has("advantage"):
			var adv: String = str(b_dict["advantage"]).to_lower()
			if adv == "surpresa":
				adv = "surprise"
			elif adv == "emboscada":
				adv = "ambush"

			if adv in ["normal", "surprise", "ambush"]:
				if GameState != null:
					GameState.encounter_type = adv
			else:
				push_warning("DebugBoot: Vantagem de batalha desconhecida '%s'" % adv)

		if b_dict.has("encounter_id"):
			push_warning(
				(
					"DebugBoot: battle.encounter_id '%s' ainda não suportado (chega na G2-05)"
					% b_dict["encounter_id"]
				)
			)

	# 5. Party (unsupported before G1-07)
	if data.has("party"):
		push_warning("DebugBoot: party state ainda não suportado (chega na G1-07)")

	# 6. Time scale
	if data.has("time_scale"):
		Engine.time_scale = float(data["time_scale"])

	# 7. Scene transition
	if change_scene and data.has("scene") and not str(data["scene"]).is_empty():
		var scene_path: String = str(data["scene"])
		if ResourceLoader.exists(scene_path):
			if SceneManager != null:
				SceneManager.change_scene(scene_path)
		else:
			push_warning("DebugBoot: Cena não encontrada: %s" % scene_path)

	return true


func _parse_scenario_arg() -> String:
	var user_args: PackedStringArray = OS.get_cmdline_user_args()
	for i in range(user_args.size()):
		var arg: String = user_args[i]
		if arg.begins_with("--scenario="):
			return arg.trim_prefix("--scenario=")
		if arg == "--scenario" and i + 1 < user_args.size():
			return user_args[i + 1]
	return ""


func _boot_scenario(scenario_id: String) -> void:
	load_and_apply_scenario(scenario_id, true)
