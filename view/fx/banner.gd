class_name Banner
extends Control
## Big "YOUR TURN" style ribbon that sweeps across the screen and frees itself.

const IN := 0.35
const HOLD := 0.6
const OUT := 0.3


static func show_turn(parent: Control, text: String, color: Color) -> Banner:
	var b := Banner.new()
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(b)
	b.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var ribbon := Panel.new()
	ribbon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.border_color = Palette.INK
	sb.set_border_width_all(5)
	sb.set_corner_radius_all(16)
	sb.shadow_color = Color(Palette.INK, 0.5)
	sb.shadow_offset = Vector2(0, 6)
	ribbon.add_theme_stylebox_override("panel", sb)
	var w: float = 560.0
	var h: float = 104.0
	var vp: Vector2 = parent.get_viewport_rect().size
	ribbon.size = Vector2(w, h)
	ribbon.position = Vector2(-w - 20.0, vp.y * 0.32)
	b.add_child(ribbon)
	var l := UiStyle.title(UiStyle.label(text, 60, Color.WHITE)) as Label
	l.size = ribbon.size
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_color_override("font_outline_color", Palette.INK)
	l.add_theme_constant_override("outline_size", 12)
	ribbon.add_child(l)
	var mid: float = (vp.x - w) / 2.0
	var tw := b.create_tween()
	tw.tween_property(ribbon, "position:x", mid, IN).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(HOLD)
	tw.tween_property(ribbon, "position:x", vp.x + 20.0, OUT).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.tween_callback(b.queue_free)
	return b
