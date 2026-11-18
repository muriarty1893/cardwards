class_name MenuButtons
extends RefCounted
## Chunky buttons shared by the menu and results screen.


static func big(text: String, color: Color, font_size: int = 22) -> Button:
	var b := Button.new()
	b.text = text
	b.add_theme_font_size_override("font_size", font_size)
	UiStyle.title(b)
	UiStyle.sound_button(b)
	b.focus_mode = Control.FOCUS_ALL
	# White asks for the plain button: parchment on the table look.
	if color == Color.WHITE:
		color = UiStyle.PARCHMENT
	for st: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		var sb := UiStyle.panel(color if st != "hover" else color.lightened(0.2), 14)
		sb.shadow_color = UiStyle.WOOD_INK
		sb.shadow_offset = Vector2(0, 1) if st == "pressed" else Vector2(0, 5)
		sb.content_margin_top = 10
		sb.content_margin_bottom = 10
		sb.content_margin_left = 22
		sb.content_margin_right = 22
		if st == "focus":
			sb.border_color = UiStyle.BRASS_DARK
		b.add_theme_stylebox_override(st, sb)
	for c: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(c, UiStyle.WOOD_INK)
	return b
