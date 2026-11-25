extends TestCase
## Dark Moon spec 2.2 (the ring turn) and 2.3 (stealing).


func _moon(s: GameState, dir_choice: int) -> Array[GameEvent]:
	s.players[0].hand.append(CardDB.card(&"dark_moon"))
	s.players[0].magic = 10
	var ev: Array[GameEvent] = Rules.apply(s, Action.play(0, s.players[0].hand.size() - 1, -1))
	assert_eq(s.phase, GameState.Phase.CHOOSING, "choose a direction")
	assert_eq(s.pending_kind, &"direction", "a direction choice")
	assert_eq(s.pending_choice.size(), 2, "left or right")
	ev.append_array(Rules.apply(s, Action.choose(0, dir_choice)))
	return ev


func test_ring_order() -> bool:
	assert_eq(Rules.ring(0), [[0, 0], [0, 1], [0, 2], [0, 3], [1, 3], [1, 2], [1, 1], [1, 0]], "your lanes, then theirs back")
	return true


func test_right_turn_moves_to_next_occupied() -> bool:
	var s: GameState = Fx.blank()
	Fx.put_creature(s, 0, 0, &"gumdrop")
	Fx.put_creature(s, 0, 2, &"magmaw")
	Fx.put_creature(s, 1, 3, &"sporeling")
	var ev: Array[GameEvent] = _moon(s, 1)
	assert_eq(s.players[0].at(2).card.id, &"gumdrop", "(0,0) -> (0,2)")
	assert_eq(s.players[1].at(3).card.id, &"magmaw", "(0,2) -> (1,3): changes sides")
	assert_eq(s.players[0].at(0).card.id, &"sporeling", "(1,3) -> (0,0): the loop wraps")
	assert_true(not s.players[1].at(3).ready, "a creature that changed sides can't attack this turn")
	assert_true(s.players[0].at(2).ready, "one that stayed keeps its readiness")
	assert_true(&"dark_moon" in Fx.types(ev), "event for the view")
	return true


func test_left_turn() -> bool:
	var s: GameState = Fx.blank()
	Fx.put_creature(s, 0, 0, &"gumdrop")
	Fx.put_creature(s, 1, 0, &"magmaw")
	Fx.put_creature(s, 1, 2, &"sporeling")
	_moon(s, 0)
	# ring occupied: (0,0) gumdrop, (1,2) sporeling, (1,0) magmaw. Left: each moves to the previous occupied.
	assert_eq(s.players[1].at(0).card.id, &"gumdrop", "(0,0) -> (1,0)")
	assert_eq(s.players[1].at(2).card.id, &"magmaw", "(1,0) -> (1,2)")
	assert_eq(s.players[0].at(0).card.id, &"sporeling", "(1,2) -> (0,0)")
	return true


func test_followers_travel_and_buildings_stay() -> bool:
	var s: GameState = Fx.blank()
	Fx.put_creature(s, 0, 1, &"gumdrop")
	Fx.put_creature(s, 0, 5, &"sporeling")
	Fx.put_creature(s, 1, 1, &"magmaw")
	Fx.put_building(s, 0, 1, &"kiln_tower")
	s.players[0].at(1).damage = 1
	_moon(s, 1)
	assert_eq(s.players[1].at(1).card.id, &"gumdrop", "leader went across")
	assert_eq(s.players[1].at(5).card.id, &"sporeling", "its follower too")
	assert_eq(s.players[1].at(1).damage, 1, "damage travels")
	assert_eq(s.players[0].at(1).card.id, &"magmaw", "the other came over")
	assert_true(s.players[0].at(5) == null, "no follower here now")
	assert_eq(s.players[0].lane(1).building.id, &"kiln_tower", "the building stays")
	return true


func test_one_creature_nothing_moves() -> bool:
	var s: GameState = Fx.blank()
	Fx.put_creature(s, 0, 2, &"gumdrop")
	_moon(s, 1)
	assert_eq(s.players[0].at(2).card.id, &"gumdrop", "stays")
	return true


