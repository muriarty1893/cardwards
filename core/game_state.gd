class_name GameState
extends RefCounted
## The full state of one match. Pure data: no nodes, no visuals.

enum Phase { MAIN, ATTACK, OVER }

const START_HP := 25
const MAX_HP := 25
const START_HAND := 5
const HAND_LIMIT := 7
const MAGIC_PER_TURN := 2
const FATIGUE_DAMAGE := 2
const LANES := 4

var players: Array[PlayerState] = []
var active: int = 0
var first_player: int = 0
var turn: int = 1
var phase: Phase = Phase.MAIN
var winner: int = -1
var rng: RandomNumberGenerator = RandomNumberGenerator.new()


class PlayerState:
	extends RefCounted
	var hero_hp: int = START_HP
	var magic: int = 0
	var magic_cap: int = 0
	var deck: Array[CardData] = []
	var hand: Array[CardData] = []
	var discard: Array[CardData] = []
	var lanes: Array[LaneState] = []

	func clone() -> PlayerState:
		var p := PlayerState.new()
		p.hero_hp = hero_hp
		p.magic = magic
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
	## Attacked or booped this turn.
	var acted: bool = false
	var played_turn: int = 0

	func is_frozen() -> bool:
		return freeze_turn >= 0

	func clone() -> CreatureState:
		var c := CreatureState.new()
		c.card = card
		c.damage = damage
		c.freeze_turn = freeze_turn
		c.acted = acted
		c.played_turn = played_turn
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
	s.rng.seed = rng.seed
	s.rng.state = rng.state
	return s


func opponent(p: int) -> int:
	return 1 - p
