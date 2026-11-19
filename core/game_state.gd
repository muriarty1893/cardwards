class_name GameState
extends RefCounted
## The full state of one match. Pure data: no nodes, no visuals.

## CHOOSING: waiting for a Dream Up pick (only CHOOSE is legal).
enum Phase { MAIN, OVER, CHOOSING }

const START_HP := 25
const MAX_ARMOUR := 20
const MAX_HP := 25
const START_HAND := 5
const HAND_LIMIT := 8
## Max magic grows by 1 each turn up to this.
const MAGIC_CAP := 8
const MAGIC_CAP_MAX := 10
const FATIGUE_DAMAGE := 2
const LANES := 4

var players: Array[PlayerState] = []
var active: int = 0
var first_player: int = 0
var turn: int = 1
var phase: Phase = Phase.MAIN
var winner: int = -1
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
## Dream Up: the cards on offer and who picks.
var pending_choice: Array[CardData] = []
var pending_player: int = -1
## The field spell in play for both players (null: none) and who played it.
var field: CardData = null
var field_owner: int = -1


class PlayerState:
	extends RefCounted
	var hero_hp: int = START_HP
	## Soaks hero damage before HP (living board spec 7).
	var armour: int = 0
	var magic: int = 0
	var max_magic: int = 0
	## Draws from an empty deck so far; each one hurts 1 more (so healing can't stall a match).
	var fatigue: int = 0
	## Cards played this turn (for Combo).
	var cards_played: int = 0
	## Your next spell this turn costs this much less (Sugar High); cleared at the end of the turn.
	var spell_discount: int = 0
	## Highest max magic the turn growth reaches (Deep Roots raises it, up to MAGIC_CAP_MAX).
	var magic_cap: int = MAGIC_CAP
	var deck: Array[CardData] = []
	var hand: Array[CardData] = []
	var discard: Array[CardData] = []
	var lanes: Array[LaneState] = []

	func clone() -> PlayerState:
		var p := PlayerState.new()
		p.hero_hp = hero_hp
		p.armour = armour
		p.magic = magic
		p.max_magic = max_magic
		p.fatigue = fatigue
		p.cards_played = cards_played
		p.spell_discount = spell_discount
		p.magic_cap = magic_cap
		p.deck = deck.duplicate()
		p.hand = hand.duplicate()
		p.discard = discard.duplicate()
		for l: LaneState in lanes:
			p.lanes.append(l.clone())
		return p


class LaneState:
	extends RefCounted
	var land: int = 0
	var creature: CreatureState = null
	var building: CardData = null

	func clone() -> LaneState:
		var l := LaneState.new()
		l.land = land
		l.creature = creature.clone() if creature else null
		l.building = building
		return l


class CreatureState:
	extends RefCounted
	var card: CardData
	var damage: int = 0
	## Turn the freeze was applied; -1 when not frozen.
	var freeze_turn: int = -1
	var played_turn: int = 0
	## Keywords gained from effects (printed ones live on the card).
	var gained: Array[StringName] = []
	## Hushed: printed keywords and effects no longer count.
	var hushed: bool = false
	var atk_bonus: int = 0
	var hp_bonus: int = 0
	## Attack that lasts until the end of the turn (Grove Roar).
	var temp_atk: int = 0
	## Destroyed at the end of its owner's turn (Overheat).
	var doomed: bool = false
	## Bubble still up.
	var bubble: bool = false
	## Still hidden (not yet revealed by attacking or booping).
	var hidden: bool = false
	var second_wind_used: bool = false
	var attacks_used: int = 0
	var booped: bool = false
	## On its owner's board since the start of their turn.
	var ready: bool = false
	## Level 1..Levels.MAX and experience toward the next (living board spec 6).
	var level: int = 1
	var xp: int = 0

	func is_frozen() -> bool:
		return freeze_turn >= 0

	func clone() -> CreatureState:
		var c := CreatureState.new()
		c.card = card
		c.damage = damage
		c.freeze_turn = freeze_turn
		c.played_turn = played_turn
		c.gained = gained.duplicate()
		c.hushed = hushed
		c.atk_bonus = atk_bonus
		c.hp_bonus = hp_bonus
		c.temp_atk = temp_atk
		c.doomed = doomed
		c.bubble = bubble
		c.hidden = hidden
		c.second_wind_used = second_wind_used
		c.attacks_used = attacks_used
		c.booped = booped
		c.ready = ready
		c.level = level
		c.xp = xp
		return c


func clone() -> GameState:
	var s := GameState.new()
	for p: PlayerState in players:
		s.players.append(p.clone())
	s.active = active
	s.first_player = first_player
	s.turn = turn
	s.phase = phase
	s.winner = winner
	s.pending_choice = pending_choice.duplicate()
	s.pending_player = pending_player
	s.field = field
	s.field_owner = field_owner
	s.rng.seed = rng.seed
	s.rng.state = rng.state
	return s


func opponent(p: int) -> int:
	return 1 - p


## md5 of every field of the match (cards by id, the random generator included). Two games that
## agree on this are in the same state; online play compares it after every move.
func digest() -> String:
	return var_to_str(_dump(self)).md5_text()


## Generic so fields added later are covered without touching this: script variables of the state
## classes, cards as their id, the generator as seed + state.
static func _dump(v: Variant) -> Variant:
	if v is CardData:
		return String((v as CardData).id)
	if v is RandomNumberGenerator:
		return [(v as RandomNumberGenerator).seed, (v as RandomNumberGenerator).state]
	if v is Array:
		var out: Array = []
		for x: Variant in v:
			out.append(_dump(x))
		return out
	if v is Dictionary:
		var keys: Array = (v as Dictionary).keys()
		keys.sort()
		var pairs: Array = []
		for k: Variant in keys:
			pairs.append([k, _dump((v as Dictionary)[k])])
		return pairs
	if v is Object:
		if v == null:
			return null
		var fields: Array = []
		for prop: Dictionary in (v as Object).get_property_list():
			if int(prop["usage"]) & PROPERTY_USAGE_SCRIPT_VARIABLE:
				fields.append([prop["name"], _dump((v as Object).get(prop["name"]))])
		return fields
	return v
