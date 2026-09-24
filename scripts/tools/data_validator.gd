class_name DataValidator
extends RefCounted
## Validates all game data resources (.tres) in res://data/ for consistency.


static func validate_all() -> Dictionary:
	var errors: Array[String] = []
	var warnings: Array[String] = []
	var validated_count: int = 0
	var id_registry: Dictionary = {
		"characters": {}, "enemies": {}, "skills": {}, "items": {}, "quests": {}
	}

	validated_count += _validate_dir(
		"res://data/skills/", "SkillData", id_registry["skills"], errors
	)
	validated_count += _validate_dir("res://data/items/", "ItemData", id_registry["items"], errors)
	validated_count += _validate_dir(
		"res://data/characters/", "CharacterData", id_registry["characters"], errors
	)
	validated_count += _validate_dir(
		"res://data/enemies/", "EnemyData", id_registry["enemies"], errors
	)
	validated_count += _validate_dir(
		"res://data/quests/", "QuestData", id_registry["quests"], errors
	)

	# Cross-reference validation: check that enemy drop_item_id exists in items
	for enemy_id in id_registry["enemies"]:
		var enemy: EnemyData = id_registry["enemies"][enemy_id]
		if not enemy.drop_item_id.is_empty():
			if not id_registry["items"].has(enemy.drop_item_id):
				warnings.append(
					(
						"Enemy '%s' references nonexistent drop_item_id: '%s'"
						% [enemy_id, enemy.drop_item_id]
					)
				)

	var success: bool = errors.is_empty()
	return {
		"success": success,
		"validated_count": validated_count,
		"errors": errors,
		"warnings": warnings
	}


static func _validate_dir(
	dir_path: String, type_name: String, registry: Dictionary, errors: Array[String]
) -> int:
	var count: int = 0
	if not DirAccess.dir_exists_absolute(dir_path):
		return 0

	var dir: DirAccess = DirAccess.open(dir_path)
	if dir == null:
		errors.append("Cannot open directory: %s" % dir_path)
		return 0

	dir.list_dir_begin()
	var file_name: String = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var file_path: String = dir_path + file_name
			if ResourceLoader.exists(file_path):
				var res: Resource = load(file_path)
				if res != null:
					_validate_single_resource(res, file_path, type_name, registry, errors)
					count += 1
				else:
					errors.append("Failed to load resource: %s" % file_path)
		file_name = dir.get_next()
	dir.list_dir_end()
	return count


static func _validate_single_resource(
	res: Resource, file_path: String, type_name: String, registry: Dictionary, errors: Array[String]
) -> void:
	match type_name:
		"SkillData":
			if not res is SkillData:
				errors.append("%s is not a SkillData" % file_path)
				return
			var s: SkillData = res as SkillData
			if s.id.is_empty():
				errors.append("%s has empty 'id'" % file_path)
			elif registry.has(s.id):
				errors.append("Duplicate SkillData id '%s' in %s" % [s.id, file_path])
			else:
				registry[s.id] = s
			if s.skill_name.is_empty():
				errors.append("%s has empty 'skill_name'" % file_path)
			if s.cost_mp < 0:
				errors.append("%s has negative 'cost_mp'" % file_path)
			if s.power_multiplier < 0.0:
				errors.append("%s has negative 'power_multiplier'" % file_path)
			if s.base_value < 0:
				errors.append("%s has negative 'base_value'" % file_path)

		"ItemData":
			if not res is ItemData:
				errors.append("%s is not an ItemData" % file_path)
				return
			var item: ItemData = res as ItemData
			if item.id.is_empty():
				errors.append("%s has empty 'id'" % file_path)
			elif registry.has(item.id):
				errors.append("Duplicate ItemData id '%s' in %s" % [item.id, file_path])
			else:
				registry[item.id] = item
			if item.item_name.is_empty():
				errors.append("%s has empty 'item_name'" % file_path)
			if item.price < 0:
				errors.append("%s has negative price" % file_path)
			if (
				not item.equip_slot.is_empty()
				and item.equip_slot not in ["weapon", "armor", "accessory"]
			):
				errors.append("%s has invalid equip_slot '%s'" % [file_path, item.equip_slot])

		"CharacterData":
			if not res is CharacterData:
				errors.append("%s is not a CharacterData" % file_path)
				return
			var c: CharacterData = res as CharacterData
			if c.id.is_empty():
				errors.append("%s has empty 'id'" % file_path)
			elif registry.has(c.id):
				errors.append("Duplicate CharacterData id '%s' in %s" % [c.id, file_path])
			else:
				registry[c.id] = c
			if c.character_name.is_empty():
				errors.append("%s has empty 'character_name'" % file_path)
			if c.max_hp <= 0:
				errors.append("%s has non-positive max_hp" % file_path)
			if c.attack <= 0:
				errors.append("%s has non-positive attack" % file_path)

		"EnemyData":
			if not res is EnemyData:
				errors.append("%s is not an EnemyData" % file_path)
				return
			var e: EnemyData = res as EnemyData
			if e.id.is_empty():
				errors.append("%s has empty 'id'" % file_path)
			elif registry.has(e.id):
				errors.append("Duplicate EnemyData id '%s' in %s" % [e.id, file_path])
			else:
				registry[e.id] = e
			if e.enemy_name.is_empty():
				errors.append("%s has empty 'enemy_name'" % file_path)
			if e.max_hp <= 0:
				errors.append("%s has non-positive max_hp" % file_path)
			if e.attack <= 0:
				errors.append("%s has non-positive attack" % file_path)
			if e.xp_reward < 0:
				errors.append("%s has negative xp_reward" % file_path)
			if e.gold_reward < 0:
				errors.append("%s has negative gold_reward" % file_path)

		"QuestData":
			if not res is QuestData:
				errors.append("%s is not a QuestData" % file_path)
				return
			var q: QuestData = res as QuestData
			if q.id.is_empty():
				errors.append("%s has empty 'id'" % file_path)
			elif registry.has(q.id):
				errors.append("Duplicate QuestData id '%s' in %s" % [q.id, file_path])
			else:
				registry[q.id] = q
			if q.quest_name.is_empty():
				errors.append("%s has empty 'quest_name'" % file_path)
			if q.stages.is_empty():
				errors.append("%s has no stages defined" % file_path)
