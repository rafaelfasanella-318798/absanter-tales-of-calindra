class_name DebugConsoleUI
extends CanvasLayer
## In-game developer debug console for teleport, items, flags, and battles.

signal console_toggled(is_open: bool)
signal command_executed(command: String, output: String)

var is_open: bool = false
var history: Array[String] = []
var history_index: int = -1

var _max_history: int = 50
var _fps_overlay: Label = null

@onready var panel: Control = $Panel
@onready var output_label: RichTextLabel = $Panel/OutputLabel
@onready var line_edit: LineEdit = $Panel/LineEdit


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if panel != null:
		panel.visible = false
	if line_edit != null:
		line_edit.text_submitted.connect(_on_text_submitted)
	_setup_fps_overlay()


func _process(_delta: float) -> void:
	if _fps_overlay != null and _fps_overlay.visible:
		var fps: float = Performance.get_monitor(Performance.TIME_FPS)
		var draw_calls: float = Performance.get_monitor(
			Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME
		)
		var prims: float = Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
		_fps_overlay.text = (
			"FPS: %d | Draw: %d | Prims: %d" % [int(fps), int(draw_calls), int(prims)]
		)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("debug_console"):
		toggle_console()
		get_viewport().set_input_as_handled()
	elif is_open:
		if event.is_action_pressed("ui_cancel"):
			close_console()
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_up"):
			_navigate_history(-1)
			get_viewport().set_input_as_handled()
		elif event.is_action_pressed("ui_down"):
			_navigate_history(1)
			get_viewport().set_input_as_handled()


func toggle_console() -> void:
	if is_open:
		close_console()
	else:
		open_console()


func open_console() -> void:
	is_open = true
	if panel != null:
		panel.visible = true
	if line_edit != null:
		line_edit.clear()
		line_edit.grab_focus()
	console_toggled.emit(true)


func close_console() -> void:
	is_open = false
	if panel != null:
		panel.visible = false
	if line_edit != null:
		line_edit.release_focus()
	console_toggled.emit(false)


func execute_command(raw_text: String) -> String:
	var trimmed: String = raw_text.strip_edges()
	if trimmed.is_empty():
		return ""

	_add_to_history(trimmed)
	var tokens: PackedStringArray = trimmed.split(" ", false)
	var cmd: String = tokens[0].to_lower()
	var args: PackedStringArray = tokens.slice(1)
	var result: String = ""

	match cmd:
		"help":
			result = (
				"Comandos disponíveis:\n"
				+ "  help - Exibe esta ajuda\n"
				+ "  scenario [id] - Aplica ou lista cenários de debug\n"
				+ "  speed <x> - Altera velocidade do jogo (ex.: speed 2.0)\n"
				+ "  fps - Alterna overlay de desempenho (FPS, draw calls, prims)\n"
				+ "  encounter <normal|surprise|ambush> - Vantagem da próxima batalha\n"
				+ "  restart - Reinicia a cena atual\n"
				+ "  3d / battle3d / camp - Atalhos para cenas 3D\n"
				+ "  teleport <kakariko|house|cave|boss> - Muda de mapa\n"
				+ "  item <item_id> [qtd] - Adiciona item ao inventário\n"
				+ "  gold <qtd> - Adiciona ouro\n"
				+ "  quest <quest_id> <stage> - Altera estágio de quest\n"
				+ "  heal - Recupera vida e mana de todos\n"
				+ "  god - Alterna modo invulnerável\n"
				+ "  level [qtd] - Sobe nível da party\n"
				+ "  battle <inimigo> - Inicia combate imediato\n"
				+ "  flag <nome> <valor> - Define flag do GameState\n"
				+ "  clear - Limpa a tela do console\n"
				+ "  exit - Fecha o console"
			)
		"teleport", "tp":
			result = _cmd_teleport(args)
		"item", "give":
			result = _cmd_item(args)
		"gold":
			result = _cmd_gold(args)
		"quest":
			result = _cmd_quest(args)
		"heal":
			result = _cmd_heal()
		"god":
			result = _cmd_god()
		"level":
			result = _cmd_level(args)
		"battle":
			result = _cmd_battle(args)
		"flag":
			result = _cmd_flag(args)
		"scenario":
			result = _cmd_scenario(args)
		"speed":
			result = _cmd_speed(args)
		"fps":
			result = _cmd_fps()
		"encounter":
			result = _cmd_encounter(args)
		"restart":
			result = _cmd_restart()
		"3d", "kakariko3d":
			SceneManager.change_scene("res://scenes/world_3d/kakariko_3d.tscn")
			close_console()
			result = "Carregando Kakariko 3D..."
		"battle3d":
			SceneManager.change_scene("res://scenes/battle_3d/battle_3d.tscn")
			close_console()
			result = "Iniciando Batalha 3D Grandia..."
		"camp", "camp3d":
			SceneManager.change_scene("res://scenes/world_3d/camp_3d.tscn")
			close_console()
			result = "Abrindo Camp 3D (fogueira com Ragg e Calindra)..."
		"clear":
			if output_label != null:
				output_label.clear()
			return ""
		"exit", "close":
			close_console()
			return "Console fechado."
		_:
			result = "Comando desconhecido: '%s'. Digite 'help' para ajuda." % cmd

	_log(result)
	command_executed.emit(trimmed, result)
	return result


