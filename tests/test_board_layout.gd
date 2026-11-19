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


## Each half (your side z >= 0, the rival's z < 0) over the z its tiles cover.
static func _half_zs(h: int) -> Array[float]:
	var out: Array[float] = []
	for k: int in 33:
		var z: float = lerpf(0.0, BoardLayout.Z_END, k / 32.0)
		out.append(z if h == 0 else -maxf(z, 0.001))
	return out


func test_widths_in_range() -> bool:
	for seed: int in 200:
		var lay: BoardLayout = BoardLayout.make(seed * 7919 + 3)
		for h: int in 2:
			for l: int in 4:
				var lo: float = INF
				var hi: float = 0.0
				for z: float in _half_zs(h):
					lo = minf(lo, lay.width(l, z))
					hi = maxf(hi, lay.width(l, z))
				assert_true(lo >= 2.2 and hi <= 3.3, "seed %d half %d lane %d width %.2f..%.2f" % [seed, h, l, lo, hi])
	return true


func test_widths_clearly_differ() -> bool:
	# In each half the widest lane is at least 1.25x the narrowest, and the two halves don't mirror each other.
	for seed: int in 200:
		var lay: BoardLayout = BoardLayout.make(seed * 104729 + 11)
		var most_apart: float = 0.0
		for h: int in 2:
			var ws: Array[float] = []
			for l: int in 4:
				ws.append(lay.base_width(l, h))
			assert_true(ws.max() / ws.min() >= BoardLayout.MIN_RATIO - 0.0001, "seed %d half %d widths %s" % [seed, h, ws])
		for l: int in 4:
			most_apart = maxf(most_apart, absf(lay.base_width(l, 0) - lay.base_width(l, 1)))
		assert_true(most_apart >= BoardLayout.MIN_HALF_DIFF - 0.0001, "seed %d halves differ (%.2f)" % [seed, most_apart])
		assert_true(lay._amp[0] > 0.0, "seed %d rolled a real layout, not the straight fallback" % seed)
	return true


func test_borders_wobble_their_own_way() -> bool:
	# Within a half, each border has its own bend: wobble sizes and bend lengths are not all the same.
	var lay: BoardLayout = BoardLayout.make(42)
	for h: int in 2:
		var sizes: Array[float] = []
		var bends: Array[float] = []
		for i: int in 3:
			var lo: float = INF
			var hi: float = -INF
			for z: float in _half_zs(h):
				var x: float = lay.border_x(i, z)
				lo = minf(lo, x)
				hi = maxf(hi, x)
			assert_true(hi - lo > 0.08 and hi - lo < 0.7, "half %d border %d wobbles (%.2f)" % [h, i, hi - lo])
			sizes.append(snappedf(hi - lo, 0.01))
			bends.append(snappedf(lay.curve_params(i, h).z, 0.01))
		assert_true(sizes.max() - sizes.min() > 0.02 or bends.max() - bends.min() > 0.05, "half %d borders differ (%s, %s)" % [h, sizes, bends])
	return true


func test_halves_meet_at_seam() -> bool:
	# Each half has its own borders: at the seam they jump from the rival's position to yours.
	var jumps: int = 0
	for seed: int in 20:
		var lay: BoardLayout = BoardLayout.make(seed)
		for i: int in 3:
			if absf(lay.border_x(i, 0.0) - lay.border_x(i, -0.001)) > 0.05:
				jumps += 1
			for z: float in [0.5, 2.0, 5.0]:
				assert_eq(lay.border_x(i, z), lay.border_x_in(0, i, z), "your half's border %d at z %.1f" % [i, z])
				assert_eq(lay.border_x(i, -z), lay.border_x_in(1, i, -z), "rival half's border %d at z %.1f" % [i, -z])
	assert_true(jumps > 30, "borders usually jump at the seam (%d of 60)" % jumps)
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
		for h: int in 2:
			assert_true(absf(lay.base_centre(l, h) - OLD_LANE_X[l]) < 0.0001, "straight lane %d base centre half %d" % [l, h])
	return true


func test_curve_params_reproduce_border() -> bool:
	var lay: BoardLayout = BoardLayout.make(8)
	for h: int in 2:
		for i: int in 3:
			var c1: Vector4 = lay.curve_params(i, h)
			var c2: Vector4 = lay.curve_params2(i, h)
			for z: float in _half_zs(h):
				var x: float = c1.x + c1.y * sin(z * c1.z + c1.w) + c2.x * sin(z * c2.y + c2.z)
				assert_true(absf(x - lay.border_x(i, z)) < 0.0001, "params rebuild half %d border %d at z %.2f" % [h, i, z])
	return true
