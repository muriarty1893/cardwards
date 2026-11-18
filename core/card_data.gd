class_name CardData
extends Resource
## Static definition of one card. Immutable at runtime: game state references it, never edits it.

enum Kind { CREATURE, BUILDING, SPELL }
## NEUTRAL: cards of no land (Star Shard). On the board it is Meadow, the bare land every lane
## starts as (Lands.MEADOW).
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
## Printed keywords (Keywords.ORDER ids).
@export var keywords: Array[StringName] = []
@export var spell_power: int = 0
## Creature tribe (Tribes.ORDER id), &"" for none.
@export var tribe: StringName = &""
## Field spell: stays in play for both players until another field replaces it.
@export var field: bool = false
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
