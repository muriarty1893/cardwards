class_name UiStyle
extends RefCounted
## Shared chunky cartoon UI styling.

## Lilita One (OFL) for names, numbers and titles.
const TITLE_FONT := "res://assets/fonts/LilitaOne-Regular.ttf"
## Wood, parchment and brass for the table HUD (tabletop spec 7.1).
const WOOD := Color("#8a5a34")
const WOOD_DARK := Color("#5b3a22")
const WOOD_INK := Color("#3b2a1a")
const BRASS := Color("#e0b04a")
const BRASS_DARK := Color("#9c6f22")
const PARCHMENT := Color("#f6e7c4")

static var _title_font: FontFile
static var _bold_font: SystemFont


## Chunky panel with a dark wood border (parchment by default).
static func panel(bg: Color = PARCHMENT, radius: int = 16) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = WOOD_INK
	sb.set_border_width_all(5)
	sb.set_corner_radius_all(radius)
	sb.shadow_color = Color(WOOD_INK, 0.45)
	sb.shadow_offset = Vector2(0, 5)
	sb.shadow_size = 1
	sb.set_content_margin_all(8)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	return sb


static func parchment_panel(radius: int = 16) -> StyleBoxFlat:
	return panel(PARCHMENT, radius)


static func wood_panel(radius: int = 16) -> StyleBoxFlat:
	return panel(WOOD, radius)


static func label(text: String, size: int = 20, color: Color = Palette.INK) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


static func bold(l: Label) -> Label:
	# One shared SystemFont: building a new one per label cost ~8 ms each (hand rebuild hitches).
	if _bold_font == null:
		_bold_font = SystemFont.new()
		_bold_font.font_names = PackedStringArray(["Nunito", "Fredoka", "Noto Sans", "sans-serif"])
		_bold_font.font_weight = 800
	l.add_theme_font_override("font", _bold_font)
	return l


## Hover tick and click sound on a button.
static func sound_button(b: BaseButton) -> void:
	b.mouse_entered.connect(func() -> void:
		if not b.disabled:
			Audio.sfx(&"ui_hover", 0.05))
	b.pressed.connect(func() -> void: Audio.sfx(&"ui_click", 0.05))


## Applies the cartoon title font (Lilita One) to a label or button.
static func title(c: Control) -> Control:
	if _title_font == null:
		_title_font = load(TITLE_FONT) as FontFile
	c.add_theme_font_override("font", _title_font)
	return c
