class_name CreatureView
extends Node3D
## A creature on the board: its VisualDB model in the cartoon style, sized by level,
## playing idle with the odd fidget, plus hit flash, dissolve and the freeze shell.

const BASE_Y := 0.58
## Standing height in world units by creature level (index 0 unused).
const HEIGHTS: Array[float] = [1.0, 1.0, 1.3, 1.7]
## Wide flyers are scaled down so they stay inside their lane.
const MAX_WIDTH := 1.9
const ATTACK_ANIMS: Array[StringName] = [&"Punch", &"Bite_Front", &"Headbutt"]
const HIT_ANIMS: Array[StringName] = [&"HitReact", &"HitRecieve"]
const IDLE_ANIMS: Array[StringName] = [&"Idle", &"Flying_Idle"]
const FIDGET_ANIMS: Array[StringName] = [&"Wave", &"Yes", &"Dance"]

var card: CardData
var busy: bool = false
var body: Node3D
var height: float = 1.0
var _ice: MeshInstance3D
var _anim: AnimationPlayer
var _idle: StringName = &""
var _fidget_in: float = 0.0


static func create(c: CardData, model_override: String = "") -> CreatureView:
	var v := CreatureView.new()
	v.card = c
	v.height = HEIGHTS[clampi(c.level, 0, 3)]
	var path: String = model_override if model_override != "" else VisualDB.model_path(c.id)
	if path != "" and ResourceLoader.exists(path):
		v._build_model(load(path) as PackedScene, VisualDB.tint(c.id))
	else:
		v._build_fallback(c)
	v._add_ice()
	v._fidget_in = randf_range(6.0, 12.0)
	return v


func _build_model(scene: PackedScene, tint: Color) -> void:
	body = scene.instantiate() as Node3D
	add_child(body)
	Toon.apply(body, tint)
	var box: AABB = Palette.bounds(body)
	var k: float = height / maxf(box.size.y, 0.01)
	k = minf(k, MAX_WIDTH / maxf(maxf(box.size.x, box.size.z), 0.01))
	body.scale = Vector3.ONE * k
	# Feet on the lane surface; the view's origin is BASE_Y above the board's zero.
	body.position = Vector3(0, Island.TOP_Y - BASE_Y - box.position.y * k, 0)
	_anim = body.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if _anim:
		for n: StringName in IDLE_ANIMS:
			if _anim.has_animation(n):
				_idle = n
				_anim.get_animation(n).loop_mode = Animation.LOOP_LINEAR
				break
		_anim.animation_finished.connect(func(_n: StringName) -> void: _play_idle())
		_play_idle()
		_anim.seek(randf() * 1.5, true)


## Land-coloured toon capsule, used only if a model file is missing.
func _build_fallback(c: CardData) -> void:
	body = Node3D.new()
	add_child(body)
	var cap := CapsuleMesh.new()
	cap.height = height
	cap.radius = height * 0.3
	body.add_child(Palette.mesh(cap, Toon.plain(Palette.LAND_CARD[c.land]), Vector3(0, height / 2.0, 0)))
	body.position = Vector3(0, Island.TOP_Y - BASE_Y, 0)


func _play_idle() -> void:
	if _anim and _idle != &"":
		_anim.play(_idle, 0.15)


func _play_first(names: Array[StringName]) -> float:
	if _anim == null:
		return 0.0
	for n: StringName in names:
		if _anim.has_animation(n):
			_anim.play(n, 0.08)
			return _anim.get_animation(n).length
	return 0.0


func play_attack() -> void:
	_play_first(ATTACK_ANIMS)


func play_hit() -> void:
	_play_first(HIT_ANIMS)


## Returns the death animation's length (0 if the model has none).
func play_death() -> float:
	return _play_first([&"Death"])


## Plays one of the model's fidget clips. False when busy or the model has none.
func fidget() -> bool:
	if busy or _anim == null:
		return false
	var options: Array[StringName] = []
	for n: StringName in FIDGET_ANIMS:
		if _anim.has_animation(n):
			options.append(n)
	if options.is_empty():
		return false
	_anim.play(options[randi() % options.size()], 0.2)
	return true


## Brief white flash (hit feedback).
func flash(duration: float = 0.12) -> void:
	var tw := create_tween()
	tw.tween_method(func(x: float) -> void: Toon.set_flash(body, x), 1.0, 0.0, duration)


## Dissolves the model away (death). Awaitable.
func dissolve(duration: float = 0.35) -> void:
	var tw := create_tween()
	tw.tween_method(func(x: float) -> void: Toon.set_dissolve(body, x), 0.0, 1.0, duration)
	await tw.finished


func _add_ice() -> void:
	_ice = Palette.mesh(BoxMesh.new(), _ice_mat(), Vector3(0, Island.TOP_Y - BASE_Y + height * 0.5, 0), false)
	_ice.scale = Vector3.ONE * height * 1.1
	_ice.visible = false
	add_child(_ice)


func _ice_mat() -> StandardMaterial3D:
	var m := Palette.mat(Color("#bfe8ff"), 0.05)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color.a = 0.45
	return m


func set_frozen(on: bool) -> void:
	_ice.visible = on


func _process(delta: float) -> void:
	_fidget_in -= delta
	if _fidget_in <= 0.0:
		_fidget_in = randf_range(6.0, 12.0)
		fidget()
