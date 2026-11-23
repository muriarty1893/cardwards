extends TestCase
## Drives the real match scene's InputController with screen positions, as a mouse would.


func _load_match() -> MatchController:
	var m: MatchController = await Fx.load_match()
	assert_true(m != null, "human's turn reached")
	return m


func _island_screen(m: MatchController, p: int, l: int) -> Vector2:
	return m.rig.camera.unproject_position(m.board.anchor(p, l) - Vector3(0, 0.45, 0))


func test_drag_creature_onto_island() -> bool:
	var m: MatchController = await _load_match()
	var s: GameState = m.state
	s.players[0].hand.clear()
	s.players[0].hand.append(CardDB.card(&"cinderpup"))
	m.refresh_ui()
	m.input.on_drag_started(0)
	assert_eq(m.input.mode, InputController.Mode.DRAGGING, "dragging")
	m.input.on_dropped(0, _island_screen(m, 0, 2))
	assert_true(s.players[0].lanes[2].creature != null, "creature placed on lane 2")
	assert_eq(s.players[0].lanes[2].creature.card.id, &"cinderpup", "right card")
	m.queue_free()
	return true


func test_drop_on_enemy_island_rejected() -> bool:
	var m: MatchController = await _load_match()
	var s: GameState = m.state
	s.players[0].hand.clear()
	s.players[0].hand.append(CardDB.card(&"cinderpup"))
	m.refresh_ui()
	m.input.on_drag_started(0)
	m.input.on_dropped(0, _island_screen(m, 1, 1))
	assert_eq(s.players[0].hand.size(), 1, "card still in hand")
	m.queue_free()
	return true


func test_spell_targeting_by_click() -> bool:
	var m: MatchController = await _load_match()
	var s: GameState = m.state
	Fx.put_creature(s, 1, 3, &"mossback")
	m.sync_all()
	s.players[0].hand.clear()
	s.players[0].hand.append(CardDB.card(&"fireball"))
	s.players[0].magic = 9
	m.refresh_ui()
	m.input.on_drag_started(0)
	m.input.on_dropped(0, Vector2(640, 300))
	assert_eq(m.input.mode, InputController.Mode.TARGETING, "targeting after spell drop")
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = _island_screen(m, 1, 3)
	m.input._unhandled_input(click)
	assert_eq(s.players[1].lanes[3].creature.damage, 3, "fireball hit the clicked creature")
	m.queue_free()
	return true


func test_click_boop() -> bool:
	var m: MatchController = await _load_match()
	var s: GameState = m.state
	Fx.put_creature(s, 0, 1, &"magmaw")
	m.sync_all()
	m.refresh_ui()
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = _island_screen(m, 0, 1)
	m.input._unhandled_input(click)
	var up := click.duplicate() as InputEventMouseButton
	up.pressed = false
	m.input._input(up)  # a press and release in place is a click: boop, not an attack
	assert_eq(s.players[1].hero_hp, GameState.START_HP - 2, "magmaw boop hit the hero")
	m.queue_free()
	return true


func test_pause_blocks_play() -> bool:
	var m: MatchController = await _load_match()
	var s: GameState = m.state
	s.players[0].hand.clear()
	s.players[0].hand.append(CardDB.card(&"cinderpup"))
	m.refresh_ui()
	m.hud.pause_button.pressed.emit()
	assert_true(m.hud.is_paused(), "pause menu open")
	assert_true(not m.hand.enabled and not m.input.enabled, "hand and board input off while paused")
	m.input.on_drag_started(0)
	m.input.on_dropped(0, _island_screen(m, 0, 2))
	assert_eq(s.players[0].hand.size(), 1, "card not played while paused")
	assert_eq(s.players[0].lanes[2].creature, null, "lane still empty")
	m.hud.close_pause()
	assert_true(m.hand.enabled and m.input.enabled, "input back after resume")
	m.queue_free()
	return true


# --- Drag to attack (Rules 2.0) ---

func _mouse(m: MatchController, pos: Vector2, pressed: bool) -> void:
	var b := InputEventMouseButton.new()
	b.button_index = MOUSE_BUTTON_LEFT
	b.pressed = pressed
	b.position = pos
	if pressed:
		m.input._unhandled_input(b)
	else:
		m.input._input(b)


func _drag(m: MatchController, from: Vector2, to: Vector2) -> void:
	_mouse(m, from, true)
	var mv := InputEventMouseMotion.new()
	mv.position = to
	m.input._input(mv)
	_mouse(m, to, false)


