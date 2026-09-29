class_name Battle3D
extends Node3D
## Grandia III-style 3D turn-based combat.
## IP Timeline (0→1): WAIT → COM (0.75) → ACT (0.75→1.0) → Execute
## COMBO: 2 hits rápidos, empurra alvo -0.2 na IP e gera SP.
## CRITICAL: 1 hit forte; se alvo estiver em ACT → CANCEL (recuo -0.55 na IP).

signal battle_ended(victory: bool)

# ──────────────────────────────────────────────
# Constantes de balanceamento (estilo Grandia III)
# ──────────────────────────────────────────────
const IP_COM_THRESHOLD: float = 0.75      ## Ponto de Comando
const IP_ACT_THRESHOLD: float = 0.75      ## ACT começa no mesmo ponto (alias semântico)
const IP_SPEED_BASE: float = 0.035        ## Multiplicador de avanço de IP por speed
const IP_ACT_SPEEDUP: float = 1.5        ## Multiplicador na fase ACT (preparação)

# Reações da IP ao receber golpes
const IP_PUSH_COMBO: float = 0.20        ## Quanto COMBO empurra o alvo para trás na IP
const IP_PUSH_CRITICAL_HIT: float = 0.55 ## Quanto CRITICAL empurra o alvo no momento de CANCEL

# Multiplicadores de dano
const COMBO_HIT_1_MULT: float = 0.80    ## 1º golpe do COMBO
const COMBO_HIT_2_MULT: float = 0.65    ## 2º golpe do COMBO
const CRITICAL_MULT: float = 2.20       ## Golpe único de CRITICAL
const CRITICAL_CANCEL_BONUS: float = 1.45 ## Bônus de dano ao aplicar CANCEL
const SKILL_MULT: float = 1.80          ## Multiplicador de habilidade

const SP_GAIN_PER_COMBO: int = 8        ## SP ganho por COMBO completado

var combatants: Array[Dictionary] = []
var active_player_index: int = -1
var is_time_stopped: bool = false
var is_battle_over: bool = false

var default_camera_pos: Vector3 = Vector3(0, 4.5, 7.5)
var default_camera_look: Vector3 = Vector3(0, 0.5, 0)
var camera_shake_amount: float = 0.0

# ──────────────────────────────────────────────
# Nós da cena
# ──────────────────────────────────────────────
@onready var camera: Camera3D = $Camera3D
@onready var arena_floor: MeshInstance3D = $ArenaFloor
@onready var ip_gauge_bar: ProgressBar = $UI/IPGaugeContainer/IPProgressBar
@onready var ip_markers_container: Control = $UI/IPGaugeContainer/Markers
@onready var command_panel: Panel = $UI/CommandPanel
@onready var actor_name_label: Label = $UI/CommandPanel/VBox/ActorNameLabel
@onready var action_banner: Label = $UI/ActionBanner
@onready var cancel_banner: Label = $UI/CancelBanner
@onready var status_label: Label = $UI/StatusPanel/StatusLabel
@onready var victory_panel: Panel = $UI/VictoryPanel

@onready var btn_combo: Button = $UI/CommandPanel/VBox/BtnCombo
@onready var btn_critical: Button = $UI/CommandPanel/VBox/BtnCritical
@onready var btn_skill: Button = $UI/CommandPanel/VBox/BtnSkill
@onready var btn_defend: Button = $UI/CommandPanel/VBox/BtnDefend

@onready var target_panel: Panel = $UI/TargetPanel
@onready var target_vbox: VBoxContainer = $UI/TargetPanel/VBox

# Referências 3D dos combatentes
@onready var ragg_node: Node3D = $Combatants/Ragg3D
@onready var calindra_node: Node3D = $Combatants/Calindra3D
@onready var slime_node: Node3D = $Combatants/Slime3D
@onready var golem_node: Node3D = $Combatants/Golem3D


# ──────────────────────────────────────────────
# Inicialização
# ──────────────────────────────────────────────
func _ready() -> void:
	GameState.current_mode = "battle_3d"
	AudioManager.play_music("res://assets/audio/music/battle_theme.ogg", 0.3)

	_init_combatants()
	_setup_ui()
	_update_status_display()


