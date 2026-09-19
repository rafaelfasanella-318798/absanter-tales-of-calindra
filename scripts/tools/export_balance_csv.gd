class_name BalanceExporter
extends RefCounted
## Exports balance statistics of characters and enemies to a CSV summary table.

const DEFAULT_TARGET_PATH: String = "res://data/balance_summary.csv"


static func export_csv(target_path: String = DEFAULT_TARGET_PATH) -> bool:
	var rows: Array[String] = []
	rows.append("category,id,name,level,hp,mp,atk,def,mag,spd,xp_reward,gold_reward")

	# Characters
	var char_dir: DirAccess = DirAccess.open("res://data/characters/")
	if char_dir != null:
		char_dir.list_dir_begin()
		var file_name: String = char_dir.get_next()
		while file_name != "":
			if not char_dir.current_is_dir() and file_name.ends_with(".tres"):
				var c: CharacterData = load("res://data/characters/" + file_name) as CharacterData
				if c != null:
					rows.append(
						(
							'character,%s,"%s",%d,%d,%d,%d,%d,%d,%d,0,0'
							% [
								c.id,
								c.character_name,
								c.level,
								c.max_hp,
								c.max_mp,
								c.attack,
								c.defense,
								c.magic,
								c.speed
							]
						)
					)
			file_name = char_dir.get_next()
		char_dir.list_dir_end()

	# Enemies
	var enemy_dir: DirAccess = DirAccess.open("res://data/enemies/")
	if enemy_dir != null:
		enemy_dir.list_dir_begin()
		var file_name: String = enemy_dir.get_next()
		while file_name != "":
			if not enemy_dir.current_is_dir() and file_name.ends_with(".tres"):
				var e: EnemyData = load("res://data/enemies/" + file_name) as EnemyData
				if e != null:
					rows.append(
						(
							'enemy,%s,"%s",1,%d,%d,%d,%d,%d,%d,%d,%d'
							% [
								e.id,
								e.enemy_name,
								e.max_hp,
								e.max_mp,
								e.attack,
								e.defense,
								e.magic,
								e.speed,
								e.xp_reward,
								e.gold_reward
							]
						)
					)
			file_name = enemy_dir.get_next()
		enemy_dir.list_dir_end()

	var content: String = "\n".join(rows) + "\n"
	var file: FileAccess = FileAccess.open(target_path, FileAccess.WRITE)
	if file == null:
		return false

	file.store_string(content)
	file.close()
	return true
