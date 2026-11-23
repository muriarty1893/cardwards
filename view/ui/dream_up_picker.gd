class_name DreamUpPicker
extends Control
## Dream Up (keywords spec 5): three cards rise to the middle of the screen and the player keeps
## one; it flies to the hand and the others fade away. PEEK (hold) hides the picker to look at the
## board. The rival's Dream Up shows three face-down cards; one flies to their hand.

signal picked(index: int)

const CARD_SCALE := 1.35
const GAP := 36.0
const RIVAL_SCALE := 0.55

var m: MatchController
var _cards: Array[CardWidget] = []
var _content: Control
var _back: ColorRect
var _peek: Button
var _open: bool = false
var _result: int = -1
var _rival: Array[Control] = []


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	# Above the hand's cards (they use z_index for their fan order).
	z_index = 50


func is_open() -> bool:
	return _open


## The offered cards (tests click them).
func card_widget(i: int) -> CardWidget:
	return _cards[i]


## Shows the cards and waits for a click; returns the chosen index (-1 if closed by force(-1)).
func open(cards: Array[CardData]) -> int:
	_build(cards)
	_open = true
	_result = -2
	visible = true
	Audio.sfx(&"magic_gain")
	while _result == -2:
		await picked
	var i: int = _result
	await _close(i)
	return i


## Picks for the player (turn clock ran out: 0) or closes without a pick (-1).
func force(i: int) -> void:
	if _open and _result == -2:
		_result = i
		picked.emit(i)


func choose(i: int) -> void:
	force(i)