func _init_combatants() -> void:
	combatants.clear()

	# 1. Ragg
	var ragg_stats: Dictionary = (
		PartyManager.get_effective_stats("ragg", load("res://data/characters/ragg.tres"))
		if PartyManager != null
		else {"max_hp": 120, "max_mp": 30, "attack": 24, "defense": 14, "speed": 12}
	)
	combatants.append({
		"id": "ragg",
		"name": "Ragg",
		"is_player": true,
		"hp": ragg_stats["max_hp"],
		"max_hp": ragg_stats["max_hp"],
		"mp": ragg_stats["max_mp"],
		"max_mp": ragg_stats["max_mp"],
		"sp": 0,
		"max_sp": 100,
		"attack": ragg_stats["attack"],
		"defense": ragg_stats["defense"],
		"magic": 5,
		"speed": 11.0,
		"ip": 0.1,
		"state": "wait",   # wait | command | act | executing
		"node": ragg_node,
		"home_pos": ragg_node.global_position if ragg_node else Vector3(-2, 0, 1.5),
		"marker_color": Color(0.2, 0.6, 1.0),
		"marker_symbol": "⚔",
	})

	# 2. Calindra
	var cal_stats: Dictionary = (
		PartyManager.get_effective_stats("calindra", load("res://data/characters/calindra.tres"))
		if PartyManager != null
		else {"max_hp": 90, "max_mp": 60, "attack": 10, "defense": 9, "speed": 14}
	)
	combatants.append({
		"id": "calindra",
		"name": "Calindra",
		"is_player": true,
		"hp": cal_stats["max_hp"],
		"max_hp": cal_stats["max_hp"],
		"mp": cal_stats["max_mp"],
		"max_mp": cal_stats["max_mp"],
		"sp": 0,
		"max_sp": 100,
		"attack": cal_stats["attack"],
		"defense": cal_stats["defense"],
		"magic": 18,
		"speed": 13.0,
		"ip": 0.25,
		"state": "wait",
		"node": calindra_node,
		"home_pos": calindra_node.global_position if calindra_node else Vector3(-3, 0, 0),
		"marker_color": Color(0.8, 0.4, 1.0),
		"marker_symbol": "✨",
	})

	# 3. Slime
	combatants.append({
		"id": "slime",
		"name": "Slime",
		"is_player": false,
		"hp": 45,
		"max_hp": 45,
		"mp": 10,
		"max_mp": 10,
		"sp": 0,
		"max_sp": 100,
		"attack": 12,
		"defense": 6,
		"magic": 4,
		"speed": 9.0,
		"ip": 0.05,
		"state": "wait",
		"node": slime_node,
		"home_pos": slime_node.global_position if slime_node else Vector3(2, 0, 1),
		"marker_color": Color(0.3, 0.9, 0.4),
		"marker_symbol": "👾",
		"is_airborne": false,
	})

	# 4. Golem Antigo
	combatants.append({
		"id": "golem",
		"name": "Golem Antigo",
		"is_player": false,
		"hp": 90,
		"max_hp": 90,
		"mp": 20,
		"max_mp": 20,
		"sp": 0,
		"max_sp": 100,
		"attack": 18,
		"defense": 12,
		"magic": 6,
		"speed": 7.5,
		"ip": 0.0,
		"state": "wait",
		"node": golem_node,
		"home_pos": golem_node.global_position if golem_node else Vector3(3, 0, -1),
		"marker_color": Color(0.9, 0.5, 0.2),
		"marker_symbol": "🗿",
		"is_airborne": false,
	})


func _setup_ui() -> void:
	if command_panel != null:
		command_panel.visible = false
	if target_panel != null:
		target_panel.visible = false
	if cancel_banner != null:
		cancel_banner.visible = false
	if action_banner != null:
		action_banner.text = "Início do Combate 3D · Grandia III IP Timeline Ativa!"
	if victory_panel != null:
		victory_panel.visible = false

	if btn_combo != null:
		btn_combo.pressed.connect(_on_combo_chosen)
	if btn_critical != null:
		btn_critical.pressed.connect(_on_critical_chosen)
	if btn_skill != null:
		btn_skill.pressed.connect(_on_skill_chosen)
	if btn_defend != null:
		btn_defend.pressed.connect(_on_defend_chosen)


# ──────────────────────────────────────────────
# Loop principal — IP Timeline
# ──────────────────────────────────────────────
func _process(delta: float) -> void:
	if is_battle_over:
		return

	_handle_camera(delta)

	if is_time_stopped:
		return

	# Avança a barra de IP de todos os combatentes vivos
	for i in range(combatants.size()):
		var c: Dictionary = combatants[i]
		if c["hp"] <= 0:
			continue

		var advance_rate: float = (c["speed"] * IP_SPEED_BASE) * delta

		if c["state"] == "wait":
			c["ip"] += advance_rate
			if c["ip"] >= IP_COM_THRESHOLD:
				c["ip"] = IP_COM_THRESHOLD
				c["state"] = "command"
				_on_combatant_reached_command(i)
		elif c["state"] == "act":
			c["ip"] += advance_rate * IP_ACT_SPEEDUP
			if c["ip"] >= 1.0:
				c["ip"] = 1.0
				c["state"] = "executing"
				_execute_combatant_action(i)

	_update_ip_markers()


