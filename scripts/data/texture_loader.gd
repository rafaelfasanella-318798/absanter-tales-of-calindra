class_name TextureLoader
extends RefCounted
## Utility to load and cache textures at runtime cleanly without editor import dependence.

static var _cache: Dictionary = {}


static func get_texture(path: String) -> Texture2D:
	if path in _cache:
		return _cache[path]

	var global_path: String = ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(path) or FileAccess.file_exists(global_path):
		var img: Image = Image.load_from_file(global_path)
		if img != null:
			var tex: ImageTexture = ImageTexture.create_from_image(img)
			_cache[path] = tex
			return tex

	push_warning("TextureLoader: Could not load texture from " + path)
	return null


static func get_kenney_tile(tile_index: int) -> Texture2D:
	var path: String = "res://assets/tilesets/placeholder/Tiles/tile_%04d.png" % tile_index
	return get_texture(path)


static func get_ui_tile(tile_index: int) -> Texture2D:
	var path: String = (
		"res://assets/ui/placeholder/Tiles/Large tiles/Thin outline/tile_%04d.png" % tile_index
	)
	return get_texture(path)
