extends SceneTree
## CLI tool to run 1000 headless battles and report win rates and balance metrics.


func _init() -> void:
	print("==================================================")
	print("  Absanter - Simulador de 1000 Batalhas Headless  ")
	print("==================================================")

	# 1. Batalha regular (Ragg + Calindra vs Slime + Cave Bat)
	print("\n[1/2] Simulando 1000 batalhas comuns (Ragg & Calindra vs Slime & Morcego)...")
	var t0: int = Time.get_ticks_msec()
	var starter_res: Dictionary = BattleSimulator.simulate_battles(
		1000, ["ragg", "calindra"], ["slime", "cave_bat"]
	)
	var dt_starter: int = Time.get_ticks_msec() - t0

	print("Tempo de execucao: %d ms" % dt_starter)
	print("Vitorias: %d / %d" % [starter_res["victories"], starter_res["total_battles"]])
	print("Derrotas: %d / %d" % [starter_res["defeats"], starter_res["total_battles"]])
	print("Taxa de vitoria: %.2f%%" % (starter_res["win_rate"] * 100.0))
	print("Media de turnos: %.2f" % starter_res["average_rounds"])
	print("HP medio restante da party: %.2f%%" % (starter_res["average_party_hp_pct"] * 100.0))

	# 2. Batalha contra Mini-Chefe (Mímico de Kakariko)
	print("\n[2/2] Simulando 1000 batalhas contra Mini-Chefe (Ragg & Calindra vs Mímico)...")
	var t1: int = Time.get_ticks_msec()
	var mimic_res: Dictionary = BattleSimulator.simulate_battles(
		1000, ["ragg", "calindra"], ["kakariko_mimic"]
	)
	var dt_mimic: int = Time.get_ticks_msec() - t1

	print("Tempo de execucao: %d ms" % dt_mimic)
	print("Vitorias: %d / %d" % [mimic_res["victories"], mimic_res["total_battles"]])
	print("Derrotas: %d / %d" % [mimic_res["defeats"], mimic_res["total_battles"]])
	print("Taxa de vitoria: %.2f%%" % (mimic_res["win_rate"] * 100.0))
	print("Media de turnos: %.2f" % mimic_res["average_rounds"])
	print("HP medio restante da party: %.2f%%" % (mimic_res["average_party_hp_pct"] * 100.0))

	print("\n==================================================")
	print("  Simulacao concluida com sucesso!                ")
	print("==================================================")
	quit(0)
