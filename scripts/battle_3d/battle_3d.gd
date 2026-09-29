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

# Aerial Launch & Aerial Combo (mecânica icônica do Grandia III)
const SP_COST_AERIAL: int = 30          ## Custo de SP para o parceiro realizar o Aerial Combo
const AERIAL_LAUNCH_HEIGHT: float = 2.5 ## Altura do arremesso aéreo em unidades 3D
const AERIAL_COMBO_HITS: int = 3        ## Número de golpes do Aerial Combo
const AERIAL_HIT_MULT: float = 0.90     ## Multiplicador de dano por golpe aéreo (acumula)
const AERIAL_SMASH_MULT: float = 2.20   ## Multiplicador do golpe de finalização no solo
const IP_PUSH_AERIAL_SMASH: float = 0.70 ## Recuo extra na IP após queda no solo

# Evasão tática (Evade / Move)
const IP_COST_EVADE: float = 0.15       ## Custo de IP que a evasão retira do personagem (recua na timeline)
const EVADE_RADIUS: float = 2.5         ## Raio máximo de reposicionamento na arena



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
@onready var btn_evade: Button = $UI/CommandPanel/VBox/BtnEvade

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
	_apply_encounter_type(GameState.encounter_type)
	_setup_ui()
	_update_status_display()


func _apply_encounter_type(enc_type: String) -> void:
	## Ajusta a IP inicial dos combatentes de acordo com o tipo de encontro.
	## Surprise Attack (player atacou pelas costas): party começa com IP alta.
	## Ambush (inimigo veio pelas costas): inimigos começam com IP alta.
	match enc_type:
		"surprise":
			# Party começa perto do ponto COM — pode agir quase imediatamente
			for c in combatants:
				if c["is_player"]:
					c["ip"] = 0.70
			if action_banner != null:
				action_banner.text = "★ SURPRISE ATTACK! Party age primeiro! ★"
		"ambush":
			# Inimigos começam quase no ponto ACT — agem antes
			for c in combatants:
				if not c["is_player"]:
					c["ip"] = 0.72
			if action_banner != null:
				action_banner.text = "⚠ AMBUSH! Inimigos agem primeiro! ⚠"
		_:
			pass  # Normal: IPs definidas em _init_combatants

	# Reseta o encounter_type para normal após usar
	GameState.encounter_type = "normal"


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

	# 3. Slime — carregado a partir do EnemyData resource
	var slime_data: EnemyData = _load_enemy_data("res://data/enemies/slime.tres")
	combatants.append(
		_enemy_data_to_dict(
			slime_data if slime_data else null,
			"slime",
			"Slime",
			slime_node,
			slime_node.global_position if slime_node else Vector3(2, 0, 1),
			Color(0.3, 0.9, 0.4),
			"👾",
			0.05
		)
	)

	# 4. Golem Antigo — carregado a partir do EnemyData resource
	var golem_data: EnemyData = _load_enemy_data("res://data/enemies/kakariko_golem.tres")
	combatants.append(
		_enemy_data_to_dict(
			golem_data if golem_data else null,
			"golem",
			"Golem Antigo",
			golem_node,
			golem_node.global_position if golem_node else Vector3(3, 0, -1),
			Color(0.9, 0.5, 0.2),
			"🗿",
			0.0
		)
	)


func _load_enemy_data(path: String) -> EnemyData:
	## Tenta carregar um EnemyData resource de forma segura; retorna null em falha.
	if not ResourceLoader.exists(path):
		push_warning("Battle3D: EnemyData não encontrado em %s" % path)
		return null
	var res: Resource = load(path)
	if not (res is EnemyData):
		push_warning("Battle3D: Recurso em %s não é EnemyData" % path)
		return null
	return res as EnemyData


