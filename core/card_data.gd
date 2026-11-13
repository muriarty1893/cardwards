class_name CardData
extends Resource
## Static definition of one card. Immutable at runtime: game state references it, never edits it.

enum Kind { CREATURE, BUILDING, SPELL }
enum Land { MUSHROOM, EMBER, CANDY, FROST }

const LAND_NAMES: Array[String] = ["Mushroom Forest", "Ember Flats", "Candy Hills", "Frostpeak"]

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


func is_creature() -> bool:
	return kind == Kind.CREATURE
