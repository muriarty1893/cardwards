class_name CardWidget
extends Control
## A 140x196 card face: land-coloured frame with an ink border, baked picture, name ribbon,
## type line, rules text, cost gem and (creatures) sword and heart badges.

const SIZE := Vector2(140, 196)
const ART := Rect2(8, 8, 124, 93)
const KIND_NAMES: Array[String] = ["CREATURE", "BUILDING", "SPELL"]
## Cost gem number while a discount lowers the cost.
const DISCOUNT := Color("#7dff6a")
## A changed copy's number that got worse (Dark Moon spec 6).
const WORSE := Color("#ff6a6a")
## Frames: curses are purple-black; legendaries get a gold rim and a crown.
const CURSE_FRAME := Color("#3a2552")
const ICON_CROWN := "res://assets/icons/crown.svg"
const ICON_GIFT := "res://assets/icons/evil-moon.svg"


## "BEAST · L2" for creatures (the tribe says it's a creature), "FIELD SPELL", "BUILDING"...
static func type_line(c: CardData) -> String:
	if c.is_creature():
		var tribe: String = Tribes.NAMES.get(c.tribe, "Creature")
		return "%s  ·  L%d" % [tribe.to_upper(), c.level]
	if c.field:
		return "FIELD SPELL"
	return KIND_NAMES[c.kind]

var card: CardData
var index: int = -1
var _art: TextureRect
var _text: RichTextLabel
var _combo: Panel
var _ready: Panel
static var _bold: FontVariation
var _cost: Label
var _atk: Label
var _hp: Label
var _frame_color: Color
## Cost shown on the gem (the printed cost unless set_cost lowered it).
var _shown_cost: int = 0


func setup(c: CardData, i: int) -> void:
	card = c
	index = i
	custom_minimum_size = SIZE
	size = SIZE
	pivot_offset = Vector2.ZERO
	mouse_filter = Control.MOUSE_FILTER_STOP
	var land: Color = CURSE_FRAME if c.curse else Palette.LAND_CARD[c.land]
	_frame_color = land
	var frame := _panel(Rect2(Vector2.ZERO, SIZE), land, 4, 12)
	if c.land == CardData.Land.NEUTRAL or c.legendary:
		# Neutral cards (Star Shard) get a gold rim.
		var fsb := frame.get_theme_stylebox("panel") as StyleBoxFlat
		fsb.border_color = Palette.GOLD.darkened(0.35)
		fsb.set_border_width_all(6)
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
	var kind := UiStyle.bold(UiStyle.label(type_line(c), 10, Palette.INK))
	kind.position = Vector2(4, 118)
	kind.size = Vector2(SIZE.x - 8, 13)
	kind.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	frame.add_child(kind)
	# Rules text on a paper panel (kept above the stat badges on creatures).
	var text_rect := Rect2(8, 131, SIZE.x - 16, 38 if c.is_creature() else 56)
	var paper := _panel(text_rect, Palette.PAPER, 2, 6)
	frame.add_child(paper)
	var rules: String = CardText.render(c)
	# Rich text so mechanic names are bold; their rules show in KeywordNotes beside an enlarged card.
	# The biggest size (10 down to MIN_TEXT_SIZE) at which the whole text fits the box.
	var fs: int = fit_size(rules, text_rect.size.x - 6, text_rect.size.y)
	_text = RichTextLabel.new()
	_text.bbcode_enabled = true
	_text.scroll_active = false
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_text.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_text.add_theme_font_size_override("normal_font_size", fs)
	_text.add_theme_font_size_override("bold_font_size", fs)
	_text.add_theme_font_override("bold_font", bold_font())
	_text.add_theme_color_override("default_color", Palette.INK)
	_text.add_theme_constant_override("line_separation", LINE_GAP)
	_text.text = CardText.render_bbcode(c)
	_text.position = Vector2(3, 0)
	_text.size = text_rect.size - Vector2(6, 0)
	paper.add_child(_text)
	paper.visible = rules != ""
	var gem := _gem(Vector2(-8, -8), 36, Palette.MAGIC, str(c.cost), 18)
	add_child(gem)
	_cost = gem.get_child(gem.get_child_count() - 1) as Label
	_shown_cost = c.cost
	var printed: CardData = CardDB.card(c.id) if CardDB.has_card(c.id) else c
	if c.cost != printed.cost:
		_cost.add_theme_color_override("font_color", DISCOUNT if c.cost < printed.cost else WORSE)
	if c.is_creature():
		var ag := _gem(Vector2(-4, 166), 34, Color("#ffcf3a"), str(c.attack), 17, VisualDB.ICON_SWORDS)
		add_child(ag)
		_atk = ag.get_child(ag.get_child_count() - 1) as Label
		var hg := _gem(Vector2(SIZE.x - 30, 166), 34, Palette.HP, str(c.health), 17, VisualDB.ICON_HEART)
		add_child(hg)
		_hp = hg.get_child(hg.get_child_count() - 1) as Label
		if c.attack != printed.attack:
			_atk.add_theme_color_override("font_color", DISCOUNT if c.attack > printed.attack else WORSE)
		if c.health != printed.health:
			_hp.add_theme_color_override("font_color", DISCOUNT if c.health > printed.health else WORSE)
	if c.legendary:
		var crown := TextureRect.new()
		crown.name = "Crown"
		crown.texture = load(ICON_CROWN) as Texture2D
		crown.modulate = Palette.GOLD
		crown.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		crown.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		crown.size = Vector2(40, 30)
		crown.position = Vector2(SIZE.x / 2.0 - 20.0, -18)
		crown.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(crown)
	if c.changes.has("gift"):
		var mark := _gem(Vector2(SIZE.x - 30, 4), 26, Color("#5a3aa8"), "", 10, ICON_GIFT)
		mark.name = "GiftMark"
		(mark.get_node("Symbol") as TextureRect).modulate = Color(1, 1, 1, 0.95)
		mark.tooltip_text = "Dark Gift: %s" % Gifts.TEXT.get(StringName(c.changes["gift"]), "")
		add_child(mark)


