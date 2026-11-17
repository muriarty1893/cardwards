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
	assert_eq(board.ambient.amount_total(), 34, "low: half ambient")
	board.apply_quality(GameSettings.Quality.HIGH)
	assert_eq(board.ambient.amount_total(), 68, "high: full ambient")
	board.queue_free()
	await tree.process_frame
	return true


static func _tile_rect(p: int, l: int) -> Rect2:
	return Rect2(Board.LANE_X[l] - Island.WIDTH / 2.0, Board.STRIP_Z[p] - Island.LENGTH / 2.0, Island.WIDTH, Island.LENGTH)


static func _circle_hits_rect(c: Vector2, r: float, rect: Rect2) -> bool:
	var q := Vector2(clampf(c.x, rect.position.x, rect.end.x), clampf(c.y, rect.position.y, rect.end.y))
	return q.distance_to(c) < r


func _board() -> Board:
	var b := Board.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(b)
	var lands: Array[Array] = [[0, 1, 2, 3], [3, 2, 1, 0]]
	b.build(lands)
	return b


func test_zones_inside_tiles() -> bool:
	var b: Board = _board()
	for p: int in 2:
		for l: int in 4:
			var tile: Rect2 = _tile_rect(p, l)
			assert_true(tile.encloses(b.roam_rect(p, l)), "roam zone inside tile p%d l%d" % [p, l])
			var bp: Vector3 = b.building_point(p, l)
			assert_true(tile.has_point(Vector2(bp.x, bp.z)), "building spot inside tile p%d l%d" % [p, l])
			assert_true(is_equal_approx(bp.y, Island.TOP_Y), "building spot on the surface")
			var a: Vector3 = b.anchor(p, l)
			assert_true(b.roam_rect(p, l).get_center().distance_to(Vector2(a.x, a.z)) < 0.001, "anchor at roam centre p%d l%d" % [p, l])
	b.free()
	return true


func test_zones_disjoint() -> bool:
	var b: Board = _board()
	for p: int in 2:
		for l: int in 4:
			var bp: Vector3 = b.building_point(p, l)
			assert_true(not _circle_hits_rect(Vector2(bp.x, bp.z), 0.5, b.roam_rect(p, l)), "building clear of roam p%d l%d" % [p, l])
	for l: int in 4:
		var bo: Vector3 = b.boop_point(l)
		var bp: Vector3 = b.building_point(0, l)
		assert_true(not _circle_hits_rect(Vector2(bo.x, bo.z), 0.35, b.roam_rect(0, l)), "boop clear of roam l%d" % l)
		assert_true(Vector2(bo.x, bo.z).distance_to(Vector2(bp.x, bp.z)) >= 0.85, "boop clear of building l%d" % l)
		assert_true(_tile_rect(0, l).has_point(Vector2(bo.x, bo.z)), "boop inside its tile l%d" % l)
	b.free()
	return true


func test_lane_at_screen_zone_centres() -> bool:
	var tree := Engine.get_main_loop() as SceneTree
	var vp := SubViewport.new()
	vp.size = Vector2i(1280, 720)
	tree.root.add_child(vp)
	var rig := CameraRig.new(); vp.add_child(rig)
	var b := Board.new(); vp.add_child(b)
	var lands: Array[Array] = [[0, 1, 2, 3], [3, 2, 1, 0]]
	b.build(lands)
	await tree.process_frame
	for z: float in [0.0, 0.5, 1.0]:
		rig.set_zoom(z, true)
		for p: int in 2:
			for l: int in 4:
				var c: Vector2 = b.roam_rect(p, l).get_center()
				var s: Vector2 = rig.camera.unproject_position(Vector3(c.x, Island.TOP_Y, c.y))
				if not Rect2(Vector2.ZERO, Vector2(vp.size)).has_point(s):
					continue
				assert_eq(b.lane_at_screen(rig.camera, s), {"player": p, "lane": l}, "zoom %.1f p%d l%d" % [z, p, l])
	vp.free()
	return true


func test_tray_inside_room_clear() -> bool:
	assert_true(Room.BOARD_CLEAR.encloses(Board.TRAY_RECT), "tray inside the room's clear area")
	for p: int in 2:
		for l: int in 4:
			assert_true(Board.TRAY_RECT.encloses(_tile_rect(p, l)), "tile p%d l%d inside the tray" % [p, l])
	return true
