class_name Fx
extends RefCounted
## Test helpers for building game states directly.


static func blank(lands_a: Array[int] = [0, 1, 2, 3], lands_b: Array[int] = [0, 1, 2, 3]) -> GameState:
	var s := GameState.new()
	s.rng.seed = 1
	for p: int in 2:
		var ps := GameState.PlayerState.new()
		var lands: Array[int] = lands_a if p == 0 else lands_b
		for i: int in 4:
			var lane := GameState.LaneState.new()
			lane.land = lands[i]
			ps.lanes.append(lane)
		ps.magic = 2
		ps.magic_cap = 2
		s.players.append(ps)
	s.turn = 3
	s.active = 0
	s.first_player = 0
	s.phase = GameState.Phase.MAIN
	return s


static func put_creature(s: GameState, p: int, lane: int, id: StringName, damage: int = 0) -> void:
	var c := GameState.CreatureState.new()
	c.card = CardDB.card(id)
	c.damage = damage
	c.played_turn = s.turn - 1
	s.players[p].lanes[lane].creature = c


static func put_building(s: GameState, p: int, lane: int, id: StringName) -> void:
	s.players[p].lanes[lane].building = CardDB.card(id)


static func give(s: GameState, p: int, id: StringName) -> int:
	s.players[p].hand.append(CardDB.card(id))
	return s.players[p].hand.size() - 1


static func types(events: Array[GameEvent]) -> Array[StringName]:
	var out: Array[StringName] = []
	for e: GameEvent in events:
		out.append(e.type)
	return out


static func fill_deck(s: GameState, p: int, id: StringName, n: int) -> void:
	for i: int in n:
		s.players[p].deck.append(CardDB.card(id))
