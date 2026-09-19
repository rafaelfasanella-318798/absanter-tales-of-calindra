extends GutTest


func test_starter_battle_balance_100_runs() -> void:
	var result: Dictionary = BattleSimulator.simulate_battles(
		100, ["ragg", "calindra"], ["slime", "cave_bat"]
	)

	assert_gt(
		result["win_rate"],
		0.80,
		"Starter overworld battle (Ragg+Calindra vs Slime+Bat) win rate should be >= 80%"
	)
	assert_lt(
		result["average_rounds"],
		10.0,
		"Battle should be snappy and resolve in fewer than 10 rounds on average"
	)
	assert_gt(
		result["average_party_hp_pct"],
		0.40,
		"Party should comfortably survive regular encounters (> 40% average HP remaining)"
	)


func test_mimic_boss_battle_balance_50_runs() -> void:
	var result: Dictionary = BattleSimulator.simulate_battles(
		50, ["ragg", "calindra"], ["kakariko_mimic"]
	)

	assert_gt(
		result["win_rate"],
		0.65,
		"Mimic boss encounter should be challenging but winnable (>= 65% win rate)"
	)
	assert_lte(result["win_rate"], 1.0, "Win rate cannot exceed 100%")
