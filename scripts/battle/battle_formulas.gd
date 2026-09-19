class_name BattleFormulas
extends RefCounted
## Pure static calculation functions for damage, healing, level progression, and turn mechanics.

const MIN_DAMAGE: int = 1
const CRITICAL_MULTIPLIER: float = 1.5
const WEAKNESS_MULTIPLIER: float = 1.5
const DEFENSE_STANCE_REDUCTION: float = 0.5


static func calculate_damage(
	attacker_stats: Dictionary,
	target_stats: Dictionary,
	skill: SkillData,
	variance_roll: float = 1.0,
	is_target_defending: bool = false,
	is_critical_roll: bool = false
) -> Dictionary:
	var result: Dictionary = {
		"damage": MIN_DAMAGE, "is_critical": is_critical_roll, "is_weakness": false
	}

	if skill == null:
		return result

	var is_magical: bool = (
		skill.element != Enums.Element.PHYSICAL and skill.element != Enums.Element.NONE
		or attacker_stats.get("magic", 0) > attacker_stats.get("attack", 0)
	)

	var raw_power: float = 0.0
	if is_magical:
		var mag: float = float(attacker_stats.get("magic", 5))
		var def: float = float(target_stats.get("defense", 5))
		raw_power = (mag * 2.2 - def * 0.6) * skill.power_multiplier + float(skill.base_value)
	else:
		var atk: float = float(attacker_stats.get("attack", 10))
		var def: float = float(target_stats.get("defense", 5))
		raw_power = (atk * 2.0 - def * 1.0) * skill.power_multiplier + float(skill.base_value)

	raw_power = maxf(raw_power, float(MIN_DAMAGE))

	# Check elemental weakness
	var target_weakness: int = target_stats.get("element_weakness", Enums.Element.NONE)
	if target_weakness != Enums.Element.NONE and target_weakness == skill.element:
		raw_power *= WEAKNESS_MULTIPLIER
		result["is_weakness"] = true

	# Check critical
	if is_critical_roll:
		raw_power *= CRITICAL_MULTIPLIER

	# Apply defense stance
	if is_target_defending:
		raw_power *= DEFENSE_STANCE_REDUCTION

	# Apply random variance (default 0.9 to 1.1)
	var final_dmg: int = maxi(MIN_DAMAGE, int(round(raw_power * variance_roll)))
	result["damage"] = final_dmg
	return result


static func calculate_healing(
	user_stats: Dictionary, skill: SkillData, variance_roll: float = 1.0
) -> int:
	if skill == null:
		return 0

	var mag: float = float(user_stats.get("magic", 10))
	var base_heal: float = mag * skill.power_multiplier + float(skill.base_value)
	return maxi(1, int(round(base_heal * variance_roll)))


static func calculate_xp_for_level(target_level: int) -> int:
	if target_level <= 1:
		return 0
	return int(round(40.0 * pow(float(target_level), 1.45)))


static func check_level_up(
	current_level: int, current_xp: int, growth_data: Dictionary = {}
) -> Dictionary:
	var next_level: int = current_level + 1
	var required_xp: int = calculate_xp_for_level(next_level)

	if current_xp >= required_xp:
		var stat_gains: Dictionary = {
			"max_hp": growth_data.get("hp_growth", 15),
			"max_mp": growth_data.get("mp_growth", 5),
			"attack": growth_data.get("attack_growth", 3),
			"defense": growth_data.get("defense_growth", 2),
			"magic": growth_data.get("magic_growth", 2),
			"speed": growth_data.get("speed_growth", 1)
		}
		return {"leveled_up": true, "new_level": next_level, "stat_gains": stat_gains}

	return {"leveled_up": false, "new_level": current_level, "stat_gains": {}}


static func calculate_escape_chance(
	party_avg_spd: float, enemy_avg_spd: float, attempts: int = 1
) -> bool:
	var base_chance: float = 0.65
	var spd_diff: float = (party_avg_spd - enemy_avg_spd) * 0.02
	var attempt_bonus: float = float(attempts - 1) * 0.10
	var final_chance: float = clampf(base_chance + spd_diff + attempt_bonus, 0.20, 0.95)
	return randf() < final_chance
