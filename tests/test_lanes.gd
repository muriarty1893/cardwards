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
