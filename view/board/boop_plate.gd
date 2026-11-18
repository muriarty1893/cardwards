class_name BoopPlate
extends Node3D
## A pill-shaped button set into one of your lanes (board look 2, spec 1.4): sunk below the surface until the board
## splits, then risen. DIM when the lane's creature can't boop now, LIT (warm, pulsing) when it can; presses down when
## clicked.

enum State { HIDDEN, DIM, LIT }

## Footprint on the board (x across the lane, z along it).
const SIZE := Vector2(1.1, 0.42)
const RIM := Color("#c8933a")
const LIT := Color("#ffcf3a")
const DIM := Color("#8a86a8")
## Rest height of the plate's top above the tile surface, and how far below it hides.
const REST_Y := 0.03
const HIDE_Y := -0.16
const PRESS := 0.03

var state: State = State.HIDDEN
var hovered: bool = false:
	set(v):
		hovered = v
		_paint()
var _top: Node3D
## Own copy of the toon material (no per-instance fx on the board): its colour pulses while lit.
var _top_mat: ShaderMaterial
var _label: Label3D
var _press_tween: Tween
var _rise_tween: Tween
var _t: float = 0.0


func _init() -> void:
	name = "BoopPlate"
	var rim := _pill(SIZE + Vector2(0.08, 0.08), 0.05, Toon.plain(RIM))
	rim.position.y = 0.0
	add_child(rim)
	_top_mat = Toon.plain(DIM).duplicate() as ShaderMaterial
	_top = _pill(SIZE, 0.05, _top_mat)
	_top.position.y = 0.02
	add_child(_top)
	_label = Label3D.new()
	_label.text = "BOOP"
	_label.font = load(UiStyle.TITLE_FONT)
	_label.font_size = 64
	_label.pixel_size = 0.0044
	_label.outline_size = 14
	_label.modulate = Color("#3a2a1a")
	_label.outline_modulate = Color(1, 1, 1, 0.55)
	_label.rotation = Vector3(-PI / 2.0, 0.0, 0.0)
	_label.position.y = 0.051
	_label.shaded = false
	_label.double_sided = false
	_top.add_child(_label)
	position.y = Island.TOP_Y + HIDE_Y
	visible = false
	set_process(false)


## A flat pill (box with round ends) of `size` (x long, z deep) and height `h`, its base at y = 0.
static func _pill(size: Vector2, h: float, mat: Material) -> Node3D:
	var root := Node3D.new()
	var r: float = size.y / 2.0
	var box := BoxMesh.new()
	box.size = Vector3(size.x - size.y, h, size.y)
	root.add_child(Palette.mesh(box, mat, Vector3(0, h / 2.0, 0), false))
	for sx: float in [-1.0, 1.0]:
		root.add_child(Palette.mesh(Palette.cylinder(r, r, h, 20), mat, Vector3(sx * (size.x - size.y) / 2.0, h / 2.0, 0), false))
	return root


func set_state(s: State, animate: bool = true) -> void:
	if s == state:
		return
	var was: State = state
	state = s
	if was == State.HIDDEN:
		rise(animate)
	elif s == State.HIDDEN:
		visible = false
		position.y = Island.TOP_Y + HIDE_Y
	set_process(s == State.LIT)
	_paint()


## Comes up out of the board.
func rise(animate: bool) -> void:
	visible = true
	if state == State.HIDDEN:
		state = State.DIM
	if _rise_tween and _rise_tween.is_valid():
		_rise_tween.kill()
	var rest: float = Island.TOP_Y + REST_Y - 0.02
	if not animate or not is_inside_tree():
		position.y = rest
		_paint()
		return
	position.y = Island.TOP_Y + HIDE_Y
	_rise_tween = create_tween()
	_rise_tween.tween_property(self, "position:y", rest, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_paint()


## The press-down-and-spring-back of a click.
func press() -> void:
	if not is_inside_tree():
		return
	if _press_tween and _press_tween.is_valid():
		_press_tween.kill()
	_top.position.y = 0.02
	_press_tween = create_tween()
	_press_tween.tween_property(_top, "position:y", 0.02 - PRESS, 0.06).set_ease(Tween.EASE_OUT)
	_press_tween.tween_property(_top, "position:y", 0.02, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## True if world point `p` (on the board) is on the plate.
func contains(p: Vector3) -> bool:
	var l: Vector3 = global_transform.affine_inverse() * p if is_inside_tree() else p - position
	var half_box: float = (SIZE.x - SIZE.y) / 2.0
	var r: float = SIZE.y / 2.0
	var dx: float = maxf(absf(l.x) - half_box, 0.0)
	return Vector2(dx, l.z).length() <= r


func _paint() -> void:
	if _top == null:
		return
	var lit: bool = state == State.LIT
	_label.modulate = Color("#3a2a1a") if lit else Color("#4a4660")
	_set_top(_glow(0.0))


## The top's colour: DIM, or LIT brightened by `pulse` (0..1) and more when hovered.
func _glow(pulse: float) -> Color:
	if state != State.LIT:
		return DIM
	return LIT.lightened(0.28 if hovered else 0.06 + 0.12 * pulse)


func _set_top(c: Color) -> void:
	_top_mat.set_shader_parameter("albedo_color", c)


func _process(delta: float) -> void:
	_t += delta
	_set_top(_glow(0.5 + 0.5 * sin(_t * TAU * 0.8)))
