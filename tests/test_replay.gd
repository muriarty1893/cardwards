extends TestCase


func _new_match(seed: int) -> GameState:
	var s: GameState = Rules.setup(CardDB.deck(&"sugar_storm"), CardDB.deck(&"deep_freeze"), seed)
	Rules.start_turn(s)
	return s


func test_legal_actions_all_valid() -> bool:
	var s: GameState = _new_match(7)
	var pick := RandomNumberGenerator.new()
	pick.seed = 3
	var checked: int = 0
	for step: int in 200:
		var acts: Array[Action] = Rules.legal_actions(s)
		if acts.is_empty():
			break
		for a: Action in acts:
			var err: String = Rules.validate(s, a)
			if err != "":
				assert_eq(err, "", "legal action invalid: %s" % a)
			checked += 1
		Rules.apply(s, acts[pick.randi_range(0, acts.size() - 1)])
	assert_true(checked > 200, "checked many actions (%d)" % checked)
	return true


func test_replay_identical() -> bool:
	var s: GameState = _new_match(99)
	var pick := RandomNumberGenerator.new()
	pick.seed = 99
	var log: Array[Dictionary] = []
	var types_a: Array[StringName] = []
	for step: int in 400:
		var acts: Array[Action] = Rules.legal_actions(s)
		if acts.is_empty():
			break
		var a: Action = acts[pick.randi_range(0, acts.size() - 1)]
		log.append(a.to_dict())
		types_a.append_array(Fx.types(Rules.apply(s, a)))
	var r: GameState = _new_match(99)
	var types_b: Array[StringName] = []
	for d: Dictionary in log:
		types_b.append_array(Fx.types(Rules.apply(r, Action.from_dict(d))))
	assert_eq([r.players[0].hero_hp, r.players[1].hero_hp, r.turn], [s.players[0].hero_hp, s.players[1].hero_hp, s.turn], "same final state")
	assert_eq(types_b, types_a, "same event stream")
	assert_true(log.size() > 20, "match had real length (%d actions)" % log.size())
	return true


func test_action_round_trip_new_fields() -> bool:
	for a: Action in [Action.attack(1, 2, 3, Action.Hit.CRIT, true), Action.attack(0, 1, -1, Action.Hit.GLANCE), Action.choose(1, 2)]:
		var b: Action = Action.from_dict(a.to_dict())
		assert_eq([b.type, b.player, b.lane, b.target_lane, b.hit, b.blocked, b.choice], [a.type, a.player, a.lane, a.target_lane, a.hit, a.blocked, a.choice], "round trip %s" % a)
	return true
