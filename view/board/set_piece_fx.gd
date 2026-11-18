class_name SetPieceFx
extends Node3D
## Timed effects on a set piece (board look 2, spec 2): calls `fire` every interval.x..interval.y seconds while it is
## in the tree (volcano eruptions, vent puffs). Freed with its dressing, so the effect stops when the land changes.
## Particle helpers for set pieces live here too. Low quality halves particle counts.

const TEX := "res://assets/fx/particles/%s.png"

var interval := Vector2(12.0, 25.0)
var fire: Callable
var _timer: Timer
var _rng := RandomNumberGenerator.new()


## Adds a periodic effect under `parent`. The first firing comes after a random share of the interval.
static func periodic(parent: Node3D, lo: float, hi: float, fire_: Callable, seed: int) -> SetPieceFx:
	var fx := SetPieceFx.new()
	fx.name = "Fx"
	fx.interval = Vector2(lo, hi)
	fx.fire = fire_
	fx._rng.seed = seed
	parent.add_child(fx)
	return fx


func _ready() -> void:
	_timer = Timer.new()
	_timer.one_shot = true
	add_child(_timer)
	_timer.timeout.connect(_on_timeout)
	_timer.start(_rng.randf_range(interval.x * 0.15, interval.y * 0.6))


func _on_timeout() -> void:
	if fire.is_valid():
		fire.call()
	_timer.start(_rng.randf_range(interval.x, interval.y))


## How many particles to use at the current quality.
static func amount(n: int) -> int:
	return maxi(1, n / 2) if Settings.quality == GameSettings.Quality.LOW else n


## A billboard particle emitter (unshaded, faded in and out). `additive` for glows, otherwise alpha smoke.
static func emitter(tex: String, color: Color, size: float, n: int, additive: bool = true) -> CPUParticles3D:
	var e := CPUParticles3D.new()
	e.amount = amount(n)
	e.local_coords = false
	var quad := QuadMesh.new()
	quad.size = Vector2(size, size)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.vertex_color_use_as_albedo = true
	mat.albedo_texture = load(TEX % tex)
	if additive:
		mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	quad.material = mat
	e.mesh = quad
	e.color = color
	var fade := Gradient.new()
	fade.offsets = PackedFloat32Array([0.0, 0.15, 0.7, 1.0])
	fade.colors = PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 1), Color(1, 1, 1, 0.8), Color(1, 1, 1, 0)])
	e.color_ramp = fade
	return e


## An unshaded glowing material (lava, embers, vent holes).
static func glow(color: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = color
	return m
