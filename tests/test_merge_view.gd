extends TestCase
## Card expansion 2, spec 4.3: merged creatures look like both partners together; dragging a partner shows a merge
## highlight on its partner's lane, and dropping it there merges.


func test_merged_view_has_both_models() -> bool:
	var v: CreatureView = CreatureView.create(CardDB.card(&"twinflame_hound"))
	var rider: Node = v.find_child("Rider", true, false)
	assert_true(rider != null, "a rider model sits on the big partner")
	assert_true(v.find_children("*", "AnimationPlayer", true, false).size() >= 2, "both models animate")
	var plain: CreatureView = CreatureView.create(CardDB.card(&"cinderpup"))
	assert_true(v.height > plain.height, "the merged form stands taller than a partner alone")
	assert_true(v.find_child("MergeAura", true, false) != null, "a soft two-colour aura")
	v.free()
	plain.free()
	return true


func test_merge_highlight_and_drop() -> bool:
	var m: MatchController = await Fx.load_match()
	var s: GameState = m.state
	Fx.put_creature(s, 0, 2, &"cinderpup")
	Fx.put_creature(s, 0, 1, &"magmaw")
	s.players[0].hand.clear()
	var i: int = Fx.give(s, 0, &"emberkit")
	s.players[0].magic = 5
	m.sync_all(); m.refresh_ui()
	await (Engine.get_main_loop() as SceneTree).process_frame
	m.input.on_drag_started(i)
	assert_eq(m.board.island(0, 2).highlight, Island.Highlight.MERGE, "the partner's lane shows the merge highlight")
	assert_eq(m.board.island(0, 1).highlight, Island.Highlight.OFF, "another creature's lane is not a drop target")
	assert_eq(m.board.island(0, 0).highlight, Island.Highlight.VALID, "an empty lane is a normal drop target")
	var screen: Vector2 = m.rig.camera.unproject_position(m.board.anchor(0, 2))
	m.input.on_dropped(i, screen)
	await (Engine.get_main_loop() as SceneTree).create_timer(2.5).timeout
	assert_eq(s.players[0].lanes[2].creature.card.id, &"twinflame_hound", "dropped on its partner: merged")
	var view: CreatureView = m.creature_views[0][2]
	assert_true(view != null and view.card.id == &"twinflame_hound", "the lane shows the merged view")
	assert_true(view.find_child("Rider", true, false) != null, "with both models")
	m.queue_free()
	return true
