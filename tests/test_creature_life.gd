extends TestCase
## Creatures with personality (look & feel spec 4): springs settle at the rest size, low health
## sweats, creatures watch a dragged card.


func _tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


func test_springs_settle_at_rest_size() -> bool:
	var root := Node3D.new()
	_tree().root.add_child(root)
	var v := CreatureView.create(CardDB.card(&"cinderpup"))
	root.add_child(v)
	v.set_level(2)
	var rest: Vector3 = v.rest_scale()
	v.spring(0.3)
	v.cower()
	v.hop_happy()
	await _tree().create_timer(1.3).timeout
	assert_true(v.body.scale.is_equal_approx(rest), "back at rest size %s (got %s)" % [rest, v.body.scale])
	root.queue_free()
	return true


func test_low_health_sweats() -> bool:
	var m: MatchController = await Fx.load_match()
	Fx.put_creature(m.state, 0, 1, &"magmaw", 3)
	Fx.put_creature(m.state, 0, 2, &"magmaw", 0)
	m.sync_all()
	assert_true((m.creature_views[0][1] as CreatureView).sweaty, "1 HP of 4 sweats")
	assert_true(not (m.creature_views[0][2] as CreatureView).sweaty, "full health doesn't")
	m.queue_free()
	return true


func test_creatures_watch_a_point_then_wander_again() -> bool:
	var m: MatchController = await Fx.load_match()
	Fx.put_creature(m.state, 0, 1, &"cinderpup")
	m.sync_all()
	var v: CreatureView = m.creature_views[0][1]
	var spot: Vector3 = v.global_position + Vector3(2.0, 0, 0)
	v.look_point = spot
	v.wanderer.step(0.016)
	var before: float = v.rotation.y
	for i: int in 60:
		v.wanderer.step(0.05)
	var want: float = atan2(spot.x - v.position.x, spot.z - v.position.z)
	assert_true(absf(angle_difference(v.rotation.y, want)) < 0.2, "turned to the point (%.2f vs %.2f, from %.2f)" % [v.rotation.y, want, before])
	m.input.cancel()
	await _tree().process_frame
	assert_true(not v.look_point.is_finite(), "not dragging: stops watching")
	m.queue_free()
	return true
