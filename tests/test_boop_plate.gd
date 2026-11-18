extends TestCase
## Board look 2, spec 1.4: a 3D boop plate on each of your lanes replaces the floating BOOP button.

const LANDS: Array[Array] = [[4, 4, 4, 4], [4, 4, 4, 4]]
## Building footprint half size (x, z) around Board.building_point.
const BUILDING_HALF := Vector2(0.5, 0.42)


func test_plates_hidden_until_split() -> bool:
	var b := Board.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(b)
	b.build(LANDS, BoardLayout.make(2))
	for l: int in 4:
		assert_eq(b.boop_plate(l).state, BoopPlate.State.HIDDEN, "plate %d hidden before the split" % l)
	b.reveal_split(false)
	for l: int in 4:
		assert_eq(b.boop_plate(l).state, BoopPlate.State.DIM, "plate %d up and dim after the split" % l)
		var bp: Vector3 = b.boop_point(l)
		var pos: Vector3 = b.boop_plate(l).position
		assert_true(Vector2(pos.x, pos.z).distance_to(Vector2(bp.x, bp.z)) < 0.001, "plate %d at its boop point" % l)
	b.free()
	return true


func test_plate_states() -> bool:
	var m: MatchController = await Fx.load_match()
	Fx.put_creature(m.state, 0, 0, &"gumdrop")    # on_boop
	Fx.put_creature(m.state, 0, 1, &"cinderpup")  # no boop
	m.sync_all(); m.refresh_ui()
	await (Engine.get_main_loop() as SceneTree).process_frame
	assert_eq(m.board.boop_plate(0).state, BoopPlate.State.LIT, "gumdrop's plate lit")
	assert_eq(m.board.boop_plate(1).state, BoopPlate.State.DIM, "no boop: dim")
	assert_eq(m.board.boop_plate(2).state, BoopPlate.State.DIM, "empty lane: dim")
	m.busy = true
	m.refresh_ui()
	assert_eq(m.board.boop_plate(0).state, BoopPlate.State.DIM, "dim while busy")
	m.busy = false
	m.state.players[0].lanes[0].creature.hushed = true
	m.refresh_ui()
	assert_eq(m.board.boop_plate(0).state, BoopPlate.State.DIM, "hushed: dim")
	m.queue_free()
	return true


func test_click_plate_boops() -> bool:
	var m: MatchController = await Fx.load_match()
	Fx.put_creature(m.state, 0, 2, &"gumdrop")
	m.sync_all(); m.refresh_ui()
	await (Engine.get_main_loop() as SceneTree).process_frame
	assert_true(m.input.try_plate(m.board.boop_point(2)), "a click on a lit plate is taken")
	await (Engine.get_main_loop() as SceneTree).create_timer(1.0).timeout
	assert_true(m.state.players[0].lanes[2].creature.booped, "boop resolved via the plate")
	assert_true(not m.input.try_plate(m.board.boop_point(1)), "a click on a dim plate is not taken")
	assert_true(not m.input.try_plate(m.board.anchor(0, 2)), "a click beside the plate is not taken")
	m.queue_free()
	return true


func test_plate_clear_of_zones() -> bool:
	for seed: int in 50:
		var b := Board.new()
		b.layout = BoardLayout.make(seed * 13 + 1)
		for l: int in 4:
			var bp: Vector3 = b.boop_point(l)
			var plate := Rect2(bp.x - BoopPlate.SIZE.x / 2.0, bp.z - BoopPlate.SIZE.y / 2.0, BoopPlate.SIZE.x, BoopPlate.SIZE.y)
			assert_true(not plate.intersects(b.roam_rect(0, l)), "seed %d plate %d clear of the roam zone" % [seed, l])
			var bd: Vector3 = b.building_point(0, l)
			var building := Rect2(bd.x - BUILDING_HALF.x, bd.z - BUILDING_HALF.y, BUILDING_HALF.x * 2.0, BUILDING_HALF.y * 2.0)
			assert_true(not plate.intersects(building), "seed %d plate %d clear of the building" % [seed, l])
			for z: float in [plate.position.y, plate.end.y]:
				assert_true(plate.position.x > b.layout.left_x(l, z) + 0.05 and plate.end.x < b.layout.right_x(l, z) - 0.05, "seed %d plate %d inside its lane" % [seed, l])
		b.free()
	return true