func _build(cards: Array[CardData]) -> void:
	_free_own()
	_cards.clear()
	_back = ColorRect.new()
	_back.color = Color(0.05, 0.03, 0.12, 0.62)
	_back.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_back)
	_back.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_content = Control.new()
	_content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_content)
	_content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var title := UiStyle.title(UiStyle.label("DREAM UP", 54, Palette.GOLD)) as Label
	title.add_theme_color_override("font_outline_color", Palette.INK)
	title.add_theme_constant_override("outline_size", 12)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.name = "Title"
	_content.add_child(title)
	var sub := UiStyle.title(UiStyle.label("Choose a card to keep", 22, Color.WHITE)) as Label
	sub.add_theme_color_override("font_outline_color", Palette.INK)
	sub.add_theme_constant_override("outline_size", 7)
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sub.name = "Sub"
	_content.add_child(sub)
	var vp: Vector2 = get_viewport_rect().size
	var w: float = CardWidget.SIZE.x * CARD_SCALE
	var total: float = cards.size() * w + (cards.size() - 1) * GAP
	var top: float = vp.y * 0.5 - CardWidget.SIZE.y * CARD_SCALE * 0.5 + 20.0
	title.position = Vector2(0, top - 118.0)
	title.size = Vector2(vp.x, 64)
	sub.position = Vector2(0, top - 54.0)
	sub.size = Vector2(vp.x, 30)
	for i: int in cards.size():
		var cw := CardWidget.new()
		cw.setup(cards[i], i)
		cw.pivot_offset = CardWidget.SIZE / 2.0
		cw.scale = Vector2.ONE * CARD_SCALE
		var x: float = (vp.x - total) / 2.0 + i * (w + GAP) + (w - CardWidget.SIZE.x) / 2.0
		var rest := Vector2(x, top + (CardWidget.SIZE.y * CARD_SCALE - CardWidget.SIZE.y) / 2.0)
		cw.position = rest + Vector2(0, vp.y * 0.6)
		cw.modulate.a = 0.0
		cw.set_meta(&"rest", rest)
		cw.mouse_entered.connect(func() -> void: _hover(cw, true))
		cw.mouse_exited.connect(func() -> void: _hover(cw, false))
		cw.gui_input.connect(func(ev: InputEvent) -> void:
			var mb := ev as InputEventMouseButton
			if mb and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT and _open:
				Audio.sfx(&"ui_click")
				choose(i))
		_content.add_child(cw)
		_cards.append(cw)
		var tw := cw.create_tween().set_parallel(true)
		tw.tween_interval(0.08 * i)
		tw.chain().tween_property(cw, "position", rest, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(cw, "modulate:a", 1.0, 0.2)
	# Hold PEEK to look at the board under the picker.
	_peek = MenuButtons.big("PEEK", Color.WHITE, 18)
	_peek.name = "Peek"
	_peek.tooltip_text = "Hold to look at the board"
	_peek.button_down.connect(func() -> void: set_peeking(true))
	_peek.button_up.connect(func() -> void: set_peeking(false))
	add_child(_peek)
	_peek.reset_size()
	_peek.position = Vector2((vp.x - _peek.size.x) / 2.0, top + CardWidget.SIZE.y * CARD_SCALE + 28.0)


## PEEK held: everything but the button goes see-through and stops catching clicks.
func set_peeking(on: bool) -> void:
	if _content == null or _back == null:
		return
	_content.modulate.a = 0.08 if on else 1.0
	_back.color.a = 0.0 if on else 0.62
	_back.mouse_filter = Control.MOUSE_FILTER_IGNORE if on else Control.MOUSE_FILTER_STOP


func is_peeking() -> bool:
	return _content != null and _content.modulate.a < 0.5


func _hover(cw: CardWidget, on: bool) -> void:
	if not _open:
		return
	if on:
		Audio.sfx(&"card_flip", 0.1)
	var rest: Vector2 = cw.get_meta(&"rest")
	var tw := cw.create_tween().set_parallel(true)
	tw.tween_property(cw, "scale", Vector2.ONE * CARD_SCALE * (1.08 if on else 1.0), 0.12)
	tw.tween_property(cw, "position", rest - Vector2(0, 14 if on else 0), 0.12)


func _close(i: int) -> void:
	_open = false
	set_peeking(false)
	if is_instance_valid(_peek):
		_peek.queue_free()
	var to := Vector2(get_viewport_rect().size.x / 2.0, get_viewport_rect().size.y + 60.0)
	var tw := create_tween().set_parallel(true)
	for k: int in _cards.size():
		var cw: CardWidget = _cards[k]
		if k == i:
			tw.tween_property(cw, "position", to - CardWidget.SIZE / 2.0, 0.35).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
			tw.tween_property(cw, "scale", Vector2.ONE * 0.6, 0.35)
		else:
			tw.tween_property(cw, "modulate:a", 0.0, 0.2)
			tw.tween_property(cw, "scale", Vector2.ONE * CARD_SCALE * 0.8, 0.2)
	tw.tween_property(_back, "color:a", 0.0, 0.3)
	for n: Node in _content.get_children():
		if n is Label:
			tw.tween_property(n, "modulate:a", 0.0, 0.2)
	if i >= 0:
		Audio.sfx(&"card_draw")
	await tw.finished
	_free_own()
	_cards.clear()
	visible = _rival.size() > 0


## Frees the picker's own pieces (not the rival's face-down cards).
func _free_own() -> void:
	for n: Node in [_back, _content, _peek]:
		if is_instance_valid(n):
			n.queue_free()
	_back = null
	_content = null
	_peek = null


# --- The rival's Dream Up ----------------------------------------------------------------------

## Three face-down cards float up in front of the rival while they choose.
func show_rival_offer(count: int, back: Texture2D, near: Vector2) -> void:
	clear_rival()
	visible = true
	var w: float = CardWidget.SIZE.x * RIVAL_SCALE
	for i: int in count:
		var c := Control.new()
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		c.size = CardWidget.SIZE
		c.pivot_offset = CardWidget.SIZE / 2.0
		c.scale = Vector2.ONE * RIVAL_SCALE
		var tr := TextureRect.new()
		tr.texture = back
		tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		tr.stretch_mode = TextureRect.STRETCH_SCALE
		tr.size = CardWidget.SIZE
		tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
		c.add_child(tr)
		var rest := near + Vector2((i - (count - 1) / 2.0) * (w + 12.0), 70.0) - CardWidget.SIZE / 2.0
		c.position = near - CardWidget.SIZE / 2.0
		c.modulate.a = 0.0
		add_child(c)
		_rival.append(c)
		var tw := c.create_tween().set_parallel(true)
		tw.tween_property(c, "position", rest, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(c, "modulate:a", 1.0, 0.2)
		tw.tween_property(c, "rotation", (i - (count - 1) / 2.0) * 0.12, 0.3)
	await get_tree().create_timer(0.45).timeout


## The rival keeps one (which one stays secret): it flies to their hand, the rest fade.
func rival_pick(to: Vector2) -> void:
	if _rival.is_empty():
		return
	var keep: int = _rival.size() / 2
	var tw := create_tween().set_parallel(true)
	for k: int in _rival.size():
		var c: Control = _rival[k]
		if k == keep:
			tw.tween_property(c, "position", to - CardWidget.SIZE / 2.0, 0.35).set_trans(Tween.TRANS_SINE)
			tw.tween_property(c, "scale", Vector2.ONE * 0.3, 0.35)
		else:
			tw.tween_property(c, "modulate:a", 0.0, 0.25)
	Audio.sfx(&"card_deal")
	await tw.finished
	clear_rival()


func clear_rival() -> void:
	for c: Control in _rival:
		if is_instance_valid(c):
			c.queue_free()
	_rival.clear()
	visible = _open


func rival_showing() -> bool:
	return not _rival.is_empty()
