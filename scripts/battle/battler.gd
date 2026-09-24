class_name Battler
extends Node2D
## Represents an active combatant (Party member or Enemy) in the turn-based battle system.

signal health_changed(current: int, maximum: int)
signal mana_changed(current: int, maximum: int)
signal damaged(amount: int, is_critical: bool, is_weakness: bool)
signal healed(amount: int)
signal died

const FLASH_DURATION: float = 0.15

@export var battler_id: String = ""
@export var battler_name: String = ""
@export var is_player: bool = false
@export var level: int = 1
@export var current_xp: int = 0
@export var max_hp: int = 100
@export var current_hp: int = 100
@export var max_mp: int = 20
@export var current_mp: int = 20
@export var attack: int = 15
@export var defense: int = 10
@export var magic: int = 5
@export var speed: int = 10
@export var element_affinity: int = Enums.Element.NONE
@export var element_weakness: int = Enums.Element.NONE
@export var xp_reward: int = 0
@export var gold_reward: int = 0
@export var drop_item_id: String = ""
@export var drop_chance: float = 0.0

var skills: Array[SkillData] = []
var active_buffs: Dictionary = {}  # StatusEffect -> turns_remaining
var is_defending: bool = false
var is_dead: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var damage_spawn_point: Marker2D = $DamageSpawnPoint


func _ready() -> void:
	if current_hp <= 0:
		current_hp = max_hp
	if current_mp < 0:
		current_mp = max_mp


func setup_from_character_data(data: CharacterData) -> void:
	if data == null:
		return
	battler_id = data.id
	battler_name = data.character_name
	is_player = true
	var bonuses: Dictionary = {"hp": 0, "mp": 0, "attack": 0, "defense": 0, "magic": 0, "speed": 0}
	if PartyManager != null:
		bonuses = PartyManager.get_equipment_bonuses(data.id)

	max_hp = data.max_hp + bonuses["hp"]
	current_hp = max_hp
	max_mp = data.max_mp + bonuses["mp"]
	current_mp = max_mp
	attack = data.attack + bonuses["attack"]
	defense = data.defense + bonuses["defense"]
	magic = data.magic + bonuses["magic"]
	speed = data.speed + bonuses["speed"]

	skills.clear()
	for s in data.starting_skills:
		if s is SkillData:
			skills.append(s)


func setup_from_enemy_data(data: EnemyData) -> void:
	if data == null:
		return
	battler_id = data.id
	battler_name = data.enemy_name
	is_player = false
	max_hp = data.max_hp
	current_hp = data.max_hp
	max_mp = data.max_mp
	current_mp = data.max_mp
	attack = data.attack
	defense = data.defense
	magic = data.magic
	speed = data.speed
	element_affinity = data.element_affinity
	element_weakness = data.element_weakness
	xp_reward = data.xp_reward
	gold_reward = data.gold_reward
	drop_item_id = data.drop_item_id
	drop_chance = data.drop_chance

	skills.clear()
	for s in data.skills:
		if s is SkillData:
			skills.append(s)

	if sprite != null and data.tile_index > 0:
		sprite.texture = TextureLoader.get_kenney_tile(data.tile_index)


func take_damage(amount: int, is_critical: bool = false, is_weakness: bool = false) -> int:
	if is_dead:
		return 0

	var actual_damage: int = maxi(1, amount)
	current_hp = maxi(0, current_hp - actual_damage)
	health_changed.emit(current_hp, max_hp)
	damaged.emit(actual_damage, is_critical, is_weakness)
	_play_hit_flash()

	if current_hp == 0:
		is_dead = true
		died.emit()
		_play_death_animation()

	return actual_damage


func heal(amount: int) -> int:
	if is_dead:
		return 0

	var missing: int = max_hp - current_hp
	var actual_heal: int = mini(missing, maxi(0, amount))
	current_hp += actual_heal
	health_changed.emit(current_hp, max_hp)
	healed.emit(actual_heal)
	return actual_heal


func use_mp(amount: int) -> bool:
	if current_mp < amount:
		return false
	current_mp -= amount
	mana_changed.emit(current_mp, max_mp)
	return true


func restore_mp(amount: int) -> int:
	var missing: int = max_mp - current_mp
	var actual_restore: int = mini(missing, maxi(0, amount))
	current_mp += actual_restore
	mana_changed.emit(current_mp, max_mp)
	return actual_restore


func apply_buff(buff_type: int, duration: int = 3) -> void:
	active_buffs[buff_type] = duration


func tick_turn_effects() -> void:
	is_defending = false

	# Decrement buff timers
	var expired: Array[int] = []
	for buff in active_buffs.keys():
		active_buffs[buff] -= 1
		if active_buffs[buff] <= 0:
			expired.append(buff)
	for exp_buff in expired:
		active_buffs.erase(exp_buff)


func get_effective_defense() -> int:
	var def: float = float(defense)
	if active_buffs.has(Enums.StatusEffect.DEF_BUFF):
		def *= 1.4
	elif active_buffs.has(Enums.StatusEffect.DEF_DEBUFF):
		def *= 0.7
	return int(round(def))


func get_effective_attack() -> int:
	var atk: float = float(attack)
	if active_buffs.has(Enums.StatusEffect.ATK_BUFF):
		atk *= 1.4
	elif active_buffs.has(Enums.StatusEffect.ATK_DEBUFF):
		atk *= 0.7
	return int(round(atk))


func get_stats_dict() -> Dictionary:
	return {
		"attack": get_effective_attack(),
		"defense": get_effective_defense(),
		"magic": magic,
		"speed": speed,
		"element_affinity": element_affinity,
		"element_weakness": element_weakness
	}


func _play_hit_flash() -> void:
	if sprite == null:
		return
	var tween: Tween = create_tween()
	tween.tween_property(sprite, "modulate", Color(1.0, 0.3, 0.3, 1.0), FLASH_DURATION * 0.5)
	tween.tween_property(sprite, "modulate", Color.WHITE, FLASH_DURATION * 0.5)


func _play_death_animation() -> void:
	if sprite == null:
		return
	var tween: Tween = create_tween()
	tween.tween_property(sprite, "modulate:a", 0.0, 0.4)