func _enemy_data_to_dict(
	data: EnemyData,
	fallback_id: String,
	fallback_name: String,
	node: Node3D,
	home_pos: Vector3,
	marker_color: Color,
	marker_symbol: String,
	initial_ip: float
) -> Dictionary:
	## Converte um EnemyData resource para o dicionário de combatente usado pelo Battle3D.
	## Se data for null, usa os valores de fallback hardcoded.
	if data == null:
		return {
			"id": fallback_id,
			"name": fallback_name,
			"is_player": false,
			"hp": 45,
			"max_hp": 45,
			"mp": 10,
			"max_mp": 10,
			"sp": 0,
			"max_sp": 100,
			"attack": 12,
			"defense": 6,
			"magic": 5,
			"speed": 8.0,
			"ip": initial_ip,
			"state": "wait",
			"node": node,
			"home_pos": home_pos,
			"marker_color": marker_color,
			"marker_symbol": marker_symbol,
			"is_airborne": false,
			"enemy_data": null,
		}

	return {
		"id": data.id if data.id != "" else fallback_id,
		"name": data.enemy_name if data.enemy_name != "" else fallback_name,
		"is_player": false,
		"hp": data.max_hp,
		"max_hp": data.max_hp,
		"mp": data.max_mp,
		"max_mp": data.max_mp,
		"sp": 0,
		"max_sp": 100,
		"attack": data.attack,
		"defense": data.defense,
		"magic": data.magic,
		"speed": float(data.speed),
		"ip": initial_ip,
		"state": "wait",
		"node": node,
		"home_pos": home_pos,
		"marker_color": marker_color,
		"marker_symbol": marker_symbol,
		"is_airborne": false,
		"enemy_data": data,          # Referência ao resource original para acesso a skills/drops
	}



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
	if btn_evade != null:
		btn_evade.pressed.connect(_on_evade_chosen)


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


func _on_evade_chosen() -> void:
	## Evasão não precisa de alvo — o personagem se move imediatamente.
	var c: Dictionary = combatants[active_player_index]
	if command_panel != null:
		command_panel.visible = false
	if target_panel != null:
		target_panel.visible = false
	is_time_stopped = false
	_resolve_evade(c)


func _resolve_evade(c: Dictionary) -> void:
	## Reposiciona o personagem num ponto aleatório da arena e recua sua IP.
	## Custo: IP -IP_COST_EVADE (ainda fica na fase de wait/act sem agir).
	var node: Node3D = c["node"]
	if node == null:
		c["state"] = "wait"
		c["ip"] = maxf(0.0, c["ip"] - IP_COST_EVADE)
		return

	# Calcula um ponto de destino aleatório dentro do raio definido
	var angle: float = randf_range(0.0, TAU)
	var radius: float = randf_range(1.0, EVADE_RADIUS)
	var new_pos: Vector3 = Vector3(cos(angle) * radius, 0.0, sin(angle) * radius)
	new_pos.y = c.get("home_pos", Vector3.ZERO).y  # Mantém a altura original

	# Atualiza home_pos para que o personagem fique no novo local
	c["home_pos"] = new_pos
	c["state"] = "wait"
	c["ip"] = maxf(0.0, c["ip"] - IP_COST_EVADE)

	if action_banner != null:
		action_banner.text = (
			"💨 %s se esquiva! Novo ponto na arena. IP recuou %.0f%%."
			% [c["name"], IP_COST_EVADE * 100]
		)

	# Animação 3D de movimentação rápida
	var tween: Tween = create_tween()
	tween.tween_property(node, "global_position", new_pos, 0.28).set_trans(Tween.TRANS_QUAD)

	# Câmera acompanha rapidamente o personagem
	default_camera_pos = new_pos + Vector3(0, 3.5, 5.5)
	default_camera_look = new_pos + Vector3(0, 0.5, 0)
	var t: Tween = create_tween()
	t.tween_interval(0.5)
	t.tween_callback(func():
		default_camera_pos = Vector3(0, 4.5, 7.5)
		default_camera_look = Vector3(0, 0.5, 0)
	)

	_update_status_display()


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

	# Se foi um CANCEL e o alvo ainda está vivo → Aerial Launch
	if is_cancel and target["hp"] > 0:
		_trigger_aerial_launch(target, attacker)
	elif target["hp"] <= 0 and target["node"] != null:
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
# AERIAL LAUNCH & AERIAL COMBO (Grandia III)
# ──────────────────────────────────────────────
func _trigger_aerial_launch(target: Dictionary, launcher: Dictionary) -> void:
	## Lança o inimigo no ar após um CANCEL. Se houver um parceiro com SP suficiente e
	## IP >= 0.5, ele executa o Aerial Combo automaticamente; caso contrário, o alvo
	## cai sozinho e toma dano de impacto.
	if target["node"] == null:
		return

	target["is_airborne"] = true

	# Câmera dinâmica para cima durante o voo
	var target_pos: Vector3 = target["node"].global_position
	default_camera_pos = target_pos + Vector3(0, 5.0, 6.0)
	default_camera_look = target_pos + Vector3(0, 2.0, 0)
	camera_shake_amount = 0.2

	if action_banner != null:
		action_banner.text = "🚀 %s foi arremessado ao ar!" % target["name"]

	# Animação de voo: sobe, fica no ar e desce
	var orig_pos: Vector3 = target["node"].global_position
	var peak_pos: Vector3 = orig_pos + Vector3(0, AERIAL_LAUNCH_HEIGHT, 0)
	var tween: Tween = create_tween().set_parallel(false)
	tween.tween_property(target["node"], "global_position", peak_pos, 0.35).set_trans(Tween.TRANS_SINE)
	tween.tween_interval(0.2)  # Pausa dramática no ar

	# Verifica se algum parceiro pode realizar o Aerial Combo
	var aerial_partner: Dictionary = _find_aerial_partner(launcher)
	var has_aerial: bool = not aerial_partner.is_empty()

	if has_aerial:
		tween.tween_callback(func():
			_execute_aerial_combo(aerial_partner, target, orig_pos)
		)
	else:
		# Sem parceiro disponível: cai sozinho e toma dano de queda
		tween.tween_property(target["node"], "global_position", orig_pos, 0.4).set_trans(Tween.TRANS_BOUNCE)
		tween.tween_callback(func():
			target["is_airborne"] = false
			var fall_dmg: int = maxi(5, int(target["max_hp"] * 0.12))
			target["hp"] = maxi(0, target["hp"] - fall_dmg)
			target["ip"] = maxf(0.0, target["ip"] - IP_PUSH_AERIAL_SMASH)
			camera_shake_amount = 0.3
			_show_damage_popup(target["node"], fall_dmg, false, "FALL")
			if action_banner != null:
				action_banner.text = "%s caiu no solo! -%d de dano de impacto!" % [target["name"], fall_dmg]
			if target["hp"] <= 0 and target["node"] != null:
				target["node"].visible = false
			default_camera_pos = Vector3(0, 4.5, 7.5)
			default_camera_look = Vector3(0, 0.5, 0)
			_update_status_display()
			_check_battle_end()
		)


