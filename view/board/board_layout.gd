class_name BoardLayout
extends RefCounted
## The board's lane shapes for one match (board look 2, spec 1.1): three river-like border curves between the four
## lanes. Each half (your side z >= 0, the rival's z < 0) rolls its own lane widths and border wobbles, so the halves
## don't mirror each other; at the seam a border simply restarts at the other half's position (the seam bar covers the
## joint). The outer edges stay straight against the tray frame. View only: the rules never see it.
##
## Border i of half h: x(z) = base + amp * sin(z * k + phase) + amp2 * sin(z * K2 + phase2).

## Outer lane edges (world x).
const HALF_W := 5.4
## Board ends (world z): tile far/near edges.
const Z_END := 5.55
const LANE_W := 2.7
## Lane widths as fractions of LANE_W before a half's widths are normalised to the board: one lane is rolled
## narrow, one wide, the others anywhere in between.
const NARROW := Vector2(0.86, 0.91)
const WIDE := Vector2(1.1, 1.16)
## Margin kept inside MIN_W..MAX_W by the check, so widths between samples stay in range too.
const CHECK_MARGIN := 0.02
## Each border's bend: size, and length of one wave (world units); a small ripple on top.
const AMP := Vector2(0.05, 0.14)
const BEND := Vector2(3.0, 6.0)
const AMP2 := Vector2(0.015, 0.035)
const K2 := TAU / 1.6
## Accepted lane widths anywhere in a half.
const MIN_W := 2.2
const MAX_W := 3.3
## In each half the widest lane is at least this many times the narrowest (base widths), so the difference shows.
const MIN_RATIO := 1.2
## Some lane's base width differs by at least this much between the halves.
const MIN_HALF_DIFF := 0.3
## Re-rolls before falling back to straight lanes.
const ATTEMPTS := 400

## Per border, indexed half * 3 + border.
var _base: PackedFloat32Array = PackedFloat32Array([-LANE_W, 0.0, LANE_W, -LANE_W, 0.0, LANE_W])
var _amp: PackedFloat32Array = PackedFloat32Array([0.0, 0.0, 0.0, 0.0, 0.0, 0.0])
var _k: PackedFloat32Array = PackedFloat32Array([1.0, 1.0, 1.0, 1.0, 1.0, 1.0])
var _phase: PackedFloat32Array = PackedFloat32Array([0.0, 0.0, 0.0, 0.0, 0.0, 0.0])
var _amp2: PackedFloat32Array = PackedFloat32Array([0.0, 0.0, 0.0, 0.0, 0.0, 0.0])
var _phase2: PackedFloat32Array = PackedFloat32Array([0.0, 0.0, 0.0, 0.0, 0.0, 0.0])
var seed: int = 0


## Even straight lanes (no shift, no wave), the same in both halves.
static func straight() -> BoardLayout:
	return BoardLayout.new()


## A random layout for `seed_`; re-rolls (deterministically) until both halves fit the width rules.
static func make(seed_: int) -> BoardLayout:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(seed_) ^ 0x5eed1a
	for attempt: int in ATTEMPTS:
		var lay := BoardLayout.new()
		lay.seed = seed_
		lay._roll(rng)
		if lay._widths_ok():
			return lay
	var flat := BoardLayout.straight()
	flat.seed = seed_
	return flat


## Which half world z lies in: 0 your side (z >= 0), 1 the rival's.
static func half_of(z: float) -> int:
	return 0 if z >= 0.0 else 1


func _roll(rng: RandomNumberGenerator) -> void:
	for h: int in 2:
		var widths: Array[float] = []
		for l: int in 4:
			widths.append(LANE_W * rng.randf_range(NARROW.y, WIDE.x))
		var narrow: int = rng.randi() % 4
		var wide: int = (narrow + 1 + rng.randi() % 3) % 4
		widths[narrow] = LANE_W * rng.randf_range(NARROW.x, NARROW.y)
		widths[wide] = LANE_W * rng.randf_range(WIDE.x, WIDE.y)
		var total: float = 0.0
		for w: float in widths:
			total += w
		var x: float = -HALF_W
		for i: int in 3:
			var j: int = h * 3 + i
			x += widths[i] * (2.0 * HALF_W) / total
			_base[j] = x
			_amp[j] = rng.randf_range(AMP.x, AMP.y)
			_k[j] = TAU / rng.randf_range(BEND.x, BEND.y)
			_phase[j] = rng.randf() * TAU
			_amp2[j] = rng.randf_range(AMP2.x, AMP2.y)
			_phase2[j] = rng.randf() * TAU


func _widths_ok() -> bool:
	var most_apart: float = 0.0
	for h: int in 2:
		var lo: float = INF
		var hi: float = 0.0
		for l: int in 4:
			var bw: float = base_width(l, h)
			lo = minf(lo, bw)
			hi = maxf(hi, bw)
			most_apart = maxf(most_apart, absf(base_width(l, 0) - base_width(l, 1)))
			for k: int in 49:
				var z: float = lerpf(0.0, Z_END, k / 48.0)
				var w: float = width(l, z if h == 0 else -maxf(z, 0.001))
				if w < MIN_W + CHECK_MARGIN or w > MAX_W - CHECK_MARGIN:
					return false
		if hi / lo < MIN_RATIO:
			return false
	return most_apart >= MIN_HALF_DIFF


## Border i at world z (in z's half).
func border_x(i: int, z: float) -> float:
	return border_x_in(half_of(z), i, z)


## Border i of half h at z (any z: the half's curve carried on).
func border_x_in(h: int, i: int, z: float) -> float:
	var j: int = h * 3 + i
	return _base[j] + _amp[j] * sin(z * _k[j] + _phase[j]) + _amp2[j] * sin(z * K2 + _phase2[j])


func left_x(lane: int, z: float) -> float:
	return -HALF_W if lane == 0 else border_x(lane - 1, z)


func right_x(lane: int, z: float) -> float:
	return HALF_W if lane == 3 else border_x(lane, z)


func centre_x(lane: int, z: float) -> float:
	return (left_x(lane, z) + right_x(lane, z)) / 2.0


func width(lane: int, z: float) -> float:
	return right_x(lane, z) - left_x(lane, z)


## The lane's centre in half h ignoring the wobble (tile meshes sit here).
func base_centre(lane: int, h: int = 0) -> float:
	var l: float = -HALF_W if lane == 0 else _base[h * 3 + lane - 1]
	var r: float = HALF_W if lane == 3 else _base[h * 3 + lane]
	return (l + r) / 2.0


## The lane's width in half h ignoring the wobble.
func base_width(lane: int, h: int = 0) -> float:
	var l: float = -HALF_W if lane == 0 else _base[h * 3 + lane - 1]
	var r: float = HALF_W if lane == 3 else _base[h * 3 + lane]
	return r - l


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


## Border i of half h as (base, amp, k, phase), for shaders.
func curve_params(i: int, h: int = 0) -> Vector4:
	var j: int = h * 3 + i
	return Vector4(_base[j], _amp[j], _k[j], _phase[j])


## Border i of half h's ripple as (amp2, K2, phase2, 0), for shaders.
func curve_params2(i: int, h: int = 0) -> Vector4:
	var j: int = h * 3 + i
	return Vector4(_amp2[j], K2, _phase2[j], 0.0)
