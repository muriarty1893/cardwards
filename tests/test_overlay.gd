extends TestCase
## Stat bars, boop buttons and hover lookups follow the game state and the pieces.


func test_stats_match_state() -> bool:
	var m: MatchController = await Fx.load_match()
	assert_true(m != null, "match loaded")
	Fx.put_creature(m.state, 0, 1, &"magmaw", 2)
	Fx.put_creature(m.state, 1, 2, &"mossback", 0)
	Fx.put_building(m.state, 0, 1, &"kiln_tower")
	m.sync_all()
	await (Engine.get_main_loop() as SceneTree).process_frame
	var e: Dictionary = m.overlay.entry(0, 1)
	assert_eq(e["atk"], Rules.effective_attack(m.state, 0, 1), "atk with kiln")
	assert_eq(e["hp"], 2, "hp left 4-2")
	assert_eq(e["max"], 4, "max hp")
	assert_eq(e["bar_color"], Color("#ffcf3a"), "50% is yellow")
	assert_true(not m.overlay.entry(0, 0)["visible"], "empty lane hidden")
	m.queue_free()
	return true

func test_boop_button_matches_rules() -> bool:
	var m: MatchController = await Fx.load_match()
	Fx.put_creature(m.state, 0, 0, &"gumdrop")    # on_boop
	Fx.put_creature(m.state, 0, 1, &"cinderpup")  # no boop
	m.sync_all(); m.refresh_ui()
	await (Engine.get_main_loop() as SceneTree).process_frame
	assert_eq(m.board.boop_plate(0).state, BoopPlate.State.LIT, "gumdrop boop ready")
	assert_eq(m.board.boop_plate(1).state, BoopPlate.State.DIM, "no lit plate without boop")
	m.input.try_plate(m.board.boop_point(0))
	await (Engine.get_main_loop() as SceneTree).create_timer(1.0).timeout
	assert_true(m.state.players[0].lanes[0].creature.booped, "boop resolved via button")
	m.queue_free()
	return true

func test_boop_buttons_disabled_while_busy() -> bool:
	var m: MatchController = await Fx.load_match()
	Fx.put_creature(m.state, 0, 0, &"gumdrop")
	m.sync_all()
	m.busy = true
	m.refresh_ui()
	await (Engine.get_main_loop() as SceneTree).process_frame
	assert_eq(m.board.boop_plate(0).state, BoopPlate.State.DIM, "dim while busy")
	m.queue_free()
	return true

func test_overlay_follows_swap() -> bool:
	var m: MatchController = await Fx.load_match()
	Fx.put_creature(m.state, 0, 0, &"gumdrop")
	Fx.put_creature(m.state, 0, 3, &"magmaw")
	m.sync_all()
	var i: int = Fx.give(m.state, 0, &"swap_trick")
	m.state.players[0].magic = 5
	await m.perform(Action.play(0, i, -1, [{"player": 0, "lane": 0}, {"player": 0, "lane": 3}]))
	await (Engine.get_main_loop() as SceneTree).process_frame
	assert_eq(m.overlay.entry(0, 0)["atk"], Rules.effective_attack(m.state, 0, 0), "lane 0 shows magmaw now")
	assert_eq(m.board.boop_plate(3).state, BoopPlate.State.LIT, "gumdrop's plate lit in lane 3")
	m.queue_free()
	return true

func test_piece_at_finds_creature() -> bool:
	var m: MatchController = await Fx.load_match()
	Fx.put_creature(m.state, 1, 2, &"mossback")
	m.sync_all()
	var v: CreatureView = m.creature_views[1][2]
	var at: Vector2 = m.rig.camera.unproject_position(v.global_position + Vector3(0, Island.TOP_Y - CreatureView.BASE_Y + v.height * 0.5, 0))
	var hit: Dictionary = m.overlay.piece_at(at)
	assert_eq(hit.get("lane", -1), 2, "lane"); assert_eq(hit.get("player", -1), 1, "player")
	m.queue_free()
	return true


func test_hover_card_above_hud() -> bool:
	var m: MatchController = await Fx.load_match()
	assert_true(m.overlay.hover_layer().layer > MatchController.HUD_LAYER, "hover card draws over the HUD")
	m.queue_free()
	return true


func test_overlay_uses_title_font_and_icons() -> bool:
	var m: MatchController = await Fx.load_match()
	Fx.put_creature(m.state, 0, 1, &"magmaw")
	Fx.put_building(m.state, 0, 1, &"kiln_tower")
	m.sync_all()
	await (Engine.get_main_loop() as SceneTree).process_frame
	var atk := m.overlay.find_child("Atk", true, false) as Label
	assert_true(atk != null and atk.get_theme_font("font").resource_path == UiStyle.TITLE_FONT, "attack number in Lilita One")
	var icon := m.overlay.badge(0, 1).find_child("Icon", true, false) as TextureRect
	assert_true(icon != null and icon.texture != null and icon.texture.resource_path == VisualDB.badge_icon(&"kiln_tower"), "kiln badge shows its icon")
	m.queue_free()
	return true


func test_readiness_states() -> bool:
	var m: MatchController = await Fx.load_match()
	var s: GameState = m.state
	m.player.speed = 20.0
	m.pace = 20.0
	m.timing_bar.auto_stop = true
	m.timing_bar.force_needle = 0.5
	for p: int in 2:
		for l: int in 4:
			s.players[p].lanes[l].creature = null
	Fx.put_creature(s, 0, 0, &"flarebeak")
	s.players[0].magic = 9
	s.players[0].hand = [CardDB.card(&"ashmite")] as Array[CardData]  # blaze rush lands: ember
	m.sync_all()
	await m.perform(Action.play(0, 0, 1))
	m.refresh_pieces()
	assert_eq((m.creature_views[0][1] as CreatureView).readiness, CreatureView.Readiness.SLEEPING, "just played: asleep")
	assert_eq((m.creature_views[0][0] as CreatureView).readiness, CreatureView.Readiness.READY, "ready one")
	await m.request_attack(0, -1)
	m.refresh_pieces()
	assert_eq((m.creature_views[0][0] as CreatureView).readiness, CreatureView.Readiness.SPENT, "after attacking: spent")
	m.queue_free()
	return true
