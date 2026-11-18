class_name BoardLayout
extends RefCounted
## The board's lane shapes for one match (board look 2, spec 1.1): three river-like border curves between the four
## lanes, running the whole board (rival's back edge to yours) so a border lines up across both halves. Lane widths
## shift a little per game; the outer edges stay straight against the tray frame. View only: the rules never see it.
##
## Border i (between lane i and i+1): x(z) = base + amp * sin(z * K1 + phase) + amp2 * sin(z * K2 + phase2).

## Outer lane edges (world x).
const HALF_W := 5.4
## Board ends (world z): tile far/near edges.
const Z_END := 5.55
const LANE_W := 2.7
## Per-lane width jitter (fraction of LANE_W) before the widths are normalised to the board.
const WIDTH_JITTER := 0.09
const AMP := Vector2(0.10, 0.14)
const AMP2 := Vector2(0.02, 0.035)
## One gentle bend over ~4.5 units, a small ripple over ~1.6.
const K1 := TAU / 4.5
const K2 := TAU / 1.6
## Borders share one bend phase, each nudged by up to this much, so they flow together like a river.
const PHASE_SPREAD := 0.7
## Accepted lane widths anywhere along the board.
const MIN_W := 2.35
const MAX_W := 3.15

var _base: PackedFloat32Array = PackedFloat32Array([-LANE_W, 0.0, LANE_W])
var _amp: PackedFloat32Array = PackedFloat32Array([0.0, 0.0, 0.0])
var _phase: PackedFloat32Array = PackedFloat32Array([0.0, 0.0, 0.0])
var _amp2: PackedFloat32Array = PackedFloat32Array([0.0, 0.0, 0.0])
var _phase2: PackedFloat32Array = PackedFloat32Array([0.0, 0.0, 0.0])
var seed: int = 0


## Today's straight, even lanes (no shift, no wave).
static func straight() -> BoardLayout:
	return BoardLayout.new()


## A random layout for `seed_`; re-rolls (deterministically) until every lane width stays in MIN_W..MAX_W.
static func make(seed_: int) -> BoardLayout:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(seed_) ^ 0x5eed1a
	for attempt: int in 64:
		var lay := BoardLayout.new()
		lay.seed = seed_
		lay._roll(rng)
		if lay._widths_ok():
			return lay
	var flat := BoardLayout.straight()
	flat.seed = seed_
	return flat


func _roll(rng: RandomNumberGenerator) -> void:
	var widths: Array[float] = []
	var total: float = 0.0
	for l: int in 4:
		var w: float = LANE_W * (1.0 + rng.randf_range(-WIDTH_JITTER, WIDTH_JITTER))
		widths.append(w)
		total += w
	var x: float = -HALF_W
	var common: float = rng.randf() * TAU
	for i: int in 3:
		x += widths[i] * (2.0 * HALF_W) / total
		_base[i] = x
		_amp[i] = rng.randf_range(AMP.x, AMP.y)
		_phase[i] = common + rng.randf_range(-PHASE_SPREAD, PHASE_SPREAD)
		_amp2[i] = rng.randf_range(AMP2.x, AMP2.y)
		_phase2[i] = rng.randf() * TAU


func _widths_ok() -> bool:
	for l: int in 4:
		for k: int in 65:
			var w: float = width(l, lerpf(-Z_END, Z_END, k / 64.0))
			if w < MIN_W or w > MAX_W:
				return false
	return true


func border_x(i: int, z: float) -> float:
	return _base[i] + _amp[i] * sin(z * K1 + _phase[i]) + _amp2[i] * sin(z * K2 + _phase2[i])


func left_x(lane: int, z: float) -> float:
	return -HALF_W if lane == 0 else border_x(lane - 1, z)


func right_x(lane: int, z: float) -> float:
	return HALF_W if lane == 3 else border_x(lane, z)


func centre_x(lane: int, z: float) -> float:
	return (left_x(lane, z) + right_x(lane, z)) / 2.0


func width(lane: int, z: float) -> float:
	return right_x(lane, z) - left_x(lane, z)


## The lane's centre ignoring the wobble (tile meshes sit here).
func base_centre(lane: int) -> float:
	var l: float = -HALF_W if lane == 0 else _base[lane - 1]
	var r: float = HALF_W if lane == 3 else _base[lane]
	return (l + r) / 2.0


## The lane's narrowest width between z0 and z1 (sampled).
func min_width(lane: int, z0: float, z1: float) -> float:
	var out: float = INF
	for k: int in 49:
		out = minf(out, width(lane, lerpf(z0, z1, k / 48.0)))
	return out


## Largest left edge and smallest right edge between z0 and z1: the strip every z of the lane contains.
func inner_span(lane: int, z0: float, z1: float) -> Vector2:
	var lo: float = -INF
	var hi: float = INF
	for k: int in 49:
		var z: float = lerpf(z0, z1, k / 48.0)
		lo = maxf(lo, left_x(lane, z))
		hi = minf(hi, right_x(lane, z))
	return Vector2(lo, hi)


## Smallest left edge and largest right edge between z0 and z1: what a mesh must cover.
func outer_span(lane: int, z0: float, z1: float) -> Vector2:
	var lo: float = INF
	var hi: float = -INF
	for k: int in 49:
		var z: float = lerpf(z0, z1, k / 48.0)
		lo = minf(lo, left_x(lane, z))
		hi = maxf(hi, right_x(lane, z))
	return Vector2(lo, hi)


## The lane under world x at z, or -1 off the board's sides.
func lane_at(x: float, z: float) -> int:
	if absf(x) > HALF_W:
		return -1
	for i: int in 3:
		if x < border_x(i, z):
			return i
	return 3


## Border i as (base, amp, K1, phase), for shaders.
func curve_params(i: int) -> Vector4:
	return Vector4(_base[i], _amp[i], K1, _phase[i])


## Border i's ripple as (amp2, K2, phase2, 0), for shaders.
func curve_params2(i: int) -> Vector4:
	return Vector4(_amp2[i], K2, _phase2[i], 0.0)