# ──────────────────────────────────────────────
# Câmera dinâmica
# ──────────────────────────────────────────────
func _handle_camera(delta: float) -> void:
	if camera == null:
		return

	var shake_offset: Vector3 = Vector3.ZERO
	if camera_shake_amount > 0.01:
		shake_offset = Vector3(
			randf_range(-camera_shake_amount, camera_shake_amount),
			randf_range(-camera_shake_amount, camera_shake_amount),
			randf_range(-camera_shake_amount, camera_shake_amount)
		)
		camera_shake_amount = move_toward(camera_shake_amount, 0.0, delta * 3.0)

	camera.global_position = (
		camera.global_position.lerp(default_camera_pos, 4.0 * delta) + shake_offset
	)
	camera.look_at(default_camera_look, Vector3.UP)


# ──────────────────────────────────────────────
# Lógica de ponto COM atingido
# ──────────────────────────────────────────────
func _on_combatant_reached_command(idx: int) -> void:
	var c: Dictionary = combatants[idx]
	if c["is_player"]:
		is_time_stopped = true
		active_player_index = idx
		if command_panel != null:
			command_panel.visible = true
			if actor_name_label != null:
				actor_name_label.text = "— %s —" % c["name"]
			if action_banner != null:
				action_banner.text = "%s: escolha o comando!" % c["name"]
	else:
		# IA inimiga: escolhe CRITICAL com 30% de chance; COMBO caso contrário
		var living_players: Array[int] = _get_living_player_indices()
		if living_players.is_empty():
			return
		c["chosen_target"] = living_players.pick_random()
		c["chosen_action"] = "critical" if randf() < 0.3 else "combo"
		c["state"] = "act"
		if action_banner != null:
			var prep_type: String = "Critical" if c["chosen_action"] == "critical" else "Combo"
			action_banner.text = "⚠ %s prepara um %s!" % [c["name"], prep_type]


# ──────────────────────────────────────────────
# Botões do menu de comando
# ──────────────────────────────────────────────
func _on_combo_chosen() -> void:
	_open_target_selection("combo")


func _on_critical_chosen() -> void:
	_open_target_selection("critical")


func _on_skill_chosen() -> void:
	_open_target_selection("skill")


func _on_defend_chosen() -> void:
	var c: Dictionary = combatants[active_player_index]
	c["chosen_action"] = "defend"
	c["state"] = "act"
	if command_panel != null:
		command_panel.visible = false
	if target_panel != null:
		target_panel.visible = false
	is_time_stopped = false


func _open_target_selection(action_type: String) -> void:
	if command_panel != null:
		command_panel.visible = false
	if target_panel == null or target_vbox == null:
		return

	target_panel.visible = true
	for child in target_vbox.get_children():
		child.queue_free()

	for i in range(combatants.size()):
		var target: Dictionary = combatants[i]
		if not target["is_player"] and target["hp"] > 0:
			var btn: Button = Button.new()
			var airborne_tag: String = " [AR]" if target.get("is_airborne", false) else ""
			var act_tag: String = " ← ACT!" if target["state"] == "act" else ""
			btn.text = "%s (HP:%d/%d)%s%s" % [
				target["name"], target["hp"], target["max_hp"], airborne_tag, act_tag
			]
			btn.add_theme_font_size_override("font_size", 8)
			btn.pressed.connect(_on_target_selected.bind(action_type, i))
			target_vbox.add_child(btn)


func _on_target_selected(action_type: String, target_idx: int) -> void:
	var c: Dictionary = combatants[active_player_index]
	c["chosen_action"] = action_type
	c["chosen_target"] = target_idx
	c["state"] = "act"

	if target_panel != null:
		target_panel.visible = false
	is_time_stopped = false


