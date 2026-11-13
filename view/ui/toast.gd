class_name Toast
extends Label
## Short message near the top centre (rejected actions, turn banners).

var _tw: Tween


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_theme_font_size_override("font_size", 26)
	add_theme_color_override("font_color", Color.WHITE)
	add_theme_color_override("font_outline_color", Palette.INK)
	add_theme_constant_override("outline_size", 10)
	UiStyle.bold(self)
	modulate.a = 0.0


func show_message(text_: String, seconds: float = 1.5) -> void:
	text = text_
	if _tw:
		_tw.kill()
	modulate.a = 1.0
	_tw = create_tween()
	_tw.tween_interval(seconds)
	_tw.tween_property(self, "modulate:a", 0.0, 0.3)
