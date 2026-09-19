extends GutTest

const ALL_SCENES: Array[String] = [
	"res://scenes/battle/battler.tscn",
	"res://scenes/battle/battle_scene.tscn",
	"res://scenes/battle/floating_text.tscn",
	"res://scenes/main/main.tscn",
	"res://scenes/ui/debug_console.tscn",
	"res://scenes/ui/dialogue_box.tscn",
	"res://scenes/ui/hud.tscn",
	"res://scenes/ui/pause_menu.tscn",
	"res://scenes/ui/shop_menu.tscn",
	"res://scenes/world/chest.tscn",
	"res://scenes/world/door.tscn",
	"res://scenes/world/enemy_wanderer.tscn",
	"res://scenes/world/follower.tscn",
	"res://scenes/world/kakariko.tscn",
	"res://scenes/world/kakariko_boss_room.tscn",
	"res://scenes/world/kakariko_cave.tscn",
	"res://scenes/world/kakariko_house.tscn",
	"res://scenes/world/npc.tscn",
	"res://scenes/world/player.tscn",
	"res://scenes/world/save_point.tscn"
]


func test_all_scenes_instantiate_cleanly() -> void:
	for scene_path in ALL_SCENES:
		assert_true(ResourceLoader.exists(scene_path), "Scene file must exist: %s" % scene_path)
		var packed: PackedScene = load(scene_path) as PackedScene
		assert_not_null(packed, "Failed to load packed scene: %s" % scene_path)
		if packed != null:
			var node: Node = packed.instantiate()
			assert_not_null(node, "Failed to instantiate scene: %s" % scene_path)
			add_child_autofree(node)
