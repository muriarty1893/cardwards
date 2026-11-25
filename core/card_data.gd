class_name CardData
extends Resource
## Static definition of one card. Immutable at runtime: game state references it, never edits it.

enum Kind { CREATURE, BUILDING, SPELL }
## NEUTRAL: cards of no land (Star Shard). On the board it is Meadow, the bare land every lane
## starts as (Lands.MEADOW). DUNES came later and sits after NEUTRAL, so older data keeps its numbers.
enum Land { MUSHROOM, EMBER, CANDY, FROST, NEUTRAL, DUNES }

const LAND_NAMES: Array[String] = ["Mushroom Forest", "Ember Flats", "Candy Hills", "Frostpeak", "Neutral", "Sunny Dunes"]
## The lands cards and lanes can have (all but NEUTRAL), in display order.
const REAL_LANDS: Array[int] = [Land.MUSHROOM, Land.EMBER, Land.CANDY, Land.FROST, Land.DUNES]

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
## Merging (card expansion 2, spec 4): played onto your creature `merge_with`, this card merges with it into
## `merges_into`. Both partners name each other.
@export var merge_with: StringName = &""
@export var merges_into: StringName = &""
## False for merged forms and tokens: never in decks, the deck builder or Dream Up.
@export var collectible: bool = true
## Legendary: at most 1 copy per deck; gold-crowned frame.
@export var legendary: bool = false
## False only for cards that can never be put in a deck (Star Shard).
@export var deck_legal: bool = true
## A deck holding this card may have 40 cards instead of 30.
@export var allows_40: bool = false
## Curse: a bad card made for the rival (their hand or deck).
@export var curse: bool = false
## A changed copy (Dark Moon spec 3.1): how it differs from the printed card with the same id.
## Keys: "cost", "attack", "health" (int deltas), "keywords" (Array[StringName] gained),
## "gift" (StringName, a Dark Gift bonus). Empty for printed cards. Made only by CardDB.variant.
var changes: Dictionary = {}
## Pack (Dark Moon spec 2.1): the token that enters this creature's lane as its follower.
@export var follower_id: StringName = &""


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
