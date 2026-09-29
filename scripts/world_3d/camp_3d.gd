class_name Camp3D
extends Node3D
## Sistema de Acampamento (Camp/Dinner) — estilo Grandia III.
## Ragg e Calindra descansam ao redor de uma fogueira entre batalhas.
## HP/MP são restaurados e diálogos narrativos aprofundam a relação dos personagens.

signal camp_finished

@export var camp_index: int = 0  ## Índice de diálogo de acampamento a usar

# ──────────────────────────────────────────────
# Dados dos diálogos de acampamento
## Cada entrada: {"speaker": "Ragg"|"Calindra", "text": "..."}
# ──────────────────────────────────────────────
const CAMP_DIALOGUES: Array[Array] = [
	# Acampamento 0 — após primeiro combate
	[
		{"speaker": "Ragg", "text": "...Que canseira. Mas conseguimos."},
		{"speaker": "Calindra", "text": "Você foi bem lá atrás. Não esperava que cortasse assim."},
		{"speaker": "Ragg", "text": "Aprendi com quem eu cresci. (pausa) E você? Parece que está bem tranquila pra uma maga."},
		{"speaker": "Calindra", "text": "Cresci vendo batalhas. A tranquilidade é só treino. (sorri levemente) Come logo — o feijão vai esfriar."},
	],
	# Acampamento 1 — caminhada pelo mundo
	[
		{"speaker": "Calindra", "text": "Você conhece a história do Golem Antigo que derrubamos?"},
		{"speaker": "Ragg", "text": "Não. Por quê estava ali?"},
		{"speaker": "Calindra", "text": "Guardava algo. Não sei o quê ainda, mas há magia muito antiga naquele lugar."},
		{"speaker": "Ragg", "text": "Então temos que voltar um dia desses."},
		{"speaker": "Calindra", "text": "Já contava com isso."},
	],
	# Acampamento 2 — momento de vulnerabilidade
	[
		{"speaker": "Ragg", "text": "Às vezes me pergunto se estamos no caminho certo."},
		{"speaker": "Calindra", "text": "...Eu também. Mas o caminho existe. Isso já é mais do que a maioria tem."},
		{"speaker": "Ragg", "text": "Filosofando enquanto come?"},
		{"speaker": "Calindra", "text": "A comida inspira. (ri) Agora descansa — amanhã pode ser pior."},
	],
]

# ──────────────────────────────────────────────
# Estado do acampamento
# ──────────────────────────────────────────────
var _dialogue_lines: Array = []
var _current_line: int = 0
var _is_finished: bool = false

# ──────────────────────────────────────────────
# Nós da cena
# ──────────────────────────────────────────────
@onready var speaker_label: Label = $UI/DialoguePanel/SpeakerLabel
@onready var dialogue_label: Label = $UI/DialoguePanel/DialogueLabel
@onready var btn_next: Button = $UI/DialoguePanel/BtnNext
@onready var btn_skip: Button = $UI/DialoguePanel/BtnSkip
@onready var restore_label: Label = $UI/RestoreLabel
@onready var btn_leave: Button = $UI/BtnLeave
@onready var campfire_light: OmniLight3D = $Campfire/OmniLight3D
@onready var ragg_seat: Node3D = $Seats/RaggSeat
@onready var calindra_seat: Node3D = $Seats/CalindraSeat


# ──────────────────────────────────────────────
# Inicialização
# ──────────────────────────────────────────────
func _ready() -> void:
	GameState.current_mode = "camp"

	# Escolhe o índice de diálogo (cíclico)
	var idx: int = GameState.get_flag("camp_count", 0) % CAMP_DIALOGUES.size()
	_dialogue_lines = CAMP_DIALOGUES[idx]

	# Registra a visita ao camp
	var camp_count: int = GameState.get_flag("camp_count", 0)
	GameState.set_flag("camp_count", camp_count + 1)

	_restore_party()
	_start_campfire_glow()
	_show_line(0)

	if btn_next != null:
		btn_next.pressed.connect(_on_next_pressed)
	if btn_skip != null:
		btn_skip.pressed.connect(_on_skip_pressed)
	if btn_leave != null:
		btn_leave.pressed.connect(_on_leave_pressed)
		btn_leave.visible = false


# ──────────────────────────────────────────────
# Restauração de HP/MP da party
# ──────────────────────────────────────────────
func _restore_party() -> void:
	## Restauração completa de HP e parcial de MP (75%).
	if restore_label != null:
		restore_label.text = "★ HP e MP da party restaurados! ★"
		restore_label.modulate = Color(0.3, 1.0, 0.5)

	# Usa o PartyManager para restaurar através da fonte de dados
	# (se não disponível, apenas registra a ação)
	if PartyManager != null and PartyManager.has_method("restore_all"):
		PartyManager.restore_all(1.0, 0.75)  # 100% HP, 75% MP


# ──────────────────────────────────────────────
# Fogueira — animação de luz pulsante
# ──────────────────────────────────────────────
func _start_campfire_glow() -> void:
	if campfire_light == null:
		return
	campfire_light.light_energy = 2.5
	var tween: Tween = create_tween().set_loops()
	tween.tween_property(campfire_light, "light_energy", 3.5, 0.6).set_trans(Tween.TRANS_SINE)
	tween.tween_property(campfire_light, "light_energy", 2.0, 0.8).set_trans(Tween.TRANS_SINE)


# ──────────────────────────────────────────────
# Sistema de diálogo
# ──────────────────────────────────────────────
func _show_line(index: int) -> void:
	if index >= _dialogue_lines.size():
		_end_dialogue()
		return
	_current_line = index
	var line: Dictionary = _dialogue_lines[index]
	if speaker_label != null:
		speaker_label.text = line.get("speaker", "")
		speaker_label.modulate = (
			Color(0.4, 0.7, 1.0) if line.get("speaker") == "Ragg"
			else Color(0.85, 0.5, 1.0)
		)
	if dialogue_label != null:
		dialogue_label.text = line.get("text", "")
	if btn_next != null:
		btn_next.text = "Próximo ▶" if index < _dialogue_lines.size() - 1 else "Terminar ✓"


func _on_next_pressed() -> void:
	_show_line(_current_line + 1)


func _on_skip_pressed() -> void:
	_end_dialogue()


func _end_dialogue() -> void:
	if _is_finished:
		return
	_is_finished = true
	if speaker_label != null:
		speaker_label.text = ""
	if dialogue_label != null:
		dialogue_label.text = "(Silêncio aconchegante ao redor da fogueira...)"
	if btn_next != null:
		btn_next.visible = false
	if btn_skip != null:
		btn_skip.visible = false
	if btn_leave != null:
		btn_leave.visible = true


func _on_leave_pressed() -> void:
	camp_finished.emit()
	SceneManager.change_scene("res://scenes/world_3d/kakariko_3d.tscn")
