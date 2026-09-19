class_name EventBusAutoload
extends Node
## Central decoupled event bus for game-wide signals.

# Exploration signals
signal interaction_requested(interactable: Node)
signal player_moved(new_position: Vector2)
signal map_transition_requested(target_map: String, spawn_point_id: String)
signal map_loaded(map_name: String)

# Battle signals
signal battle_start_requested(battle_data: Dictionary)
signal battle_ended(victory: bool)
signal battle_turn_started(battler: Node)

# Dialogue signals
signal dialogue_started(dialogue_id: String)
signal dialogue_ended(dialogue_id: String)
signal dialogue_choice_selected(choice_index: int)

# Quest & Progression signals
signal quest_started(quest_id: String)
signal quest_updated(quest_id: String, stage: int)
signal quest_completed(quest_id: String)

# Inventory signals
signal item_added(item_id: String, quantity: int)
signal item_removed(item_id: String, quantity: int)
signal gold_changed(new_amount: int, delta: int)
