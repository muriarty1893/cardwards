class_name KeywordNotes
extends VBoxContainer
## Small parchment notes beside an enlarged card, one per mechanic it uses ("Guard: Enemies must
## attack a Guard first…"), with the keyword's icon. Like the keyword boxes next to a big card in
## Hearthstone: the player never has to know the rules by heart.

const WIDTH := 210.0
const GAP := 8.0

var card: CardData


## Notes for `c`, or null when the card uses no mechanics and has no tribe.
static func make(c: CardData) -> KeywordNotes:
	var keys: Array[StringName] = CardText.mechanics(c)
	if keys.is_empty() and c.tribe == &"":
		return null
	var n := KeywordNotes.new()
	n.card = c
	n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	n.add_theme_constant_override("separation", 4)
	n.custom_minimum_size = Vector2(WIDTH, 0)
	for k: StringName in keys:
		n.add_child(_note(VisualDB.keyword_icon(k), Keywords.NAMES[k], Keywords.RULES[k], VisualDB.KEYWORD_COLORS.get(k, UiStyle.WOOD)))
	if c.tribe != &"":
		n.add_child(_note(null, Tribes.NAMES[c.tribe], Tribes.rules_text(c.tribe), UiStyle.WOOD))
	return n


## Rect for notes of `size_` beside a card shown at `card_rect`: to its right, or left when that
## would leave the screen; nudged up so it stays on screen.
static func place(card_rect: Rect2, size_: Vector2, screen: Vector2) -> Vector2:
	var x: float = card_rect.end.x + GAP
	if x + size_.x > screen.x - 4.0:
		x = card_rect.position.x - GAP - size_.x
	var y: float = clampf(card_rect.position.y, 4.0, maxf(4.0, screen.y - size_.y - 4.0))
	return Vector2(x, y)


static func _note(icon: Texture2D, title: String, rule: String, col: Color) -> PanelContainer:
	var p := PanelContainer.new()
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = UiStyle.PARCHMENT
	sb.border_color = UiStyle.WOOD_INK
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(10)
	sb.set_content_margin_all(6)
	sb.shadow_color = Color(UiStyle.WOOD_INK, 0.35)
	sb.shadow_offset = Vector2(0, 3)
	p.add_theme_stylebox_override("panel", sb)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	p.add_child(row)
	if icon:
		row.add_child(KeywordNotes.icon_chip(icon, col, 26.0))
	var col_box := VBoxContainer.new()
	col_box.add_theme_constant_override("separation", 0)
	col_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(col_box)
	var t := UiStyle.title(UiStyle.label(title, 15, UiStyle.WOOD_INK)) as Label
	col_box.add_child(t)
	var r := UiStyle.label(rule, 12, Palette.INK)
	r.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	r.custom_minimum_size = Vector2(WIDTH - 52.0, 0)
	col_box.add_child(r)
	return p


## A round coloured chip with a white icon (keyword badges on tags and notes).
static func icon_chip(icon: Texture2D, col: Color, d: float) -> Panel:
	var chip := Panel.new()
	chip.custom_minimum_size = Vector2(d, d)
	chip.size = Vector2(d, d)
	chip.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.border_color = Palette.INK
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(int(d / 2.0))
	chip.add_theme_stylebox_override("panel", sb)
	var tr := TextureRect.new()
	tr.name = "Icon"
	tr.texture = icon
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.position = Vector2(d, d) * 0.17
	tr.size = Vector2(d, d) * 0.66
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_child(tr)
	return chip
