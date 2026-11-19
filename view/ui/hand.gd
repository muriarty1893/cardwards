class_name Hand
extends Control
## The slim hand along the bottom edge (tabletop spec 7.2): cards in a slight fan, shown a bit
## smaller and only their top part peeking up (cost, picture and name), so the board stays clear.
## Hover: the card rises to full size above the edge and its neighbours slide apart. Press-drag-
## release plays it; over the board the dragged card shrinks to a small token so the lanes show.

signal card_drag_started(index: int)
signal card_dropped(index: int, screen_pos: Vector2)

## Kept clear on both sides (the gems / END TURN column on the right), so the hand sits centred
## under the board.
const REGION_LEFT := 244.0
const REGION_RIGHT := 244.0
const MAX_STEP := 128.0
## Resting cards are drawn at this scale with this many pixels showing above the screen edge.
const REST_SCALE := 0.85
const PEEK := 118.0
## A hovered card: this scale, bottom this far above the screen edge.
const HOVER_SCALE := 1.5
const HOVER_BOTTOM := 8.0
## Neighbours of the hovered card slide this far aside.
const SPREAD := 40.0
## Fan: degrees per card from the middle, and how much lower the outer cards sit (px per step²).
const FAN_DEG := 2.5
const ARC := 2.5
## Dragged card over the board.
const TOKEN_SCALE := 0.45

var _cards: Array[CardWidget] = []
## Set by MatchController: over the board the dragged card is shown as this 3D card (seen by `camera`).
var drag_card: DragCard3D
var camera: Camera3D
var _shown: Array[CardData] = []
var _hover: int = -1
var _drag: int = -1
var enabled: bool = true
## Where the last dragged card was released (playback flies the card from here).
var last_drop_pos: Vector2 = Vector2.ZERO


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## `costs`: each card's current cost (a spell discount lowers it); printed costs when empty.
func show_hand(cards: Array[CardData], playable: Array[bool], costs: Array[int] = []) -> void:
	# Same cards as shown: only update which are playable and their costs (rebuilding costs a hitch).
	if cards == _shown and _cards.size() == cards.size():
		for i: int in _cards.size():
			_cards[i].set_playable(playable[i] if i < playable.size() else true)
			_cards[i].set_cost(costs[i] if i < costs.size() else cards[i].cost)
		return
	_shown = cards.duplicate()
	for w: CardWidget in _cards:
		w.queue_free()
	_cards.clear()
	_hover = -1
	_drag = -1
	_hide_3d()
	for i: int in cards.size():
		var w := CardWidget.new()
		w.setup(cards[i], i)
		w.set_playable(playable[i] if i < playable.size() else true)
		if i < costs.size() and costs[i] != cards[i].cost:
			w.set_cost(costs[i])
		# Scale and tilt around the bottom centre, like a card held from below.
		w.pivot_offset = Vector2(CardWidget.SIZE.x / 2.0, CardWidget.SIZE.y)
		w.mouse_entered.connect(_on_enter.bind(i))
		w.mouse_exited.connect(_on_exit.bind(i))
		w.gui_input.connect(_on_card_input.bind(i))
		add_child(w)
		_cards.append(w)
	_layout(false)


## Centre x of card i at rest (no hover spread).
func _centre_x(i: int) -> float:
	var n: int = _cards.size()
	var left: float = REGION_LEFT
	var right: float = size.x - REGION_RIGHT
	var w: float = CardWidget.SIZE.x * REST_SCALE
	var step: float = MAX_STEP
	if n > 1:
		step = minf(MAX_STEP, (right - left - w) / float(n - 1))
	var total: float = step * (n - 1) + w
	return (left + right) / 2.0 - total / 2.0 + w / 2.0 + i * step


func _offset_from_middle(i: int) -> float:
	return float(i) - float(_cards.size() - 1) / 2.0


## Resting card i on screen (local to the hand; rotation not included).
func _rest_rect(i: int) -> Rect2:
	var cx: float = _centre_x(i)
	if _hover >= 0 and i != _hover and _drag < 0:
		cx += SPREAD * signf(float(i - _hover))
	var k: float = _offset_from_middle(i)
	var top: float = size.y - PEEK + ARC * k * k
	var sz: Vector2 = CardWidget.SIZE * REST_SCALE
	return Rect2(Vector2(cx - sz.x / 2.0, top), sz)


## Enlarged card i: full size above the bottom edge, kept inside the hand region.
func _hover_rect(i: int) -> Rect2:
	var big: Vector2 = CardWidget.SIZE * HOVER_SCALE
	var x: float = _centre_x(i) - big.x / 2.0
	x = clampf(x, 8.0, maxf(8.0, size.x - REGION_RIGHT - big.x))
	return Rect2(Vector2(x, size.y - HOVER_BOTTOM - big.y), big)