func _setup_fps_overlay() -> void:
	_fps_overlay = Label.new()
	_fps_overlay.name = "FPSOverlay"
	_fps_overlay.visible = false
	_fps_overlay.anchor_left = 1.0
	_fps_overlay.anchor_top = 0.0
	_fps_overlay.anchor_right = 1.0
	_fps_overlay.anchor_bottom = 0.0
	_fps_overlay.offset_left = -260.0
	_fps_overlay.offset_top = 8.0
	_fps_overlay.offset_right = -8.0
	_fps_overlay.offset_bottom = 28.0
	_fps_overlay.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_fps_overlay.add_theme_font_size_override("font_size", 11)
	_fps_overlay.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4, 0.9))
	_fps_overlay.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	_fps_overlay.add_theme_constant_override("shadow_offset_x", 1)
	_fps_overlay.add_theme_constant_override("shadow_offset_y", 1)
	add_child(_fps_overlay)


func _cmd_teleport(args: PackedStringArray) -> String:
	if args.is_empty():
		return "Uso: teleport <kakariko|house|cave|boss>"
	var dest: String = args[0].to_lower()
	var scene_path: String = ""
	match dest:
		"kakariko", "village":
			scene_path = "res://scenes/world/kakariko.tscn"
		"house":
			scene_path = "res://scenes/world/kakariko_house.tscn"
		"cave":
			scene_path = "res://scenes/world/kakariko_cave.tscn"
		"boss", "golem":
			scene_path = "res://scenes/world/kakariko_boss_room.tscn"
		_:
			return "Destino desconhecido: %s" % dest

	close_console()
	SceneManager.change_scene(scene_path)
	return "Teleportando para %s..." % dest


func _cmd_item(args: PackedStringArray) -> String:
	if args.is_empty():
		return "Uso: item <item_id> [qtd]"
	var item_id: String = args[0]
	var qty: int = 1
	if args.size() > 1 and args[1].is_valid_int():
		qty = args[1].to_int()
	InventoryManager.add_item(item_id, qty)
	return "Adicionado %dx '%s' ao inventário." % [qty, item_id]


func _cmd_gold(args: PackedStringArray) -> String:
	if args.is_empty():
		return "Ouro atual: %d G. Uso: gold <qtd>" % InventoryManager.gold
	var amount: int = args[0].to_int()
	InventoryManager.add_gold(amount)
	return "Ouro alterado. Total: %d G." % InventoryManager.gold


func _cmd_quest(args: PackedStringArray) -> String:
	if args.size() < 2:
		return "Uso: quest <quest_id> <stage_int>"
	var q_id: String = args[0]
	var stage: int = args[1].to_int()
	if not QuestManager.is_quest_active(q_id):
		QuestManager.start_quest(q_id)
	QuestManager.set_quest_stage(q_id, stage)
	return "Quest '%s' definida para o estágio %d." % [q_id, stage]


func _cmd_heal() -> String:
	GameState.set_flag("party_healed", true)
	return "Party totalmente curada!"


func _cmd_god() -> String:
	var current: bool = GameState.get_flag("god_mode", false)
	var new_val: bool = not current
	GameState.set_flag("god_mode", new_val)
	return "God mode: %s" % ("ATIVADO" if new_val else "DESATIVADO")


func _cmd_level(args: PackedStringArray) -> String:
	var amount: int = 1
	if not args.is_empty() and args[0].is_valid_int():
		amount = args[0].to_int()
	var ragg: CharacterData = load("res://data/characters/ragg.tres") as CharacterData
	var calindra: CharacterData = load("res://data/characters/calindra.tres") as CharacterData
	if ragg != null:
		ragg.level += amount
		ragg.max_hp += 15 * amount
		ragg.attack += 3 * amount
	if calindra != null:
		calindra.level += amount
		calindra.max_hp += 10 * amount
		calindra.magic += 4 * amount
	return "Party subiu %d nível(is)!" % amount