func _settle(m: MatchController) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	await tree.process_frame
	var n: int = 0
	while m.busy and n < 2000:
		await tree.process_frame
		n += 1


func _attack_ready(m: MatchController) -> void:
	m.timing_bar.auto_stop = true
	m.timing_bar.force_needle = 0.5


func test_drag_attack_hits_target() -> bool:
	var m: MatchController = await _load_match()
	var s: GameState = m.state
	_attack_ready(m)
	Fx.put_creature(s, 0, 0, &"flarebeak")
	Fx.put(s, 1, 2, Fx.card(&"dummy", CardData.Kind.CREATURE, 1, 0, 30))  # no hit-back, can't die
	m.sync_all()
	m.refresh_ui()
	_drag(m, _island_screen(m, 0, 0), _island_screen(m, 1, 2))
	await _settle(m)
	assert_eq(s.players[0].lanes[0].creature.attacks_used, 1, "attacked")
	assert_true(s.players[1].lanes[2].creature.damage > 0, "target damaged")
	m.queue_free()
	return true


func test_drag_attack_hero() -> bool:
	var m: MatchController = await _load_match()
	var s: GameState = m.state
	_attack_ready(m)
	for l: int in 4:
		s.players[1].lanes[l].creature = null
	Fx.put_creature(s, 0, 1, &"flarebeak")
	m.sync_all()
	m.refresh_ui()
	var before: int = s.players[1].hero_hp
	_drag(m, _island_screen(m, 0, 1), m.hud.hero_rect(false).get_center())
	await _settle(m)
	assert_true(s.players[1].hero_hp < before, "enemy hero hit")
	m.queue_free()
	return true


func test_guard_highlight_and_dim() -> bool:
	var m: MatchController = await _load_match()
	var s: GameState = m.state
	for l: int in 4:
		s.players[1].lanes[l].creature = null
	Fx.put_creature(s, 0, 0, &"flarebeak")
	Fx.put_creature(s, 1, 1, &"mossback")
	Fx.put_creature(s, 1, 3, &"cinderpup")
	m.sync_all()
	m.refresh_ui()
	_mouse(m, _island_screen(m, 0, 0), true)
	var mv := InputEventMouseMotion.new()
	mv.position = _island_screen(m, 1, 3)
	m.input._input(mv)
	assert_eq(m.input.mode, InputController.Mode.AIMING, "aiming")
	assert_eq(m.board.island(1, 1).highlight, Island.Highlight.GUARD, "guard pulses")
	assert_true((m.creature_views[1][3] as CreatureView).dimmed, "non-guard dimmed")
	assert_true(m.attack_arrow.visible, "arrow shown")
	m.input.cancel()
	assert_true(not m.attack_arrow.visible and not (m.creature_views[1][3] as CreatureView).dimmed, "cancel clears")
	m.queue_free()
	return true


func test_stale_attack_rejected() -> bool:
	var m: MatchController = await _load_match()
	var s: GameState = m.state
	_attack_ready(m)
	Fx.put_creature(s, 0, 0, &"flarebeak")
	Fx.put_creature(s, 1, 2, &"cinderpup")
	m.sync_all()
	m.refresh_ui()
	_mouse(m, _island_screen(m, 0, 0), true)
	s.players[1].lanes[2].creature = null  # target gone mid-drag
	m.sync_all()
	_mouse(m, _island_screen(m, 1, 2), false)
	await _settle(m)
	assert_eq(s.players[0].lanes[0].creature.attacks_used, 0, "nothing happened")
	assert_true(m.toast.modulate.a > 0.5, "toast shown")
	m.busy = true
	_mouse(m, _island_screen(m, 0, 0), true)
	assert_eq(m.input.mode, InputController.Mode.IDLE, "no aiming while busy")
	m.busy = false
	m.queue_free()
	return true


func test_click_still_boops() -> bool:
	var m: MatchController = await _load_match()
	var s: GameState = m.state
	Fx.put_creature(s, 0, 0, &"gumdrop")
	Fx.fill_deck(s, 0, &"mossback", 3)
	m.sync_all()
	m.refresh_ui()
	_mouse(m, _island_screen(m, 0, 0), true)
	_mouse(m, _island_screen(m, 0, 0), false)
	await _settle(m)
	assert_true(s.players[0].lanes[0].creature.booped, "a click boops")
	m.queue_free()
	return true
