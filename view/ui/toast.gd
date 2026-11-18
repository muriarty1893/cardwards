class_name Toast
extends PanelContainer
## Dark see-through message banner near the top centre (turn messages, rejected actions, tips).

var _label: Label
var _tw: Tween


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.06, 0.16, 0.78)
	sb.set_corner_radius_all(12)
	sb.content_margin_left = 26
	sb.content_margin_right = 26
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	add_theme_stylebox_override("panel", sb)
	_label = UiStyle.title(UiStyle.label("", 28, Color.WHITE)) as Label
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_label)
	modulate.a = 0.0


func show_message(text_: String, seconds: float = 1.5) -> void:
	_label.text = text_
	reset_size()
	# Anchored at the top centre: keep it centred whatever the text length.
	if is_equal_approx(anchor_left, 0.5) and is_equal_approx(anchor_right, 0.5):
		offset_left = -size.x / 2.0
		offset_right = size.x / 2.0
	if _tw:
		_tw.kill()
	modulate.a = 1.0
	_tw = create_tween()
	_tw.tween_interval(seconds)
	_tw.tween_property(self, "modulate:a", 0.0, 0.3)
