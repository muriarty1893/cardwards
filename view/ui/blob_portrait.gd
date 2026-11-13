class_name BlobPortrait
extends Control
## A little drawn critter face for the hero corners (our own mascot blobs).

var body_color: Color = Color("#ffd84a")
var bg_color: Color = Color("#8fd3ff")
var horns: bool = false


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg_color
	sb.border_color = Palette.TRAY_DARK
	sb.set_border_width_all(4)
	sb.set_corner_radius_all(14)
	draw_style_box(sb, r)
	var c := Vector2(size.x * 0.5, size.y * 0.6)
	var rad: float = size.x * 0.32
	if horns:
		for s: float in [-1.0, 1.0]:
			draw_colored_polygon(PackedVector2Array([c + Vector2(s * rad * 0.3, -rad * 0.8), c + Vector2(s * rad * 0.95, -rad * 0.5), c + Vector2(s * rad * 0.85, -rad * 1.5)]), Color("#fff3dd"))
	else:
		for s: float in [-1.0, 1.0]:
			draw_circle(c + Vector2(s * rad * 0.75, -rad * 0.8), rad * 0.3, body_color.darkened(0.2))
	draw_circle(c + Vector2(0, 3), rad + 3.0, Palette.TRAY_DARK)
	draw_circle(c, rad, body_color)
	draw_circle(c + Vector2(-rad * 0.3, -rad * 0.3), rad * 0.45, body_color.lightened(0.25))
	for s: float in [-1.0, 1.0]:
		draw_circle(c + Vector2(s * rad * 0.38, -rad * 0.05), rad * 0.27, Color.WHITE)
		draw_circle(c + Vector2(s * rad * 0.38, 0.0), rad * 0.13, Color("#111111"))
	draw_arc(c + Vector2(0, rad * 0.3), rad * 0.3, 0.2, PI - 0.2, 10, Palette.TRAY_DARK, 3.0)
