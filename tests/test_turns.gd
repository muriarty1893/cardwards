extends TestCase


func _hand_ids(ps: GameState.PlayerState) -> Array[StringName]:
	var out: Array[StringName] = []
	for c: CardData in ps.hand:
		out.append(c.id)
	return out


func test_setup() -> bool:
	var a: DeckData = CardDB.deck(&"grove_guard")
	var b: DeckData = CardDB.deck(&"blaze_rush")
	var s: GameState = Rules.setup(a, b, 42)
	for p: int in 2:
		assert_eq(s.players[p].hand.size(), 5 if p == s.first_player else 6, "hand 5, or 6 with Star Shard, p%d" % p)
		assert_eq(s.players[p].deck.size(), 25, "deck 25 p%d" % p)
		assert_eq(s.players[p].hero_hp, 25, "hero 25 p%d" % p)
	for i: int in 4:
		assert_eq(s.players[0].lanes[i].land, a.lands[i], "p0 land %d" % i)
		assert_eq(s.players[1].lanes[i].land, b.lands[i], "p1 land %d" % i)
	var s2: GameState = Rules.setup(a, b, 42)
	assert_eq(_hand_ids(s2.players[0]), _hand_ids(s.players[0]), "same seed same hand p0")
	assert_eq(_hand_ids(s2.players[1]), _hand_ids(s.players[1]), "same seed same hand p1")
	assert_eq(s2.first_player, s.first_player, "same seed same first player")
	var s3: GameState = Rules.setup(a, b, 43)
	assert_true(_hand_ids(s3.players[0]) != _hand_ids(s.players[0]) or _hand_ids(s3.players[1]) != _hand_ids(s.players[1]), "different seed differs")
	return true


func test_first_turn_no_draw() -> bool:
	var s: GameState = Rules.setup(CardDB.deck(&"grove_guard"), CardDB.deck(&"blaze_rush"), 5)
	var ev: Array[GameEvent] = Rules.start_turn(s)
	assert_eq(s.players[s.active].hand.size(), 5, "no draw on turn 1")
	assert_eq(s.players[s.active].magic, 1, "magic 1 on turn 1")
	assert_eq(ev[0].type, &"turn_started", "first event")
	return true


func test_second_turn_draws() -> bool:
	var s: GameState = Rules.setup(CardDB.deck(&"grove_guard"), CardDB.deck(&"blaze_rush"), 5)
	Rules.start_turn(s)
	var first: int = s.active
	var ev: Array[GameEvent] = Rules.apply(s, Action.end_turn(first))
	assert_eq(s.turn, 2, "turn 2")
	assert_eq(s.active, 1 - first, "other player active")
	assert_eq(s.players[s.active].hand.size(), 7, "drew 1 (6 with Star Shard)")
	assert_true(&"card_drawn" in Fx.types(ev), "card_drawn event")
	return true


func test_fatigue() -> bool:
	var s: GameState = Fx.blank()
	var ev: Array[GameEvent] = []
	Rules.draw(s, 0, ev)
	assert_eq(s.players[0].hero_hp, 23, "fatigue 2")
	assert_eq(ev[0].type, &"fatigue", "fatigue event")
	assert_eq(ev[0].data["amount"], 2, "fatigue amount")
	return true


func test_not_your_turn() -> bool:
	var s: GameState = Fx.blank()
	assert_eq(Rules.validate(s, Action.end_turn(1)), "Not your turn", "not your turn")
	return true


func test_action_roundtrip() -> bool:
	var a: Action = Action.play(1, 3, 2, [{"player": 0, "lane": 1}])
	var b: Action = Action.from_dict(a.to_dict())
	assert_eq(b.to_dict(), a.to_dict(), "play roundtrip")
	var c: Action = Action.attack(0, 2, 1, Action.Hit.CRIT, true)
	var d: Action = Action.from_dict(c.to_dict())
	assert_eq([d.type, d.player, d.lane, d.target_lane, d.hit, d.blocked], [Action.Type.ATTACK, 0, 2, 1, Action.Hit.CRIT, true], "attack roundtrip")
	return true