## Control position that draws the card (scaled `s` around its bottom-centre pivot) with its
## scaled rect's bottom centre at `bottom_centre`.
static func _position_for(bottom_centre: Vector2) -> Vector2:
	return bottom_centre - Vector2(CardWidget.SIZE.x / 2.0, CardWidget.SIZE.y)


func _layout(animated: bool = true) -> void:
	var n: int = _cards.size()
	for i: int in n:
		if i == _drag:
			continue
		var w: CardWidget = _cards[i]
		var hovered: bool = i == _hover and _drag < 0
		var r: Rect2 = _hover_rect(i) if hovered else _rest_rect(i)
		var pos: Vector2 = _position_for(Vector2(r.get_center().x, r.end.y))
		var sc: Vector2 = Vector2.ONE * (HOVER_SCALE if hovered else REST_SCALE)
		var rot: float = 0.0 if hovered else deg_to_rad(FAN_DEG * _offset_from_middle(i))
		w.z_index = 10 if hovered else i
		if animated:
			var tw := w.create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
			tw.tween_property(w, "position", pos, 0.15)
			tw.tween_property(w, "scale", sc, 0.15)
			tw.tween_property(w, "rotation", rot, 0.15)
		else:
			w.position = pos
			w.scale = sc
			w.rotation = rot


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout(false)


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


## The resting cards' on-screen area (the part above the bottom edge).
func cards_rect() -> Rect2:
	var r := Rect2()
	var screen := Rect2(Vector2.ZERO, size)
	for i: int in _cards.size():
		var g: Rect2 = _rest_rect(i).intersection(screen)
		g.position += global_position
		r = g if i == 0 else r.merge(g)
	return r


## Resting card i's on-screen rect (global), for tests.
func card_rect(i: int) -> Rect2:
	var g: Rect2 = _rest_rect(i)
	g.position += global_position
	return g


func _on_enter(i: int) -> void:
	if _drag >= 0 or not enabled:
		return
	if _hover != i:
		Audio.sfx(&"card_flip", 0.1)
	_hover = i
	_layout()


func _on_exit(i: int) -> void:
	if _hover == i and _drag < 0:
		# Leaving the risen card back down onto its own resting spot keeps it up.
		var at: Vector2 = get_local_mouse_position()
		if _hover_rect(i).has_point(at):
			return
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
		w.z_index = 20
		w.rotation = 0.0
		_follow(w, mb.global_position)
		card_drag_started.emit(i)
		accept_event()
		_layout()


## Keeps the dragged card centred on the mouse: the full 2D card over the hand strip; once over the board, a 3D card
## lying over the table (DragCard3D), or a small token when there is no 3D card.
func _follow(w: CardWidget, mouse: Vector2) -> void:
	var over_board: bool = mouse.y < global_position.y + size.y - Hud.HAND_STRIP_H - 20.0
	var three_d: bool = over_board and drag_card != null and camera != null
	var s: float = TOKEN_SCALE if over_board and not three_d else REST_SCALE
	w.scale = Vector2.ONE * s
	# The pivot is the bottom centre: put the scaled card's centre on the mouse.
	w.global_position = mouse - w.pivot_offset + Vector2(0, CardWidget.SIZE.y * s / 2.0)
	w.modulate.a = 0.0 if three_d else 1.0
	if three_d:
		drag_card.show_card(w.card, w.shown_cost())
		drag_card.follow(camera, mouse)
	else:
		_hide_3d()


func _hide_3d() -> void:
	if drag_card:
		drag_card.hide_card()


## The 2D widget being dragged (tests), or null.
func dragged_widget() -> CardWidget:
	return _cards[_drag] if _drag >= 0 and _drag < _cards.size() else null


## Starts dragging card i as a mouse press would (tests).
func begin_drag_for_test(i: int) -> void:
	_drag = i
	_hover = -1
	_cards[i].z_index = 20
	_layout()


## Moves the dragged card as the mouse would (tests).
func drag_to_for_test(mouse: Vector2) -> void:
	if _drag >= 0:
		_follow(_cards[_drag], mouse)


func _input(event: InputEvent) -> void:
	if _drag < 0:
		return
	var mm := event as InputEventMouseMotion
	if mm:
		_follow(_cards[_drag], mm.global_position)
	var mb := event as InputEventMouseButton
	if mb and mb.button_index == MOUSE_BUTTON_LEFT and not mb.pressed:
		var i: int = _drag
		_drag = -1
		_cards[i].modulate.a = 1.0
		_hide_3d()
		last_drop_pos = mb.position
		card_dropped.emit(i, mb.position)
		_layout()


## Return a dragged card to its place (drop rejected).
func cancel_drag() -> void:
	if _drag >= 0 and _drag < _cards.size():
		_cards[_drag].modulate.a = 1.0
	_drag = -1
	_hide_3d()
	_layout()
