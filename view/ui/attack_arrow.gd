class_name AttackArrow
extends Control
## The curved arrow drawn while aiming (attacks, targeted cards, and the rival's attacks).
## A smooth tapered ribbon (thin at the tail, full at the head) shaded like a tube, with an ink
## outline, a notched arrowhead, a soft glow, and bright pulses flowing toward the target.
## Gold over a valid target, grey otherwise. Never takes the mouse.

const VALID := Color("#ffcf3a")
const INVALID := Color("#a6a6b4")
const WIDTH := 22.0
const TAIL_WIDTH := 8.0
const OUTLINE := 4.0
const HEAD := Vector2(48, 34)
## Flowing pulses along the shaft: spacing and speed in pixels.
const CHEVRON_GAP := 38.0
const FLOW_SPEED := 90.0
const STEPS := 48

var _from := Vector2.ZERO
var _to := Vector2.ZERO
var _valid: bool = false
## Distance the pulse strip has scrolled toward the head, wrapped to CHEVRON_GAP.
var _flow: float = 0.0
## Seconds shown, for the head's gentle throb.
var _time: float = 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	set_process(false)


func _process(delta: float) -> void:
	_flow = fmod(_flow + delta * FLOW_SPEED, CHEVRON_GAP)
	_time += delta
	queue_redraw()


## Arc-length positions of the pulses along the shaft, from the tail.
func chevron_offsets() -> Array[float]:
	var out: Array[float] = []
	var length: float = _shaft_length()
	var d: float = _flow + CHEVRON_GAP * 0.5
	while d < length - 6.0:
		out.append(d)
		d += CHEVRON_GAP
	return out


func _shaft_length() -> float:
	var pts: PackedVector2Array = _shaft_points()
	var n: float = 0.0
	for i: int in range(1, pts.size()):
		n += pts[i - 1].distance_to(pts[i])
	return n


## The shaft (curve up to just under the head).
func _shaft_points() -> PackedVector2Array:
	var pts: PackedVector2Array = _curve()
	var tip: Vector2 = pts[pts.size() - 1]
	var dir: Vector2 = (tip - pts[pts.size() - 3]).normalized()
	var base: Vector2 = tip - dir * HEAD.x
	var shaft := PackedVector2Array()
	for p: Vector2 in pts:
		if (p - tip).dot(dir) < -HEAD.x * 0.55:
			shaft.append(p)
	shaft.append(base + dir * 6.0)
	return shaft


func aim(from: Vector2, to: Vector2, valid: bool) -> void:
	if valid and not _valid:
		_time = 0.0
	_from = from
	_to = to
	_valid = valid
	visible = true
	set_process(true)
	queue_redraw()


func clear() -> void:
	visible = false
	set_process(false)
	queue_redraw()


## Points along a curve that bows upward between the ends.
func _curve() -> PackedVector2Array:
	var lift: float = minf(170.0, _from.distance_to(_to) * 0.35)
	var ctrl: Vector2 = (_from + _to) * 0.5 + Vector2(0, -lift)
	var pts := PackedVector2Array()
	for i: int in STEPS + 1:
		var t: float = float(i) / STEPS
		pts.append(_from.lerp(ctrl, t).lerp(ctrl.lerp(_to, t), t))
	return pts


## Half-width of the ribbon at fraction k (0 tail .. 1 head), eased so it swells quickly.
func _half(k: float) -> float:
	return lerpf(TAIL_WIDTH, WIDTH, 1.0 - pow(1.0 - k, 2.2)) * 0.5


## The ribbon's two edges (left, right) for `shaft`, `grow` pixels wider on each side.
func _edges(shaft: PackedVector2Array, grow: float) -> Array[PackedVector2Array]:
	var left := PackedVector2Array()
	var right := PackedVector2Array()
	var n: int = shaft.size()
	for i: int in n:
		var a: Vector2 = shaft[maxi(i - 1, 0)]
		var b: Vector2 = shaft[mini(i + 1, n - 1)]
		var dir: Vector2 = (b - a).normalized()
		var side := Vector2(-dir.y, dir.x)
		var h: float = _half(float(i) / maxf(n - 1, 1)) + grow
		left.append(shaft[i] + side * h)
		right.append(shaft[i] - side * h)
	return [left, right]


## Fills the ribbon `grow` pixels wider, as one quad per segment (shifted by `offset`).
func _fill_ribbon(shaft: PackedVector2Array, grow: float, col: Color, offset: Vector2) -> void:
	var e: Array[PackedVector2Array] = _edges(shaft, grow)
	var cols := PackedColorArray([col, col, col, col])
	for i: int in range(1, shaft.size()):
		draw_primitive(PackedVector2Array([e[0][i - 1] + offset, e[0][i] + offset, e[1][i] + offset, e[1][i - 1] + offset]), cols, PackedVector2Array())


## The notched arrowhead: tip, outer wings and a notch at the back, `grow` pixels bigger.
func _head(tip: Vector2, dir: Vector2, grow: float, k: float = 1.0) -> PackedVector2Array:
	var side := Vector2(-dir.y, dir.x)
	var len_: float = HEAD.x * k + grow * 1.6
	var wing: float = HEAD.y * k + grow * 1.3
	var base: Vector2 = tip - dir * len_
	return PackedVector2Array([tip + dir * grow * 0.8, base + side * wing - dir * grow * 0.4,
		tip - dir * len_ * 0.72, base - side * wing - dir * grow * 0.4])


