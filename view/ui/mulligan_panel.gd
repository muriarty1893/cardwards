class_name MulliganPanel
extends Control
## The starting-hand redraw (mulligan): your starting cards in a row; click a card to mark it for a
## redraw (a red cross), then KEEP / REDRAW. Returns a bitmask of the marked hand indices.

signal done(mask: int)

const CARD_SCALE := 1.15
const GAP := 18.0
const MARK := Color("#ff5a5a")

var _cards: Array[CardData] = []
var _widgets: Array[CardWidget] = []
var _marks: Array[Control] = []
var _mask: int = 0
var _button: Button
var _open: bool = false


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


func is_open() -> bool:
	return _open


func marked() -> int:
	return _mask


## Shows the cards and waits for the button; returns the redraw mask (0 = keep all).
func open(cards: Array[CardData]) -> int:
	_build(cards)
	_open = true
	visible = true
	Audio.sfx(&"card_deal")
	var mask: int = await done
	_open = false
	visible = false
	for n: Node in get_children():
		n.queue_free()
	return mask


## Toggles card i's redraw mark (the Star Shard can't be redrawn).
func toggle(i: int) -> void:
	if i < 0 or i >= _cards.size() or _cards[i].id == &"star_shard":
		return
	_mask ^= 1 << i
	_marks[i].visible = bool(_mask & (1 << i))
	_widgets[i].modulate = Color(0.7, 0.7, 0.7) if _marks[i].visible else Color.WHITE
	Audio.sfx(&"card_deal", 0.05)
	_update_button()


## Confirms (also used by the turn clock and tools).
func confirm() -> void:
	if _open:
		done.emit(_mask)


func _update_button() -> void:
	var n: int = 0
	for i: int in _cards.size():
		if _mask & (1 << i):
			n += 1
	_button.text = "KEEP ALL" if n == 0 else "REDRAW %d" % n


func _build(cards: Array[CardData]) -> void:
	_cards = cards.duplicate()
	_widgets.clear()
	_marks.clear()
	_mask = 0
	var back := ColorRect.new()
	back.color = Color(0.05, 0.03, 0.12, 0.66)
	back.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(back)
	back.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var vp: Vector2 = get_viewport_rect().size
	var title := UiStyle.title(UiStyle.label("STARTING HAND", 50, Palette.GOLD)) as Label
	title.add_theme_color_override("font_outline_color", Palette.INK)
	title.add_theme_constant_override("outline_size", 12)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, 70)
	title.size = Vector2(vp.x, 60)
	add_child(title)
	var sub := UiStyle.title(UiStyle.label("Click the cards you want to redraw (once)", 22, Color.WHITE)) as Label
	sub.add_theme_color_override("font_outline_color", Palette.INK)
	sub.add_theme_constant_override("outline_size", 7)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.position = Vector2(0, 134)
	sub.size = Vector2(vp.x, 30)
	add_child(sub)
	var w: float = CardWidget.SIZE.x * CARD_SCALE
	var total: float = cards.size() * w + (cards.size() - 1) * GAP
	var top: float = vp.y * 0.5 - CardWidget.SIZE.y * CARD_SCALE * 0.5
	for i: int in cards.size():
		var cw := CardWidget.new()
		cw.setup(cards[i], i)
		cw.scale = Vector2.ONE * CARD_SCALE
		cw.position = Vector2(vp.x * 0.5 - total * 0.5 + i * (w + GAP), top)
		cw.gui_input.connect(func(ev: InputEvent) -> void:
			var mb := ev as InputEventMouseButton
			if mb and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
				toggle(i))
		add_child(cw)
		_widgets.append(cw)
		var mark := _cross()
		mark.position = Vector2(CardWidget.SIZE.x * 0.5 - 40.0, CardWidget.SIZE.y * 0.42 - 40.0)
		mark.visible = false
		cw.add_child(mark)
		_marks.append(mark)
	_button = Button.new()
	_button.custom_minimum_size = Vector2(240, 60)
	_button.add_theme_font_size_override("font_size", 26)
	UiStyle.title(_button)
	_button.position = Vector2(vp.x * 0.5 - 120.0, top + CardWidget.SIZE.y * CARD_SCALE + 34.0)
	_button.size = Vector2(240, 60)
	for st: String in ["normal", "hover", "pressed", "focus"]:
		var sb := UiStyle.panel(Palette.GOLD if st != "hover" else Palette.GOLD.lightened(0.2), 14)
		sb.set_border_width_all(4 if st != "pressed" else 6)
		if st == "focus":
			sb.draw_center = false
		_button.add_theme_stylebox_override(st, sb)
	for col: String in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		_button.add_theme_color_override(col, Palette.INK)
	_button.pressed.connect(confirm)
	UiStyle.sound_button(_button)
	add_child(_button)
	_update_button()


## A thick red X drawn over a marked card.
func _cross() -> Control:
	var c := Control.new()
	c.size = Vector2(80, 80)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	c.draw.connect(func() -> void:
		for seg: Array in [[Vector2(8, 8), Vector2(72, 72)], [Vector2(72, 8), Vector2(8, 72)]]:
			c.draw_line(seg[0], seg[1], Palette.INK, 18.0, true)
			c.draw_line(seg[0], seg[1], MARK, 11.0, true))
	return c
