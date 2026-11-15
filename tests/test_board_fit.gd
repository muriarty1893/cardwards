extends TestCase
## The camera frames the board between the HUD corners and the tray; scenery stays off the board.

const SIZES: Array[Vector2i] = [Vector2i(1280, 720), Vector2i(1366, 768), Vector2i(1920, 1080)]

func _rig(size: Vector2i) -> Array:
	var vp := SubViewport.new()
	vp.size = size
	(Engine.get_main_loop() as SceneTree).root.add_child(vp)
	var rig := CameraRig.new(); vp.add_child(rig)
	var board := Board.new(); vp.add_child(board)
	var lands: Array[Array] = [[0, 1, 2, 3], [3, 2, 1, 0]]
	board.build(lands)
	await (Engine.get_main_loop() as SceneTree).process_frame
	return [vp, rig, board]

func test_board_fits_view() -> bool:
	for size: Vector2i in SIZES:
		var r: Array = await _rig(size)
		var cam: Camera3D = (r[1] as CameraRig).camera
		var board: Board = r[2]
		var w: float = size.x; var h: float = size.y
		var corner_l := Rect2(Vector2(12, 10), Hud.CORNER)
		var corner_r := Rect2(Vector2(w - 12 - Hud.CORNER.x, 10), Hud.CORNER)
		for p: int in 2:
			for l: int in 4:
				var a: Vector2 = cam.unproject_position(board.anchor(p, l))
				assert_true(Rect2(0, 0, w, h - Hud.TRAY_H - 40).has_point(a), "anchor p%d l%d visible at %s" % [p, l, size])
				var head: Vector2 = cam.unproject_position(board.anchor(p, l) + Vector3(0, 2.2, 0))
				assert_true(not corner_l.has_point(head) and not corner_r.has_point(head), "head clear of corners p%d l%d at %s" % [p, l, size])
		var far_y: float = cam.unproject_position(Vector3(0, 0, Board.STRIP_Z[1] - Island.LENGTH / 2.0)).y
		assert_true(far_y >= 0.0 and far_y <= 0.14 * h, "far edge near top at %s (%f)" % [size, far_y])
		var lx: float = cam.unproject_position(Vector3(Board.LANE_X[0] - Island.WIDTH / 2.0, 0, Board.SIDE_Z[0])).x
		var rx: float = cam.unproject_position(Vector3(Board.LANE_X[3] + Island.WIDTH / 2.0, 0, Board.SIDE_Z[0])).x
		assert_true(rx - lx >= 0.72 * w, "board fills width at %s (%f)" % [size, rx - lx])
		(r[0] as Node).free()
	return true

func test_scenery_outside_board() -> bool:
	var r: Array = await _rig(Vector2i(1280, 720))
	var board: Board = r[2]
	assert_true(board.scenery_positions().size() == 70, "70 props")
	for v: Vector3 in board.scenery_positions():
		assert_true(not Board.INNER_CLEAR.has_point(Vector2(v.x, v.z)), "prop %s outside board" % v)
	(r[0] as Node).free()
	return true
