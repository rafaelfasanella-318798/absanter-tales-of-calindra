class_name BattleSimulator
extends RefCounted
## Headless combat simulation engine to evaluate game balance, difficulty, and win rates.

const MAX_ROUNDS: int = 50


static func simulate_battles(
	num_battles: int,
	party_ids: Array[String] = ["ragg", "calindra"],
	enemy_ids: Array[String] = ["slime", "cave_bat"]
) -> Dictionary:
	var victories: int = 0
	var defeats: int = 0
	var total_rounds: int = 0
	var hp_rem_pct_sum: float = 0.0

	for i in range(num_battles):
		var outcome: Dictionary = _simulate_single_battle(party_ids, enemy_ids)
		if outcome["victory"]:
			victories += 1
		else:
			defeats += 1
		total_rounds += outcome["rounds"]
		hp_rem_pct_sum += outcome["party_hp_pct"]

	var win_rate: float = float(victories) / float(maxi(1, num_battles))
	var avg_rounds: float = float(total_rounds) / float(maxi(1, num_battles))
	var avg_hp_pct: float = hp_rem_pct_sum / float(maxi(1, num_battles))

	return {
		"total_battles": num_battles,
		"victories": victories,
		"defeats": defeats,
		"win_rate": win_rate,
		"average_rounds": avg_rounds,
		"average_party_hp_pct": avg_hp_pct
	}


static func _simulate_single_battle(
	party_ids: Array[String], enemy_ids: Array[String]
) -> Dictionary:
	var party: Array[Dictionary] = []
	for p_id in party_ids:
		var char_data: CharacterData = load("res://data/characters/%s.tres" % p_id) as CharacterData
		party.append(
			{
				"id": char_data.id,
				"name": char_data.character_name,
				"is_player": true,
				"max_hp": char_data.max_hp,
				"hp": char_data.max_hp,
				"max_mp": char_data.max_mp,
				"mp": char_data.max_mp,
				"attack": char_data.attack,
				"defense": char_data.defense,
				"magic": char_data.magic,
				"speed": char_data.speed,
				"element_affinity": Enums.Element.NONE,
				"element_weakness": Enums.Element.NONE,
				"is_defending": false,
				"skills": char_data.starting_skills
			}
		)

	var enemies: Array[Dictionary] = []
	for e_id in enemy_ids:
		var enemy_data: EnemyData = load("res://data/enemies/%s.tres" % e_id) as EnemyData
		enemies.append(
			{
				"id": enemy_data.id,
				"name": enemy_data.enemy_name,
				"is_player": false,
				"max_hp": enemy_data.max_hp,
				"hp": enemy_data.max_hp,
				"max_mp": enemy_data.max_mp,
				"mp": enemy_data.max_mp,
				"attack": enemy_data.attack,
				"defense": enemy_data.defense,
				"magic": enemy_data.magic,
				"speed": enemy_data.speed,
				"element_affinity": enemy_data.element_affinity,
				"element_weakness": enemy_data.element_weakness,
				"is_defending": false,
				"skills": enemy_data.skills
			}
		)

	var rounds: int = 0
	while rounds < MAX_ROUNDS:
		rounds += 1

		# Collect living participants and sort by speed
		var turn_order: Array[Dictionary] = []
		for p in party:
			if p["hp"] > 0:
				turn_order.append(p)
		for e in enemies:
			if e["hp"] > 0:
				turn_order.append(e)

		turn_order.sort_custom(
			func(a: Dictionary, b: Dictionary) -> bool: return a["speed"] > b["speed"]
		)

		for actor in turn_order:
			if actor["hp"] <= 0:
				continue

			if actor["is_player"]:
				_simulate_player_action(actor, party, enemies)
			else:
				_simulate_enemy_action(actor, party)

			# Check battle end after every action
			var alive_enemies: Array[Dictionary] = enemies.filter(
				func(e: Dictionary) -> bool: return e["hp"] > 0
			)
			if alive_enemies.is_empty():
				var total_hp: float = 0.0
				var max_hp_sum: float = 0.0
				for p in party:
					total_hp += float(maxi(0, p["hp"]))
					max_hp_sum += float(p["max_hp"])
				return {
					"victory": true,
					"rounds": rounds,
					"party_hp_pct": total_hp / maxf(1.0, max_hp_sum)
				}

			var alive_party: Array[Dictionary] = party.filter(
				func(p: Dictionary) -> bool: return p["hp"] > 0
			)
			if alive_party.is_empty():
				return {"victory": false, "rounds": rounds, "party_hp_pct": 0.0}

	return {"victory": false, "rounds": rounds, "party_hp_pct": 0.0}


static func _simulate_player_action(
	actor: Dictionary, party: Array[Dictionary], enemies: Array[Dictionary]
) -> void:
	var living_enemies: Array[Dictionary] = enemies.filter(
		func(e: Dictionary) -> bool: return e["hp"] > 0
	)
	var living_allies: Array[Dictionary] = party.filter(
		func(p: Dictionary) -> bool: return p["hp"] > 0
	)
	if living_enemies.is_empty():
		return

	# Calindra healing check
	if actor["id"] == "calindra":
		living_allies.sort_custom(
			func(a: Dictionary, b: Dictionary) -> bool: return a["hp"] < b["hp"]
		)
		var lowest_ally: Dictionary = living_allies[0]
		if float(lowest_ally["hp"]) / float(lowest_ally["max_hp"]) < 0.45 and actor["mp"] >= 10:
			# Cast Heal
			actor["mp"] -= 10
			var heal_val: int = int(round(actor["magic"] * 1.5 + 35.0))
			lowest_ally["hp"] = mini(lowest_ally["max_hp"], lowest_ally["hp"] + heal_val)
			return

	# Attack action
	living_enemies.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["hp"] < b["hp"])
	var target: Dictionary = living_enemies[0]

	var skill_power: float = 1.0
	var skill_element: int = Enums.Element.PHYSICAL
	if actor["id"] == "ragg" and actor["mp"] >= 8 and randf() < 0.5:
		actor["mp"] -= 8
		skill_power = 1.8
	elif actor["id"] == "calindra":
		skill_power = 1.2
		skill_element = Enums.Element.LIGHT

	var dummy_skill: SkillData = SkillData.new()
	dummy_skill.power_multiplier = skill_power
	dummy_skill.element = skill_element

	var dmg_dict: Dictionary = BattleFormulas.calculate_damage(
		actor, target, dummy_skill, randf_range(0.95, 1.05), target["is_defending"]
	)
	target["hp"] = maxi(0, target["hp"] - dmg_dict["damage"])


static func _simulate_enemy_action(actor: Dictionary, party: Array[Dictionary]) -> void:
	var living_party: Array[Dictionary] = party.filter(
		func(p: Dictionary) -> bool: return p["hp"] > 0
	)
	if living_party.is_empty():
		return

	living_party.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["hp"] < b["hp"])
	var target: Dictionary = living_party[0]

	var dummy_skill: SkillData = SkillData.new()
	dummy_skill.power_multiplier = 1.0
	dummy_skill.element = Enums.Element.PHYSICAL

	var dmg_dict: Dictionary = BattleFormulas.calculate_damage(
		actor, target, dummy_skill, randf_range(0.9, 1.1), target["is_defending"]
	)
	target["hp"] = maxi(0, target["hp"] - dmg_dict["damage"])
