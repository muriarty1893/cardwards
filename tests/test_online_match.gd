extends TestCase
## The match scene online, as seat 1: the rival (seat 0) is a headless session + BotBrain on the
## same in-memory relay. A helper node pumps the relay every frame.

const VER := "n1-test"


class Pumper:
	extends Node
	var relay: FakeRelay
	var remote: OnlineSession
	## Null: the remote side is driven by the test itself.
	var brain: BotBrain
	func _process(_d: float) -> void:
		relay.pump()
		if brain:
			brain.step(remote)
		relay.pump()


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


## [relay, remote, local, match, pumper]
func _start(relay_seed: int, first: int, with_brain: bool) -> Array:
	var relay := FakeRelay.new(relay_seed)
	relay.force_first = first
	var remote := OnlineSession.new(relay.transport(&"host"), "Botty", CardDB.deck(&"deep_freeze"), VER)
	remote.mulligan = false
	remote.hello()
	relay.pump()
	var local := OnlineSession.new(relay.transport(), "Me", CardDB.deck(&"blaze_rush"), VER)
	local.mulligan = false
	local.hello()
	relay.pump()
	var online: Node = _tree().root.get_node("Online")
	online.set("session", local)
	online.set("state", &"playing")
	var pumper := Pumper.new()
	pumper.relay = relay
	pumper.remote = remote
	pumper.brain = BotBrain.new(relay_seed) if with_brain else null
	_tree().root.add_child(pumper)
	var m := (load("res://view/match.tscn") as PackedScene).instantiate() as MatchController
	m.menu_scene = ""
	_tree().root.add_child(m)
	await _tree().process_frame
	m.player.speed = 20.0
	m.pace = 20.0
	m.timing_bar.auto_stop = true
	m.timing_bar.force_needle = 0.5
	var waited: int = 0
	while not (m.driver as OnlineRival).live and waited < 2000:
		await _tree().process_frame
		waited += 1
	return [relay, remote, local, m, pumper]


func _cleanup(p: Array) -> void:
	(p[3] as Node).queue_free()
	(p[4] as Node).queue_free()
	var online: Node = _tree().root.get_node("Online")
	online.set("session", null)
	online.set("state", &"idle")


func _until(cond: Callable, frames: int = 3000) -> bool:
	for i: int in frames:
		if cond.call():
			return true
		await _tree().process_frame
	return cond.call()


func test_full_online_match_as_seat_one() -> bool:
	var p: Array = await _start(41, -1, true)
	var remote: OnlineSession = p[1]
	var local: OnlineSession = p[2]
	var m: MatchController = p[3]
	assert_true(m.driver is OnlineRival, "online driver")
	assert_eq(m.seats.seat, 1, "local is seat 1")
	assert_eq(m.hud.rival_name_text(), "BOTTY", "rival corner shows the rival's name")
	var me := AIPlayer.new(MatchController.HUMAN, AIPlayer.Difficulty.MEDIUM, 77)
	var frames: int = 0
	while local.status != &"over" and frames < 60000:
		await _tree().process_frame
		frames += 1
		if m.busy or m.driver.blocks_input() or m.state.active != MatchController.HUMAN or m.state.phase == GameState.Phase.OVER:
			continue
		var a: Action = me.choose_action(m.state) if m.state.phase == GameState.Phase.MAIN else Action.choose(MatchController.HUMAN, 0)
		match a.type:
			Action.Type.END_TURN:
				m.hud.end_turn_pressed.emit()
			Action.Type.ATTACK:
				m.request_attack(a.lane, a.target_lane)
			Action.Type.CHOOSE:
				m._on_action_requested(a)
			_:
				m.input.action_requested.emit(a)
	await _until(func() -> bool: return remote.status == &"over" and m.results.visible and not m.driver.blocks_input())
	assert_eq(local.status, &"over", "match finished (%d frames, turn %d)" % [frames, m.state.turn])
	assert_eq(local.over.get("reason", ""), "normal", "ended normally")
	assert_eq(local.state.digest(), remote.state.digest(), "both games in the same state")
	assert_eq(m.view_resyncs, 0, "the view never had to resync")
	assert_true(m.results.visible, "results shown")
	assert_eq(m.state.winner == MatchController.HUMAN, local.over["winner"] == 1, "result from this seat's point of view")
	_cleanup(p)
	return true


