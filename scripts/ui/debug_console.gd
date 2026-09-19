class_name DebugConsoleUI
extends CanvasLayer
## In-game developer debug console for teleport, items, flags, and battles.

signal console_toggled(is_open: bool)
signal command_executed(command: String, output: String)

var is_open: bool = false
var history: Array[String] = []
var history_index: int = -1

var _max_history: int = 50

@onready var panel: Control = $Panel
@onready var output_label: RichTextLabel = $Panel/OutputLabel
@onready var line_edit: LineEdit = $Panel/LineEdit


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if panel != null:
		panel.visible = false
	if line_edit != null:
		line_edit.text_submitted.connect(_on_text_submitted)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_QUOTELEFT or event.keycode == KEY_F12:
			toggle_console()
			get_viewport().set_input_as_handled()
		elif is_open and event.keycode == KEY_ESCAPE:
			close_console()
			get_viewport().set_input_as_handled()
		elif is_open and event.keycode == KEY_UP:
			_navigate_history(-1)
			get_viewport().set_input_as_handled()
		elif is_open and event.keycode == KEY_DOWN:
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
