extends TestCase
## The menu (II button / Esc) works at any time; against the AI it really pauses the game.


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func test_menu_enabled_on_rival_turn() -> bool:
	var m: MatchController = await Fx.load_match()
	m.apply_local(Action.end_turn(MatchController.HUMAN))
	m.refresh_ui()
	assert_eq(m.state.active, MatchController.AI, "rival's turn")
	assert_true(not m.hud.pause_button.disabled, "menu button usable on the rival's turn")
	assert_true(m.hud.end_turn_button.disabled, "END TURN still locked")
	m.busy = true
	m.refresh_ui()
	assert_true(not m.hud.pause_button.disabled, "menu button usable while something plays")
	m.queue_free()
	return true


func test_ai_waits_while_menu_open() -> bool:
	var m: MatchController = await Fx.load_match()
	m.apply_local(Action.end_turn(MatchController.HUMAN))
	m.hud.toggle_pause()
	assert_true(m.hud.is_paused(), "menu open")
	var before: String = m.seats.real.digest()
	(m.driver as AiRival).rival_turn()
	await _tree().create_timer(1.0).timeout
	assert_eq(m.seats.real.digest(), before, "the AI made no move while the menu was open")
	m.hud.toggle_pause()
	var waited: int = 0
	while m.state.active != MatchController.HUMAN and waited < 600:
		await _tree().create_timer(0.05).timeout
		waited += 1
	assert_eq(m.state.active, MatchController.HUMAN, "the AI finished its turn after the menu closed")
	m.queue_free()
	return true


func test_escape_toggles_menu() -> bool:
	var m: MatchController = await Fx.load_match()
	var ev := InputEventKey.new()
	ev.keycode = KEY_ESCAPE
	ev.pressed = true
	m.get_viewport().push_input(ev)
	await _tree().process_frame
	assert_true(m.hud.is_paused(), "Esc opens the menu")
	m.get_viewport().push_input(ev.duplicate())
	await _tree().process_frame
	assert_true(not m.hud.is_paused(), "Esc closes it again")
	m.results.show_result(true, 3)
	m.get_viewport().push_input(ev.duplicate())
	await _tree().process_frame
	assert_true(not m.hud.is_paused(), "no menu over the results")
	m.queue_free()
	return true
