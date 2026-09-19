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
