extends TestCase
## Two online sessions over the in-memory relay: lockstep stays in sync, rejoin, desync, concede, rematch.

const VER := "n1-test"


func _custom_deck(seed: int) -> DeckData:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var pool: Array[CardData] = CardDB.collectible_cards()
	var cards: Array[CardData] = []
	var guard: int = 0
	while cards.size() < DeckStore.DECK_SIZE and guard < 5000:
		guard += 1
		var c: CardData = pool[rng.randi_range(0, pool.size() - 1)]
		if DeckStore.can_add(cards, c):
			cards.append(c)
	return DeckStore.make(&"custom_t", "Test %d" % seed, cards)


func _deck(i: int) -> DeckData:
	if i % 5 == 4:
		return _custom_deck(i)
	return CardDB.deck(CardDB.DECK_ORDER[i % CardDB.DECK_ORDER.size()])


## Host + join on a fresh relay; returns [relay, s0, s1].
func _pair(seed: int, deck_a: DeckData, deck_b: DeckData) -> Array:
	var relay := FakeRelay.new(seed)
	var s0 := OnlineSession.new(relay.transport(&"host"), "Ann", deck_a, VER)
	s0.hello()
	relay.pump()
	var s1 := OnlineSession.new(relay.transport(), "Bo", deck_b, VER)
	s1.hello()
	relay.pump()
	return [relay, s0, s1]


func _run(relay: FakeRelay, sessions: Array, brains: Array, max_steps: int = 40000) -> void:
	for i: int in max_steps:
		var done: bool = true
		for k: int in sessions.size():
			(brains[k] as BotBrain).step(sessions[k] as OnlineSession)
			done = done and (sessions[k] as OnlineSession).status == &"over"
		relay.pump()
		if done:
			return


func test_fifty_online_matches_stay_in_sync() -> bool:
	var reasons: Dictionary = {}
	for i: int in 50:
		var p: Array = _pair(1000 + i, _deck(i), _deck(i + 1))
		var relay: FakeRelay = p[0]
		var s0: OnlineSession = p[1]
		var s1: OnlineSession = p[2]
		assert_eq([s0.seat, s1.seat], [0, 1], "seats (match %d)" % i)
		assert_eq([s0.status, s1.status], [&"playing", &"playing"], "both started (match %d)" % i)
		_run(relay, [s0, s1], [BotBrain.new(i * 2 + 1), BotBrain.new(i * 2 + 2)])
		assert_eq([s0.status, s1.status], [&"over", &"over"], "both ended (match %d)" % i)
		reasons[s0.over.get("reason", "")] = true
		assert_eq(s0.over.get("reason", ""), "normal", "normal end (match %d)" % i)
		assert_eq(s0.digests, s1.digests, "same digest after every move (match %d)" % i)
		assert_true(s0.digests.size() > 10, "a real match was played (match %d)" % i)
		assert_eq(int(s0.over["winner"]), s0.state.winner, "winner agrees with the engine (match %d)" % i)
		assert_eq(s1.state.winner, s0.state.winner, "same winner (match %d)" % i)
	assert_eq(reasons.keys(), ["normal"], "every match ended normally")
	return true


func test_rejoin_replays_to_same_digest() -> bool:
	var p: Array = _pair(77, _deck(0), _deck(1))
	var relay: FakeRelay = p[0]
	var s0: OnlineSession = p[1]
	var s1: OnlineSession = p[2]
	var b0 := BotBrain.new(5)
	var b1 := BotBrain.new(6)
	var guard: int = 0
	while s0.applied < 20 and s0.status == &"playing" and guard < 20000:
		b0.step(s0)
		b1.step(s1)
		relay.pump()
		guard += 1
	b0.step(s0)
	b1.step(s1)
	relay.pump()
	assert_true(s0.applied >= 20, "20 moves played (%d)" % s0.applied)
	assert_eq(s0.status, &"playing", "still playing when the connection drops")
	relay.drop(1)
	relay.pump()
	b0.step(s0)
	var again := OnlineSession.new(relay.transport(), "Bo", _deck(1), VER, s1.token)
	again.hello()
	relay.pump()
	assert_eq(again.seat, 1, "same seat back")
	# s0 may still hold a move the relay already logged: let its bot take it in (it may also send its next act,
	# which is not applied until the relay echoes it).
	b0.step(s0)
	assert_eq(again.applied, s0.applied, "log replayed")
	assert_eq(again.state.digest(), s0.state.digest(), "same state as the other player")
	assert_true(again.take_opening().is_empty(), "no opening after a rejoin")
	_run(relay, [s0, again], [b0, BotBrain.new(9)])
	assert_eq(s0.over.get("reason", ""), "normal", "finished normally")
	assert_eq(again.state.digest(), s0.state.digest(), "still in sync at the end")
	return true