func _pass(s: GameState) -> void:
	Rules.apply(s, Action.end_turn(s.active))


func test_magic_curve_and_cap() -> bool:
	var s: GameState = Rules.setup(CardDB.deck(&"grove_guard"), CardDB.deck(&"blaze_rush"), 5)
	Rules.start_turn(s)
	var first: int = s.active
	var seen: Array[int] = []
	while seen.size() < 10:
		if s.active == first:
			seen.append(s.players[first].magic)
		_pass(s)
	assert_eq(seen, [1, 2, 3, 4, 5, 6, 7, 8, 8, 8] as Array[int], "curve to the cap")
	return true


func test_gain_magic_is_temporary() -> bool:
	var s: GameState = Fx.blank()
	Fx.fill_deck(s, 0, &"mossback", 5)
	Fx.fill_deck(s, 1, &"mossback", 5)
	s.players[0].max_magic = 3
	s.players[0].magic = 3
	Rules.apply(s, Action.play(0, Fx.give(s, 0, &"taffy_snail"), 0))
	assert_eq(s.players[0].magic, 2, "3 - 2 + 1")
	_pass(s)
	_pass(s)
	assert_eq(s.players[0].magic, 4, "next turn: max 4, refilled")
	return true


func test_star_shard_to_second_player() -> bool:
	var s: GameState = Rules.setup(CardDB.deck(&"grove_guard"), CardDB.deck(&"blaze_rush"), 9)
	var second: int = 1 - s.first_player
	assert_eq(s.players[second].hand.size(), 6, "second player 6 cards")
	assert_true(s.players[second].hand.has(CardDB.card(&"star_shard")), "has star shard")
	assert_true(not s.players[s.first_player].hand.has(CardDB.card(&"star_shard")), "first player has none")
	return true


func test_hand_limit_8() -> bool:
	assert_eq(GameState.HAND_LIMIT, 8, "limit 8")
	var s: GameState = Fx.blank()
	for i: int in 8:
		Fx.give(s, 0, &"mossback")
	Fx.fill_deck(s, 0, &"iceling", 1)
	var ev: Array[GameEvent] = []
	Rules.draw(s, 0, ev)
	assert_eq(s.players[0].hand.size(), 8, "still 8")
	assert_eq(ev[0].type, &"card_burned", "burned")
	assert_eq(s.players[0].discard.size(), 1, "burned to discard")
	return true


func test_new_creature_not_ready_until_next_turn() -> bool:
	var s: GameState = Fx.blank()
	Fx.fill_deck(s, 0, &"mossback", 5)
	Fx.fill_deck(s, 1, &"mossback", 5)
	Rules.apply(s, Action.play(0, Fx.give(s, 0, &"sporeling"), 0))
	var cr: GameState.CreatureState = s.players[0].lanes[0].creature
	assert_true(not cr.ready, "not ready when played")
	assert_true(not Rules.can_boop(s, 0, 0), "can't boop yet")
	assert_eq(Rules.validate(s, Action.boop(0, 0)), "Not ready yet", "message")
	_pass(s)
	_pass(s)
	assert_true(cr.ready and Rules.can_boop(s, 0, 0), "ready on its owner's next turn")
	Rules.apply(s, Action.boop(0, 0))
	assert_true(cr.booped and not Rules.can_boop(s, 0, 0), "booped once")
	return true


func test_cards_played_resets() -> bool:
	var s: GameState = Fx.blank()
	Fx.fill_deck(s, 0, &"mossback", 5)
	Fx.fill_deck(s, 1, &"mossback", 5)
	Rules.apply(s, Action.play(0, Fx.give(s, 0, &"star_shard"), -1))
	assert_eq(s.players[0].cards_played, 1, "counted")
	_pass(s)
	_pass(s)
	assert_eq(s.players[0].cards_played, 0, "reset on its turn")
	return true
