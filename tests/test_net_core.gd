extends TestCase
## Engine hooks for online play: forced first player, state digest, deck codec.


func _ids(arr: Array[CardData]) -> Array[StringName]:
	var out: Array[StringName] = []
	for c: CardData in arr:
		out.append(c.id)
	return out


func test_setup_first_keeps_shuffles() -> bool:
	var a: DeckData = CardDB.deck(&"blaze_rush")
	var b: DeckData = CardDB.deck(&"deep_freeze")
	var s1: GameState = Rules.setup(a, b, 99)
	var forced: int = 1 - s1.first_player
	var s2: GameState = Rules.setup(a, b, 99, forced)
	assert_eq(s2.first_player, forced, "first is forced")
	assert_eq(s2.active, forced, "forced player starts")
	assert_eq(_ids(s2.players[0].deck), _ids(s1.players[0].deck), "deck 0 shuffle unchanged")
	assert_eq(_ids(s2.players[1].deck), _ids(s1.players[1].deck), "deck 1 shuffle unchanged")
	assert_eq(s2.rng.state, s1.rng.state, "rng stream unchanged")
	assert_true(s2.players[1 - forced].hand.any(func(c: CardData) -> bool: return c.id == &"star_shard"), "second player gets the Star Shard")
	assert_true(not s2.players[forced].hand.any(func(c: CardData) -> bool: return c.id == &"star_shard"), "first player has no Star Shard")
	return true


func test_digest_stable_and_sensitive() -> bool:
	var s: GameState = Rules.setup(CardDB.deck(&"blaze_rush"), CardDB.deck(&"deep_freeze"), 5)
	assert_eq(s.digest(), s.clone().digest(), "clone has the same digest")
	assert_eq(s.digest().length(), 32, "md5 hex")
	var t: GameState = s.clone()
	t.players[1].hero_hp -= 1
	assert_true(t.digest() != s.digest(), "hp change")
	t = s.clone()
	t.rng.randi()
	assert_true(t.digest() != s.digest(), "rng advance")
	t = s.clone()
	var c: CardData = t.players[0].hand.pop_back()
	t.players[0].hand.push_front(c)
	assert_true(t.digest() != s.digest(), "hand order")
	t = s.clone()
	Fx.put_creature(t, 0, 2, &"mossback")
	var with_creature: String = t.digest()
	assert_true(with_creature != s.digest(), "creature on the board")
	t.players[0].lanes[2].creature.xp += 1
	assert_true(t.digest() != with_creature, "creature xp")
	return true


func test_builtin_decks_are_legal() -> bool:
	for id: StringName in CardDB.DECK_ORDER:
		assert_eq(DeckStore.validate(CardDB.deck(id).cards), "", "%s legal" % id)
	return true


func test_deck_codec_round_trip_and_rejects() -> bool:
	var d: DeckData = CardDB.deck(&"sugar_storm")
	var enc: Dictionary = DeckCodec.encode(d)
	assert_eq(DeckCodec.check(enc), "", "encoded deck passes")
	var back: DeckData = DeckCodec.decode(enc, &"online_1")
	assert_eq(_ids(back.cards), _ids(d.cards), "same cards in order")
	assert_eq(back.lands, d.lands, "same lands")
	assert_eq(back.display_name, d.display_name, "same name")
	assert_eq(back.id, &"online_1", "given id")
	var short: Dictionary = enc.duplicate(true)
	(short["cards"] as Array).pop_back()
	assert_true(DeckCodec.check(short) != "", "29 cards refused")
	var bad: Dictionary = enc.duplicate(true)
	bad["cards"][0] = "no_such_card"
	assert_true(DeckCodec.check(bad) != "", "unknown id refused")
	var lands: Dictionary = enc.duplicate(true)
	lands["lands"] = [0, 0, 9, 0]
	assert_true(DeckCodec.check(lands) != "", "bad land refused")
	assert_true(DeckCodec.check({"name": 3}) != "", "bad shape refused")
	assert_true(DeckCodec.check("x") != "", "not a dictionary refused")
	return true


func test_deck_codec_survives_json() -> bool:
	var enc: Dictionary = DeckCodec.encode(CardDB.deck(&"grove_guard"))
	var wire: Variant = JSON.parse_string(JSON.stringify(enc))
	assert_eq(DeckCodec.check(wire), "", "JSON floats for lands still pass")
	var back: DeckData = DeckCodec.decode(wire as Dictionary, &"x")
	assert_eq(back.lands, CardDB.deck(&"grove_guard").lands, "lands back to ints")
	return true