## Smallest rules-text size; below this a card's text would be unreadable even zoomed.
const MIN_TEXT_SIZE := 6
## Rules text line spacing (tighter than the font's own).
const LINE_GAP := -2


## Largest font size from 10 down to MIN_TEXT_SIZE whose word-wrapped `text` fits `width` x `height`.
## Measured with the bold font, the widest the label draws, so it never overflows.
static func fit_size(text: String, width: float, height: float) -> int:
	var font: Font = bold_font()
	for fs: int in range(10, MIN_TEXT_SIZE - 1, -1):
		if text_height(font, text, width, fs) <= height:
			return fs
	return MIN_TEXT_SIZE


## Height of `text` wrapped to `width` at size `fs`, with the card's tighter line spacing.
static func text_height(font: Font, text: String, width: float, fs: int) -> float:
	var lines: int = 0
	for para: String in text.split("\n"):
		var words: PackedStringArray = para.split(" ", false)
		var line: String = ""
		for wd: String in words:
			var trial: String = wd if line == "" else line + " " + wd
			if line != "" and font.get_string_size(trial, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x > width:
				lines += 1
				line = wd
			else:
				line = trial
		lines += 1
	var lh: float = font.get_height(fs)
	return lines * lh + (lines - 1) * LINE_GAP + 2.0


func attack_label() -> Label:
	return _atk


func health_label() -> Label:
	return _hp


func frame_color() -> Color:
	return _frame_color


func art_texture() -> Texture2D:
	return _art.texture


func text_label() -> RichTextLabel:
	return _text


## The default font, emboldened (works on the web too, where there are no system fonts).
static func bold_font() -> FontVariation:
	if _bold == null:
		_bold = FontVariation.new()
		_bold.base_font = ThemeDB.fallback_font
		_bold.variation_embolden = 0.9
	return _bold


## Gold glow around a Combo card while its Combo is on (you already played a card this turn).
func set_combo(on: bool) -> void:
	if not on and _combo == null:
		return
	if _combo == null:
		_combo = Panel.new()
		_combo.name = "ComboGlow"
		_combo.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_combo.position = Vector2(-5, -5)
		_combo.size = SIZE + Vector2(10, 10)
		_combo.show_behind_parent = false
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0, 0, 0, 0)
		sb.border_color = Palette.GOLD
		sb.set_border_width_all(4)
		sb.set_corner_radius_all(15)
		sb.shadow_color = Color(Palette.GOLD, 0.8)
		sb.shadow_size = 10
		_combo.add_theme_stylebox_override("panel", sb)
		add_child(_combo)
		move_child(_combo, 0)
		var tw := _combo.create_tween().set_loops()
		tw.tween_property(_combo, "modulate:a", 0.55, 0.6).set_trans(Tween.TRANS_SINE)
		tw.tween_property(_combo, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_SINE)
	_combo.visible = on


func combo_on() -> bool:
	return _combo != null and _combo.visible


func cost_label() -> Label:
	return _cost


## Shows `n` on the cost gem: green when it is below the printed cost (a spell discount), white otherwise.
func set_cost(n: int) -> void:
	_shown_cost = n
	_cost.text = str(n)
	var printed: int = CardDB.card(card.id).cost if CardDB.has_card(card.id) else card.cost
	_cost.add_theme_color_override("font_color", DISCOUNT if n < printed else (WORSE if n > printed else Color.WHITE))


func shown_cost() -> int:
	return _shown_cost


func is_discounted() -> bool:
	return _shown_cost < card.cost


func set_playable(on: bool) -> void:
	modulate = Color.WHITE if on else Color(0.68, 0.68, 0.68, 1.0)
	_set_ready_glow(on and index >= 0)


## A soft glow in the card's land colour behind a card you can play now.
func _set_ready_glow(on: bool) -> void:
	if not on and _ready == null:
		return
	if _ready == null:
		_ready = Panel.new()
		_ready.name = "ReadyGlow"
		_ready.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_ready.position = Vector2(-3, -3)
		_ready.size = SIZE + Vector2(6, 6)
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0, 0, 0, 0)
		sb.set_corner_radius_all(14)
		sb.shadow_color = Color(Palette.LAND_CARD[card.land].lightened(0.35), 0.75)
		sb.shadow_size = 9
		_ready.add_theme_stylebox_override("panel", sb)
		add_child(_ready)
		move_child(_ready, 0)
	_ready.visible = on


func ready_glow() -> bool:
	return _ready != null and _ready.visible


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


## Round badge with a number (and a faint icon behind it).
func _gem(pos: Vector2, d: float, col: Color, value: String, font: int, icon: String = "") -> Panel:
	var g := _panel(Rect2(pos, Vector2(d, d)), col, 3, int(d / 2.0))
	if icon != "":
		var s := TextureRect.new()
		s.name = "Symbol"
		s.texture = load(icon) as Texture2D
		s.modulate = Color(1, 1, 1, 0.35)
		s.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		s.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		s.position = g.size * 0.18
		s.size = g.size * 0.64
		s.mouse_filter = Control.MOUSE_FILTER_IGNORE
		g.add_child(s)
	var l := UiStyle.title(UiStyle.label(value, font, Color.WHITE)) as Label
	l.size = g.size
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_color_override("font_outline_color", Palette.INK)
	l.add_theme_constant_override("outline_size", 6)
	g.add_child(l)
	return g
