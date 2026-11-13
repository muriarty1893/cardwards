extends TestCase
## Drives the real match scene's InputController with screen positions, as a mouse would.


func _load_match() -> MatchController:
	var tree := Engine.get_main_loop() as SceneTree
	var m := (load("res://view/match.tscn") as PackedScene).instantiate() as MatchController
	tree.root.add_child(m)
	await tree.process_frame
	await tree.process_frame
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
	assert_eq(s.players[1].hero_hp, 23, "magmaw boop hit the hero")
	m.queue_free()
	return true
