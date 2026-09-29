class_name EnemyWanderer3D
extends Area3D
## Inimigo errante que patrulha o mundo 3D.
## Ao tocar o player, verifica o ângulo de aproximação:
##   - Player vem POR TRÁS do inimigo → Surprise Attack (vantagem do player)
##   - Inimigo vem POR TRÁS do player → Ambush (vantagem do inimigo)
##   - Caso contrário → Encontro Normal
##
## Emite EventBus.field_encounter_started com o tipo de encontro antes de carregar a batalha.

signal encounter_triggered(encounter_type: String)

# ──────────────────────────────────────────────
# Exportações configuráveis
# ──────────────────────────────────────────────
@export var enemy_data_path: String = "res://data/enemies/slime.tres"
@export var wander_radius: float = 4.0       ## Raio máximo de deambulação
@export var wander_speed: float = 1.8        ## Velocidade de patrulha
@export var wander_pause_time: float = 1.5   ## Pausa entre movimentos
@export var battle_scene_path: String = "res://scenes/battle_3d/battle_3d.tscn"

## Ângulo (graus) da "janela de costas" do alvo para acionar Surprise/Ambush.
## 60° = o player precisa estar dentro de 60° do arco traseiro do inimigo.
@export var backstab_angle_deg: float = 60.0

# ──────────────────────────────────────────────
# Estado interno
# ──────────────────────────────────────────────
var _wander_target: Vector3 = Vector3.ZERO
var _wander_origin: Vector3 = Vector3.ZERO
var _time_to_next_wander: float = 0.0
var _is_triggered: bool = false
var _player_ref: Player3D = null

@onready var visual: Node3D = $Visual if has_node("Visual") else null
@onready var exclamation_label: Label3D = $ExclamationLabel if has_node("ExclamationLabel") else null


# ──────────────────────────────────────────────
# Inicialização
# ──────────────────────────────────────────────
func _ready() -> void:
	_wander_origin = global_position
	_wander_target = global_position
	body_entered.connect(_on_body_entered)

	if exclamation_label != null:
		exclamation_label.visible = false


# ──────────────────────────────────────────────
# Patrulha de deambulação aleatória
# ──────────────────────────────────────────────
func _physics_process(delta: float) -> void:
	if _is_triggered:
		return

	_time_to_next_wander -= delta
	if _time_to_next_wander <= 0.0:
		_pick_new_wander_target()

	# Move em direção ao alvo
	var to_target: Vector3 = _wander_target - global_position
	to_target.y = 0.0
	if to_target.length() > 0.2:
		global_position += to_target.normalized() * wander_speed * delta
		if visual != null:
			var target_angle: float = atan2(to_target.x, to_target.z)
			visual.rotation.y = lerp_angle(visual.rotation.y, target_angle, 8.0 * delta)
	else:
		_time_to_next_wander = wander_pause_time


func _pick_new_wander_target() -> void:
	var angle: float = randf_range(0.0, TAU)
	var dist: float = randf_range(0.5, wander_radius)
	_wander_target = _wander_origin + Vector3(cos(angle) * dist, 0.0, sin(angle) * dist)
	_time_to_next_wander = randf_range(1.5, 3.5)


# ──────────────────────────────────────────────
# Detecção de colisão e classificação de encontro
# ──────────────────────────────────────────────
func _on_body_entered(body: Node3D) -> void:
	if _is_triggered:
		return
	if not (body is Player3D):
		return

	_is_triggered = true
	_player_ref = body as Player3D

	var encounter_type: String = _classify_encounter(body)
	_flash_encounter_indicator(encounter_type)

	# Grava no GameState para que Battle3D leia na inicialização
	GameState.encounter_type = encounter_type

	EventBus.field_encounter_started.emit(
		_get_enemy_id(),
		encounter_type
	)
	encounter_triggered.emit(encounter_type)

	# Pequeno delay dramático antes de carregar a batalha
	await get_tree().create_timer(0.55).timeout
	SceneManager.change_scene(battle_scene_path)


func _classify_encounter(player: Node3D) -> String:
	## Grandia III angle-check:
	## Compara o ângulo entre a direção de olhar do inimigo e a direção
	## player→inimigo, e entre a direção de olhar do player e a direção
	## inimigo→player.
	var enemy_forward: Vector3 = -global_transform.basis.z  # frente do inimigo
	var player_forward: Vector3 = -player.global_transform.basis.z

	var to_player: Vector3 = (player.global_position - global_position).normalized()
	to_player.y = 0.0

	var to_enemy: Vector3 = (global_position - player.global_position).normalized()
	to_enemy.y = 0.0
	enemy_forward.y = 0.0
	player_forward.y = 0.0

	# Ângulo entre frente do inimigo e direção até o player
	var cos_enemy_angle: float = enemy_forward.normalized().dot(to_player.normalized())
	var enemy_angle_deg: float = rad_to_deg(acos(clampf(cos_enemy_angle, -1.0, 1.0)))

	# Ângulo entre frente do player e direção até o inimigo
	var cos_player_angle: float = player_forward.normalized().dot(to_enemy.normalized())
	var player_angle_deg: float = rad_to_deg(acos(clampf(cos_player_angle, -1.0, 1.0)))

	var half_window: float = backstab_angle_deg / 2.0

	# Player vem pelas costas do inimigo = enemy_angle_deg > 180 - half_window
	if enemy_angle_deg > (180.0 - half_window):
		return "surprise"

	# Inimigo vem pelas costas do player = player_angle_deg > 180 - half_window
	if player_angle_deg > (180.0 - half_window):
		return "ambush"

	return "normal"


func _get_enemy_id() -> String:
	if ResourceLoader.exists(enemy_data_path):
		var res: Resource = load(enemy_data_path)
		if res is EnemyData:
			return (res as EnemyData).id
	return "unknown_enemy"


func _flash_encounter_indicator(encounter_type: String) -> void:
	if exclamation_label == null:
		return
	match encounter_type:
		"surprise":
			exclamation_label.text = "!!! SURPRISE !!!"
			exclamation_label.modulate = Color(0.2, 0.9, 0.2)
		"ambush":
			exclamation_label.text = "⚠ AMBUSH ⚠"
			exclamation_label.modulate = Color(1.0, 0.15, 0.1)
		_:
			exclamation_label.text = "!"
			exclamation_label.modulate = Color(1.0, 0.95, 0.2)
	exclamation_label.visible = true
