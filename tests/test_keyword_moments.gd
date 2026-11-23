extends TestCase
## Keyword moments (keywords spec 4) play on the real match: looks come and go with them and the
## views stay in sync.


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func _match() -> MatchController:
	var m: MatchController = await Fx.load_match()
	m.player.speed = 20.0
	m.pace = 20.0
	for p: int in 2:
		for l: int in 4:
			m.state.players[p].lanes[l].creature = null
			m.state.players[p].lanes[l].building = null
	m.sync_all()
	return m


func _cr(m: MatchController, p: int, l: int) -> GameState.CreatureState:
	return m.state.players[p].lanes[l].creature


func _play(m: MatchController, type: StringName, d: Dictionary) -> void:
	var ev: Array[GameEvent] = [GameEvent.make(type, d)]
	await m.player.play(ev)


func test_bubble_pops() -> bool:
	var m: MatchController = await _match()
	Fx.put_creature(m.state, 1, 1, &"cinderpup")
	_cr(m, 1, 1).gained.append(&"bubble")
	_cr(m, 1, 1).bubble = true
	m.sync_all()
	var fx: KeywordFx = KeywordFx.of(m.creature_views[1][1])
	assert_true(fx != null and fx.has_part(&"bubble"), "bubble up")
	_cr(m, 1, 1).bubble = false
	await _play(m, &"bubble_popped", {"player": 1, "lane": 1})
	assert_true(not fx.has_part(&"bubble"), "bubble gone after the pop")
	assert_true(not "bubble" in m.overlay.keyword_chips(1, 1), "chip gone")
	m.queue_free()
	return true


func test_hidden_revealed() -> bool:
	var m: MatchController = await _match()
	Fx.put_creature(m.state, 0, 2, &"cinderpup")
	_cr(m, 0, 2).gained.append(&"hidden")
	_cr(m, 0, 2).hidden = true
	m.sync_all()
	var v: CreatureView = m.creature_views[0][2]
	assert_true(v.hidden_look, "see-through while hidden")
	_cr(m, 0, 2).hidden = false
	await _play(m, &"revealed", {"player": 0, "lane": 2})
	assert_true(not v.hidden_look, "solid once revealed")
	m.queue_free()
	return true


func test_hush_strips_looks() -> bool:
	var m: MatchController = await _match()
	Fx.put_creature(m.state, 1, 0, &"mossback")
	m.sync_all()
	var fx: KeywordFx = KeywordFx.of(m.creature_views[1][0])
	assert_true(fx.has_part(&"guard"), "guard wall up")
	_cr(m, 1, 0).hushed = true
	await _play(m, &"hushed", {"player": 1, "lane": 0})
	assert_true(not fx.has_part(&"guard"), "hush took the wall")
	assert_eq(m.overlay.keyword_chips(1, 0), [] as Array[String], "no chips")
	m.queue_free()
	return true


func test_keyword_gained_shows_at_once() -> bool:
	var m: MatchController = await _match()
	Fx.put_creature(m.state, 0, 1, &"cinderpup")
	m.sync_all()
	_cr(m, 0, 1).gained.append(&"second_wind")
	await _play(m, &"keyword_gained", {"player": 0, "lane": 1, "keyword": &"second_wind"})
	var fx: KeywordFx = KeywordFx.of(m.creature_views[0][1])
	assert_true(fx != null and fx.has_part(&"second_wind"), "halo on")
	assert_true("second_wind" in m.overlay.keyword_chips(0, 1), "chip on")
	m.queue_free()
	return true


func test_buff_and_leech_play_and_clean_up() -> bool:
	var m: MatchController = await _match()
	Fx.put_creature(m.state, 0, 3, &"cinderpup")
	m.sync_all()
	var before: int = m.get_child_count()
	await _play(m, &"buffed", {"player": 0, "lane": 3, "atk": 1, "hp": 1})
	await _play(m, &"leeched", {"player": 0, "lane": 3, "amount": 2})
	await _tree().create_timer(1.5).timeout
	var after: int = m.get_children().filter(func(n: Node) -> bool: return not n.is_queued_for_deletion()).size()
	assert_true(after <= before + 1, "wisps and rings cleaned up (%d -> %d)" % [before, after])
	assert_eq(m.overlay.tag(0, 3).modulate, Color.WHITE, "tag flash ends")
	m.queue_free()
	return true


func test_venom_kill_turns_green() -> bool:
	var m: MatchController = await _match()
	Fx.put_creature(m.state, 0, 0, &"cinderpup")
	_cr(m, 0, 0).gained.append(&"venom")
	Fx.put_creature(m.state, 1, 0, &"magmaw")
	m.sync_all()
	m.state.active = 0
	assert_eq(Rules.validate(m.state, Action.attack(0, 0, 0)), "", "attack is legal")
	await m.perform(Action.attack(0, 0, 0))
	assert_true(m.state.players[1].lanes[0].creature == null, "venom killed the big one")
	assert_true(m.player.get("_venomed").has("1:0"), "its death was a venom death")
	assert_true(not is_instance_valid(m.creature_views[1][0]), "view gone")
	m.queue_free()
	return true
