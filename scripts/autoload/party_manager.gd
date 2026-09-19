class_name PartyManagerAutoload
extends Node
## Manages party members, active formation, and reserve members.

signal party_member_added(member_id: String)
signal party_member_removed(member_id: String)
signal formation_changed

var active_members: Array[String] = ["ragg", "calindra"]
var reserve_members: Array[String] = []


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
