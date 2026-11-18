class_name DeckBuilder
extends Control
## Deck viewer and builder, opened from the main menu. Left: the 4 starter decks (view only, or
## copy one to edit) and your own decks, plus NEW DECK. Middle: every card, filtered by land or
## spells; click one to add it (badges show copies in the deck). Right: the deck's name, count
## and cards by cost; click a row to take one out. Your decks save on every change.

signal closed
signal deck_chosen(id: StringName)

const FILTERS: Array[String] = ["ALL", "MUSHROOM", "EMBER", "CANDY", "FROST", "SPELLS"]
const THUMB := 0.72
const COLUMNS := 6

var deck_id: StringName = &""
var cards: Array[CardData] = []
var editable: bool = false
var _filter: int = 0
var _decks_box: VBoxContainer
var _grid: GridContainer
var _list: VBoxContainer
var _name_edit: LineEdit
var _name_label: Label
## The deck's card back (CardBacks), updated as its cards change.
var _back: TextureRect
var _lands: Array[int] = [0, 1, 2, 3]
var _count: Label
var _status: Label
var _copy_b: Button
var _delete_b: Button
var _use_b: Button
var _filter_buttons: Array[Button] = []
var _thumbs: Dictionary = {}
var _preview: CardWidget
var _deck_buttons: Dictionary = {}


func _init() -> void:
	name = "DeckBuilder"
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.5)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	for side: String in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 20)
	add_child(margin)
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiStyle.parchment_panel(22))
	margin.add_child(panel)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	panel.add_child(vb)
	var top := HBoxContainer.new()
	vb.add_child(top)
	var title := UiStyle.title(UiStyle.label("Decks", 34, UiStyle.WOOD_INK)) as Label
	top.add_child(title)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(spacer)
	var close_b := MenuButtons.big("CLOSE", Color.WHITE, 18)
	close_b.pressed.connect(close)
	top.add_child(close_b)
	var main := HBoxContainer.new()
	main.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main.add_theme_constant_override("separation", 14)
	vb.add_child(main)
	main.add_child(_build_left())
	main.add_child(_build_middle())
	main.add_child(_build_right())
	_refresh_decks()
	open_deck(CardDB.DECK_ORDER[0])


func _build_left() -> Control:
	var col := VBoxContainer.new()
	col.custom_minimum_size = Vector2(200, 0)
	col.add_theme_constant_override("separation", 8)
	_decks_box = VBoxContainer.new()
	_decks_box.add_theme_constant_override("separation", 6)
	col.add_child(_decks_box)
	var new_b := MenuButtons.big("+ NEW DECK", Palette.GOLD, 16)
	new_b.name = "NewDeck"
	new_b.pressed.connect(new_deck)
	col.add_child(new_b)
	var fill := Control.new()
	fill.size_flags_vertical = Control.SIZE_EXPAND_FILL
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	col.add_child(fill)
	_preview = CardWidget.new()
	_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_preview.visible = false
	var holder := Control.new()
	holder.custom_minimum_size = CardWidget.SIZE * 1.2
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_preview.scale = Vector2.ONE * 1.2
	holder.add_child(_preview)
	col.add_child(holder)
	return col


func _build_middle() -> Control:
	var col := VBoxContainer.new()
	col.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	col.add_theme_constant_override("separation", 8)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	col.add_child(row)
	for i: int in FILTERS.size():
		var b := Button.new()
		b.text = FILTERS[i]
		b.toggle_mode = true
		b.add_theme_font_size_override("font_size", 14)
		UiStyle.title(b)
		var base: Color = Palette.LAND_CARD[i - 1] if i >= 1 and i <= 4 else UiStyle.PARCHMENT.darkened(0.08)
		for st: String in ["normal", "hover", "pressed", "focus"]:
			var sb := UiStyle.panel(base.lerp(Color.WHITE, 0.35) if st == "normal" else base, 10)
			sb.set_border_width_all(3 if st != "pressed" else 5)
			sb.content_margin_top = 4
			sb.content_margin_bottom = 4
			if st == "focus":
				sb.draw_center = false
			b.add_theme_stylebox_override(st, sb)
		for c: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
			b.add_theme_color_override(c, UiStyle.WOOD_INK)
		b.pressed.connect(set_filter.bind(i))
		UiStyle.sound_button(b)
		row.add_child(b)
		_filter_buttons.append(b)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	# Cost and stat bubbles stick out past a card's edge: keep them inside the scroll area.
	var pad := MarginContainer.new()
	for side: String in ["left", "top", "right", "bottom"]:
		pad.add_theme_constant_override("margin_" + side, 10)
	scroll.add_child(pad)
	_grid = GridContainer.new()
	_grid.columns = COLUMNS
	_grid.add_theme_constant_override("h_separation", 12)
	_grid.add_theme_constant_override("v_separation", 12)
	pad.add_child(_grid)
	for c: CardData in CardDB.all_cards():
		if c.land == CardData.Land.NEUTRAL:
			continue
		_grid.add_child(_make_thumb(c))
	set_filter(0)
	return col


