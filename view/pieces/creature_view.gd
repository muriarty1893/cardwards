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
var _shell: IceShell
## Ground blob where the sun casts no shadows (web); null otherwise.
var _blob: BlobShadow
var _anim: AnimationPlayer
var _idle: StringName = &""
var _fidget_in: float = 0.0
## Set by play_death(): the model holds its death pose instead of returning to idle.
var _dying: bool = false
## Faded out while it can't be chosen as an attack target.
var dimmed: bool = false

## On your turn: READY to act (glowing ring), SLEEPING (played this turn: "z" puffs) or SPENT
## (already acted: slightly darker).
enum Readiness { NONE, READY, SLEEPING, SPENT }
var readiness: Readiness = Readiness.NONE
var _ring: Node3D
var _ring_tw: Tween
var _zzz_in: float = 0.0


static func create(c: CardData, model_override: String = "") -> CreatureView:
	var v := CreatureView.new()
	v.card = c
	v.height = HEIGHTS[clampi(c.level, 0, 3)]
	var path: String = model_override if model_override != "" else VisualDB.model_path(c.id)
	if path != "" and ResourceLoader.exists(path):
		v._build_model(load(path) as PackedScene, VisualDB.tint(c.id))
	else:
		v._build_fallback(c)
	v._fidget_in = randf_range(6.0, 12.0)
	if not BlobShadow.sun_shadows():
		v._add_blob()
	return v


func _add_blob() -> void:
	var box: AABB = Palette.bounds(body)
	var w: float = maxf(box.size.x, box.size.z) * body.scale.x
	_blob = BlobShadow.build(clampf(w * 0.36, 0.3, 0.7), height, Island.TOP_Y - BASE_Y + 0.02)
	add_child(_blob)


func _build_model(scene: PackedScene, tint: Color) -> void:
	body = scene.instantiate() as Node3D
	add_child(body)
	Toon.apply(body, tint, 0.0, true)
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
	body.add_child(Palette.mesh(cap, Toon.plain(Palette.LAND_CARD[c.land], 0.0, true), Vector3(0, height / 2.0, 0)))
	body.position = Vector3(0, Island.TOP_Y - BASE_Y, 0)


func _play_idle() -> void:
	if _anim and _idle != &"" and not _dying:
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
	_dying = true
	return _play_first([&"Death"])


## Plays one of the model's fidget clips. False when busy or the model has none.
func fidget() -> bool:
	if busy or _dying or _anim == null:
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
	if _blob:
		tw.parallel().tween_property(_blob, "transparency", 1.0, duration)
	await tw.finished


func set_readiness(r: Readiness) -> void:
	if r == readiness:
		return
	readiness = r
	if body:
		Toon.set_shade(body, 1.0 if r == Readiness.SPENT else 0.0)
	if r == Readiness.READY:
		_show_ring()
	elif is_instance_valid(_ring):
		_ring.queue_free()
		_ring = null
	_zzz_in = 0.0


func _show_ring() -> void:
	if is_instance_valid(_ring):
		return
	var w: float = clampf(height * 0.42, 0.42, 0.75)
	_ring = Node3D.new()
	_ring.name = "ReadyRing"
	_ring.position.y = Island.TOP_Y - BASE_Y + 0.04
	_ring.scale = Vector3(1, 0.15, 1)
	add_child(_ring)
	# A dark ink band under a bright green one, so it reads on every lane colour.
	var ink: StandardMaterial3D = _ring_material(Color(Palette.INK, 0.6), -91)
	var glow: StandardMaterial3D = _ring_material(Color("#5dff3a", 1.0), -90)
	_ring.add_child(_torus(w, 0.13, ink))
	_ring.add_child(_torus(w, 0.08, glow))
	_ring_tw = _ring.create_tween().set_loops()
	_ring_tw.tween_property(glow, "albedo_color:a", 0.55, 0.6).set_trans(Tween.TRANS_SINE)
	_ring_tw.tween_property(glow, "albedo_color:a", 1.0, 0.6).set_trans(Tween.TRANS_SINE)


func _ring_material(col: Color, priority: int) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = col
	mat.render_priority = priority
	return mat


func _torus(radius: float, half_width: float, mat: Material) -> MeshInstance3D:
	var torus := TorusMesh.new()
	torus.inner_radius = radius - half_width
	torus.outer_radius = radius + half_width
	torus.rings = 32
	torus.ring_segments = 6
	var mi := MeshInstance3D.new()
	mi.mesh = torus
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


## One "z" drifting up from a sleeping creature.
func _puff_z() -> void:
	var z := Label3D.new()
	z.text = "z"
	z.font = load(UiStyle.TITLE_FONT) as FontFile
	z.font_size = 96
	z.pixel_size = 0.004
	z.outline_size = 22
	z.outline_modulate = Palette.INK
	z.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	z.no_depth_test = true
	z.position = Vector3(0.25, Island.TOP_Y - BASE_Y + height + 0.2, 0)
	add_child(z)
	var tw := z.create_tween().set_parallel(true)
	tw.tween_property(z, "position", z.position + Vector3(0.25, 0.55, 0), 1.4)
	tw.tween_property(z, "modulate:a", 0.0, 1.4).set_ease(Tween.EASE_IN)
	tw.tween_property(z, "outline_modulate:a", 0.0, 1.4).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(z.queue_free)


func set_dimmed(on: bool) -> void:
	if on == dimmed:
		return
	dimmed = on
	if body == null:
		return
	for n: Node in body.find_children("*", "GeometryInstance3D", true, false):
		(n as GeometryInstance3D).transparency = 0.55 if on else 0.0


## Ice shell on while frozen; it shatters when the freeze ends.
func set_frozen(on: bool) -> void:
	if on and not is_instance_valid(_shell):
		_shell = IceShell.attach(self)
	elif not on and is_instance_valid(_shell):
		_shell.shatter()
		_shell = null


func is_frozen_visual() -> bool:
	return is_instance_valid(_shell)


func _process(delta: float) -> void:
	if readiness == Readiness.SLEEPING:
		_zzz_in -= delta
		if _zzz_in <= 0.0:
			_zzz_in = 0.9
			_puff_z()
	_fidget_in -= delta
	if _fidget_in <= 0.0:
		_fidget_in = randf_range(6.0, 12.0)
		fidget()
