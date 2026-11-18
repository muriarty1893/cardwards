extends TestCase
## BoardLayout: per-game river curves between lanes (board look 2, spec 1.1).

const OLD_LANE_X: Array[float] = [-4.05, -1.35, 1.35, 4.05]
const ZS: Array[float] = [-5.5, -3.0, -0.4, 0.0, 1.7, 3.3, 5.5]


func test_layout_deterministic() -> bool:
	var a: BoardLayout = BoardLayout.make(1234)
	var b: BoardLayout = BoardLayout.make(1234)
	var c: BoardLayout = BoardLayout.make(99)
	var differs: bool = false
	for i: int in 3:
		for z: float in ZS:
			assert_eq(a.border_x(i, z), b.border_x(i, z), "same seed same border %d z %.1f" % [i, z])
			if absf(a.border_x(i, z) - c.border_x(i, z)) > 0.001:
				differs = true
	assert_true(differs, "a different seed gives different borders")
	return true


func test_widths_in_range() -> bool:
	for seed: int in 200:
		var lay: BoardLayout = BoardLayout.make(seed * 7919 + 3)
		for l: int in 4:
			var lo: float = lay.min_width(l, -BoardLayout.Z_END, BoardLayout.Z_END)
			var hi: float = 0.0
			for k: int in 49:
				var z: float = lerpf(-BoardLayout.Z_END, BoardLayout.Z_END, k / 48.0)
				hi = maxf(hi, lay.width(l, z))
			assert_true(lo >= 2.3 and hi <= 3.2, "seed %d lane %d width %.2f..%.2f" % [seed, l, lo, hi])
	return true


func test_borders_wobble() -> bool:
	var lay: BoardLayout = BoardLayout.make(42)
	for i: int in 3:
		var lo: float = INF
		var hi: float = -INF
		for k: int in 49:
			var x: float = lay.border_x(i, lerpf(-BoardLayout.Z_END, BoardLayout.Z_END, k / 48.0))
			lo = minf(lo, x)
			hi = maxf(hi, x)
		assert_true(hi - lo > 0.12 and hi - lo < 0.45, "border %d wobbles a little (%.2f)" % [i, hi - lo])
	return true


func test_outer_edges_straight() -> bool:
	var lay: BoardLayout = BoardLayout.make(5)
	for z: float in ZS:
		assert_eq(lay.left_x(0, z), -BoardLayout.HALF_W, "lane 0 left edge straight at z %.1f" % z)
		assert_eq(lay.right_x(3, z), BoardLayout.HALF_W, "lane 3 right edge straight at z %.1f" % z)
	return true


func test_neighbours_share_border() -> bool:
	var lay: BoardLayout = BoardLayout.make(77)
	for l: int in 3:
		for z: float in ZS:
			assert_eq(lay.right_x(l, z), lay.left_x(l + 1, z), "lane %d/%d meet at z %.1f" % [l, l + 1, z])
	return true


func test_lane_at_round_trip() -> bool:
	for seed: int in 20:
		var lay: BoardLayout = BoardLayout.make(seed)
		for l: int in 4:
			for z: float in ZS:
				assert_eq(lay.lane_at(lay.centre_x(l, z), z), l, "seed %d centre of lane %d at z %.1f" % [seed, l, z])
	return true


func test_lane_at_covers_board() -> bool:
	var lay: BoardLayout = BoardLayout.make(31337)
	var misses: int = 0
	for z: float in ZS:
		var x: float = -5.39
		while x <= 5.39:
			if lay.lane_at(x, z) < 0:
				misses += 1
			x += 0.01
	assert_eq(misses, 0, "every point on the board is in some lane")
	assert_eq(lay.lane_at(-5.6, 0.0), -1, "left of the board is no lane")
	assert_eq(lay.lane_at(5.6, 0.0), -1, "right of the board is no lane")
	return true


func test_straight_matches_old() -> bool:
	var lay: BoardLayout = BoardLayout.straight()
	for l: int in 4:
		for z: float in ZS:
			assert_true(absf(lay.centre_x(l, z) - OLD_LANE_X[l]) < 0.0001, "straight lane %d centre at z %.1f" % [l, z])
		assert_true(absf(lay.base_centre(l) - OLD_LANE_X[l]) < 0.0001, "straight lane %d base centre" % l)
	return true


func test_curve_params_reproduce_border() -> bool:
	var lay: BoardLayout = BoardLayout.make(8)
	for i: int in 3:
		var c1: Vector4 = lay.curve_params(i)
		var c2: Vector4 = lay.curve_params2(i)
		for z: float in ZS:
			var x: float = c1.x + c1.y * sin(z * c1.z + c1.w) + c2.x * sin(z * c2.y + c2.z)
			assert_true(absf(x - lay.border_x(i, z)) < 0.0001, "params rebuild border %d at z %.1f" % [i, z])
	return true
