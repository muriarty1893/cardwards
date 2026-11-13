class_name Hand
extends Control
## Fanned hand of cards along the bottom. Hover raises a card; press-drag-release plays it.

signal card_drag_started(index: int)
signal card_dropped(index: int, screen_pos: Vector2)

const STEP_X := 95.0
const STEP_DEG := 4.8
const RAISE := 50.0
const BOTTOM_HIDE := 40.0

var _cards: Array[CardWidget] = []
var _hover: int = -1
var _drag: int = -1
var _drag_offset: Vector2
var enabled: bool = true


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func show_hand(cards: Array[CardData], playable: Array[bool]) -> void:
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
	var x: float = size.x / 2.0 + (i - (n - 1) / 2.0) * STEP_X - CardWidget.SIZE.x / 2.0
	var y: float = size.y - CardWidget.SIZE.y + BOTTOM_HIDE
	return Vector2(x, y)


func _layout(animated: bool = true) -> void:
	var n: int = _cards.size()
	for i: int in n:
		if i == _drag:
			continue
		var w: CardWidget = _cards[i]
		var pos: Vector2 = _home(i) - (Vector2(0, RAISE) if i == _hover else Vector2.ZERO)
		var rot: float = 0.0 if i == _hover else deg_to_rad((i - (n - 1) / 2.0) * STEP_DEG)
		w.z_index = 10 if i == _hover else i
		w.show_tip(i == _hover and _drag < 0)
		if animated:
			var tw := w.create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw.tween_property(w, "position", pos, 0.15)
			tw.tween_property(w, "rotation", rot, 0.15)
		else:
			w.position = pos
			w.rotation = rot


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
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
		w.rotation = 0.0
		w.z_index = 20
		w.show_tip(false)
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
		card_dropped.emit(i, mb.position)
		_layout()


## Return a dragged card to its place (drop rejected).
func cancel_drag() -> void:
	_drag = -1
	for w: CardWidget in _cards:
		w.scale = Vector2.ONE
	_layout()