func _draw() -> void:
	if not visible or _from.distance_to(_to) < 8.0:
		return
	var pts: PackedVector2Array = _curve()
	var tip: Vector2 = pts[pts.size() - 1]
	var dir: Vector2 = (tip - pts[pts.size() - 4]).normalized()
	var shaft: PackedVector2Array = _shaft_points()
	if shaft.size() < 3:
		return
	var col: Color = VALID if _valid else INVALID
	# A gentle throb on the head while it sits on a valid target.
	var k: float = 1.0 + (0.08 * sin(_time * 9.0) if _valid else 0.0)
	# Soft glow under everything.
	if _valid:
		_fill_ribbon(shaft, OUTLINE + 7.0, Color(col, 0.16), Vector2.ZERO)
		_fill_head(_head(tip, dir, OUTLINE + 7.0, k), Color(col, 0.16))
	# Drop shadow, then the ink outline (quads per segment, so the joints stay smooth).
	var drop := Vector2(3, 5)
	_fill_ribbon(shaft, OUTLINE, Color(0, 0, 0, 0.18), drop)
	_fill_head(_head(tip + drop, dir, OUTLINE, k), Color(0, 0, 0, 0.18))
	_fill_ribbon(shaft, OUTLINE, Palette.INK, Vector2.ZERO)
	var e0: Array[PackedVector2Array] = _edges(shaft, OUTLINE)
	draw_polyline(e0[0], Palette.INK, 1.5, true)
	draw_polyline(e0[1], Palette.INK, 1.5, true)
	var ink_head: PackedVector2Array = _head(tip, dir, OUTLINE, k)
	_fill_head(ink_head, Palette.INK)
	_smooth_edge(ink_head, Palette.INK)
	# The body: shaded like a tube (lighter on the top edge, deeper underneath).
	_draw_tube(shaft, col)
	var head: PackedVector2Array = _head(tip, dir, 0.0, k)
	var hc := PackedColorArray([col.lightened(0.35), col.lightened(0.2), col.darkened(0.12), col.darkened(0.25)])
	_fill_head(head, Color.WHITE, hc)
	_smooth_edge(head, col.darkened(0.1))
	# A shine along the top of the shaft and on the head.
	var e: Array[PackedVector2Array] = _edges(shaft, -WIDTH * 0.18)
	var shine: PackedVector2Array = e[0] if e[0][e[0].size() - 1].y < e[1][e[1].size() - 1].y else e[1]
	draw_polyline(shine.slice(2), Color(1, 1, 1, 0.45), 2.5, true)
	_draw_chevrons(shaft, col)
	# A round tail cap where the arrow starts.
	draw_circle(shaft[0], TAIL_WIDTH * 0.5 + OUTLINE + 1.0, Palette.INK)
	draw_circle(shaft[0], TAIL_WIDTH * 0.5 + 1.0, col)


## The notched head as two triangles (tip-wing-notch, tip-notch-wing): never needs triangulating.
func _fill_head(h: PackedVector2Array, col: Color, cols: PackedColorArray = PackedColorArray()) -> void:
	var c: PackedColorArray = cols if cols.size() == 4 else PackedColorArray([col, col, col, col])
	draw_primitive(PackedVector2Array([h[0], h[1], h[2]]), PackedColorArray([c[0], c[1], c[2]]), PackedVector2Array())
	draw_primitive(PackedVector2Array([h[0], h[2], h[3]]), PackedColorArray([c[0], c[2], c[3]]), PackedVector2Array())


## Fills the ribbon as quads coloured light (top edge) to dark (bottom edge).
func _draw_tube(shaft: PackedVector2Array, col: Color) -> void:
	var e: Array[PackedVector2Array] = _edges(shaft, 0.0)
	var top: PackedVector2Array = e[0]
	var bottom: PackedVector2Array = e[1]
	var light: Color = col.lightened(0.3)
	var dark: Color = col.darkened(0.22)
	for i: int in range(1, shaft.size()):
		# Whichever edge is higher on screen gets the light.
		var up: bool = (top[i] - bottom[i]).y <= 0.0
		var ca: Color = light if up else dark
		var cb: Color = dark if up else light
		var quad := PackedVector2Array([top[i - 1], top[i], shaft[i], shaft[i - 1]])
		draw_primitive(quad, PackedColorArray([ca, ca, col, col]), PackedVector2Array())
		var quad2 := PackedVector2Array([shaft[i - 1], shaft[i], bottom[i], bottom[i - 1]])
		draw_primitive(quad2, PackedColorArray([col, col, cb, cb]), PackedVector2Array())


## An antialiased line round a polygon so its edge isn't jagged.
func _smooth_edge(poly: PackedVector2Array, col: Color) -> void:
	var loop := PackedVector2Array(poly)
	loop.append(poly[0])
	draw_polyline(loop, col, 1.5, true)


## Bright pulses scrolling along the shaft toward the head, fading in at the tail and out at the head.
func _draw_chevrons(shaft: PackedVector2Array, col: Color) -> void:
	var length: float = _shaft_length()
	var glow: Color = col.lightened(0.75)
	for d: float in chevron_offsets():
		var walked: float = 0.0
		for i: int in range(1, shaft.size()):
			var seg: float = shaft[i - 1].distance_to(shaft[i])
			if walked + seg >= d:
				var dir: Vector2 = (shaft[i] - shaft[i - 1]).normalized()
				var c: Vector2 = shaft[i - 1] + dir * (d - walked)
				var side := Vector2(-dir.y, dir.x)
				var w: float = _half(d / maxf(length, 1.0)) * 0.75
				var fade: float = clampf(minf(d / 30.0, (length - d) / 30.0), 0.0, 1.0)
				var pts := PackedVector2Array([c - dir * w + side * w, c + dir * w * 0.5, c - dir * w - side * w])
				draw_polyline(pts, Color(glow, 0.85 * fade), 3.5, true)
				break
			walked += seg
