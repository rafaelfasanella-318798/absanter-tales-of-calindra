extends GutTest

var kakariko_scene: PackedScene = preload("res://scenes/world/kakariko.tscn")
var house_scene: PackedScene = preload("res://scenes/world/kakariko_house.tscn")


func test_kakariko_map_loads_and_spawns_entities() -> void:
	var kakariko: KakarikoMap = kakariko_scene.instantiate() as KakarikoMap
	assert_not_null(kakariko, "Kakariko scene should instantiate")
	add_child_autofree(kakariko)

	var player: Player = kakariko.get_node_or_null("Entities/Player") as Player
	assert_not_null(player, "Player should be spawned in Kakariko")

	var follower: Follower = kakariko.get_node_or_null("Entities/Follower") as Follower
	assert_not_null(follower, "Calindra follower should be spawned in Kakariko")

	var tav: NPC = kakariko.get_node_or_null("Entities/Tav") as NPC
	assert_not_null(tav, "Tav NPC should exist in Kakariko")

	var mimic: Chest = kakariko.get_node_or_null("Entities/MimicChest") as Chest
	assert_not_null(mimic, "Mimic Chest should exist in Kakariko")


func test_kakariko_house_interior_loads() -> void:
	var house: KakarikoHouseMap = house_scene.instantiate() as KakarikoHouseMap
	assert_not_null(house, "Kakariko House scene should instantiate")
	add_child_autofree(house)

	var door: Door = house.get_node_or_null("ExitDoor") as Door
	assert_not_null(door, "Exit door to village should exist in house")
	assert_eq(
		door.target_scene_path,
		"res://scenes/world/kakariko.tscn",
		"Door target should point back to Kakariko"
	)