func test_backstop_crossing_own_act() -> bool:
	var p: Array = _pair(31, _deck(2), _deck(3))
	var relay: FakeRelay = p[0]
	var s0: OnlineSession = p[1]
	var s1: OnlineSession = p[2]
	var me: OnlineSession = s0 if s0.is_my_turn() else s1
	relay.backstop()
	me.send_act(Action.end_turn(me.seat))
	relay.pump()
	var saw_auto: bool = false
	var saw_rejected: bool = false
	for msg: Dictionary in me.inbox:
		saw_auto = saw_auto or (msg["t"] == "move" and msg.get("auto", false))
		saw_rejected = saw_rejected or msg["t"] == "rejected"
	assert_true(saw_auto, "the room's END_TURN arrived")
	assert_true(saw_rejected, "the late move was rejected")
	var b0 := BotBrain.new(1)
	var b1 := BotBrain.new(2)
	for i: int in 3:
		b0.step(s0)
		b1.step(s1)
		relay.pump()
	assert_eq(s0.applied, s1.applied, "same number of moves")
	assert_eq(s0.state.digest(), s1.state.digest(), "still in sync")
	assert_eq(s0.status, &"playing", "no desync")
	return true


func test_invalid_move_is_desync() -> bool:
	var p: Array = _pair(12, _deck(0), _deck(2))
	var relay: FakeRelay = p[0]
	var s0: OnlineSession = p[1]
	var s1: OnlineSession = p[2]
	var path: String = "user://desync_%s.json" % relay.code
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var waiting: int = 1 - s1.state.active
	s1.on_message({"t": "move", "seq": 1, "a": Action.end_turn(waiting).to_dict()})
	var ev: Array[GameEvent] = s1.apply_move(s1.next())
	assert_true(ev.is_empty(), "nothing applied")
	relay.pump()
	assert_eq([s0.status, s1.status], [&"over", &"over"], "both ended")
	assert_eq([s0.over.get("reason", ""), s1.over.get("reason", "")], ["desync", "desync"], "as a desync")
	assert_true(FileAccess.file_exists(path), "desync file written")
	var dump: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	assert_true(dump is Dictionary and dump.has("seed") and dump.has("moves") and dump.has("decks"), "dump has what a replay needs")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	return true


func test_rival_deck_illegal_is_desync() -> bool:
	var relay := FakeRelay.new(3)
	relay.corrupt_deck = 1
	var s0 := OnlineSession.new(relay.transport(&"host"), "Ann", _deck(0), VER)
	s0.hello()
	relay.pump()
	var s1 := OnlineSession.new(relay.transport(), "Bo", _deck(1), VER)
	s1.hello()
	relay.pump()
	assert_eq(s0.over.get("reason", ""), "desync", "bad rival deck ends the match")
	assert_true(s0.state == null, "no match was set up")
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://desync_%s.json" % relay.code))
	return true


func test_concede_and_rematch() -> bool:
	var p: Array = _pair(8, _deck(1), _deck(3))
	var relay: FakeRelay = p[0]
	var s0: OnlineSession = p[1]
	var s1: OnlineSession = p[2]
	var starts: Array = []
	s0.started.connect(func(rejoined: bool) -> void: starts.append(rejoined))
	s1.concede()
	relay.pump()
	assert_eq(s0.over, {"winner": 0, "reason": "concede"}, "seat 0 wins by concede")
	assert_eq(s1.status, &"over", "seat 1 sees the end too")
	var old_seed: int = s0.seed
	s0.request_rematch()
	relay.pump()
	assert_true(s1.rival_wants_rematch, "seat 1 hears about the rematch")
	s1.request_rematch()
	relay.pump()
	assert_eq([s0.status, s1.status], [&"playing", &"playing"], "rematch started")
	assert_eq([s0.match_no, s1.match_no], [1, 1], "match number 1")
	assert_true(s0.seed != old_seed, "new seed")
	assert_eq(s0.state.digest(), s1.state.digest(), "same new match")
	assert_eq(starts, [false], "started once more, not as a rejoin")
	assert_true(not s0.take_opening().is_empty(), "the new match has an opening")
	return true
