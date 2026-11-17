extends TestCase
## Attacks start from where creatures stand and end where their target stands; everything is let
## go afterwards; the rival reacts; attacks get a close-up; pointing at the rival or the table in
## front of them targets the enemy hero; a half-lane picks its creature anywhere in it.


func _fast(m: MatchController) -> void:
	m.player.speed = 20.0
	m.pace = 20.0
	m.timing_bar.auto_stop = true
	m.timing_bar.force_needle = 0.5


func _clear_board(m: MatchController) -> void:
	for p: int in 2:
		for l: int in 4:
			m.state.players[p].lanes[l].creature = null
			m.state.players[p].lanes[l].building = null
	m.sync_all()


func _settle(m: MatchController) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	for i: int in 300:
		await tree.process_frame
		var moving: bool = m.busy
		for p: int in 2:
			for l: int in 4:
				var v: CreatureView = m.creature_views[p][l]
				moving = moving or (is_instance_valid(v) and v.busy)
		if not moving:
			return


func _setup(attacker: StringName, target_hp: int) -> MatchController:
	var m: MatchController = await Fx.load_match()
	_fast(m)
	_clear_board(m)
	Fx.put_creature(m.state, 0, 1, attacker)
	Fx.put(m.state, 1, 2, Fx.card(&"dummy", CardData.Kind.CREATURE, 1, 1, target_hp))
	m.sync_all()
	m.refresh_ui()
	return m


func _flat(v: Node3D) -> Vector2:
	return Vector2(v.global_position.x, v.global_position.z)


func test_attack_from_mid_roam_ends_at_target() -> bool:
	var m: MatchController = await _setup(&"flarebeak", 30)
	var a: CreatureView = m.creature_views[0][1]
	var t: CreatureView = m.creature_views[1][2]
	var za: Rect2 = m.board.roam_rect(0, 1)
	var zt: Rect2 = m.board.roam_rect(1, 2)
	a.position = Vector3(za.position.x + 0.2, a.position.y, za.end.y - 0.3)
	t.position = Vector3(zt.end.x - 0.2, t.position.y, zt.position.y + 0.4)
	var closest: Array[float] = [1e9]
	var watch := func() -> void:
		if is_instance_valid(a) and is_instance_valid(t):
			closest[0] = minf(closest[0], _flat(a).distance_to(_flat(t)))
	var tree := Engine.get_main_loop() as SceneTree
	tree.process_frame.connect(watch)
	await m.request_attack(1, 2)
	await _settle(m)
	tree.process_frame.disconnect(watch)
	assert_true(closest[0] < 0.6, "attacker reached its target where it stood (closest %.2f)" % closest[0])
	m.queue_free()
	return true


func test_all_released_after_sequences() -> bool:
	var m: MatchController = await _setup(&"flarebeak", 30)
	await m.request_attack(1, 2)
	await _settle(m)
	# A lethal attack (death) next turn-equivalent: make the attacker ready again.
	m.state.players[0].lanes[1].creature.attacks_used = 0
	m.state.players[1].lanes[2].creature.damage = 29
	await m.request_attack(1, 2)
	await _settle(m)
	for p: int in 2:
		for l: int in 4:
			var v: CreatureView = m.creature_views[p][l]
			if not is_instance_valid(v):
				continue
			assert_true(not v.busy and not v.aiming, "p%d l%d released" % [p, l])
			assert_true(m.board.roam_rect(p, l).grow(0.05).has_point(_flat(v)), "p%d l%d back in its zone (%s)" % [p, l, v.position])
	assert_true(not is_instance_valid(m.creature_views[1][2]), "the target died")
	m.queue_free()
	return true


func test_target_at_rival_rect() -> bool:
	var m: MatchController = await Fx.load_match()
	var r: Rect2 = m.rival.hero_rect(m.rig.camera)
	assert_eq(m.input._target_at(r.get_center()), -1, "pointing at the rival = enemy hero")
	m.queue_free()
	return true


func test_target_at_table_strip() -> bool:
	var m: MatchController = await Fx.load_match()
	var mid := Vector3(0.0, 0.0, (Board.TRAY_RECT.position.y + Room.TABLE_RECT.position.y) / 2.0)
	var at: Vector2 = m.rig.camera.unproject_position(mid)
	assert_eq(m.input._target_at(at), -1, "the table in front of the rival = enemy hero")
	m.queue_free()
	return true


func test_press_anywhere_on_half_lane_picks() -> bool:
	var m: MatchController = await _setup(&"flarebeak", 30)
	var a: CreatureView = m.creature_views[0][1]
	var z: Rect2 = m.board.roam_rect(0, 1)
	a.position = Vector3(z.position.x + 0.1, a.position.y, z.get_center().y)
	var press_at: Vector2 = m.rig.camera.unproject_position(Vector3(z.end.x - 0.1, Island.TOP_Y, z.get_center().y))
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	ev.position = press_at
	m.input._unhandled_input(ev)
	assert_eq(m.input.mode, InputController.Mode.AIMING, "aiming from the creature in that half-lane")
	assert_true(a.aiming, "the creature knows it's being aimed with")
	m.input.cancel()
	assert_true(not a.aiming, "aim flag cleared on cancel")
	m.queue_free()
	return true


func test_rival_reacts_to_events() -> bool:
	var m: MatchController = await Fx.load_match()
	var tree := Engine.get_main_loop() as SceneTree
	m.player.play([GameEvent.make(&"creature_played", {"player": 1, "lane": 0, "card": &"cinderpup"})])
	await tree.process_frame
	assert_eq(m.rival.upper_anim(), &"Interact", "leans in to play a card")
	await _settle(m)
	m.player.play([GameEvent.make(&"hero_damaged", {"player": 0, "amount": 1, "hp": 24})])
	await tree.process_frame
	assert_eq(m.rival.upper_anim(), &"Cheer", "cheers when it hits you")
	await _settle(m)
	await tree.create_timer(2.0).timeout
	m.player.play([GameEvent.make(&"hero_damaged", {"player": 1, "amount": 1, "hp": 24})])
	await tree.process_frame
	assert_eq(m.rival.upper_anim(), &"Hit_A", "flinches when hit")
	m.queue_free()
	await tree.process_frame
	return true


func test_close_up_per_attack() -> bool:
	var was: bool = Settings.battle_closeups
	for on: bool in [true, false]:
		Settings.battle_closeups = on
		var m: MatchController = await _setup(&"flarebeak", 30)
		var before: int = m.rig.close_up_count
		await m.request_attack(1, 2)
		await _settle(m)
		assert_eq(m.rig.close_up_count - before, 1 if on else 0, "close-ups %s" % ("on" if on else "off"))
		m.queue_free()
	Settings.battle_closeups = was
	return true


## The attacker dies mid-aim: the aim is dropped cleanly.
func test_aim_cancelled_when_attacker_dies() -> bool:
	var m: MatchController = await _setup(&"flarebeak", 30)
	var z: Rect2 = m.board.roam_rect(0, 1)
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = true
	ev.position = m.rig.camera.unproject_position(Vector3(z.get_center().x, Island.TOP_Y, z.get_center().y))
	m.input._unhandled_input(ev)
	assert_eq(m.input.mode, InputController.Mode.AIMING, "aiming")
	m.state.players[0].lanes[1].creature = null
	await m.player.play([GameEvent.make(&"creature_destroyed", {"player": 0, "lane": 1, "card": &"flarebeak"})])
	assert_eq(m.input.mode, InputController.Mode.IDLE, "aim dropped")
	assert_true(not m.attack_arrow.visible, "arrow cleared")
	m.queue_free()
	return true
