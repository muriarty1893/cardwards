class_name UiStyle
extends RefCounted
## Shared chunky cartoon UI styling.

## Lilita One (OFL) for names, numbers and titles.
const TITLE_FONT := "res://assets/fonts/LilitaOne-Regular.ttf"

static var _title_font: FontFile


static func panel(bg: Color = Color(1, 1, 1, 0.95), radius: int = 16) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = Palette.INK
	sb.set_border_width_all(4)
	sb.set_corner_radius_all(radius)
	sb.shadow_color = Color(Palette.INK, 0.45)
	sb.shadow_offset = Vector2(0, 5)
	sb.shadow_size = 1
	sb.set_content_margin_all(8)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	return sb


static func label(text: String, size: int = 20, color: Color = Palette.INK) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


static func bold(l: Label) -> Label:
	var f := SystemFont.new()
	f.font_names = PackedStringArray(["Nunito", "Fredoka", "Noto Sans", "sans-serif"])
	f.font_weight = 800
	l.add_theme_font_override("font", f)
	return l


## Applies the cartoon title font (Lilita One) to a label or button.
static func title(c: Control) -> Control:
	if _title_font == null:
		_title_font = load(TITLE_FONT) as FontFile
	c.add_theme_font_override("font", _title_font)
	return c
