extends TestCase
## Board look 2, spec 1.2: tiles follow the BoardLayout curves and meet with no gap.

const LANDS: Array[Array] = [[0, 1, 2, 3], [3, 2, 1, 0]]


func _board(lay: BoardLayout) -> Board:
	var b := Board.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(b)
	b.build(LANDS, lay)
	return b


func test_tiles_share_edges() -> bool:
	var b: Board = _board(BoardLayout.make(4242))
	for p: int in 2:
		for l: int in 3:
			var a: ShaderMaterial = b.island(p, l).material()
			var c: ShaderMaterial = b.island(p, l + 1).material()
			assert_eq(a.get_shader_parameter("right_c1"), c.get_shader_parameter("left_c1"), "p%d lanes %d/%d share a curve" % [p, l, l + 1])
			assert_eq(a.get_shader_parameter("right_c2"), c.get_shader_parameter("left_c2"), "p%d lanes %d/%d share a ripple" % [p, l, l + 1])
	b.free()
	return true


func test_tile_mesh_covers_lane() -> bool:
	var lay: BoardLayout = BoardLayout.make(77)
	var b: Board = _board(lay)
	for p: int in 2:
		for l: int in 4:
			var isl: Island = b.island(p, l)
			assert_true(absf(isl.position.x - lay.base_centre(l)) < 0.0001, "tile p%d l%d sits at the lane's base centre" % [p, l])
			var half: float = isl.mesh_size().x / 2.0
			for k: int in 11:
				var z: float = lerpf(-Island.LENGTH / 2.0, Island.LENGTH / 2.0, k / 10.0) + Board.STRIP_Z[p]
				assert_true(lay.left_x(l, z) >= isl.position.x - half and lay.right_x(l, z) <= isl.position.x + half, "mesh covers p%d l%d at z %.1f" % [p, l, z])
	b.free()
	return true


func test_no_lane_dividers() -> bool:
	var b: Board = _board(BoardLayout.make(1))
	assert_eq(b.find_children("Divider*", "", true, false).size(), 0, "no wooden dividers between lanes")
	b.free()
	return true


func test_roam_inside_lane() -> bool:
	for seed: int in 50:
		var b := Board.new()
		b.layout = BoardLayout.make(seed * 31 + 5)
		for p: int in 2:
			for l: int in 4:
				var r: Rect2 = b.roam_rect(p, l)
				for z: float in [r.position.y, r.end.y]:
					assert_true(r.position.x >= b.layout.left_x(l, z) + 0.2 and r.end.x <= b.layout.right_x(l, z) - 0.2, "seed %d p%d l%d roam inside at z %.2f" % [seed, p, l, z])
				var a: Vector3 = b.anchor(p, l)
				assert_eq(b.layout.lane_at(a.x, a.z), l, "seed %d anchor p%d l%d in its lane" % [seed, p, l])
		b.free()
	return true


func test_lane_at_world() -> bool:
	var b := Board.new()
	b.layout = BoardLayout.make(9)
	for p: int in 2:
		for l: int in 4:
			assert_eq(b.lane_at_world(b.anchor(p, l)), {"player": p, "lane": l}, "anchor p%d l%d picks its lane" % [p, l])
			assert_eq(b.lane_at_world(b.building_point(p, l)), {"player": p, "lane": l}, "building p%d l%d picks its lane" % [p, l])
	assert_eq(b.lane_at_world(Vector3(0, 0, 0)), {}, "the middle seam is no lane")
	assert_eq(b.lane_at_world(Vector3(0, 0, 9)), {}, "off the board is no lane")
	b.free()
	return true


func test_dressing_inside_wobbly_tile() -> bool:
	var lay: BoardLayout = BoardLayout.make(123)
	for p: int in 2:
		for l: int in 4:
			var shape: TileShape = TileShape.of(lay, l, Board.STRIP_Z[p])
			for land: int in 5:
				var root: Node3D = LaneDressing.build(land, p, p * 4 + l, 1.0, shape)
				for mmi: Node in root.find_children("*", "MultiMeshInstance3D", true, false):
					var mm: MultiMesh = (mmi as MultiMeshInstance3D).multimesh
					for i: int in mm.instance_count:
						var o: Vector3 = mm.get_instance_transform(i).origin
						assert_true(shape.contains(o.x, o.z), "cover p%d l%d land %d #%d inside the tile" % [p, l, land, i])
				for v: Vector3 in LaneDressing.prop_positions(root):
					assert_true(shape.contains(v.x, v.z), "prop p%d l%d land %d inside the tile" % [p, l, land])
				root.free()
	return true
