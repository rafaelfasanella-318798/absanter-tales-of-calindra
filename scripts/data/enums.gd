class_name Enums
extends RefCounted
## Global Enums and Constants for Absanter - Tales of Calindra

enum Element {
	NONE,
	PHYSICAL,
	FIRE,
	ICE,
	LIGHTNING,
	EARTH,
	LIGHT,
	DARK,
}

enum StatusEffect {
	NONE,
	POISON,
	PARALYSIS,
	SLEEP,
	SILENCE,
	BLIND,
	ATK_BUFF,
	ATK_DEBUFF,
	DEF_BUFF,
	DEF_DEBUFF,
	SPD_BUFF,
	SPD_DEBUFF,
}

enum ItemType {
	CONSUMABLE,
	WEAPON,
	ARMOR,
	ACCESSORY,
	KEY_ITEM,
	MATERIAL,
}

enum Direction {
	DOWN,
	LEFT,
	RIGHT,
	UP,
}

enum BattleState {
	INITIALIZING,
	TURN_START,
	SELECTING_ACTION,
	EXECUTING_ACTION,
	CHECK_END_CONDITION,
	VICTORY,
	DEFEAT,
	ESCAPE,
}