func test_block_wanted_runs_live_block_bar() -> bool:
	var p: Array = await _start(42, 0, false)
	var relay: FakeRelay = p[0]
	var remote: OnlineSession = p[1]
	var local: OnlineSession = p[2]
	var m: MatchController = p[3]
	for s: OnlineSession in [remote, local]:
		Fx.put_creature(s.state, 0, 1, &"glacier_tortoise")
		Fx.put_creature(s.state, 1, 2, &"mossback")
	m.sync_all()
	remote.send_attack(1, 2, Action.Hit.NORMAL)
	var ok: bool = await _until(func() -> bool: return local.applied == 1 and not m.driver.blocks_input())
	assert_true(ok, "the attack played")
	assert_true(relay.received_log.any(func(e: Dictionary) -> bool: return e["t"] == "block" and e["seat"] == 1), "the local side answered with a block")
	assert_eq(bool(local.moves[0]["blocked"]), true, "needle in the green: blocked")
	assert_eq(local.applied, 1, "the move played once")
	var mv: Dictionary = remote.next()
	while not mv.is_empty() and mv["t"] != "move":
		mv = remote.next()
	remote.apply_move(mv)
	assert_eq(local.state.digest(), remote.state.digest(), "same state after the blocked attack")
	_cleanup(p)
	return true


func test_fuse_ends_turn() -> bool:
	var p: Array = await _start(43, 1, false)
	var local: OnlineSession = p[2]
	var m: MatchController = p[3]
	var d: OnlineRival = m.driver
	assert_eq(m.state.active, MatchController.HUMAN, "local goes first")
	d.turn_left = 10.0
	await _tree().process_frame
	assert_true(m.hud.fuse_visible(), "fuse shows under 15 s")
	d.turn_left = 0.3
	var ok: bool = await _until(func() -> bool: return m.state.active == MatchController.AI)
	assert_true(ok, "the clock ended the turn")
	assert_eq(int(local.moves[0]["type"]), Action.Type.END_TURN, "an END_TURN went to the room")
	d.turn_left = 40.0
	await _tree().process_frame
	assert_true(not m.hud.fuse_visible(), "no fuse with time to spare")
	_cleanup(p)
	return true


## The turn clock keeps running while the Dream Up picker is open; at zero it keeps the first card.
func test_clock_runs_and_picks_while_choosing() -> bool:
	var p: Array = await _start(43, 1, false)
	var m: MatchController = p[3]
	var d: OnlineRival = m.driver
	assert_eq(m.state.active, MatchController.HUMAN, "local goes first")
	# Stand-in pick on the view only (nothing is sent): the clock is what's tested here.
	m.state.phase = GameState.Phase.CHOOSING
	m.state.pending_player = MatchController.HUMAN
	m.busy = true
	var got: Array = []
	var cards: Array[CardData] = [CardDB.card(&"gumdrop"), CardDB.card(&"cinderpup"), CardDB.card(&"iceling")]
	var run := func() -> void: got.append(await m.picker.open(cards))
	run.call()
	d.turn_left = 5.0
	await _tree().create_timer(0.3).timeout
	assert_true(d.turn_left < 4.95, "clock ran while choosing (%.2f)" % d.turn_left)
	d.turn_left = 0.01
	assert_true(await _until(func() -> bool: return not got.is_empty()), "the picker was closed by the clock")
	assert_eq(got, [0], "first card kept")
	m.state.phase = GameState.Phase.MAIN
	m.state.pending_player = -1
	d.turn_left = 40.0
	m.busy = false
	_cleanup(p)
	return true


