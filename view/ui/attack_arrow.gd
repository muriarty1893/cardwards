class_name AttackArrow
extends Control
## The chunky curved arrow drawn while aiming an attack (and during the rival's attacks):
## ink outline, gold over a valid target, grey otherwise. Never takes the mouse.

const VALID := Color("#ffcf3a")
const INVALID := Color("#a6a6b4")
const WIDTH := 16.0
const OUTLINE := 5.0
const HEAD := Vector2(40, 28)
## Flowing chevrons along the shaft (Hearthstone-style): spacing and speed in pixels.
const CHEVRON_GAP := 34.0
const FLOW_SPEED := 70.0

var _from := Vector2.ZERO
var _to := Vector2.ZERO
var _valid: bool = false
## Distance the chevron strip has scrolled toward the head, wrapped to CHEVRON_GAP.
var _flow: float = 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	set_process(false)


func _process(delta: float) -> void:
	_flow = fmod(_flow + delta * FLOW_SPEED, CHEVRON_GAP)
	queue_redraw()


## Arc-length positions of the chevrons along the shaft, from the tail.
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
		if (p - tip).dot(dir) < -HEAD.x * 0.6:
			shaft.append(p)
	shaft.append(base + dir * 4.0)
	return shaft


func aim(from: Vector2, to: Vector2, valid: bool) -> void:
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
	for i: int in 25:
		var t: float = i / 24.0
		pts.append(_from.lerp(ctrl, t).lerp(ctrl.lerp(_to, t), t))
	return pts


func _draw() -> void:
	if not visible or _from.distance_to(_to) < 8.0:
		return
	var pts: PackedVector2Array = _curve()
	var tip: Vector2 = pts[pts.size() - 1]
	var dir: Vector2 = (tip - pts[pts.size() - 3]).normalized()
	var side := Vector2(-dir.y, dir.x)
	var base: Vector2 = tip - dir * HEAD.x
	# The shaft stops under the head so the outline reads as one shape.
	var shaft: PackedVector2Array = _shaft_points()
	var col: Color = VALID if _valid else INVALID
	var head := PackedVector2Array([tip, base + side * HEAD.y, base - side * HEAD.y])
	var head_ink := PackedVector2Array([tip + dir * OUTLINE * 1.6, base + side * (HEAD.y + OUTLINE * 1.4) - dir * OUTLINE, base - side * (HEAD.y + OUTLINE * 1.4) - dir * OUTLINE])
	draw_polyline(shaft, Palette.INK, WIDTH + OUTLINE * 2.0, true)
	draw_colored_polygon(head_ink, Palette.INK)
	draw_polyline(shaft, col, WIDTH, true)
	draw_colored_polygon(head, col)
	# A soft highlight stripe along the top edge.
	var shine := PackedVector2Array()
	for p: Vector2 in shaft:
		shine.append(p - Vector2(0, WIDTH * 0.22))
	draw_polyline(shine, col.lightened(0.45), 3.0, true)
	_draw_chevrons(shaft, col)


## Chevrons scrolling along the shaft toward the head, fading in at the tail and out at the head.
func _draw_chevrons(shaft: PackedVector2Array, col: Color) -> void:
	var length: float = _shaft_length()
	var ink: Color = col.darkened(0.6)
	for d: float in chevron_offsets():
		var walked: float = 0.0
		for i: int in range(1, shaft.size()):
			var seg: float = shaft[i - 1].distance_to(shaft[i])
			if walked + seg >= d:
				var dir: Vector2 = (shaft[i] - shaft[i - 1]).normalized()
				var c: Vector2 = shaft[i - 1] + dir * (d - walked)
				var side := Vector2(-dir.y, dir.x)
				var w: float = WIDTH * 0.5
				var fade: float = clampf(minf(d / 24.0, (length - d) / 24.0), 0.0, 1.0)
				var pts := PackedVector2Array([c - dir * w + side * w, c + dir * w * 0.4, c - dir * w - side * w])
				draw_polyline(pts, Color(ink, 0.9 * fade), 5.0, true)
				break
			walked += seg
