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


func test_bars_fit_view() -> bool:
	for size: Vector2i in SIZES:
		var r: Array = await _rig(size)
		var cam: Camera3D = (r[1] as CameraRig).camera
		var board: Board = r[2]
		var screen := Rect2(0, 0, size.x, size.y)
		var corner_l := Rect2(Vector2(12, 10), Hud.CORNER)
		var corner_r := Rect2(Vector2(size.x - 12 - Hud.CORNER.x, 10), Hud.CORNER)
		var bar_l := Rect2(Vector2(12 + 112, 14), Hud.BAR)
		var bar_r := Rect2(Vector2(size.x - 12 - 112 - Hud.BAR.x, 14), Hud.BAR)
		var bars: Array[Rect2] = []
		for p: int in 2:
			for l: int in 4:
				var bar: Rect2 = UnitOverlay.bar_rect_at(cam, board.anchor(p, l) + Vector3(0, 1.85, 0), [corner_l, corner_r, bar_l, bar_r])
				assert_true(screen.encloses(bar), "bar p%d l%d on screen at %s (%s)" % [p, l, size, bar])
				for keep_out: Rect2 in [corner_l, corner_r, bar_l, bar_r]:
					assert_true(not bar.intersects(keep_out), "bar p%d l%d clear of HUD %s at %s" % [p, l, keep_out, size])
				assert_true(bar.end.y <= size.y - Hud.TRAY_H, "bar p%d l%d above tray at %s" % [p, l, size])
				bars.append(bar)
		for i: int in bars.size():
			for j: int in range(i + 1, bars.size()):
				assert_true(not bars[i].intersects(bars[j]), "stat bars %d and %d apart at %s" % [i, j, size])
		(r[0] as Node).free()
	return true


func test_buildings_and_boops_clear_tray() -> bool:
	for size: Vector2i in SIZES:
		var r: Array = await _rig(size)
		var cam: Camera3D = (r[1] as CameraRig).camera
		var board: Board = r[2]
		var floor_y: float = size.y - Hud.TRAY_H
		for l: int in 4:
			var base: Vector3 = board.anchor(0, l) - Vector3(0, CreatureView.BASE_Y - Island.TOP_Y, 0) + BuildingView.OFFSET
			var feet: Vector2 = cam.unproject_position(base)
			assert_true(feet.y <= floor_y - 4.0, "building l%d above tray at %s (%f)" % [l, size, feet.y])
			var top: Vector2 = cam.unproject_position(base + Vector3(0, BuildingView.HEIGHT, 0))
			var building := Rect2(top.x - 40.0, top.y, 80.0, feet.y - top.y)
			var bc: Vector2 = cam.unproject_position(board.anchor(0, l) + UnitOverlay.BOOP_OFFSET)
			var boop := Rect2(bc - UnitOverlay.BOOP_SIZE / 2.0, UnitOverlay.BOOP_SIZE)
			assert_true(boop.end.y <= floor_y, "boop l%d above tray at %s" % [l, size])
			assert_true(not boop.intersects(building), "boop l%d clear of building at %s" % [l, size])
		(r[0] as Node).free()
	return true


func test_hover_card_fits() -> bool:
	for size: Vector2i in SIZES:
		var r: Array = await _rig(size)
		var cam: Camera3D = (r[1] as CameraRig).camera
		var board: Board = r[2]
		var vp := Vector2(size)
		var floor_y: float = size.y - Hud.TRAY_H
		var avoid: Array[Rect2] = [
			Rect2(Vector2(12, 10), Hud.CORNER), Rect2(Vector2(size.x - 12 - Hud.CORNER.x, 10), Hud.CORNER),
			Rect2(Vector2(12 + 112, 14), Hud.BAR), Rect2(Vector2(size.x - 12 - 112 - Hud.BAR.x, 14), Hud.BAR),
		]
		var board_area := Rect2(0, 0, size.x, floor_y)
		for p: int in 2:
			for l: int in 4:
				var at: Vector2 = cam.unproject_position(board.anchor(p, l) + Vector3(0, 0.6, 0))
				var card: Rect2 = UnitOverlay.hover_rect(at, vp, avoid, floor_y)
				assert_true(board_area.encloses(card), "hover p%d l%d inside board area at %s (%s)" % [p, l, size, card])
				for a: Rect2 in avoid:
					assert_true(not card.intersects(a), "hover p%d l%d clear of HUD %s at %s" % [p, l, a, size])
		(r[0] as Node).free()
	return true
