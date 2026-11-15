class_name Hand
extends Control
## Row of cards along the bottom. Hover lifts and enlarges a card so it can be read;
## press-drag-release plays it.

signal card_drag_started(index: int)
signal card_dropped(index: int, screen_pos: Vector2)

## The hand is a straight row inside the HUD tray, between its left and right columns.
const MAX_STEP := 148.0
## A hovered card grows to this scale (replaces the old tooltip).
const HOVER_SCALE := 1.6
const RAISE := 34.0
const REGION_LEFT := 240.0
const REGION_RIGHT := 290.0
const BOTTOM_PAD := 8.0

var _cards: Array[CardWidget] = []
var _shown: Array[CardData] = []
var _hover: int = -1
var _drag: int = -1
var _drag_offset: Vector2
var enabled: bool = true
## Where the last dragged card was released (playback flies the card from here).
var last_drop_pos: Vector2 = Vector2.ZERO


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func show_hand(cards: Array[CardData], playable: Array[bool]) -> void:
	# Same cards as shown: only update which are playable (rebuilding costs a hitch).
	if cards == _shown and _cards.size() == cards.size():
		for i: int in _cards.size():
			_cards[i].set_playable(playable[i] if i < playable.size() else true)
		return
	_shown = cards.duplicate()
	for w: CardWidget in _cards:
		w.queue_free()
	_cards.clear()
	_hover = -1
	_drag = -1
	for i: int in cards.size():
		var w := CardWidget.new()
		w.setup(cards[i], i)
		w.set_playable(playable[i] if i < playable.size() else true)
		w.mouse_entered.connect(_on_enter.bind(i))
		w.mouse_exited.connect(_on_exit.bind(i))
		w.gui_input.connect(_on_card_input.bind(i))
		add_child(w)
		_cards.append(w)
	_layout(false)


func _home(i: int) -> Vector2:
	var n: int = _cards.size()
	var left: float = REGION_LEFT
	var right: float = size.x - REGION_RIGHT
	var step: float = MAX_STEP
	if n > 1:
		step = minf(MAX_STEP, (right - left - CardWidget.SIZE.x) / float(n - 1))
	var total: float = step * (n - 1) + CardWidget.SIZE.x
	var x: float = (left + right) / 2.0 - total / 2.0 + i * step
	return Vector2(x, size.y - CardWidget.SIZE.y - BOTTOM_PAD)


func _layout(animated: bool = true) -> void:
	var n: int = _cards.size()
	for i: int in n:
		if i == _drag:
			continue
		var w: CardWidget = _cards[i]
		var hovered: bool = i == _hover and _drag < 0
		var pos: Vector2 = _hover_rect(i).position if hovered else _home(i)
		var sc: Vector2 = Vector2.ONE * (HOVER_SCALE if hovered else 1.0)
		w.z_index = 10 if hovered else i
		if animated:
			var tw := w.create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw.tween_property(w, "position", pos, 0.15)
			tw.tween_property(w, "scale", sc, 0.15)
		else:
			w.position = pos
			w.scale = sc


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout(false)


## Enlarged card i: grown from its bottom centre, lifted, kept inside the hand region.
func _hover_rect(i: int) -> Rect2:
	var home := Rect2(_home(i), CardWidget.SIZE)
	var big: Vector2 = CardWidget.SIZE * HOVER_SCALE
	var x: float = home.get_center().x - big.x / 2.0
	x = clampf(x, REGION_LEFT, maxf(REGION_LEFT, size.x - REGION_RIGHT - big.x))
	var bottom: float = home.end.y - RAISE
	return Rect2(Vector2(x, maxf(0.0, bottom - big.y)), big)


## Screen rect of the hovered card (empty if none).
func hovered_rect() -> Rect2:
	if _hover < 0:
		return Rect2()
	var r: Rect2 = _hover_rect(_hover)
	return Rect2(global_position + r.position, r.size)


## Same as the mouse entering card i (tests use it).
func hover(i: int) -> void:
	_hover = i
	_layout(false)


func cards_rect() -> Rect2:
	var r := Rect2()
	for i: int in _cards.size():
		var g := Rect2(global_position + _home(i), CardWidget.SIZE)
		r = g if i == 0 else r.merge(g)
	return r


func _on_enter(i: int) -> void:
	if _drag >= 0 or not enabled:
		return
	if _hover != i:
		Audio.sfx(&"card_flip", 0.1)
	_hover = i
	_layout()


func _on_exit(i: int) -> void:
	if _hover == i and _drag < 0:
		_hover = -1
		_layout()


func _on_card_input(event: InputEvent, i: int) -> void:
	if not enabled:
		return
	var mb := event as InputEventMouseButton
	if mb and mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed and _drag < 0:
		_drag = i
		_hover = -1
		var w: CardWidget = _cards[i]
		w.scale = Vector2.ONE
		w.z_index = 20
		_drag_offset = CardWidget.SIZE / 2.0
		card_drag_started.emit(i)
		accept_event()


func _input(event: InputEvent) -> void:
	if _drag < 0:
		return
	var mm := event as InputEventMouseMotion
	if mm:
		_cards[_drag].global_position = mm.position - _drag_offset
		_cards[_drag].scale = Vector2.ONE * 0.8
	var mb := event as InputEventMouseButton
	if mb and mb.button_index == MOUSE_BUTTON_LEFT and not mb.pressed:
		var i: int = _drag
		_drag = -1
		_cards[i].scale = Vector2.ONE
		last_drop_pos = mb.position
		card_dropped.emit(i, mb.position)
		_layout()


## Return a dragged card to its place (drop rejected).
func cancel_drag() -> void:
	_drag = -1
	for w: CardWidget in _cards:
		w.scale = Vector2.ONE
	_layout()