func test_steal_hand() -> bool:
	var s: GameState = Fx.blank()
	s.players[1].hand.append(CardDB.card(&"gumdrop"))
	s.players[1].hand.append(CardDB.card(&"inferno_drake"))
	s.players[1].hand.append(CardDB.variant(CardDB.card(&"magmaw"), {"attack": 3}))
	var c: CardData = Fx.card(&"t_thief", CardData.Kind.SPELL, 0, 0, 0, [], [Fx.eff(&"on_play", &"steal_hand", 1, &"enemy_hero", {"amount2": 1})])
	s.players[0].hand.append(c)
	Rules.apply(s, Action.play(0, s.players[0].hand.size() - 1, -1))
	assert_eq(s.players[0].hand.back().id, &"inferno_drake", "took the most expensive")
	assert_eq(s.players[1].hand.size(), 2, "gone from their hand")
	assert_eq(int(s.players[0].history["stolen"]), 1, "counted")
	return true


func test_copy_rival_keeps_changes() -> bool:
	var s: GameState = Fx.blank()
	s.players[1].hand.clear()
	s.players[1].hand.append(CardDB.variant(CardDB.card(&"magmaw"), {"attack": 3}))
	var c: CardData = Fx.card(&"t_copy", CardData.Kind.SPELL, 0, 0, 0, [], [Fx.eff(&"on_play", &"copy_rival", 1, &"enemy_hero")])
	s.players[0].hand.append(c)
	Rules.apply(s, Action.play(0, s.players[0].hand.size() - 1, -1))
	assert_eq(s.players[0].hand.back().attack, CardDB.card(&"magmaw").attack + 3, "a copy with its changes")
	assert_eq(s.players[1].hand.size(), 1, "they keep theirs")
	return true


func test_steal_creature() -> bool:
	var s: GameState = Fx.blank()
	Fx.put_creature(s, 1, 2, &"gumdrop")
	Fx.put_creature(s, 0, 0, &"magmaw")
	var c: CardData = Fx.card(&"t_lure", CardData.Kind.SPELL, 0, 0, 0, [], [Fx.eff(&"on_play", &"steal_creature", 3, &"chosen_enemy_creature")])
	s.players[0].hand.append(c)
	Rules.apply(s, Action.play(0, s.players[0].hand.size() - 1, -1, [{"player": 1, "lane": 2}]))
	assert_eq(s.players[0].at(1).card.id, &"gumdrop", "now yours, in your first empty lane")
	assert_true(s.players[1].at(2) == null, "gone from theirs")
	assert_true(not s.players[0].at(1).ready, "can't attack this turn")
	for l: int in 4:
		if s.players[0].at(l) == null:
			Fx.put_creature(s, 0, l, &"sporeling")
	Fx.put_creature(s, 1, 3, &"gumdrop")
	s.players[0].hand.append(c)
	Rules.apply(s, Action.play(0, s.players[0].hand.size() - 1, -1, [{"player": 1, "lane": 3}]))
	assert_eq(s.players[1].at(3).card.id, &"gumdrop", "no empty lane: nothing happens")
	return true


func test_digest_same_after_moon() -> bool:
	var a: GameState = Fx.blank()
	var b: GameState = Fx.blank()
	for s: GameState in [a, b]:
		Fx.put_creature(s, 0, 0, &"gumdrop")
		Fx.put_creature(s, 1, 1, &"magmaw")
		_moon(s, 1)
	assert_eq(a.digest(), b.digest(), "both peers agree")
	return true


func test_steal_texts() -> bool:
	for op: StringName in [&"dark_moon", &"steal_hand", &"copy_rival", &"steal_creature"]:
		var t: String = CardText.render(Fx.card(&"t_x", CardData.Kind.SPELL, 0, 0, 0, [], [Fx.eff(&"on_play", op, 1, &"chosen_enemy_creature")]))
		assert_true(not String(op) in t, "%s in words: %s" % [op, t])
	return true
