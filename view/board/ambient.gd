class_name Ambient
extends Node3D
## Gentle per-land particles over each lane: fireflies (forest), rising embers (ember),
## sparkles (candy), snowfall (frost), drifting pollen (meadow). Low quality halves every
## emitter. A lane's emitter is swapped when its land changes.

## Particles per lane at High quality, by land.
const AMOUNTS: Array[int] = [6, 10, 6, 12, 4]
const TEX := "res://assets/fx/particles/%s.png"
const CANDY: Array[Color] = [Color("#ff5a5a"), Color("#ffd84a"), Color("#5ad1ff"), Color("#7aff7a"), Color("#ffffff")]

var _emitters: Array[CPUParticles3D] = []
var _base: Array[int] = []
var _quality: int = 0
var _xs: Array[float] = [-4.05, -1.35, 1.35, 4.05]


## `lane_xs`: the lanes' centres (Board.lane_x); today's even lanes when empty.
static func build(lands: Array[Array], quality: int, lane_xs: Array[float] = []) -> Ambient:
	var a := Ambient.new()
	a.name = "Ambient"
	if lane_xs.size() == 4:
		a._xs = lane_xs
	for p: int in 2:
		for l: int in 4:
			var land: int = lands[p][l]
			var e: CPUParticles3D = _emitter(land)
			e.position = Vector3(a._xs[l], e.position.y, Board.STRIP_Z[p])
			a.add_child(e)
			a._emitters.append(e)
			a._base.append(AMOUNTS[land])
	a.set_quality(quality)
	return a


## Swaps the particles over player p's lane for `land`'s.
func set_land(p: int, l: int, land: int) -> void:
	var i: int = p * 4 + l
	var old: CPUParticles3D = _emitters[i]
	var e: CPUParticles3D = _emitter(land)
	e.position = Vector3(_xs[l], e.position.y, Board.STRIP_Z[p])
	add_child(e)
	_emitters[i] = e
	_base[i] = AMOUNTS[land]
	old.emitting = false
	if is_inside_tree():
		get_tree().create_timer(old.lifetime).timeout.connect(old.queue_free)
	else:
		old.free()
	set_quality(_quality)


func set_quality(q: int) -> void:
	_quality = q
	for i: int in _emitters.size():
		var n: int = _base[i] if q == GameSettings.Quality.HIGH else maxi(1, _base[i] / 2)
		if _emitters[i].amount != n:
			_emitters[i].amount = n


func amount_total() -> int:
	var t: int = 0
	for e: CPUParticles3D in _emitters:
		t += e.amount
	return t


static func _emitter(land: int) -> CPUParticles3D:
	var e := CPUParticles3D.new()
	e.amount = AMOUNTS[land]
	e.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	e.emission_box_extents = Vector3(0.95, 0.25, 2.0)
	e.local_coords = false
	var quad := QuadMesh.new()
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.vertex_color_use_as_albedo = true
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	var fade := Gradient.new()
	fade.offsets = PackedFloat32Array([0.0, 0.2, 0.8, 1.0])
	fade.colors = PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 1), Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	e.color_ramp = fade
	match land:
		0:  # fireflies
			quad.size = Vector2(0.09, 0.09)
			mat.albedo_texture = load(TEX % "circle_05")
			e.color = Color("#f4ff8a")
			e.position.y = 0.7
			e.lifetime = 3.0
			e.gravity = Vector3.ZERO
			e.spread = 180.0
			e.initial_velocity_min = 0.08
			e.initial_velocity_max = 0.22
		1:  # embers
			quad.size = Vector2(0.07, 0.07)
			mat.albedo_texture = load(TEX % "circle_05")
			e.color = Color("#ff8a2a")
			e.position.y = 0.25
			e.lifetime = 2.2
			e.direction = Vector3.UP
			e.spread = 25.0
			e.gravity = Vector3(0, 0.25, 0)
			e.initial_velocity_min = 0.25
			e.initial_velocity_max = 0.55
		2:  # sparkles
			quad.size = Vector2(0.14, 0.14)
			mat.albedo_texture = load(TEX % "star_06")
			var ramp := Gradient.new()
			ramp.offsets = PackedFloat32Array([0.0, 0.25, 0.5, 0.75, 1.0])
			ramp.colors = PackedColorArray(CANDY)
			e.color_initial_ramp = ramp
			e.position.y = 0.55
			e.lifetime = 1.6
			e.gravity = Vector3.ZERO
			e.spread = 180.0
			e.initial_velocity_min = 0.02
			e.initial_velocity_max = 0.1
		4:  # pollen drifting over the meadow
			quad.size = Vector2(0.06, 0.06)
			mat.albedo_texture = load(TEX % "circle_05")
			e.color = Color("#fff6c8")
			e.position.y = 0.5
			e.lifetime = 4.0
			e.gravity = Vector3.ZERO
			e.direction = Vector3(1, 0.2, 0)
			e.spread = 60.0
			e.initial_velocity_min = 0.05
			e.initial_velocity_max = 0.15
		_:  # snow
			quad.size = Vector2(0.07, 0.07)
			mat.albedo_texture = load(TEX % "circle_05")
			mat.blend_mode = BaseMaterial3D.BLEND_MODE_MIX
			e.color = Color.WHITE
			e.position.y = 2.4
			e.emission_box_extents = Vector3(0.95, 0.1, 2.0)
			e.lifetime = 4.0
			e.direction = Vector3.DOWN
			e.spread = 15.0
			e.gravity = Vector3(0, -0.15, 0)
			e.initial_velocity_min = 0.35
			e.initial_velocity_max = 0.55
	quad.material = mat
	e.mesh = quad
	e.preprocess = e.lifetime
	return e
