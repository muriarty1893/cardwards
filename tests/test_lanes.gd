extends TestCase
## Lane props stay clear of pieces; ambient particle amounts follow the quality setting.


func test_props_clear_of_pieces() -> bool:
	for land: int in 4:
		for p: int in 2:
			var root: Node3D = LaneDressing.build(land, p, p * 4 + land)
			var pos: Array[Vector3] = LaneDressing.prop_positions(root)
			assert_true(pos.size() >= 7 and pos.size() <= 10, "7-10 props land %d p%d" % [land, p])
			for v: Vector3 in pos:
				assert_true(LaneDressing.is_clear(v, p), "prop %s clear land %d p%d" % [v, land, p])
			root.free()
	return true

func test_ambient_amounts() -> bool:
	var lands: Array[Array] = [[0, 1, 2, 3], [3, 2, 1, 0]]
	var hi: Ambient = Ambient.build(lands, GameSettings.Quality.HIGH)
	assert_eq(hi.amount_total(), 68, "high total")
	hi.set_quality(GameSettings.Quality.LOW)
	assert_eq(hi.amount_total(), 34, "low total")
	hi.free()
	return true


func test_quality_presets() -> bool:
	var tree := Engine.get_main_loop() as SceneTree
	var board := Board.new()
	tree.root.add_child(board)
	var lands: Array[Array] = [[0, 1, 2, 3], [3, 2, 1, 0]]
	board.build(lands)
	await tree.process_frame
	board.apply_quality(GameSettings.Quality.LOW)
	assert_true(not board.env.ssao_enabled, "low: no SSAO")
	assert_true(not board.env.glow_enabled, "low: no glow")
	assert_eq(board.get_viewport().msaa_3d, Viewport.MSAA_DISABLED, "low: no MSAA")
	assert_eq(board.ambient.amount_total(), 34, "low: half ambient")
	board.apply_quality(GameSettings.Quality.HIGH)
	assert_true(board.env.ssao_enabled, "high: SSAO")
	assert_true(board.env.glow_enabled, "high: glow")
	assert_eq(board.get_viewport().msaa_3d, Viewport.MSAA_2X, "high: MSAA 2x")
	assert_eq(board.ambient.amount_total(), 68, "high: full ambient")
	board.queue_free()
	await tree.process_frame
	return true