func _cmd_battle(args: PackedStringArray) -> String:
	var enemy_id: String = "slime"
	if not args.is_empty():
		enemy_id = args[0]
	close_console()
	SceneManager.start_battle([enemy_id])
	return "Iniciando batalha com [%s]..." % enemy_id


func _cmd_flag(args: PackedStringArray) -> String:
	if args.size() < 2:
		return "Uso: flag <nome> <valor>"
	var flag_name: String = args[0]
	var raw_val: String = args[1]
	var val: Variant = raw_val
	if raw_val.to_lower() == "true":
		val = true
	elif raw_val.to_lower() == "false":
		val = false
	elif raw_val.is_valid_int():
		val = raw_val.to_int()
	GameState.set_flag(flag_name, val)
	return "Flag '%s' = %s" % [flag_name, str(val)]


func _cmd_scenario(args: PackedStringArray) -> String:
	var boot_node: Node = get_node_or_null("/root/DebugBoot")
	if boot_node == null:
		return "DebugBoot não disponível."

	if args.is_empty():
		var scenarios: PackedStringArray = []
		if boot_node.has_method("get_available_scenarios"):
			scenarios = boot_node.get_available_scenarios()
		if scenarios.is_empty():
			return "Nenhum cenário encontrado em res://data/debug/scenarios/"
		var list_str: String = "Cenários disponíveis:\n"
		for s in scenarios:
			list_str += "  - %s\n" % s
		list_str += "Uso: scenario <id>"
		return list_str.strip_edges()

	var s_id: String = args[0]
	if boot_node.has_method("load_and_apply_scenario"):
		var success: bool = boot_node.load_and_apply_scenario(s_id, true)
		if success:
			close_console()
			return "Cenário '%s' aplicado com sucesso." % s_id
		return "Falha ao carregar cenário '%s'." % s_id
	return "DebugBoot não suporta load_and_apply_scenario."


func _cmd_speed(args: PackedStringArray) -> String:
	if args.is_empty():
		return "Velocidade atual: %.2fx. Uso: speed <fator>" % Engine.time_scale
	var s: float = args[0].to_float()
	if s <= 0.0:
		return "Fator de velocidade inválido: %s" % args[0]
	Engine.time_scale = s
	return "Velocidade do jogo definida para %.2fx." % s


func _cmd_fps() -> String:
	if _fps_overlay == null:
		_setup_fps_overlay()
	_fps_overlay.visible = not _fps_overlay.visible
	return "Overlay de desempenho: %s" % ("ATIVADO" if _fps_overlay.visible else "DESATIVADO")


func _cmd_encounter(args: PackedStringArray) -> String:
	if args.is_empty():
		return (
			"Vantagem atual: %s. Uso: encounter <normal|surprise|ambush>" % GameState.encounter_type
		)
	var enc: String = args[0].to_lower()
	if enc == "surpresa":
		enc = "surprise"
	elif enc == "emboscada":
		enc = "ambush"

	if enc in ["normal", "surprise", "ambush"]:
		GameState.encounter_type = enc
		return "Próximo encontro definido como '%s'." % enc
	return "Vantagem inválida: '%s'. Use normal, surprise ou ambush." % args[0]


func _cmd_restart() -> String:
	close_console()
	var current: Node = get_tree().current_scene
	if current != null and not current.scene_file_path.is_empty():
		if SceneManager != null:
			SceneManager.change_scene(current.scene_file_path)
		else:
			get_tree().change_scene_to_file(current.scene_file_path)
		return "Reiniciando cena '%s'..." % current.scene_file_path
	get_tree().reload_current_scene()
	return "Reiniciando cena atual..."


func _log(text: String) -> void:
	if output_label != null:
		output_label.append_text(text + "\n")


func _add_to_history(command: String) -> void:
	history.append(command)
	if history.size() > _max_history:
		history.pop_front()
	history_index = history.size()


func _navigate_history(direction: int) -> void:
	if history.is_empty():
		return
	history_index = clampi(history_index + direction, 0, history.size())
	if line_edit != null:
		if history_index < history.size():
			line_edit.text = history[history_index]
			line_edit.caret_column = line_edit.text.length()
		else:
			line_edit.clear()


func _on_text_submitted(new_text: String) -> void:
	execute_command(new_text)
	if line_edit != null:
		line_edit.clear()
