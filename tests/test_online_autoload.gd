extends TestCase
## The Online autoload: codes, the player's name, host/join through the fake relay, rejoin file,
## reconnecting after a drop, and an unreachable server.

const ONLINE := preload("res://autoload/online.gd")


class DeadLink:
	extends RefCounted
	signal opened
	signal received(msg: Dictionary)
	signal closed(code: int, reason: String)
	func send(_m: Dictionary) -> void:
		pass
	func close() -> void:
		pass
	func is_open() -> bool:
		return false
	func was_open() -> bool:
		return false
	func poll() -> void:
		pass


func _online(relay: FakeRelay, rejoin: String) -> Node:
	var o: Node = ONLINE.new()
	o.link_factory = func(path: String) -> Object:
		return relay.transport(&"host" if path == "/host" else &"join")
	o.rejoin_path = rejoin
	DirAccess.remove_absolute(ProjectSettings.globalize_path(rejoin))
	return o


func test_normalize_code() -> bool:
	for t: String in ["frog42", "FROG 42", " frog-42 ", "Frog_42"]:
		assert_eq(ONLINE.normalize_code(t), "FROG-42", "normalizes '%s'" % t)
	for t: String in ["frog", "42", "froggyy-42", "", "fr-42", "frog-421", "12-frog"]:
		assert_eq(ONLINE.normalize_code(t), "", "refuses '%s'" % t)
	return true


func test_player_name_default_and_saved() -> bool:
	var path: String = "user://test_online_settings.cfg"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var st := GameSettings.new()
	st.path = path
	st.load_settings()
	var re := RegEx.create_from_string("^Dreamer[1-9][0-9]{2}$")
	assert_true(re.search(st.player_name) != null, "default name %s" % st.player_name)
	st.set_player_name("  Zed\u0007 the Bold of the Isles!  ")
	assert_eq(st.player_name, "Zed the Bold of", "cleaned, cut to 16 and trimmed like the server")
	var st2 := GameSettings.new()
	st2.path = path
	st2.load_settings()
	assert_eq(st2.player_name, "Zed the Bold of", "saved")
	st2.set_player_name("   ")
	assert_true(re.search(st2.player_name) != null, "empty falls back to a default")
	st.free()
	st2.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	return true


func test_host_join_through_fake_relay() -> bool:
	var relay := FakeRelay.new(5)
	var a: Node = _online(relay, "user://test_rejoin_a.json")
	var b: Node = _online(relay, "user://test_rejoin_b.json")
	var ready: Array = []
	a.match_ready.connect(func() -> void: ready.append("a"))
	b.match_ready.connect(func() -> void: ready.append("b"))
	a.host("Ann", CardDB.deck(&"grove_guard"))
	relay.pump()
	assert_eq(a.state, &"hosting", "hosting")
	assert_eq(a.session.code, "FAKE-01", "has the room code")
	b.join("fake01", "Bo", CardDB.deck(&"blaze_rush"))
	relay.pump()
	assert_eq([a.state, b.state], [&"playing", &"playing"], "both playing")
	assert_eq(ready, ["a", "b"], "match_ready on both")
	assert_eq(b.session.rival_name(), "Ann", "names arrive")
	assert_true(FileAccess.file_exists("user://test_rejoin_a.json"), "rejoin file saved")
	assert_true(a.has_rejoin(), "has_rejoin")
	a.leave()
	relay.pump()
	assert_eq(b.session.over, {"winner": 1, "reason": "concede"}, "leaving concedes")
	assert_true(not FileAccess.file_exists("user://test_rejoin_a.json"), "rejoin file removed on leave")
	assert_eq(a.state, &"idle", "back to idle")
	a.free()
	b.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://test_rejoin_b.json"))
	return true


func test_reconnect_after_drop() -> bool:
	var relay := FakeRelay.new(6)
	var a: Node = _online(relay, "user://test_rejoin_a.json")
	var b: Node = _online(relay, "user://test_rejoin_b.json")
	a.host("Ann", CardDB.deck(&"grove_guard"))
	relay.pump()
	b.join("FAKE-01", "Bo", CardDB.deck(&"blaze_rush"))
	relay.pump()
	var ba := BotBrain.new(1)
	var bb := BotBrain.new(2)
	for i: int in 8:
		ba.step(a.session)
		bb.step(b.session)
		relay.pump()
	ba.step(a.session)
	assert_eq(b.session.status, &"playing", "match still running at the drop")
	relay.drop(1)
	assert_eq(b.state, &"reconnecting", "reconnecting after the drop")
	b._process(1.1)
	relay.pump()
	ba.step(a.session)
	assert_eq(b.state, &"playing", "back in the match")
	assert_eq(b.session.state.digest(), a.session.state.digest(), "same state as the rival")
	a.free()
	b.free()
	for p: String in ["user://test_rejoin_a.json", "user://test_rejoin_b.json"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
	return true


func test_gives_up_after_the_window() -> bool:
	var relay := FakeRelay.new(7)
	var a: Node = _online(relay, "user://test_rejoin_a.json")
	var b: Node = _online(relay, "user://test_rejoin_b.json")
	a.host("Ann", CardDB.deck(&"grove_guard"))
	relay.pump()
	b.join("FAKE-01", "Bo", CardDB.deck(&"blaze_rush"))
	relay.pump()
	relay.drop(1)
	b.link_factory = func(_path: String) -> Object: return DeadLink.new()
	for i: int in 70:
		b._process(1.0)
	assert_eq(b.state, &"error", "gave up")
	assert_eq(b.message, "Lost the connection", "says why")
	a.free()
	b.free()
	for p: String in ["user://test_rejoin_a.json", "user://test_rejoin_b.json"]:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
	return true


func test_unreachable_server() -> bool:
	var o: Node = ONLINE.new()
	var made: Array = []
	o.link_factory = func(_path: String) -> Object:
		var l := DeadLink.new()
		made.append(l)
		return l
	o.rejoin_path = "user://test_rejoin_c.json"
	o.host("Ann", CardDB.deck(&"grove_guard"))
	(made[0] as DeadLink).closed.emit(1006, "")
	assert_eq(o.state, &"error", "error state")
	assert_eq(o.message, "Can't reach the Dream Isles server", "says why")
	o.free()
	return true


func test_bad_code_makes_no_connection() -> bool:
	var o: Node = ONLINE.new()
	var made: Array = []
	o.link_factory = func(_path: String) -> Object:
		made.append(1)
		return DeadLink.new()
	o.join("xyz", "Ann", CardDB.deck(&"grove_guard"))
	assert_eq(made.size(), 0, "no connection attempt")
	assert_eq(o.state, &"error", "error")
	assert_eq(o.message, "That isn't a room code", "says why")
	o.free()
	return true
