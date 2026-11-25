class_name GameState
extends RefCounted
## The full state of one match. Pure data: no nodes, no visuals.

## CHOOSING: waiting for a Dream Up pick (only CHOOSE is legal).
enum Phase { MAIN, OVER, CHOOSING }

const START_HP := 40
const MAX_ARMOUR := 20
const MAX_HP := 40
const START_HAND := 5
const HAND_LIMIT := 8
## Max magic grows by 1 each turn up to this.
const MAGIC_CAP := 10
const MAGIC_CAP_MAX := 15
const FATIGUE_DAMAGE := 2
const LANES := 4
## Creature spots per player: 0..3 are the lanes' main creatures, 4..7 their followers (a pack
## card's companion shares the lane; Dark Moon spec 2.1). Spot k is in lane k % LANES.
const SPOTS := 8

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
## The pending choice is a Dark Gift: the pick gets a random Gifts bonus.
var pending_gift: bool = false
## &"" for a Dream Up card pick; &"direction" for Dark Moon's left (0) / right (1).
var pending_kind: StringName = &""
## Choices waiting behind the pending one (echoed Dream Ups): {"player", "kind", "land", "gift"}.
var pending_queue: Array[Dictionary] = []
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
	## Your next N spells happen twice (next_spell_twice).
	var spell_twice: int = 0
	## Highest max magic the turn growth reaches (Deep Roots raises it, up to MAGIC_CAP_MAX).
	var magic_cap: int = MAGIC_CAP
	var deck: Array[CardData] = []
	var hand: Array[CardData] = []
	var discard: Array[CardData] = []
	var lanes: Array[LaneState] = []
	## What happened this game (Dark Moon spec 3.2), kept by GameHistory: "spells" (ids in cast
	## order), "spell_lands" (their lands), "deaths_own", "stolen", "start_size",
	## "start_no_dupes", "start_ids".
	var history: Dictionary = GameHistory.fresh()

	## The creature in a spot (0..3 main, 4..7 follower), or null.
	func at(spot: int) -> CreatureState:
		if spot < 0 or spot >= SPOTS:
			return null
		var l: LaneState = lanes[spot % LANES]
		return l.creature if spot < LANES else l.follower

	func put(spot: int, cr: CreatureState) -> void:
		if spot < LANES:
			lanes[spot].creature = cr
		else:
			lanes[spot - LANES].follower = cr

	## The lane a spot is in.
	func lane(spot: int) -> LaneState:
		return lanes[spot % LANES]

	## Occupied spots, mains first (0..3) then followers (4..7).
	func creature_spots() -> Array[int]:
		var out: Array[int] = []
		for i: int in SPOTS:
			if at(i) != null:
				out.append(i)
		return out

	func clone() -> PlayerState:
		var p := PlayerState.new()
		p.hero_hp = hero_hp
		p.armour = armour
		p.magic = magic
		p.max_magic = max_magic
		p.fatigue = fatigue
		p.cards_played = cards_played
		p.spell_discount = spell_discount
		p.spell_twice = spell_twice
		p.magic_cap = magic_cap
		p.deck = deck.duplicate()
		p.hand = hand.duplicate()
		p.discard = discard.duplicate()
		for l: LaneState in lanes:
			p.lanes.append(l.clone())
		p.history = history.duplicate(true)
		return p


class LaneState:
	extends RefCounted
	var land: int = 0
	var creature: CreatureState = null
	## A pack card's follower sharing this lane (spot lane + LANES), or null. Only set while
	## `creature` is set: when the main creature leaves, the follower moves up.
	var follower: CreatureState = null
	var building: CardData = null

	func clone() -> LaneState:
		var l := LaneState.new()
		l.land = land
		l.creature = creature.clone() if creature else null
		l.follower = follower.clone() if follower else null
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
	s.pending_gift = pending_gift
	s.pending_kind = pending_kind
	s.pending_queue = pending_queue.duplicate(true)
	s.field = field
	s.field_owner = field_owner
	s.rng.seed = rng.seed
	s.rng.state = rng.state
	return s


## The lane a creature spot is in.
static func lane_of(spot: int) -> int:
	return spot % LANES


static func is_follower(spot: int) -> bool:
	return spot >= LANES


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
		var cd := v as CardData
		return String(cd.id) if cd.changes.is_empty() else [String(cd.id), _dump(cd.changes)]
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