func _make_thumb(c: CardData) -> Control:
	var holder := Control.new()
	holder.name = String(c.id)
	holder.custom_minimum_size = CardWidget.SIZE * THUMB
	holder.mouse_filter = Control.MOUSE_FILTER_STOP
	var w := CardWidget.new()
	w.setup(c, 0)
	w.mouse_filter = Control.MOUSE_FILTER_IGNORE
	w.scale = Vector2.ONE * THUMB
	holder.add_child(w)
	var badge := UiStyle.title(UiStyle.label("", 15, Color.WHITE)) as Label
	badge.position = Vector2(CardWidget.SIZE.x * THUMB - 34, -6)
	badge.size = Vector2(38, 24)
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var sb := StyleBoxFlat.new()
	sb.bg_color = UiStyle.BRASS_DARK
	sb.border_color = UiStyle.WOOD_INK
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(10)
	badge.add_theme_stylebox_override("normal", sb)
	badge.add_theme_color_override("font_outline_color", UiStyle.WOOD_INK)
	badge.add_theme_constant_override("outline_size", 4)
	badge.visible = false
	holder.add_child(badge)
	holder.gui_input.connect(func(e: InputEvent) -> void:
		var mb := e as InputEventMouseButton
		if mb and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			add_card(c.id)
		elif mb and mb.pressed and mb.button_index == MOUSE_BUTTON_RIGHT:
			remove_card(c.id))
	holder.mouse_entered.connect(func() -> void: _show_preview(c))
	holder.mouse_exited.connect(func() -> void: _preview.visible = false)
	_thumbs[c.id] = {"holder": holder, "badge": badge, "card": c}
	return holder


func _build_right() -> Control:
	var col := VBoxContainer.new()
	col.custom_minimum_size = Vector2(270, 0)
	col.add_theme_constant_override("separation", 8)
	_back = TextureRect.new()
	_back.custom_minimum_size = Vector2(56, 78)
	_back.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_back.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_back.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_back.tooltip_text = "This deck's card back"
	col.add_child(_back)
	_name_edit = LineEdit.new()
	_name_edit.max_length = 24
	_name_edit.add_theme_font_size_override("font_size", 20)
	UiStyle.title(_name_edit)
	_name_edit.text_changed.connect(func(t: String) -> void:
		if editable:
			_save())
	col.add_child(_name_edit)
	_name_label = UiStyle.title(UiStyle.label("", 22, UiStyle.WOOD_INK)) as Label
	col.add_child(_name_label)
	_count = UiStyle.title(UiStyle.label("0/30", 18, UiStyle.WOOD_INK)) as Label
	col.add_child(_count)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	col.add_child(scroll)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 3)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_list)
	_status = UiStyle.label("", 14, Palette.HP.darkened(0.2))
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.custom_minimum_size = Vector2(260, 0)
	col.add_child(_status)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	col.add_child(row)
	_copy_b = MenuButtons.big("COPY TO EDIT", Color.WHITE, 14)
	_copy_b.pressed.connect(copy_deck)
	row.add_child(_copy_b)
	_delete_b = MenuButtons.big("DELETE", Color.WHITE, 14)
	_delete_b.pressed.connect(delete_deck)
	row.add_child(_delete_b)
	_use_b = MenuButtons.big("PLAY WITH IT", Palette.GOLD, 18)
	_use_b.pressed.connect(func() -> void:
		if DeckStore.validate(cards) == "":
			deck_chosen.emit(deck_id)
			close())
	col.add_child(_use_b)
	return col


