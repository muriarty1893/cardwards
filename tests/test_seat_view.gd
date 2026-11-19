extends TestCase
## The seat mirror: the seat-1 player sees the canonical match with the players swapped.


func _check_mirror(real: GameState, view: GameState, label: String) -> void:
	assert_true(view.players[0] == real.players[1] and view.players[1] == real.players[0], "%s: players swapped (same objects)" % label)
	assert_eq([view.active, view.first_player, view.winner, view.pending_player, view.field_owner],
		[_f(real.active), _f(real.first_player), _f(real.winner), _f(real.pending_player), _f(real.field_owner)], "%s: flipped scalars" % label)
	assert_eq([view.turn, view.phase], [real.turn, real.phase], "%s: turn and phase" % label)
	assert_true(view.field == real.field, "%s: field" % label)
	assert_eq(view.pending_choice.size(), real.pending_choice.size(), "%s: pending choice" % label)


func _f(p: int) -> int:
	return 1 - p if p == 0 or p == 1 else p


func _check_events(ev: Array[GameEvent], vev: Array[GameEvent]) -> void:
	assert_eq(vev.size(), ev.size(), "same number of events")
	for i: int in mini(ev.size(), vev.size()):
		assert_eq(vev[i].type, ev[i].type, "same type")
		for key: String in ["player", "winner"]:
			if ev[i].data.has(key):
				assert_eq(vev[i].data[key], _f(int(ev[i].data[key])), "%s %s flipped" % [ev[i].type, key])
		for key: Variant in ev[i].data:
			if key != "player" and key != "winner":
				assert_eq(vev[i].data[key], ev[i].data[key], "%s %s copied" % [ev[i].type, key])


func test_mirror_tracks_a_whole_match() -> bool:
	var real: GameState = Rules.setup(CardDB.deck(&"grove_guard"), CardDB.deck(&"blaze_rush"), 31)
	var sv := SeatView.new(real, 1)
	var ais: Array[AIPlayer] = [AIPlayer.new(0, AIPlayer.Difficulty.MEDIUM, 3), AIPlayer.new(1, AIPlayer.Difficulty.MEDIUM, 4)]
	var ev: Array[GameEvent] = Rules.start_turn(real)
	sv.sync()
	_check_events(ev, sv.events_to_view(ev))
	_check_mirror(real, sv.view, "after opening")
	var steps: int = 0
	var fails: int = failed
	while real.phase != GameState.Phase.OVER and steps < 3000 and failed == fails:
		var a: Action = ais[real.active].choose_action(real) if real.phase == GameState.Phase.MAIN \
			else Action.choose(real.pending_player, 0)
		var va: Action = sv.action_to_view(a)
		assert_eq(Rules.validate(sv.view, va), Rules.validate(real, a), "same verdict on the mirror (%s)" % a)
		ev = Rules.apply(real, a)
		sv.sync()
		steps += 1
		_check_events(ev, sv.events_to_view(ev))
		_check_mirror(real, sv.view, "step %d" % steps)
	assert_eq(real.phase, GameState.Phase.OVER, "match ended")
	assert_eq(sv.view.winner, 1 - real.winner, "winner flipped")
	return true


func test_seat_zero_is_identity() -> bool:
	var real: GameState = Rules.setup(CardDB.deck(&"grove_guard"), CardDB.deck(&"blaze_rush"), 2)
	var sv := SeatView.new(real, 0)
	assert_true(sv.view == real, "same object")
	var a: Action = Action.play(0, 1, 2, [{"player": 1, "lane": 3}])
	assert_eq(sv.action_to_real(a).to_dict(), a.to_dict(), "action unchanged")
	var ev: Array[GameEvent] = Rules.start_turn(real)
	assert_true(sv.events_to_view(ev) == ev, "events unchanged")
	assert_eq(sv.flip(0), 0, "no flip on seat 0")
	return true


func test_action_flip_round_trip() -> bool:
	var sv := SeatView.new(Fx.blank(), 1)
	var a: Action = Action.play(0, 1, 2, [{"player": 1, "lane": 3}, {"discard": 4}])
	var r: Action = sv.action_to_real(a)
	assert_eq([r.player, r.targets[0]["player"], r.targets[1].has("player")], [1, 0, false], "flipped")
	assert_eq(sv.action_to_view(r).to_dict(), a.to_dict(), "round trip")
	assert_eq(a.player, 0, "original untouched")
	assert_eq([sv.flip(0), sv.flip(1), sv.flip(-1)], [1, 0, -1], "flip")
	return true
