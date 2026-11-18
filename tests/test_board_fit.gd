extends TestCase
## The seat view frames the whole board in the lower part of the screen with the rival's head
## above it; the lean-in view frames your half of the board.

const SIZES: Array[Vector2i] = [Vector2i(1280, 720), Vector2i(1366, 768), Vector2i(1920, 1080)]


func _rig(size: Vector2i) -> Array:
	var vp := SubViewport.new()
	vp.size = size
	(Engine.get_main_loop() as SceneTree).root.add_child(vp)
	var rig := CameraRig.new(); vp.add_child(rig)
	var board := Board.new(); vp.add_child(board)
	var lands: Array[Array] = [[0, 1, 2, 3], [3, 2, 1, 0]]
	board.build(lands)
	var rival := RivalSeat.new(); vp.add_child(rival)
	rival.setup(MatchController.RIVAL_MODEL)
	await (Engine.get_main_loop() as SceneTree).process_frame
	await (Engine.get_main_loop() as SceneTree).process_frame
	return [vp, rig, board, rival]


static func _tile_corners(p: int, l: int) -> Array[Vector3]:
	var out: Array[Vector3] = []
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			out.append(Vector3(Board.LANE_X[l] + sx * Island.WIDTH / 2.0, Island.TOP_Y, Board.STRIP_Z[p] + sz * Island.LENGTH / 2.0))
	return out


func test_seat_view_fits() -> bool:
	for size: Vector2i in SIZES:
		var r: Array = await _rig(size)
		var rig: CameraRig = r[1]
		rig.set_zoom(0.0, true)
		var w: float = size.x; var h: float = size.y
		for p: int in 2:
			for l: int in 4:
				for c: Vector3 in _tile_corners(p, l):
					var s: Vector2 = rig.camera.unproject_position(c)
					assert_true(s.x >= 0.03 * w and s.x <= 0.97 * w, "tile p%d l%d corner x in view at %s (%s)" % [p, l, size, s])
					assert_true(s.y >= 0.22 * h and s.y <= 0.80 * h, "tile p%d l%d corner y in band at %s (%s)" % [p, l, size, s])
		(r[0] as Node).free()
	return true


func test_rival_head_visible() -> bool:
	for size: Vector2i in SIZES:
		var r: Array = await _rig(size)
		var rig: CameraRig = r[1]
		rig.set_zoom(0.0, true)
		var rect: Rect2 = (r[3] as RivalSeat).hero_rect(rig.camera)
		var h: float = size.y
		# The user asked for a view that favours the board (2026-11-18): the head may touch the top edge.
		assert_true(rect.position.y >= 0.0 and rect.position.y <= 0.30 * h, "rival head top in view at %s (%s)" % [size, rect])
		assert_true(absf(rect.get_center().x - size.x / 2.0) <= 0.1 * size.x, "rival centred at %s (%s)" % [size, rect])
		(r[0] as Node).free()
	return true


func test_lean_view_fits_near_half() -> bool:
	for size: Vector2i in SIZES:
		var r: Array = await _rig(size)
		var rig: CameraRig = r[1]
		rig.set_zoom(1.0, true)
		var w: float = size.x; var h: float = size.y
		for l: int in 4:
			for c: Vector3 in _tile_corners(0, l):
				var s: Vector2 = rig.camera.unproject_position(c)
				assert_true(s.x >= 0.0 and s.x <= w, "near tile l%d corner x in view at %s (%s)" % [l, size, s])
				assert_true(s.y >= 0.08 * h and s.y <= 0.82 * h, "near tile l%d corner y in band at %s (%s)" % [l, size, s])
		(r[0] as Node).free()
	return true


## WebGL fits only ~256 instances with instance uniforms, so scenery must use the plain toon shader.
func test_board_uses_no_instance_fx() -> bool:
	var r: Array = await _rig(Vector2i(1280, 720))
	var fx: int = 0
	for n: Node in (r[2] as Node).find_children("*", "GeometryInstance3D", true, false):
		var mats: Array[Material] = [(n as GeometryInstance3D).material_override]
		var mi := n as MeshInstance3D
		if mi and mi.mesh:
			for i: int in mi.mesh.get_surface_count():
				mats.append(mi.get_active_material(i))
		for m: Material in mats:
			var sm := m as ShaderMaterial
			if sm and sm.shader and sm.shader.resource_path in [Toon.FX_PATH, Toon.FX_CUTOUT_PATH]:
				fx += 1
				break
	assert_true(fx == 0, "board meshes with per-instance fx: %d" % fx)
	(r[0] as Node).free()
	return true