# --- Actions (also used by tests) --------------------------------------------------------

func open_deck(id: StringName) -> void:
	deck_id = id
	editable = DeckStore.is_custom(id)
	var d: DeckData = DeckStore.find(id) if editable else CardDB.deck(id)
	cards = d.cards.duplicate() if d else []
	_lands = d.lands.duplicate() if d else [0, 1, 2, 3]
	_name_edit.visible = editable
	_name_label.visible = not editable
	_name_edit.text = d.display_name if d else ""
	_name_label.text = d.display_name if d else ""
	_copy_b.visible = not editable
	_delete_b.visible = editable
	for k: StringName in _deck_buttons:
		(_deck_buttons[k] as Button).set_pressed_no_signal(k == id)
	_refresh()


func new_deck() -> void:
	var id: StringName = DeckStore.new_id()
	DeckStore.put(DeckStore.make(id, "My deck %s" % String(id).trim_prefix(DeckStore.ID_PREFIX), []))
	_refresh_decks()
	open_deck(id)


## A starter deck copied into a new deck of your own, ready to edit.
func copy_deck() -> void:
	var id: StringName = DeckStore.new_id()
	DeckStore.put(DeckStore.make(id, "%s copy" % _name_label.text, cards))
	_refresh_decks()
	open_deck(id)


func delete_deck() -> void:
	if not editable:
		return
	DeckStore.remove(deck_id)
	_refresh_decks()
	open_deck(CardDB.DECK_ORDER[0])


func add_card(id: StringName) -> bool:
	var c: CardData = CardDB.card(id)
	if not editable:
		_status.text = "Starter decks are view only: COPY TO EDIT."
		return false
	if not DeckStore.can_add(cards, c):
		_status.text = "The deck is full." if cards.size() >= DeckStore.DECK_SIZE else "At most %d of each card." % DeckStore.MAX_COPIES
		return false
	cards.append(c)
	Audio.sfx(&"card_deal", 0.05)
	_save()
	_refresh()
	return true


func remove_card(id: StringName) -> bool:
	if not editable:
		return false
	var c: CardData = CardDB.card(id)
	var i: int = cards.find(c)
	if i < 0:
		return false
	cards.remove_at(i)
	Audio.sfx(&"card_flip", 0.05)
	_save()
	_refresh()
	return true


func set_filter(i: int) -> void:
	_filter = i
	for j: int in _filter_buttons.size():
		_filter_buttons[j].set_pressed_no_signal(j == i)
	for id: StringName in _thumbs:
		var c: CardData = _thumbs[id]["card"]
		var show: bool = i == 0 or (i <= 4 and c.land == i - 1) or (i == 5 and c.kind == CardData.Kind.SPELL)
		(_thumbs[id]["holder"] as Control).visible = show


func visible_cards() -> int:
	var n: int = 0
	for id: StringName in _thumbs:
		if (_thumbs[id]["holder"] as Control).visible:
			n += 1
	return n


func close() -> void:
	closed.emit()
	queue_free()


# --- Internals -------------------------------------------------------------------------------

func _save() -> void:
	if editable:
		var name_: String = _name_edit.text.strip_edges()
		DeckStore.put(DeckStore.make(deck_id, name_ if name_ != "" else "My deck", cards))
		var b: Variant = _deck_buttons.get(deck_id)
		if b:
			(b as Button).text = name_ if name_ != "" else "My deck"


func _refresh_decks() -> void:
	for c: Node in _decks_box.get_children():
		c.free()
	_deck_buttons.clear()
	var head := UiStyle.title(UiStyle.label("STARTER DECKS", 14, UiStyle.WOOD_DARK)) as Label
	_decks_box.add_child(head)
	for d: DeckData in CardDB.all_decks():
		_decks_box.add_child(_deck_button(d))
	var mine: Array[DeckData] = DeckStore.all()
	if not mine.is_empty():
		_decks_box.add_child(UiStyle.title(UiStyle.label("YOUR DECKS", 14, UiStyle.WOOD_DARK)) as Label)
		for d: DeckData in mine:
			_decks_box.add_child(_deck_button(d))


