class_name PartyManagerAutoload
extends Node
## Manages party members, active formation, reserve members, and character equipment.

signal party_member_added(member_id: String)
signal party_member_removed(member_id: String)
signal formation_changed
signal equipment_changed(character_id: String, slot: String, item_id: String)

const VALID_SLOTS: Array[String] = ["weapon", "armor", "accessory"]

var active_members: Array[String] = ["ragg", "calindra"]
var reserve_members: Array[String] = []

## Equipment mapping: character_id -> { "weapon": item_id, "armor": item_id, "accessory": item_id }
var character_equipment: Dictionary = {
	"ragg": {"weapon": "", "armor": "", "accessory": ""},
	"calindra": {"weapon": "", "armor": "", "accessory": ""}
}


func add_member(member_id: String) -> void:
	if member_id not in active_members and member_id not in reserve_members:
		active_members.append(member_id)
		party_member_added.emit(member_id)


func remove_member(member_id: String) -> void:
	if member_id in active_members:
		active_members.erase(member_id)
		party_member_removed.emit(member_id)
	elif member_id in reserve_members:
		reserve_members.erase(member_id)
		party_member_removed.emit(member_id)


func swap_members(idx_a: int, idx_b: int) -> void:
	if (
		idx_a >= 0
		and idx_a < active_members.size()
		and idx_b >= 0
		and idx_b < active_members.size()
	):
		var temp: String = active_members[idx_a]
		active_members[idx_a] = active_members[idx_b]
		active_members[idx_b] = temp
		formation_changed.emit()


func move_to_reserve(member_id: String) -> void:
	if member_id in active_members and active_members.size() > 1:
		active_members.erase(member_id)
		reserve_members.append(member_id)
		formation_changed.emit()


func move_to_active(member_id: String) -> void:
	if member_id in reserve_members:
		reserve_members.erase(member_id)
		active_members.append(member_id)
		formation_changed.emit()


func is_in_party(member_id: String) -> bool:
	return member_id in active_members or member_id in reserve_members


func is_active(member_id: String) -> bool:
	return member_id in active_members


func get_leader_id() -> String:
	return active_members[0] if not active_members.is_empty() else ""


func recruit_member(member_id: String, to_active: bool = true) -> void:
	if is_in_party(member_id):
		return
	if to_active:
		active_members.append(member_id)
	else:
		reserve_members.append(member_id)
	party_member_added.emit(member_id)
	formation_changed.emit()


func dismiss_member(member_id: String) -> void:
	remove_member(member_id)
	formation_changed.emit()


func reset_party() -> void:
	active_members = ["ragg", "calindra"]
	reserve_members.clear()
	character_equipment = {
		"ragg": {"weapon": "", "armor": "", "accessory": ""},
		"calindra": {"weapon": "", "armor": "", "accessory": ""}
	}
	formation_changed.emit()


func get_character_equipment(character_id: String) -> Dictionary:
	if not character_equipment.has(character_id):
		character_equipment[character_id] = {"weapon": "", "armor": "", "accessory": ""}
	return character_equipment[character_id]


func get_equipped_item(character_id: String, slot: String) -> String:
	var equip_dict: Dictionary = get_character_equipment(character_id)
	return equip_dict.get(slot, "")


func can_equip(character_id: String, item_id: String) -> bool:
	if item_id.is_empty():
		return false
	var path: String = "res://data/items/%s.tres" % item_id
	if not ResourceLoader.exists(path):
		return false
	var item: ItemData = load(path) as ItemData
	if item == null:
		return false
	if item.equip_slot not in VALID_SLOTS:
		return false
	if not item.allowed_characters.is_empty() and character_id not in item.allowed_characters:
		return false
	return true


func equip(character_id: String, item_id: String, from_inventory: bool = true) -> bool:
	if not can_equip(character_id, item_id):
		return false

	var path: String = "res://data/items/%s.tres" % item_id
	var item: ItemData = load(path) as ItemData
	var slot: String = item.equip_slot

	if from_inventory and not InventoryManager.has_item(item_id, 1):
		return false

	var equip_dict: Dictionary = get_character_equipment(character_id)
	var current_item: String = equip_dict.get(slot, "")

	if not current_item.is_empty():
		InventoryManager.add_item(current_item, 1)

	if from_inventory:
		InventoryManager.remove_item(item_id, 1)

	equip_dict[slot] = item_id
	equipment_changed.emit(character_id, slot, item_id)
	return true


func unequip(character_id: String, slot: String, return_to_inventory: bool = true) -> bool:
	if slot not in VALID_SLOTS:
		return false
	var equip_dict: Dictionary = get_character_equipment(character_id)
	var current_item: String = equip_dict.get(slot, "")
	if current_item.is_empty():
		return false

	equip_dict[slot] = ""
	if return_to_inventory:
		InventoryManager.add_item(current_item, 1)

	equipment_changed.emit(character_id, slot, "")
	return true


