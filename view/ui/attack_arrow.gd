class_name AttackArrow
extends Control
## The chunky curved arrow drawn while aiming an attack (and during the rival's attacks):
## ink outline, gold over a valid target, grey otherwise. Never takes the mouse.

const VALID := Color("#ffcf3a")
const INVALID := Color("#a6a6b4")
const WIDTH := 16.0
const OUTLINE := 5.0
const HEAD := Vector2(40, 28)

var _from := Vector2.ZERO
var _to := Vector2.ZERO
var _valid: bool = false


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


func aim(from: Vector2, to: Vector2, valid: bool) -> void:
	_from = from
	_to = to
	_valid = valid
	visible = true
	queue_redraw()


func clear() -> void:
	visible = false
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
	var shaft := PackedVector2Array()
	for p: Vector2 in pts:
		if (p - tip).dot(dir) < -HEAD.x * 0.6:
			shaft.append(p)
	shaft.append(base + dir * 4.0)
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