func _find_aerial_partner(launcher: Dictionary) -> Dictionary:
	## Retorna o dicionário de um parceiro player (diferente do launcher)
	## que tenha SP suficiente e IP >= 0.5 para executar o Aerial Combo.
	for c in combatants:
		if (c["is_player"]
				and c["id"] != launcher["id"]
				and c["hp"] > 0
				and c["sp"] >= SP_COST_AERIAL
				and c["ip"] >= 0.5):
			return c
	return {}


func _execute_aerial_combo(partner: Dictionary, target: Dictionary, land_pos: Vector3) -> void:
	## Parceiro salta, desfere AERIAL_COMBO_HITS golpes no ar e finaliza com smash no solo.
	if partner["node"] == null or target["node"] == null:
		target["is_airborne"] = false
		return

	# Consome SP do parceiro
	partner["sp"] = maxi(0, partner["sp"] - SP_COST_AERIAL)

	if action_banner != null:
		action_banner.text = "✨ %s executa AERIAL COMBO em %s!" % [partner["name"], target["name"]]

	var partner_orig: Vector3 = partner["node"].global_position
	var target_air_pos: Vector3 = target["node"].global_position

	# Câmera se aproxima da ação aérea
	default_camera_pos = target_air_pos + Vector3(0, 1.0, 4.5)
	default_camera_look = target_air_pos

	var tween: Tween = create_tween().set_parallel(false)
	# Parceiro salta até o alvo no ar
	tween.tween_property(partner["node"], "global_position", target_air_pos + Vector3(0.6, 0, 0), 0.25)

	# Golpes aéreos
	var total_air_dmg: int = 0
	for i in range(AERIAL_COMBO_HITS):
		var hit_delay: float = float(i) * 0.18
		tween.tween_callback(func():
			var base_dmg: int = int(partner["attack"] * 1.0 - target["defense"] * 0.2)
			var hit_dmg: int = maxi(3, int(base_dmg * AERIAL_HIT_MULT))
			target["hp"] = maxi(0, target["hp"] - hit_dmg)
			total_air_dmg += hit_dmg
			camera_shake_amount = 0.1
			_show_damage_popup(target["node"], hit_dmg, false, "AIR%d" % (i + 1))
		).set_delay(hit_delay)
	tween.tween_interval(AERIAL_COMBO_HITS * 0.18)

	# Smash final: parceiro empurra o alvo para baixo
	tween.tween_callback(func():
		var base_smash: int = int(partner["attack"] * 1.5 - target["defense"] * 0.4)
		var smash_dmg: int = maxi(10, int(base_smash * AERIAL_SMASH_MULT))
		target["hp"] = maxi(0, target["hp"] - smash_dmg)
		target["ip"] = maxf(0.0, target["ip"] - IP_PUSH_AERIAL_SMASH)
		camera_shake_amount = 0.5
		_show_damage_popup(target["node"], smash_dmg, true, "SMASH")
		if action_banner != null:
			action_banner.text = (
				"💥 AERIAL SMASH! %s finalizou %s: %d de dano! ★"
				% [partner["name"], target["name"], smash_dmg]
			)
	)

	# Animação de queda do alvo e parceiro retornando ao chão (sequenciais)
	tween.tween_property(target["node"], "global_position", land_pos, 0.3).set_trans(Tween.TRANS_BOUNCE)
	tween.tween_property(partner["node"], "global_position", partner_orig, 0.20).set_trans(Tween.TRANS_QUAD)


	tween.tween_callback(func():
		target["is_airborne"] = false
		if target["hp"] <= 0 and target["node"] != null:
			target["node"].visible = false
		default_camera_pos = Vector3(0, 4.5, 7.5)
		default_camera_look = Vector3(0, 0.5, 0)
		_update_status_display()
		_check_battle_end()
	)


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
	## Atualiza os marcadores na timeline de IP com:
	## • Símbolo + nome abreviado + estado (WAIT / COM! / ACT▶)
	## • Linha divisória vertical no ponto COM (75%)
	## • Para a party: mini-barra de SP em cores

	if ip_markers_container == null:
		return

	for child in ip_markers_container.get_children():
		child.queue_free()

	var bar_width: float = ip_markers_container.size.x
	if bar_width < 1.0:
		bar_width = 240.0  # fallback antes do primeiro frame de layout

	# Linha divisória no ponto COM (75%)
	var com_marker: ColorRect = ColorRect.new()
	com_marker.color = Color(0.9, 0.8, 0.1, 0.7)
	com_marker.size = Vector2(1.5, ip_markers_container.size.y if ip_markers_container.size.y > 0.0 else 10.0)
	com_marker.position = Vector2(IP_COM_THRESHOLD * bar_width - 0.75, 0)
	ip_markers_container.add_child(com_marker)

	# Marcador por combatente vivo
	for c in combatants:
		if c["hp"] <= 0:
			continue

		# Estado legível
		var state_tag: String
		var state_color: Color
		match c["state"]:
			"command":
				state_tag = " COM!"
				state_color = Color(1.0, 0.95, 0.1)  # amarelo
			"act":
				state_tag = " ACT▶"
				state_color = Color(1.0, 0.35, 0.1)  # laranja-vermelho
			"executing":
				state_tag = " ★EXE"
				state_color = Color(1.0, 0.2, 0.8)   # magenta
			_:
				state_tag = ""
				state_color = c["marker_color"]

		# Nome abreviado (máx 4 chars) + símbolo
		var short_name: String = c["name"].substr(0, 4)
		var marker: Label = Label.new()
		marker.text = "%s%s%s" % [c.get("marker_symbol", "◆"), short_name, state_tag]
		marker.add_theme_font_size_override("font_size", 8)
		marker.modulate = state_color if state_tag != "" else c["marker_color"]
		marker.tooltip_text = "%s · IP: %.0f%%  HP: %d/%d" % [
			c["name"], c["ip"] * 100, c["hp"], c["max_hp"]
		]

		var x_pos: float = clampf(c["ip"] * bar_width - 12.0, 0.0, bar_width - 40.0)
		marker.position = Vector2(x_pos, 0)
		ip_markers_container.add_child(marker)

		# Mini barra de SP para combatentes da party (aparece acima do marcador)
		if c["is_player"] and c.get("max_sp", 0) > 0:
			var sp_bar: ColorRect = ColorRect.new()
			var sp_ratio: float = float(c.get("sp", 0)) / float(c["max_sp"])
			var sp_bar_max_w: float = 28.0
			sp_bar.color = Color(0.2, 0.6, 1.0, 0.9) if c["id"] == "ragg" else Color(0.7, 0.3, 1.0, 0.9)
			sp_bar.size = Vector2(sp_ratio * sp_bar_max_w, 2.0)
			sp_bar.position = Vector2(x_pos, -4.0)
			ip_markers_container.add_child(sp_bar)



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