# ──────────────────────────────────────────────
# Execução das ações — coração do Grandia III
# ──────────────────────────────────────────────
func _execute_combatant_action(idx: int) -> void:
	var attacker: Dictionary = combatants[idx]
	var target_idx: int = attacker.get("chosen_target", -1)
	var action: String = attacker.get("chosen_action", "combo")

	if action == "defend":
		attacker["state"] = "wait"
		attacker["ip"] = 0.0
		if action_banner != null:
			action_banner.text = "%s adota postura defensiva!" % attacker["name"]
		_update_status_display()
		_check_battle_end()
		return

	if target_idx < 0 or target_idx >= combatants.size():
		attacker["state"] = "wait"
		attacker["ip"] = 0.0
		return

	var target: Dictionary = combatants[target_idx]
	if target["hp"] <= 0:
		var alts: Array[int] = (
			_get_living_enemy_indices() if attacker["is_player"] else _get_living_player_indices()
		)
		if alts.is_empty():
			attacker["state"] = "wait"
			attacker["ip"] = 0.0
			return
		target_idx = alts[0]
		target = combatants[target_idx]

	match action:
		"combo":
			_resolve_combo(attacker, target)
		"critical":
			_resolve_critical(attacker, target)
		"skill":
			_resolve_skill(attacker, target)
		_:
			_resolve_combo(attacker, target)

	# Reseta o atacante na IP
	attacker["state"] = "wait"
	attacker["ip"] = 0.0
	_update_status_display()
	_check_battle_end()


# ──────────────────────────────────────────────
# COMBO: 2 golpes rápidos
# ──────────────────────────────────────────────
func _resolve_combo(attacker: Dictionary, target: Dictionary) -> void:
	var base: int = int(attacker["attack"] * 1.2 - target["defense"] * 0.4)
	var hit1: int = maxi(3, int(base * COMBO_HIT_1_MULT))
	var hit2: int = maxi(3, int(base * COMBO_HIT_2_MULT))

	# Aplica IP push independente da fase do alvo
	target["ip"] = maxf(0.0, target["ip"] - IP_PUSH_COMBO)
	if target["state"] == "act":
		target["state"] = "wait"

	target["hp"] = maxi(0, target["hp"] - hit1 - hit2)

	# Ganho de SP para a party player
	if attacker["is_player"]:
		attacker["sp"] = mini(attacker["max_sp"], attacker["sp"] + SP_GAIN_PER_COMBO)

	_show_damage_popup(target["node"], hit1, false, "1")
	_show_damage_popup_delayed(target["node"], hit2, false, "2", 0.25)

	if action_banner != null:
		action_banner.text = (
			"%s usou COMBO em %s: %d + %d = %d de dano! [IP ↓ %.0f%%]"
			% [attacker["name"], target["name"], hit1, hit2, hit1 + hit2, IP_PUSH_COMBO * 100]
		)

	_animate_combo_3d(attacker["node"], target["node"])

	if target["hp"] <= 0 and target["node"] != null:
		target["node"].visible = false


# ──────────────────────────────────────────────
# CRITICAL: 1 golpe forte · CANCEL se alvo em ACT
# ──────────────────────────────────────────────
func _resolve_critical(attacker: Dictionary, target: Dictionary) -> void:
	var is_cancel: bool = (target["state"] == "act")
	var mult: float = CRITICAL_MULT
	if is_cancel:
		mult *= CRITICAL_CANCEL_BONUS
		target["state"] = "wait"
		target["ip"] = maxf(0.0, target["ip"] - IP_PUSH_CRITICAL_HIT)
		_trigger_cancel_effect(target["name"])

	var base: int = int(attacker["attack"] * 1.6 - target["defense"] * 0.5)
	var damage: int = maxi(8, int(base * mult))
	target["hp"] = maxi(0, target["hp"] - damage)

	_show_damage_popup(target["node"], damage, is_cancel, "CRIT")

	if action_banner != null:
		var cancel_tag: String = " 💥 CANCEL BONUS!" if is_cancel else ""
		action_banner.text = (
			"%s usou CRITICAL em %s: %d de dano!%s" % [attacker["name"], target["name"], damage, cancel_tag]
		)

	_animate_attack_3d(attacker["node"], target["node"], is_cancel)

	if target["hp"] <= 0 and target["node"] != null:
		target["node"].visible = false


