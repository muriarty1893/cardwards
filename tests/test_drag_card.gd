extends TestCase
## Board look 2, spec 3.2: a card dragged over the board becomes a 3D card lying almost flat over the table.


func _rig() -> Array:
	var tree := Engine.get_main_loop() as SceneTree
	var vp := SubViewport.new()
	vp.size = Vector2i(1280, 720)
	tree.root.add_child(vp)
	var rig := CameraRig.new()
	vp.add_child(rig)
	var dc := DragCard3D.new()
	vp.add_child(dc)
	await tree.process_frame
	return [vp, rig, dc]


func test_card_lies_near_flat() -> bool:
	var r: Array = await _rig()
	var dc: DragCard3D = r[2]
	var cam: Camera3D = (r[1] as CameraRig).camera
	dc.show_card(CardDB.card(&"fireball"))
	assert_true(dc.visible, "shown while dragging over the board")
	for i: int in 30:
		dc.follow(cam, Vector2(640, 360))
		dc.step(1.0 / 60.0)
	var normal: Vector3 = dc.card_normal()
	assert_true(normal.dot(Vector3.UP) >= cos(deg_to_rad(25.0)), "card lies within 25 degrees of flat (%s)" % normal)
	assert_true(normal.dot(Vector3.UP) <= cos(deg_to_rad(10.0)), "but tilts toward the camera (%s)" % normal)
	assert_true(normal.z > 0.0, "the tilt faces the camera side")
	var hit: Vector3 = Vector3(dc.global_position.x, Island.TOP_Y, dc.global_position.z)
	assert_true(absf(dc.global_position.y - (Island.TOP_Y + DragCard3D.HOVER)) < 0.05, "hovers above the tiles (%.2f)" % dc.global_position.y)
	var screen: Vector2 = cam.unproject_position(dc.global_position)
	assert_true(screen.distance_to(Vector2(640, 360)) < 4.0, "stays under the mouse (%s)" % screen)
	assert_true(hit.is_finite(), "over the board")
	(r[0] as Node).free()
	return true


func test_sway_capped() -> bool:
	var r: Array = await _rig()
	var dc: DragCard3D = r[2]
	var cam: Camera3D = (r[1] as CameraRig).camera
	dc.show_card(CardDB.card(&"fireball"))
	var max_roll: float = 0.0
	# Fast steady sweeps right then left (60 px a frame).
	for sweep: int in 2:
		for i: int in 16:
			var x: float = 200.0 + 60.0 * i if sweep == 0 else 1100.0 - 60.0 * i
			dc.follow(cam, Vector2(x, 360))
			dc.step(1.0 / 60.0)
			max_roll = maxf(max_roll, absf(dc.roll))
	assert_true(max_roll > deg_to_rad(2.0), "fast moves make the card sway (%.1f deg)" % rad_to_deg(max_roll))
	assert_true(max_roll <= deg_to_rad(DragCard3D.MAX_ROLL_DEG) + 0.001, "sway is capped (%.1f deg)" % rad_to_deg(max_roll))
	(r[0] as Node).free()
	return true


func test_hand_switches_between_2d_and_3d() -> bool:
	var m: MatchController = await Fx.load_match()
	var tree := Engine.get_main_loop() as SceneTree
	m.hand.begin_drag_for_test(0)
	var vp: Vector2 = m.hud.get_viewport_rect().size
	m.hand.drag_to_for_test(Vector2(vp.x / 2.0, vp.y * 0.4))
	await tree.process_frame
	assert_true(m.drag_card.visible, "over the board: the 3D card shows")
	assert_true(m.hand.dragged_widget().modulate.a < 0.01, "and the 2D card hides")
	m.hand.drag_to_for_test(Vector2(vp.x / 2.0, vp.y - 30.0))
	await tree.process_frame
	assert_true(not m.drag_card.visible, "back over the hand: the 3D card hides")
	assert_true(m.hand.dragged_widget().modulate.a > 0.99, "and the 2D card is back")
	m.hand.cancel_drag()
	assert_true(not m.drag_card.visible, "cancel hides the 3D card")
	m.queue_free()
	return true