func get_equipment_bonuses(character_id: String) -> Dictionary:
	var totals: Dictionary = {"hp": 0, "mp": 0, "attack": 0, "defense": 0, "magic": 0, "speed": 0}
	var equip_dict: Dictionary = get_character_equipment(character_id)
	for slot in VALID_SLOTS:
		var item_id: String = equip_dict.get(slot, "")
		if item_id.is_empty():
			continue
		var path: String = "res://data/items/%s.tres" % item_id
		if ResourceLoader.exists(path):
			var item: ItemData = load(path) as ItemData
			if item != null:
				totals["hp"] += item.bonus_hp
				totals["mp"] += item.bonus_mp
				totals["attack"] += item.bonus_attack
				totals["defense"] += item.bonus_defense
				totals["magic"] += item.bonus_magic
				totals["speed"] += item.bonus_speed
	return totals


func get_effective_stats(character_id: String, base_data: CharacterData) -> Dictionary:
	var bonuses: Dictionary = get_equipment_bonuses(character_id)
	if base_data == null:
		return {
			"level": 1,
			"max_hp": bonuses["hp"],
			"max_mp": bonuses["mp"],
			"attack": bonuses["attack"],
			"defense": bonuses["defense"],
			"magic": bonuses["magic"],
			"speed": bonuses["speed"],
			"bonuses": bonuses
		}
	return {
		"level": base_data.level,
		"max_hp": base_data.max_hp + bonuses["hp"],
		"max_mp": base_data.max_mp + bonuses["mp"],
		"attack": base_data.attack + bonuses["attack"],
		"defense": base_data.defense + bonuses["defense"],
		"magic": base_data.magic + bonuses["magic"],
		"speed": base_data.speed + bonuses["speed"],
		"bonuses": bonuses
	}


func preview_equipment_change(
	character_id: String, base_data: CharacterData, new_item_id: String, target_slot: String = ""
) -> Dictionary:
	var cur_effective: Dictionary = get_effective_stats(character_id, base_data)
	var slot: String = target_slot
	var new_item_data: ItemData = null
	if not new_item_id.is_empty():
		var path: String = "res://data/items/%s.tres" % new_item_id
		if ResourceLoader.exists(path):
			new_item_data = load(path) as ItemData
			if new_item_data != null and slot.is_empty():
				slot = new_item_data.equip_slot

	var current_item_id: String = (
		get_equipped_item(character_id, slot) if not slot.is_empty() else ""
	)
	var current_item_data: ItemData = null
	if not current_item_id.is_empty():
		var cur_path: String = "res://data/items/%s.tres" % current_item_id
		if ResourceLoader.exists(cur_path):
			current_item_data = load(cur_path) as ItemData

	var cur_hp_bonus: int = current_item_data.bonus_hp if current_item_data != null else 0
	var cur_mp_bonus: int = current_item_data.bonus_mp if current_item_data != null else 0
	var cur_atk_bonus: int = current_item_data.bonus_attack if current_item_data != null else 0
	var cur_def_bonus: int = current_item_data.bonus_defense if current_item_data != null else 0
	var cur_mag_bonus: int = current_item_data.bonus_magic if current_item_data != null else 0
	var cur_spd_bonus: int = current_item_data.bonus_speed if current_item_data != null else 0

	var new_hp_bonus: int = new_item_data.bonus_hp if new_item_data != null else 0
	var new_mp_bonus: int = new_item_data.bonus_mp if new_item_data != null else 0
	var new_atk_bonus: int = new_item_data.bonus_attack if new_item_data != null else 0
	var new_def_bonus: int = new_item_data.bonus_defense if new_item_data != null else 0
	var new_mag_bonus: int = new_item_data.bonus_magic if new_item_data != null else 0
	var new_spd_bonus: int = new_item_data.bonus_speed if new_item_data != null else 0

	var diff: Dictionary = {
		"hp": new_hp_bonus - cur_hp_bonus,
		"mp": new_mp_bonus - cur_mp_bonus,
		"attack": new_atk_bonus - cur_atk_bonus,
		"defense": new_def_bonus - cur_def_bonus,
		"magic": new_mag_bonus - cur_mag_bonus,
		"speed": new_spd_bonus - cur_spd_bonus
	}

	var preview_stats: Dictionary = {
		"level": cur_effective["level"],
		"max_hp": cur_effective["max_hp"] + diff["hp"],
		"max_mp": cur_effective["max_mp"] + diff["mp"],
		"attack": cur_effective["attack"] + diff["attack"],
		"defense": cur_effective["defense"] + diff["defense"],
		"magic": cur_effective["magic"] + diff["magic"],
		"speed": cur_effective["speed"] + diff["speed"]
	}

	return {"current_stats": cur_effective, "preview_stats": preview_stats, "diff": diff}