func test_leave_confirms_then_concedes() -> bool:
	var p: Array = await _start(44, 0, false)
	var relay: FakeRelay = p[0]
	var remote: OnlineSession = p[1]
	var m: MatchController = p[3]
	m.hud.toggle_pause()
	assert_eq(m.hud.pause_title_text(), "Menu", "online menu title")
	assert_eq(m.hud.quit_button.text, "LEAVE MATCH", "leave button")
	m.hud.quit_button.pressed.emit()
	assert_true(m.hud.leave_confirm_visible(), "asks first")
	m.hud.stay_button.pressed.emit()
	assert_true(not m.hud.leave_confirm_visible(), "STAY closes the question")
	assert_true(remote.over.is_empty(), "nothing sent yet")
	m.hud.quit_button.pressed.emit()
	m.hud.leave_button.pressed.emit()
	relay.pump()
	assert_eq(remote.over, {"winner": 0, "reason": "concede"}, "leaving conceded")
	_cleanup(p)
	return true


func test_rematch_off_after_rival_left() -> bool:
	var p: Array = await _start(45, 0, false)
	var relay: FakeRelay = p[0]
	var remote: OnlineSession = p[1]
	var m: MatchController = p[3]
	remote.concede()
	var ok: bool = await _until(func() -> bool: return m.results.visible and not m.driver.blocks_input())
	assert_true(ok, "results after the rival conceded")
	assert_eq(m.results.reason_text(), "Rival conceded", "says why")
	assert_true(m.results.rematch_enabled(), "rematch possible")
	(remote.link as FakeRelay.Link).close()
	relay.pump()
	await _until(func() -> bool: return not m.results.rematch_enabled())
	assert_true(not m.results.rematch_enabled(), "rematch off once the rival left")
	assert_eq(m.results.rematch_text(), "Rival left", "says why")
	_cleanup(p)
	return true


func test_banner_when_rival_drops() -> bool:
	var p: Array = await _start(46, 1, false)
	var relay: FakeRelay = p[0]
	var remote: OnlineSession = p[1]
	var m: MatchController = p[3]
	relay.drop(0)
	var ok: bool = await _until(func() -> bool: return m.hud.banner_text().begins_with("Rival disconnected — waiting"))
	assert_true(ok, "banner shows (%s)" % m.hud.banner_text())
	var back := OnlineSession.new(relay.transport(), "Botty", CardDB.deck(&"deep_freeze"), VER, remote.token)
	back.hello()
	ok = await _until(func() -> bool: return m.hud.banner_text() == "")
	assert_true(ok, "banner cleared when the rival is back")
	_cleanup(p)
	return true


func test_lost_connection_shows_results() -> bool:
	var p: Array = await _start(47, 1, false)
	var m: MatchController = p[3]
	var online: Node = _tree().root.get_node("Online")
	online.set("state", &"error")
	online.set("message", "Lost the connection")
	var ok: bool = await _until(func() -> bool: return m.results.visible)
	assert_true(ok, "the match says what happened")
	assert_eq(m.results.reason_text(), "Lost the connection", "the reason")
	assert_true(not m.results.rematch_enabled(), "no rematch without a connection")
	_cleanup(p)
	return true


func test_rejoin_into_finished_match_shows_results() -> bool:
	var relay := FakeRelay.new(48)
	var remote := OnlineSession.new(relay.transport(&"host"), "Botty", CardDB.deck(&"deep_freeze"), VER)
	remote.hello()
	relay.pump()
	var local := OnlineSession.new(relay.transport(), "Me", CardDB.deck(&"blaze_rush"), VER)
	local.hello()
	relay.pump()
	remote.concede()
	relay.pump()
	assert_eq(local.status, &"over", "the match ended before the scene loaded")
	var online: Node = _tree().root.get_node("Online")
	online.set("session", local)
	online.set("state", &"playing")
	var m := (load("res://view/match.tscn") as PackedScene).instantiate() as MatchController
	m.menu_scene = ""
	_tree().root.add_child(m)
	await _tree().process_frame
	m.player.speed = 20.0
	m.pace = 20.0
	assert_true(m.driver is OnlineRival, "still the online match, not one against the AI")
	var ok: bool = await _until(func() -> bool: return m.results.visible)
	assert_true(ok, "results shown")
	assert_eq(m.results.reason_text(), "Rival conceded", "with the reason")
	m.queue_free()
	online.set("session", null)
	online.set("state", &"idle")
	return true
