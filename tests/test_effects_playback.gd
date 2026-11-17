extends TestCase
## Every spell and every boop plays through the real match scene without errors, the views
## end up matching the state, and hit-stop always restores the time scale.


func _clear_board(m: MatchController) -> void:
	for p: int in 2:
		for l: int in 4:
			m.state.players[p].lanes[l].creature = null
			m.state.players[p].lanes[l].building = null
	m.sync_all()


func _views_match(m: MatchController, label: String) -> void:
	for p: int in 2:
		for l: int in 4:
			var has: bool = m.state.players[p].lanes[l].creature != null
			assert_eq(is_instance_valid(m.creature_views[p][l]), has, "%s: view p%d l%d" % [label, p, l])
	assert_eq(Engine.time_scale, 1.0, "%s: time scale restored" % label)


func _fast(m: MatchController) -> void:
	m.player.speed = 20.0
	m.pace = 20.0


func test_every_spell_plays() -> bool:
	var m: MatchController = await Fx.load_match()
	assert_true(m != null, "match loaded")
	_fast(m)
	var s: GameState = m.state
	for c: CardData in CardDB.all_cards():
		if c.kind != CardData.Kind.SPELL:
			continue
		_clear_board(m)
		Fx.put_creature(s, 0, 0, &"mossback", 3)
		Fx.put_creature(s, 0, 1, &"sporeling", 1)
		for l: int in 3:
			Fx.put_creature(s, 1, l, &"glacier_tortoise")
		s.players[0].discard.append(CardDB.card(&"cinderpup"))
		m.sync_all()
		var i: int = Fx.give(s, 0, c.id)
		s.players[0].magic = 9
		var who: StringName = Targeting.chosen_who(c, &"on_play")
		var valid: Array[Dictionary] = Targeting.valid(s, 0, who)
		var need: int = 0 if who == &"" else Targeting.needed(who)
		var targets: Array[Dictionary] = []
		for t: int in mini(need, valid.size()):
			targets.append(valid[t])
		await m.perform(Action.play(0, i, -1, targets))
		_views_match(m, String(c.id))
	m.queue_free()
	return true


func test_every_boop_plays() -> bool:
	var m: MatchController = await Fx.load_match()
	assert_true(m != null, "match loaded")
	_fast(m)
	var s: GameState = m.state
	for c: CardData in CardDB.all_cards():
		if not c.has_effect(&"on_boop"):
			continue
		_clear_board(m)
		Fx.put_creature(s, 0, 1, c.id)
		Fx.put_creature(s, 0, 2, &"mossback", 2)
		Fx.put_creature(s, 1, 1, &"glacier_tortoise")
		Fx.put_creature(s, 1, 2, &"cinderpup")
		Fx.put_building(s, 1, 1, &"kiln_tower")
		m.sync_all()
		var who: StringName = Targeting.chosen_who(c, &"on_boop")
		var valid: Array[Dictionary] = Targeting.valid(s, 0, who, 1)
		var targets: Array[Dictionary] = []
		if who != &"" and not valid.is_empty():
			targets.append(valid[0])
		var err: String = Rules.validate(s, Action.boop(0, 1, targets))
		assert_eq(err, "", "%s boop is legal" % c.id)
		await m.perform(Action.boop(0, 1, targets))
		_views_match(m, String(c.id))
	m.queue_free()
	return true


# --- Rules 2.0 combat playback ---

func _ready_attack(m: MatchController) -> void:
	_fast(m)
	m.timing_bar.auto_stop = true
	m.timing_bar.force_needle = 0.5


func _settle(m: MatchController) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	for i: int in 240:
		await tree.process_frame
		var moving: bool = m.busy
		for p: int in 2:
			for l: int in 4:
				var v: CreatureView = m.creature_views[p][l]
				moving = moving or (is_instance_valid(v) and v.busy)
		if not moving:
			return


func test_attack_cross_lane_playback() -> bool:
	var m: MatchController = await Fx.load_match()
	_ready_attack(m)
	_clear_board(m)
	Fx.put_creature(m.state, 0, 0, &"flarebeak")
	Fx.put(m.state, 1, 3, Fx.card(&"wall", CardData.Kind.CREATURE, 1, 2, 30))
	m.sync_all()
	m.refresh_ui()
	await m.request_attack(0, 3)
	await _settle(m)
	var v: CreatureView = m.creature_views[0][0]
	assert_true(m.board.roam_rect(0, 0).grow(0.05).has_point(Vector2(v.position.x, v.position.z)), "attacker back in its lane (%s)" % v.position)
	assert_true(not v.busy, "attacker released")
	assert_eq(m.state.players[0].lanes[0].creature.damage, 2, "took the hit-back")
	_views_match(m, "cross-lane attack")
	m.queue_free()
	return true


func test_hit_back_number_shown() -> bool:
	var m: MatchController = await Fx.load_match()
	_ready_attack(m)
	_clear_board(m)
	Fx.put_creature(m.state, 0, 1, &"flarebeak")
	Fx.put(m.state, 1, 1, Fx.card(&"wall", CardData.Kind.CREATURE, 1, 2, 30))
	m.sync_all()
	m.refresh_ui()
	await m.request_attack(1, 1)
	var found: bool = false
	for n: Node in m.find_children("*", "Label3D", true, false):
		if n is DamageNumber and (n as Label3D).text.begins_with("-2"):
			found = true
	assert_true(found, "a -2 number for the hit-back")
	m.queue_free()
	return true


func test_ai_attack_shows_arrow() -> bool:
	var m: MatchController = await Fx.load_match()
	_fast(m)
	_clear_board(m)
	var s: GameState = m.state
	s.players[1].hand.clear()
	Fx.put_creature(s, 1, 2, &"flarebeak")
	s.active = MatchController.AI
	m.sync_all()
	m.busy = true
	var tree := Engine.get_main_loop() as SceneTree
	var seen: bool = false
	var done: Array[bool] = [false]
	var run := func() -> void:
		await m._ai_turn()
		done[0] = true
	run.call()
	for i: int in 3000:
		if done[0]:
			break
		seen = seen or m.attack_arrow.visible
		await tree.process_frame
	assert_true(seen, "the arrow showed the AI's attack")
	assert_true(not m.attack_arrow.visible, "and was cleared")
	m.queue_free()
	return true
