class_name BaseMap
extends Node2D
## Base class for game world maps with spawn points and entity management.

@export var map_name: String = "Vila Kakariko"

@onready var player: Player = $Entities/Player
@onready var follower: Follower = $Entities/Follower
@onready var hud: HUD = $HUD
@onready var spawn_points: Node2D = $SpawnPoints


func _ready() -> void:
	EventBus.map_loaded.emit(map_name)
	_position_player_at_spawn()
	if hud != null:
		hud.show_location(map_name)


func _position_player_at_spawn() -> void:
	if player == null:
		return

	var pending_pos: Variant = GameState.get_flag("pending_player_pos", null)
	if pending_pos != null and pending_pos is Vector2 and pending_pos != Vector2.ZERO:
		player.global_position = pending_pos
		GameState.flags.erase("pending_player_pos")
		player.position_history.clear()
		player.position_history.append(player.global_position)
		if follower != null:
			follower.global_position = player.global_position + Vector2(-16, 0)
		return

	var spawn_id: String = GameState.get_flag("last_spawn_id", "default")
	if spawn_points != null:
		var target_marker: Marker2D = spawn_points.get_node_or_null(spawn_id) as Marker2D
		if target_marker == null:
			target_marker = spawn_points.get_node_or_null("default") as Marker2D

		if target_marker != null:
			player.global_position = target_marker.global_position
			player.position_history.clear()
			player.position_history.append(player.global_position)
			if follower != null:
				follower.global_position = player.global_position + Vector2(-16, 0)