# ──────────────────────────────────────────────
# SKILL: habilidade mágica de área/única
# ──────────────────────────────────────────────
func _resolve_skill(attacker: Dictionary, target: Dictionary) -> void:
	var is_cancel: bool = (target["state"] == "act")
	if is_cancel:
		target["state"] = "wait"
		target["ip"] = maxf(0.0, target["ip"] - IP_PUSH_COMBO)
		_trigger_cancel_effect(target["name"])

	var base: int = int(attacker.get("magic", attacker["attack"]) * 1.5 - target["defense"] * 0.3)
	var damage: int = maxi(5, int(base * SKILL_MULT))
	target["hp"] = maxi(0, target["hp"] - damage)

	var skill_name: String = (
		"Impacto Sísmico" if attacker["id"] == "ragg" else "Chama Arcana"
	)
	_show_damage_popup(target["node"], damage, is_cancel, "SKILL")

	if action_banner != null:
		action_banner.text = (
			"%s usou %s em %s: %d de dano!" % [attacker["name"], skill_name, target["name"], damage]
		)

	_animate_attack_3d(attacker["node"], target["node"], is_cancel)

	if target["hp"] <= 0 and target["node"] != null:
		target["node"].visible = false


# ──────────────────────────────────────────────
# Animações 3D
# ──────────────────────────────────────────────
func _animate_attack_3d(attacker_node: Node3D, target_node: Node3D, is_cancel: bool) -> void:
	if attacker_node == null or target_node == null:
		return

	var orig_pos: Vector3 = attacker_node.global_position
	var target_pos: Vector3 = target_node.global_position

	default_camera_pos = target_pos + Vector3(0, 2.5, 4.0)
	default_camera_look = target_pos + Vector3(0, 0.5, 0)
	camera_shake_amount = 0.35 if is_cancel else 0.15

	var tween: Tween = create_tween()
	var charge_pos: Vector3 = target_pos + (orig_pos - target_pos).normalized() * 0.8
	tween.tween_property(attacker_node, "global_position", charge_pos, 0.18).set_trans(Tween.TRANS_QUAD)
	tween.tween_interval(0.20)
	tween.tween_property(attacker_node, "global_position", orig_pos, 0.22).set_trans(Tween.TRANS_QUAD)
	tween.finished.connect(func():
		default_camera_pos = Vector3(0, 4.5, 7.5)
		default_camera_look = Vector3(0, 0.5, 0)
	)


func _animate_combo_3d(attacker_node: Node3D, target_node: Node3D) -> void:
	## Dois avanços rápidos: hit 1 + recuo + hit 2 + recuo
	if attacker_node == null or target_node == null:
		return

	var orig_pos: Vector3 = attacker_node.global_position
	var target_pos: Vector3 = target_node.global_position
	var charge_pos: Vector3 = target_pos + (orig_pos - target_pos).normalized() * 0.9

	default_camera_pos = target_pos + Vector3(0, 2.0, 3.5)
	default_camera_look = target_pos + Vector3(0, 0.5, 0)
	camera_shake_amount = 0.12

	var tween: Tween = create_tween()
	# Hit 1
	tween.tween_property(attacker_node, "global_position", charge_pos, 0.12).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(attacker_node, "global_position", orig_pos, 0.12).set_trans(Tween.TRANS_QUAD)
	# Hit 2
	tween.tween_property(attacker_node, "global_position", charge_pos, 0.12).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(attacker_node, "global_position", orig_pos, 0.14).set_trans(Tween.TRANS_QUAD)

	tween.finished.connect(func():
		default_camera_pos = Vector3(0, 4.5, 7.5)
		default_camera_look = Vector3(0, 0.5, 0)
	)


func _trigger_cancel_effect(target_name: String) -> void:
	if cancel_banner != null:
		cancel_banner.text = "💥 CANCEL! Ataque de %s Interrompido! 💥" % target_name
		cancel_banner.visible = true
		camera_shake_amount = 0.45
		var t: Tween = create_tween()
		t.tween_interval(2.0)
		t.tween_property(cancel_banner, "visible", false, 0.0)


# ──────────────────────────────────────────────
# Popups de dano flutuante 3D
# ──────────────────────────────────────────────
func _show_damage_popup(target_node: Node3D, amount: int, is_cancel: bool, tag: String = "") -> void:
	if target_node == null:
		return
	var label: Label3D = Label3D.new()
	var tag_str: String = " [%s]" % tag if tag != "" else ""
	var cancel_str: String = " CANCEL!" if is_cancel else ""
	label.text = "-%d%s%s" % [amount, tag_str, cancel_str]
	label.font_size = 20
	label.pixel_size = 0.007
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	label.modulate = Color(1.0, 0.15, 0.1) if is_cancel else (
		Color(1.0, 0.85, 0.1) if tag == "CRIT" else Color(0.9, 0.95, 1.0)
	)
	label.outline_size = 4
	label.outline_modulate = Color(0, 0, 0, 1)
	target_node.add_child(label)
	label.global_position = target_node.global_position + Vector3(
		randf_range(-0.3, 0.3), 1.4, 0
	)

	var tween: Tween = create_tween()
	tween.tween_property(label, "global_position", label.global_position + Vector3(0, 0.9, 0), 0.85)
	tween.finished.connect(label.queue_free)


