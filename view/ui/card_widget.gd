class_name CardWidget
extends Control
## A 140x196 card face: land-coloured frame with an ink border, baked picture, name ribbon,
## type line, rules text, cost gem and (creatures) sword and heart badges.

const SIZE := Vector2(140, 196)
const ART := Rect2(8, 8, 124, 93)
const KIND_NAMES: Array[String] = ["CREATURE", "BUILDING", "SPELL"]

var card: CardData
var index: int = -1
var _art: TextureRect
var _text: Label


func setup(c: CardData, i: int) -> void:
	card = c
	index = i
	custom_minimum_size = SIZE
	size = SIZE
	pivot_offset = Vector2.ZERO
	mouse_filter = Control.MOUSE_FILTER_STOP
	var land: Color = Palette.LAND_CARD[c.land]
	var frame := _panel(Rect2(Vector2.ZERO, SIZE), land, 4, 12)
	add_child(frame)
	# Picture window.
	var art_back := _panel(ART.grow(2), Palette.INK, 0, 8)
	frame.add_child(art_back)
	_art = TextureRect.new()
	_art.position = ART.position
	_art.size = ART.size
	_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(VisualDB.art_path(c.id)):
		_art.texture = load(VisualDB.art_path(c.id)) as Texture2D
	frame.add_child(_art)
	# Name ribbon across the bottom of the picture.
	var ribbon := _panel(Rect2(4, 92, SIZE.x - 8, 26), land.darkened(0.25), 3, 6)
	frame.add_child(ribbon)
	var name_l := UiStyle.title(UiStyle.label(c.display_name, 15 if c.display_name.length() <= 13 else 14, Color.WHITE)) as Label
	name_l.size = ribbon.size
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_l.clip_text = true
	name_l.add_theme_color_override("font_outline_color", Palette.INK)
	name_l.add_theme_constant_override("outline_size", 6)
	ribbon.add_child(name_l)
	var kind := UiStyle.bold(UiStyle.label(KIND_NAMES[c.kind] + ("  ·  L%d" % c.level if c.is_creature() else ""), 10, Palette.INK))
	kind.position = Vector2(4, 119)
	kind.size = Vector2(SIZE.x - 8, 14)
	kind.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	frame.add_child(kind)
	# Rules text on a paper panel (kept above the stat badges on creatures).
	var text_rect := Rect2(8, 134, SIZE.x - 16, 34 if c.is_creature() else 44)
	var paper := _panel(text_rect, Palette.PAPER, 2, 6)
	frame.add_child(paper)
	var rules: String = CardText.render(c)
	_text = UiStyle.label(rules, 10 if rules.length() <= 34 else 9, Palette.INK)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_text.position = Vector2(3, 0)
	_text.size = text_rect.size - Vector2(6, 0)
	_text.add_theme_constant_override("line_spacing", -2)
	paper.add_child(_text)
	paper.visible = rules != ""
	add_child(_gem(Vector2(-8, -8), 36, Palette.MAGIC, str(c.cost), 18))
	if c.is_creature():
		add_child(_gem(Vector2(-4, 166), 34, Color("#ffcf3a"), str(c.attack), 17, "⚔"))
		add_child(_gem(Vector2(SIZE.x - 30, 166), 34, Palette.HP, str(c.health), 17, "♥"))


func art_texture() -> Texture2D:
	return _art.texture


func text_label() -> Label:
	return _text


func set_playable(on: bool) -> void:
	modulate = Color.WHITE if on else Color(0.68, 0.68, 0.68, 1.0)


func _panel(r: Rect2, bg: Color, border: int, radius: int) -> Panel:
	var p := Panel.new()
	p.position = r.position
	p.size = r.size
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = Palette.INK
	sb.set_border_width_all(border)
	sb.set_corner_radius_all(radius)
	p.add_theme_stylebox_override("panel", sb)
	return p


## Round badge with a number (and a faint symbol behind it).
func _gem(pos: Vector2, d: float, col: Color, value: String, font: int, symbol: String = "") -> Panel:
	var g := _panel(Rect2(pos, Vector2(d, d)), col, 3, int(d / 2.0))
	if symbol != "":
		var s := UiStyle.label(symbol, int(d * 0.62), Color(1, 1, 1, 0.35))
		s.size = g.size
		s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		s.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		g.add_child(s)
	var l := UiStyle.title(UiStyle.label(value, font, Color.WHITE)) as Label
	l.size = g.size
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_color_override("font_outline_color", Palette.INK)
	l.add_theme_constant_override("outline_size", 6)
	g.add_child(l)
	return g
