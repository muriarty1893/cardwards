class_name TimingBar
extends Control
## The strike/block timing minigame (spec 4.4). A needle sweeps; tap (click or Space) to stop it.

signal _stopped(x: float)

const PANEL := Vector2(380, 92)
const PERIOD := 1.25
const TIMEOUT := 2.0
## Zone edges as fractions of the bar.
const EDGES: Array[float] = [0.30, 0.44, 0.56, 0.70]

## Tests only: when >= 0, the needle stays at this x.
var force_needle: float = -1.0
## Tests only: stop at the needle position on the first frame instead of waiting for a tap.
var auto_stop: bool = false

var _active: bool = false
var _t: float = 0.0
var _x: float = 0.0
var _block: bool = false
var _title: Label
var _bar: Control
var _hint: Label


static func zone_at(x: float) -> Action.Hit:
	if x >= EDGES[1] and x < EDGES[2]:
		return Action.Hit.CRIT
	if x >= EDGES[0] and x < EDGES[3]:
		return Action.Hit.NORMAL
	return Action.Hit.GLANCE


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_CENTER_TOP)
	custom_minimum_size = PANEL
	size = PANEL
	offset_left = -PANEL.x / 2.0
	offset_right = PANEL.x / 2.0
	offset_top = 150
	offset_bottom = 150 + PANEL.y
	var bg := Panel.new()
	bg.add_theme_stylebox_override("panel", UiStyle.panel(Color(1, 1, 1, 0.97), 18))
	bg.size = PANEL
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	_title = UiStyle.bold(UiStyle.label("STRIKE!", 18))
	_title.position = Vector2(0, 6)
	_title.size = Vector2(PANEL.x, 24)
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_title)
	_bar = Control.new()
	_bar.position = Vector2(18, 34)
	_bar.size = Vector2(PANEL.x - 36, 28)
	_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bar.draw.connect(_draw_bar)
	add_child(_bar)
	_hint = UiStyle.label("click or SPACE", 11, Color("#667777"))
	_hint.position = Vector2(0, 68)
	_hint.size = Vector2(PANEL.x, 16)
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_hint)
	visible = false


func run_attack() -> Action.Hit:
	var x: float = await _run(false)
	return Action.Hit.NORMAL if x < 0.0 else zone_at(x)


func run_block() -> bool:
	var x: float = await _run(true)
	return x >= 0.0 and zone_at(x) == Action.Hit.CRIT


## Show an AI roll: the needle glides to a spot inside the rolled zone.
func simulate_attack(hit: Action.Hit) -> void:
	var x: float = 0.5
	match hit:
		Action.Hit.NORMAL:
			x = [0.37, 0.63].pick_random()
		Action.Hit.GLANCE:
			x = [0.14, 0.86].pick_random()
	await _simulate(x, false)


func simulate_block(blocked: bool) -> void:
	await _simulate(0.5 if blocked else [0.2, 0.8].pick_random(), true)


func _simulate(x: float, block: bool) -> void:
	_setup(block, "RIVAL STRIKES" if not block else "RIVAL BLOCKS")
	_hint.text = ""
	var tw := create_tween()
	tw.tween_method(func(v: float) -> void:
		_x = v
		_bar.queue_redraw(), 0.0, x, 0.6).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_interval(0.35)
	await tw.finished
	visible = false


func _setup(block: bool, title: String) -> void:
	_block = block
	_title.text = title
	_hint.text = "click or SPACE"
	_t = 0.0
	_x = 0.0
	visible = true
	_bar.queue_redraw()


func _run(block: bool) -> float:
	_setup(block, "BLOCK! tap in the green" if block else "STRIKE! tap in the green")
	_active = true
	var x: float = await _stopped
	_active = false
	_bar.queue_redraw()
	await get_tree().create_timer(0.35).timeout
	visible = false
	return x


func _process(delta: float) -> void:
	if not _active:
		return
	_t += delta
	_x = force_needle if force_needle >= 0.0 else pingpong(_t / (PERIOD / 2.0), 1.0)
	_bar.queue_redraw()
	if auto_stop:
		_active = false
		_stopped.emit(_x)
		return
	if _t >= TIMEOUT:
		_active = false
		_title.text = "Too slow!"
		_stopped.emit(-1.0)


func _input(event: InputEvent) -> void:
	if not _active:
		return
	var key := event as InputEventKey
	var mb := event as InputEventMouseButton
	if (key and key.pressed and not key.echo and key.keycode == KEY_SPACE) or (mb and mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT):
		_active = false
		var hit: Action.Hit = zone_at(_x)
		if _block:
			_title.text = "BLOCKED!" if hit == Action.Hit.CRIT else "No block"
		else:
			_title.text = ["Hit!", "CRITICAL!", "Glancing..."][hit]
		if is_inside_tree():
			get_viewport().set_input_as_handled()
		_stopped.emit(_x)


func _draw_bar() -> void:
	var w: float = _bar.size.x
	var h: float = _bar.size.y
	var red := Palette.HP
	var yellow := Palette.GOLD
	var green := Color("#3ad16a")
	var stops: Array[float] = [0.0, EDGES[0], EDGES[1], EDGES[2], EDGES[3], 1.0]
	var cols: Array[Color] = [red, yellow, green, yellow, red]
	if _block:
		cols = [Color("#c8c8c8"), Color("#c8c8c8"), green, Color("#c8c8c8"), Color("#c8c8c8")]
	for i: int in 5:
		_bar.draw_rect(Rect2(stops[i] * w, 0, (stops[i + 1] - stops[i]) * w, h), cols[i])
	_bar.draw_rect(Rect2(0, 0, w, h), Palette.INK, false, 3.0)
	_bar.draw_rect(Rect2(_x * w - 3, -5, 6, h + 10), Palette.INK)
