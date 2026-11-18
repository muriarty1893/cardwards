extends TestCase
## Lane props stay clear of pieces; ambient particle amounts follow the quality setting.


func test_props_clear_of_pieces() -> bool:
	for land: int in 4:
		for p: int in 2:
			var root: Node3D = LaneDressing.build(land, p, p * 4 + land, 1.0)
			var pos: Array[Vector3] = LaneDressing.prop_positions(root)
			assert_true(pos.size() >= 4 and pos.size() <= 8, "4-8 accent props land %d p%d (%d)" % [land, p, pos.size()])
			for v: Vector3 in pos:
				assert_true(LaneDressing.is_clear(v, p), "prop %s clear land %d p%d" % [v, land, p])
			root.free()
	return true


## Tile-local building spot and boop plate centre for `player` (straight tiles: the tile centre is the lane centre).
static func _spots(player: int) -> Array[Vector2]:
	var s: float = 1.0 if player == 0 else -1.0
	var back: float = (Board.SEAM / 2.0 + Island.LENGTH * (1.0 - Board.BUILDING_DEPTH / 2.0)) * s - Board.STRIP_Z[player]
	return [Vector2(0.0, back), Vector2(0.0, Board.PLATE_Z - Board.STRIP_Z[0])]


func test_dressing_avoids_spots() -> bool:
	for land: int in 4:
		for p: int in 2:
			var root: Node3D = LaneDressing.build(land, p, p * 4 + land, 1.0)
			var spots: Array[Vector2] = _spots(p)
			var n: int = 0
			for mmi: Node in root.find_children("*", "MultiMeshInstance3D", true, false):
				var mm: MultiMesh = (mmi as MultiMeshInstance3D).multimesh
				var base: Transform3D = (mmi as MultiMeshInstance3D).transform
				for i: int in mm.instance_count:
					var o: Vector3 = base * mm.get_instance_transform(i).origin
					n += 1
					assert_true(Vector2(o.x, o.z).distance_to(spots[0]) >= LaneDressing.BUILDING_R, "land %d p%d cover %d clear of building" % [land, p, i])
					if p == 0:
						var off: Vector2 = (Vector2(o.x, o.z) - spots[1]).abs()
						assert_true(off.x >= BoopPlate.SIZE.x / 2.0 or off.y >= BoopPlate.SIZE.y / 2.0, "land %d p%d cover %d clear of the boop plate" % [land, p, i])
					assert_true(absf(o.x) <= Island.WIDTH / 2.0 and absf(o.z) <= Island.LENGTH / 2.0, "land %d cover %d on its tile" % [land, i])
			assert_true(n >= LaneDressing.DENSITY[land] * 0.8, "land %d p%d dense (%d)" % [land, p, n])
			root.free()
	return true


static func _cover_count(root: Node) -> int:
	var n: int = 0
	for mmi: Node in root.find_children("*", "MultiMeshInstance3D", true, false):
		n += (mmi as MultiMeshInstance3D).multimesh.instance_count
	return n


func test_low_density_halves() -> bool:
	for land: int in 4:
		var hi: Node3D = LaneDressing.build(land, 0, land, 1.0)
		var lo: Node3D = LaneDressing.build(land, 0, land, 0.5)
		assert_true(_cover_count(lo) <= int(_cover_count(hi) * 0.55), "land %d low %d <= 55%% of %d" % [land, _cover_count(lo), _cover_count(hi)])
		hi.free()
		lo.free()
	return true


func test_bend_points_uniform() -> bool:
	var b: Board = _board()
	var pts := PackedVector3Array([Vector3(1, 0.6, 2), Vector3(-2, 0.6, -1), Vector3(4, 0.6, 3)])
	b.set_bend_points(pts)
	var mat: ShaderMaterial = LaneDressing.cover_material()
	var arr: Variant = mat.get_shader_parameter("bend_points")
	assert_eq((arr as Array).size(), 8, "8 bend slots")
	for i: int in 3:
		var v: Vector4 = arr[i]
		assert_true(Vector3(v.x, v.y, v.z).distance_to(pts[i]) < 0.001 and v.w > 0.0, "slot %d holds point %d" % [i, i])
	for i: int in range(3, 8):
		assert_eq((arr[i] as Vector4).w, 0.0, "slot %d unused" % i)
	b.free()
	return true


## WebGL fits only ~256 instances with instance uniforms: the cover shader must not use them.
func test_dressing_no_instance_fx() -> bool:
	var mat: ShaderMaterial = LaneDressing.cover_material()
	assert_true(not "instance uniform" in mat.shader.code, "cover shader has no instance uniforms")
	var root: Node3D = LaneDressing.build(2, 0, 3, 1.0)
	for n: Node in root.find_children("*", "GeometryInstance3D", true, false):
		var sm := (n as GeometryInstance3D).material_override as ShaderMaterial
		if sm and sm.shader:
			assert_true(not sm.shader.resource_path in [Toon.FX_PATH, Toon.FX_CUTOUT_PATH], "no fx toon on dressing")
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
	return Rect2(BoardLayout.straight().base_centre(l) - Island.WIDTH / 2.0, Board.STRIP_Z[p] - Island.LENGTH / 2.0, Island.WIDTH, Island.LENGTH)


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
		var plate := Rect2(bo.x - BoopPlate.SIZE.x / 2.0, bo.z - BoopPlate.SIZE.y / 2.0, BoopPlate.SIZE.x, BoopPlate.SIZE.y)
		assert_true(not plate.intersects(b.roam_rect(0, l)), "boop plate clear of roam l%d" % l)
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
