class_name Fx
extends RefCounted
## Test helpers for building game states directly.


## Lanes default to Meadow (no home quirks), like the start of a real match.
static func blank(lands_a: Array[int] = [4, 4, 4, 4], lands_b: Array[int] = [4, 4, 4, 4]) -> GameState:
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
		ps.max_magic = 2
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
	c.ready = true
	c.bubble = &"bubble" in c.card.keywords
	c.hidden = &"hidden" in c.card.keywords
	s.players[p].lanes[lane].creature = c


static func put_building(s: GameState, p: int, lane: int, id: StringName) -> void:
	s.players[p].lanes[lane].building = CardDB.card(id)


## A test-only effect step; `extra` may set amount2, keyword, filter_kind, filter_land, combo.
static func eff(when: StringName, op: StringName, amount: int, who: StringName, extra: Dictionary = {}) -> EffectData:
	var e := EffectData.new()
	e.when = when
	e.op = op
	e.amount = amount
	e.who = who
	for k: String in extra:
		e.set(k, extra[k])
	return e


## A test-only level-1 Mushroom card.
static func card(id: StringName, kind: CardData.Kind, cost: int, atk: int, hp: int, keywords: Array[StringName] = [], effects: Array[EffectData] = []) -> CardData:
	var c := CardData.new()
	c.id = id
	c.display_name = String(id)
	c.kind = kind
	c.land = CardData.Land.MUSHROOM
	c.level = 1 if kind == CardData.Kind.CREATURE else 0
	c.cost = cost
	c.attack = atk
	c.health = hp
	c.keywords = keywords
	c.effects = effects
	return c


## Places a built creature that has been on the board since last turn.
static func put(s: GameState, p: int, lane: int, c: CardData) -> GameState.CreatureState:
	var cr := GameState.CreatureState.new()
	cr.card = c
	cr.played_turn = s.turn - 1
	cr.ready = true
	cr.bubble = &"bubble" in c.keywords
	cr.hidden = &"hidden" in c.keywords
	s.players[p].lanes[lane].creature = cr
	return cr


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


## Loads the real match scene (blaze_rush vs deep_freeze, seed 1) at high playback speed and
## waits for the human's turn. Returns null if the human turn is never reached.
static func load_match() -> MatchController:
	var tree := Engine.get_main_loop() as SceneTree
	var session: Node = tree.root.get_node("Session")
	session.set("player_deck", &"blaze_rush")
	session.set("ai_deck", &"deep_freeze")
	session.set("seed", 1)
	var m := (load("res://view/match.tscn") as PackedScene).instantiate() as MatchController
	tree.root.add_child(m)
	await tree.process_frame
	m.player.speed = 8.0
	m.pace = 8.0
	# Wait out the opening (and the AI's first turn if it won the coin flip).
	var waited: int = 0
	while (m.busy or m.state.active != MatchController.HUMAN) and waited < 3000:
		await tree.process_frame
		waited += 1
	if m.busy or m.state.active != MatchController.HUMAN:
		return null
	return m
