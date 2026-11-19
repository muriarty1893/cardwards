extends TestCase
## The match talks to its rival through a driver; against the AI that is AiRival.


func test_match_uses_ai_driver() -> bool:
	var m: MatchController = await Fx.load_match()
	assert_true(m != null, "match reached the human turn")
	assert_true(m.driver is AiRival, "AI driver")
	assert_eq(m.seats.seat, 0, "seat 0")
	assert_true(m.state == m.seats.real, "the view state is the real state")
	assert_eq(m.driver.rival_name(), "Rival", "rival name")
	assert_true(not m.driver.is_online(), "offline")
	assert_true(not m.driver.blocks_input(), "AI never holds input between turns")
	m.queue_free()
	return true


func test_apply_local_returns_view_events() -> bool:
	var m: MatchController = await Fx.load_match()
	var before: int = m.state.players[0].hand.size()
	var ev: Array[GameEvent] = m.apply_local(Action.end_turn(MatchController.HUMAN))
	assert_true(ev.size() > 0, "events came back")
	assert_eq(m.state.active, MatchController.AI, "turn passed")
	assert_eq(m.state.players[0].hand.size(), before, "own hand untouched")
	m.queue_free()
	return true
