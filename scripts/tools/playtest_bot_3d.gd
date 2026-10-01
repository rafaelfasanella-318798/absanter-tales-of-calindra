class_name PlaytestBot3D
extends RefCounted
## Autonomous playtest agent that plays 3D exploration and battles,
## detecting softlocks, infinite loops, and input stalls.

var log_messages: Array[String] = []


func log_event(msg: String) -> void:
	log_messages.append(msg)


## Plays a Battle3D instance autonomously to completion (victory or defeat).
## Returns true if battle finished normally, false if timed out / softlocked.
func play_battle_to_completion(
	battle: Battle3D, max_frames: int = 1200, preferred_action: String = "combo"
) -> Dictionary:
	var frames: int = 0
	var commands_executed: int = 0
	var delta: float = 0.033  # ~30 fps simulated

	log_event("Iniciando playtest de batalha...")

	while frames < max_frames and not battle.is_battle_over:
		frames += 1
		battle._process(delta)

		# Se um herói está aguardando comando
		if battle.is_time_stopped and battle.command_panel.visible:
			var active_idx: int = battle.active_player_index
			if active_idx < 0:
				log_event("ERRO: Menu visível mas active_player_index < 0 no frame %d" % frames)
				return {"success": false, "reason": "invalid_active_player_index", "frames": frames}

			var living_enemies: Array[int] = battle._get_living_enemy_indices()
			if living_enemies.is_empty():
				# Se não há inimigos vivos, o jogo deve encerrar a batalha
				battle._check_battle_end()
				continue

			var target_idx: int = living_enemies[0]
			var action: String = preferred_action

			# Alterna entre combo e critical para testar ambos
			if commands_executed % 3 == 1:
				action = "critical"
			elif commands_executed % 3 == 2 and commands_executed % 6 == 2:
				action = "defend"

			if action == "defend":
				battle._on_defend_chosen()
				log_event("Frame %d: Herói %d escolheu DEFEND" % [frames, active_idx])
			elif action == "evade":
				battle._on_evade_chosen()
				log_event("Frame %d: Herói %d escolheu EVADE" % [frames, active_idx])
			else:
				battle._on_target_selected(action, target_idx)
				log_event(
					(
						"Frame %d: Herói %d usou %s no alvo %d"
						% [frames, active_idx, action, target_idx]
					)
				)

			commands_executed += 1

	var success: bool = battle.is_battle_over
	var outcome: String = "timeout"
	if success:
		if battle.victory_panel != null and battle.victory_panel.visible:
			outcome = "victory"
		elif battle.defeat_panel != null and battle.defeat_panel.visible:
			outcome = "defeat"
		else:
			outcome = "ended"

	log_event(
		(
			"Playtest de batalha concluído. Resultado: %s em %d frames com %d comandos"
			% [outcome, frames, commands_executed]
		)
	)

	return {
		"success": success,
		"outcome": outcome,
		"frames": frames,
		"commands_executed": commands_executed,
		"log": log_messages,
	}