func _deck_button(d: DeckData) -> Button:
	var b := Button.new()
	b.name = "Deck_%s" % d.id
	b.text = d.display_name
	b.toggle_mode = true
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_font_size_override("font_size", 16)
	UiStyle.title(b)
	var base: Color = Palette.LAND_CARD[d.lands[0]] if not d.lands.is_empty() else UiStyle.PARCHMENT
	for st: String in ["normal", "hover", "pressed", "focus"]:
		var sb := UiStyle.panel(base.lerp(Color.WHITE, 0.5) if st == "normal" else base.lerp(Color.WHITE, 0.15), 10)
		sb.set_border_width_all(5 if st == "pressed" else 3)
		sb.content_margin_top = 6
		sb.content_margin_bottom = 6
		if st == "focus":
			sb.draw_center = false
		b.add_theme_stylebox_override(st, sb)
	for c: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(c, UiStyle.WOOD_INK)
	b.pressed.connect(open_deck.bind(d.id))
	UiStyle.sound_button(b)
	_deck_buttons[d.id] = b
	return b


func _refresh() -> void:
	if _back:
		var tmp := DeckData.new()
		tmp.lands = _lands
		tmp.cards = cards
		_back.texture = CardBacks.texture_for(tmp)
	var err: String = DeckStore.validate(cards)
	_count.text = "%d / %d cards" % [cards.size(), DeckStore.DECK_SIZE]
	_count.add_theme_color_override("font_color", UiStyle.WOOD_INK if cards.size() == DeckStore.DECK_SIZE else Palette.HP.darkened(0.1))
	_status.text = "" if err == "" or not editable else err
	_use_b.disabled = err != ""
	# Badges and dimming in the collection.
	for id: StringName in _thumbs:
		var c: CardData = _thumbs[id]["card"]
		var n: int = cards.count(c)
		var badge: Label = _thumbs[id]["badge"]
		badge.visible = n > 0
		badge.text = "%d/%d" % [n, DeckStore.MAX_COPIES]
		(_thumbs[id]["holder"] as Control).modulate = Color.WHITE if (not editable or DeckStore.can_add(cards, c) or n > 0) else Color(1, 1, 1, 0.45)
	# The deck list: one row per card, by cost then name.
	for c: Node in _list.get_children():
		c.free()
	var unique: Array[CardData] = []
	for c: CardData in cards:
		if not c in unique:
			unique.append(c)
	unique.sort_custom(func(a: CardData, b: CardData) -> bool: return a.cost < b.cost if a.cost != b.cost else a.display_name < b.display_name)
	for c: CardData in unique:
		var row := Button.new()
		row.name = "Row_%s" % c.id
		row.text = "%d   %s   ×%d" % [c.cost, c.display_name, cards.count(c)]
		row.alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.add_theme_font_size_override("font_size", 15)
		UiStyle.title(row)
		var sb := StyleBoxFlat.new()
		sb.bg_color = Palette.LAND_CARD[c.land].lerp(Color.WHITE, 0.45)
		sb.border_color = UiStyle.WOOD_INK
		sb.set_border_width_all(2)
		sb.set_corner_radius_all(8)
		sb.content_margin_left = 8
		sb.content_margin_top = 3
		sb.content_margin_bottom = 3
		for st: String in ["normal", "hover", "pressed", "focus"]:
			var s2: StyleBoxFlat = sb.duplicate()
			if st == "hover":
				s2.bg_color = s2.bg_color.darkened(0.08)
			row.add_theme_stylebox_override(st, s2)
		for col: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
			row.add_theme_color_override(col, UiStyle.WOOD_INK)
		row.pressed.connect(remove_card.bind(c.id))
		row.mouse_entered.connect(func() -> void: _show_preview(c))
		row.mouse_exited.connect(func() -> void: _preview.visible = false)
		_list.add_child(row)


## A big copy of the hovered card in the left column (a fresh widget: setup() builds on top).
func _show_preview(c: CardData) -> void:
	var holder: Node = _preview.get_parent()
	_preview.queue_free()
	_preview = CardWidget.new()
	_preview.setup(c, 0)
	_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_preview.scale = Vector2.ONE * 1.2
	holder.add_child(_preview)


func _unhandled_key_input(event: InputEvent) -> void:
	var k := event as InputEventKey
	if k and k.pressed and k.keycode == KEY_ESCAPE:
		close()
		get_viewport().set_input_as_handled()
