class_name Kakariko3D
extends Node3D
## Vila Kakariko — exploração 3D no estilo Grandia / PS2.
## Câmera de órbita com SpringArm3D: segue o player, colide com geometria
## e rotaciona com o mouse ou analógico direito.

@export var battle_scene_path: String = "res://scenes/battle_3d/battle_3d.tscn"

# ──────────────────────────────────────────────
# Configurações de câmera
# ──────────────────────────────────────────────
@export_group("Câmera")
@export var camera_follow_speed: float = 8.0  ## Suavização de seguimento (lerp)
@export var camera_height_offset: float = 1.2  ## Altura do CameraRig acima do player
@export var orbit_speed_mouse: float = 0.3  ## Sensibilidade de órbita pelo mouse (graus/pixel)
@export var orbit_speed_gamepad: float = 80.0  ## Sensibilidade de órbita pelo analógico (graus/s)
@export var orbit_pitch_min: float = 5.0  ## Ângulo de inclinação mínimo (graus)
@export var orbit_pitch_max: float = 60.0  ## Ângulo de inclinação máximo (graus)

# Estado interno da órbita
var _orbit_yaw: float = 0.0  ## Rotação horizontal (Y) em graus
var _orbit_pitch: float = 20.0  ## Inclinação vertical (X) em graus
var _is_mouse_orbiting: bool = false

# ──────────────────────────────────────────────
# Nós da cena
# ──────────────────────────────────────────────
@onready var player: Player3D = $Player3D
@onready var follower: Follower3D = $Follower3D
@onready var camera: Camera3D = $CameraRig/SpringArm3D/Camera3D
@onready var camera_rig: Node3D = $CameraRig
@onready var spring_arm: SpringArm3D = $CameraRig/SpringArm3D
@onready var battle_portal: Area3D = $BattlePortal


# ──────────────────────────────────────────────
# Inicialização
# ──────────────────────────────────────────────
func _ready() -> void:
	GameState.current_mode = "exploration_3d"
	AudioManager.play_music("title_theme", 0.5)

	if battle_portal != null:
		battle_portal.body_entered.connect(_on_battle_trigger_entered)

	# Captura o mouse para câmera de órbita quando a janela tiver foco
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _exit_tree() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


# ──────────────────────────────────────────────
# Câmera de órbita — segue o player via SpringArm3D
# ──────────────────────────────────────────────
func _process(delta: float) -> void:
	if player == null or camera_rig == null:
		return

	# 1. Posição do CameraRig: segue o player com suavização
	var target_rig_pos: Vector3 = player.global_position + Vector3(0, camera_height_offset, 0)
	camera_rig.global_position = camera_rig.global_position.lerp(
		target_rig_pos, camera_follow_speed * delta
	)

	# 2. Rotação de órbita pelo analógico direito (joypad)
	var joy_x: float = Input.get_joy_axis(0, JOY_AXIS_RIGHT_X)
	var joy_y: float = Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)
	var deadzone: float = 0.15
	if absf(joy_x) > deadzone:
		_orbit_yaw -= joy_x * orbit_speed_gamepad * delta
	if absf(joy_y) > deadzone:
		_orbit_pitch = clampf(
			_orbit_pitch - joy_y * orbit_speed_gamepad * delta, orbit_pitch_min, orbit_pitch_max
		)

	# 3. Aplica a rotação ao CameraRig (pitch negativo para mirar para baixo)
	camera_rig.rotation_degrees.y = _orbit_yaw
	camera_rig.rotation_degrees.x = -_orbit_pitch

	# 4. Faz o SpringArm apontar sempre para frente a partir do rig (sem rotação extra)
	if spring_arm != null:
		spring_arm.rotation = Vector3.ZERO


# ──────────────────────────────────────────────
# Entrada de mouse para órbita
# ──────────────────────────────────────────────
func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_RIGHT:
			_is_mouse_orbiting = mb.pressed

	elif event is InputEventMouseMotion and _is_mouse_orbiting:
		var mm: InputEventMouseMotion = event as InputEventMouseMotion
		_orbit_yaw -= mm.relative.x * orbit_speed_mouse
		_orbit_pitch = clampf(
			_orbit_pitch - mm.relative.y * orbit_speed_mouse, orbit_pitch_min, orbit_pitch_max
		)

	elif event.is_action_pressed("ui_cancel"):
		# Libera o mouse quando ESC for pressionado antes do menu
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("menu"):
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		SceneManager.change_scene("res://scenes/main/main.tscn")
		get_viewport().set_input_as_handled()


func _on_battle_trigger_entered(body: Node3D) -> void:
	if body is Player3D:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		SceneManager.change_scene(battle_scene_path)
