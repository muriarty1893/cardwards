class_name CardData
extends Resource
## Static definition of one card. Immutable at runtime: game state references it, never edits it.

enum Kind { CREATURE, BUILDING, SPELL }
## NEUTRAL: cards of no land (Star Shard); never a land on the board.
enum Land { MUSHROOM, EMBER, CANDY, FROST, NEUTRAL }

const LAND_NAMES: Array[String] = ["Mushroom Forest", "Ember Flats", "Candy Hills", "Frostpeak", "Neutral"]

@export var id: StringName = &""
@export var display_name: String = ""
@export var kind: Kind = Kind.CREATURE
@export var land: Land = Land.MUSHROOM
@export var level: int = 0
@export var cost: int = 0
@export var attack: int = 0
@export var health: int = 0
## "", on_play, on_boop, on_destroyed, on_deal_damage, start_of_turn, end_of_turn, passive
@export var trigger: StringName = &""
@export var ability_id: StringName = &""
## none, any_creature, own_creature, own_empty_lane, own_two_creatures, discard_creature
@export var target: StringName = &"none"
@export_multiline var text: String = ""
## Printed keywords (Keywords.ORDER ids).
@export var keywords: Array[StringName] = []
@export var spell_power: int = 0
@export var effects: Array[EffectData] = []


func is_creature() -> bool:
	return kind == Kind.CREATURE


func effects_for(when_: StringName) -> Array[EffectData]:
	var out: Array[EffectData] = []
	for e: EffectData in effects:
		if e.when == when_:
			out.append(e)
	return out


func has_effect(when_: StringName) -> bool:
	for e: EffectData in effects:
		if e.when == when_:
			return true
	return false
