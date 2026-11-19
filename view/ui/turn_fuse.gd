class_name TurnFuse
extends Control
## A burning rope along the top of END TURN for the last seconds of an online turn: the rope shrinks
## toward the left, a flickering spark eats it, and the seconds left sit at the spark.

const ROPE := Color("#c9a26a")
const ROPE_DARK := Color("#8a6a3e")
const ASH := Color(0.25, 0.22, 0.2, 0.55)
const SPARK := Color("#ffb347")
const SPARK_CORE := Color("#fff4c2")

## 1 = full rope (FUSE_SECONDS left), 0 = burnt out.
var fraction: float = 1.0
var seconds_left: int = 15
var _t: float = 0.0
var _label: Label


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label = UiStyle.title(UiStyle.label("15", 15, Color.WHITE)) as Label
	_label.add_theme_color_override("font_outline_color", UiStyle.WOOD_INK)
	_label.add_theme_constant_override("outline_size", 6)
	_label.size = Vector2(28, 18)
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_label)
	visible = false


func show_left(seconds: float, fuse_seconds: float) -> void:
	fraction = clampf(seconds / fuse_seconds, 0.0, 1.0)
	seconds_left = ceili(seconds)
	visible = true
	queue_redraw()


func _process(delta: float) -> void:
	if visible:
		_t += delta
		queue_redraw()


func _draw() -> void:
	var y: float = size.y * 0.5
	var x0: float = 10.0
	var x1: float = size.x - 10.0
	var burn: float = lerpf(x0, x1, fraction)
	# Ash where the rope was.
	draw_line(Vector2(burn, y), Vector2(x1, y), ASH, 3.0, true)
	# The rope: a thick strand with diagonal twists.
	if burn > x0:
		draw_line(Vector2(x0, y), Vector2(burn, y), ROPE_DARK, 7.0, true)
		draw_line(Vector2(x0, y), Vector2(burn, y), ROPE, 5.0, true)
		var x: float = x0
		while x < burn - 4.0:
			draw_line(Vector2(x, y + 2.5), Vector2(x + 4.0, y - 2.5), ROPE_DARK, 1.5, true)
			x += 7.0
	# The spark, flickering; it turns redder in the last five seconds.
	var hot: Color = SPARK.lerp(Color("#ff4a2a"), clampf(1.0 - seconds_left / 5.0, 0.0, 1.0))
	var flick: float = 1.0 + 0.25 * sin(_t * 31.0) + 0.15 * sin(_t * 17.0)
	draw_circle(Vector2(burn, y), 11.0 * flick, Color(hot, 0.25))
	draw_circle(Vector2(burn, y), 6.5 * flick, Color(hot, 0.8))
	draw_circle(Vector2(burn, y), 3.0, SPARK_CORE)
	for i: int in 3:
		var a: float = _t * (9.0 + i * 3.0) + i * 2.1
		var r: float = 8.0 + 5.0 * fmod(_t * 3.0 + i * 0.37, 1.0)
		draw_circle(Vector2(burn, y) + Vector2(cos(a), -absf(sin(a))) * r, 1.6, Color(hot, 0.9))
	_label.text = str(seconds_left)
	_label.position = Vector2(clampf(burn - 14.0, 0.0, size.x - 28.0), y - 26.0)