func _show_damage_popup_delayed(
	target_node: Node3D,
	amount: int,
	is_cancel: bool,
	tag: String,
	delay: float
) -> void:
	var timer: SceneTreeTimer = get_tree().create_timer(delay)
	timer.timeout.connect(func():
		_show_damage_popup(target_node, amount, is_cancel, tag)
	)


# ──────────────────────────────────────────────
# Barra de IP — marcadores com retrato/símbolo
# ──────────────────────────────────────────────
func _update_ip_markers() -> void:
	if ip_markers_container == null:
		return

	for child in ip_markers_container.get_children():
		child.queue_free()

	var bar_width: float = ip_markers_container.size.x
	if bar_width < 1.0:
		bar_width = 240.0  # fallback antes do primeiro frame

	for c in combatants:
		if c["hp"] <= 0:
			continue
		var marker: Label = Label.new()
		var state_tag: String = ""
		if c["state"] == "command":
			state_tag = "!"
		elif c["state"] == "act":
			state_tag = "▶"
		marker.text = "%s%s" % [c.get("marker_symbol", "◆"), state_tag]
		marker.add_theme_font_size_override("font_size", 9)
		marker.modulate = c["marker_color"]
		marker.tooltip_text = c["name"]
		# Clamp para que o marcador fique sempre dentro da barra
		var x_pos: float = clampf(c["ip"] * bar_width - 8.0, 0.0, bar_width - 16.0)
		marker.position = Vector2(x_pos, 0)
		ip_markers_container.add_child(marker)


# ──────────────────────────────────────────────
# Status panel (HP/MP/SP)
# ──────────────────────────────────────────────
func _update_status_display() -> void:
	if status_label == null:
		return
	var text: String = "PARTY:\n"
	for c in combatants:
		if c["is_player"]:
			text += "%s: %d/%d HP | %d/%d MP | SP:%d\n" % [
				c["name"], c["hp"], c["max_hp"], c["mp"], c["max_mp"], c.get("sp", 0)
			]
	text += "\nINIMIGOS:\n"
	for c in combatants:
		if not c["is_player"]:
			var status: String
			if c["hp"] <= 0:
				status = "DERROTADO"
			else:
				var state_tag: String = " [ACT!]" if c["state"] == "act" else ""
				status = "%d/%d HP%s" % [c["hp"], c["max_hp"], state_tag]
			text += "%s: %s\n" % [c["name"], status]
	status_label.text = text


# ──────────────────────────────────────────────
# Fim de batalha
# ──────────────────────────────────────────────
func _check_battle_end() -> void:
	var living_enemies: Array[int] = _get_living_enemy_indices()
	var living_players: Array[int] = _get_living_player_indices()

	if living_enemies.is_empty():
		is_battle_over = true
		_on_victory()
	elif living_players.is_empty():
		is_battle_over = true
		_on_defeat()


func _on_victory() -> void:
	if action_banner != null:
		action_banner.text = "★ VITÓRIA! Arena 3D Grandia III conquistada! ★"
	if victory_panel != null:
		victory_panel.visible = true
	var btn_leave: Button = $UI/VictoryPanel/VBox/BtnReturn
	if btn_leave != null and not btn_leave.pressed.is_connected(_on_return_to_kakariko):
		btn_leave.pressed.connect(_on_return_to_kakariko)


func _on_defeat() -> void:
	if action_banner != null:
		action_banner.text = "A party foi derrotada! Pressione ESC para tentar novamente."


func _on_return_to_kakariko() -> void:
	SceneManager.change_scene("res://scenes/world_3d/kakariko_3d.tscn")


# ──────────────────────────────────────────────
# Helpers de índices
# ──────────────────────────────────────────────
func _get_living_player_indices() -> Array[int]:
	var result: Array[int] = []
	for i in range(combatants.size()):
		if combatants[i]["is_player"] and combatants[i]["hp"] > 0:
			result.append(i)
	return result


func _get_living_enemy_indices() -> Array[int]:
	var result: Array[int] = []
	for i in range(combatants.size()):
		if not combatants[i]["is_player"] and combatants[i]["hp"] > 0:
			result.append(i)
	return result
