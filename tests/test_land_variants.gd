extends TestCase
## Board look 2, spec 2: each land has 3 looks; big set pieces stay out of the play zones.


func test_variant_rolls_spread() -> bool:
	var variants := {}
	var corners := {}
	for n: int in 60:
		var r: Vector2i = Island.roll_look(777, 0, 2, n)
		assert_true(r.x >= 0 and r.x < LaneDressing.VARIANTS, "variant in range (%d)" % r.x)
		assert_true(r.y == 0 or r.y == 1, "corner is 0 or 1 (%d)" % r.y)
		variants[r.x] = true
		corners[r.y] = true
	assert_eq(variants.size(), 3, "60 rolls hit all 3 variants")
	assert_eq(corners.size(), 2, "60 rolls hit both corners")
	assert_eq(Island.roll_look(777, 0, 2, 5), Island.roll_look(777, 0, 2, 5), "a roll is repeatable")
	return true


func test_island_rolls_on_change() -> bool:
	var b := Board.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(b)
	b.build([[4, 4, 4, 4], [4, 4, 4, 4]], BoardLayout.make(31))
	var isl: Island = b.island(0, 1)
	var seen := {}
	var land: int = 0
	for n: int in 40:
		isl.change_land(land, Vector2.ZERO, false)
		assert_eq(Vector2i(isl.variant, isl.corner), Island.roll_look(31, 0, 1, isl.changes), "island look follows its roll")
		seen[isl.variant] = true
		land = (land + 1) % 4
	assert_eq(seen.size(), 3, "an island shows every variant over many changes")
	b.free()
	return true


## Tile-local no-go rects for player p's tile in lane l: roam zone, building, house and (yours) the boop plate.
static func _no_go(lay: BoardLayout, p: int, l: int) -> Array[Rect2]:
	var tx: float = lay.base_centre(l)
	var tz: float = Board.STRIP_Z[p]
	var out: Array[Rect2] = []
	var r: Rect2 = Board.roam_rect_for(lay, p, l)
	out.append(Rect2(r.position - Vector2(tx, tz), r.size))
	var bp: Vector3 = Board.building_point_for(lay, p, l)
	out.append(Rect2(bp.x - tx - 0.5, bp.z - tz - 0.42, 1.0, 0.84))
	var hp: Vector3 = Board.house_point_for(lay, p, l)
	out.append(Rect2(hp.x - tx - 0.3, hp.z - tz - 0.3, 0.6, 0.6))
	if p == 0:
		var pp: Vector3 = Board.boop_point_for(lay, l)
		out.append(Rect2(pp.x - tx - BoopPlate.SIZE.x / 2.0, pp.z - tz - BoopPlate.SIZE.y / 2.0, BoopPlate.SIZE.x, BoopPlate.SIZE.y))
	return out


func test_set_pieces_clear() -> bool:
	for seed: int in [3, 58, 404]:
		var lay: BoardLayout = BoardLayout.make(seed)
		for land: int in 4:
			for v: int in LaneDressing.VARIANTS:
				for p: int in 2:
					for corner: int in 2:
						var l: int = (seed + land + v) % 4
						var shape: TileShape = TileShape.of(lay, l, Board.STRIP_Z[p])
						var root: Node3D = LaneDressing.build(land, p, p * 4 + l, 1.0, shape, v, corner)
						var rects: Array[Rect2] = LaneDressing.set_piece_rects(root)
						assert_true(rects.size() >= 1, "land %d v%d has set pieces" % [land, v])
						for fp: Rect2 in rects:
							for zone: Rect2 in _no_go(lay, p, l):
								assert_true(not fp.intersects(zone), "seed %d land %d v%d p%d c%d: piece %s clear of %s" % [seed, land, v, p, corner, fp, zone])
							for c: Vector2 in [fp.position, fp.end, Vector2(fp.position.x, fp.end.y), Vector2(fp.end.x, fp.position.y)]:
								assert_true(shape.contains(c.x, c.y), "seed %d land %d v%d p%d c%d: piece corner %s on the tile" % [seed, land, v, p, corner, c])
						root.free()
	return true


func test_meadow_single_look() -> bool:
	for v: int in LaneDressing.VARIANTS:
		var root: Node3D = LaneDressing.build(Lands.MEADOW, 0, 1, 1.0, null, v, 0)
		assert_eq(LaneDressing.set_piece_rects(root).size(), 0, "meadow v%d has no set pieces" % v)
		root.free()
	return true


func test_cover_avoids_set_pieces() -> bool:
	var lay: BoardLayout = BoardLayout.make(9)
	for land: int in 4:
		for v: int in LaneDressing.VARIANTS:
			var shape: TileShape = TileShape.of(lay, 1, Board.STRIP_Z[0])
			var root: Node3D = LaneDressing.build(land, 0, 1, 1.0, shape, v, 1)
			var rects: Array[Rect2] = LaneDressing.set_piece_rects(root)
			for v3: Vector3 in LaneDressing.prop_positions(root):
				for fp: Rect2 in rects:
					assert_true(not fp.has_point(Vector2(v3.x, v3.z)), "land %d v%d accent prop off the set pieces" % [land, v])
			root.free()
	return true
