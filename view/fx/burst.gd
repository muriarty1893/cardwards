class_name Burst
extends CPUParticles3D
## One-shot particle burst with Kenney particle textures (CC0). Frees itself when done.

const TEX := "res://assets/fx/particles/%s.png"
const CANDY: Array[Color] = [Color("#ff5a5a"), Color("#ffd84a"), Color("#5ad1ff"), Color("#7aff7a"), Color("#ffffff")]
## texture, count, lifetime, speed min/max, size, gravity y, spread, colour, additive, flat ring
const PRESETS: Dictionary = {
	&"sparks": ["spark_01", 18, 0.4, 3.0, 6.0, 0.22, -6.0, 180.0, "#fff3b0", true, false],
	&"stars": ["star_04", 8, 0.6, 2.0, 3.5, 0.34, -4.0, 180.0, "#ffe14a", true, false],
	&"dust_ring": ["smoke_04", 14, 0.5, 2.0, 3.0, 0.55, 0.0, 180.0, "#e8dcc8", false, true],
	&"leaves": ["dirt_01", 12, 0.7, 1.5, 3.0, 0.2, -3.0, 120.0, "#7bd36a", false, false],
	&"embers": ["spark_04", 14, 0.8, 1.0, 2.5, 0.16, 1.5, 60.0, "#ff8a2a", true, false],
	&"sprinkles": ["circle_05", 16, 0.6, 2.0, 4.0, 0.12, -6.0, 180.0, "#ffffff", false, false],
	&"snow": ["circle_05", 14, 0.8, 1.0, 2.5, 0.14, -2.0, 180.0, "#ffffff", false, false],
	&"smoke": ["smoke_07", 10, 0.9, 0.5, 1.2, 0.8, 0.6, 60.0, "#8a8a92", false, false],
	&"heal": ["star_06", 14, 0.8, 1.0, 2.0, 0.24, 1.2, 40.0, "#6aff7a", true, false],
	# Living board: land reactions and level-ups.
	&"steam": ["smoke_07", 16, 1.2, 0.8, 1.8, 0.7, 1.4, 35.0, "#f4f8ff", false, false],
	&"flames": ["flame_02", 16, 0.7, 1.2, 2.6, 0.4, 2.2, 40.0, "#ff7a1a", true, false],
	&"caramel": ["circle_05", 14, 0.8, 1.0, 2.2, 0.16, -5.0, 120.0, "#c87a2a", false, false],
	&"petals": ["dirt_01", 16, 1.0, 1.0, 2.4, 0.22, -1.5, 150.0, "#ffb3dd", false, false],
	&"gold": ["star_04", 22, 0.9, 2.0, 4.0, 0.3, -2.0, 180.0, "#ffd84a", true, false],
	&"sand": ["circle_05", 18, 0.7, 1.2, 2.8, 0.13, -4.0, 140.0, "#e8c27a", false, false],
}


## `color` WHITE keeps the preset's colour; anything else tints it. `scale_` multiplies size.
static func spawn(parent: Node, preset: StringName, pos: Vector3, color: Color = Color.WHITE, scale_: float = 1.0) -> Burst:
	var cfg: Array = PRESETS.get(preset, PRESETS[&"sparks"])
	var b := Burst.new()
	b.amount = cfg[1]
	b.lifetime = cfg[2]
	b.one_shot = true
	b.explosiveness = 0.95
	b.local_coords = false
	b.initial_velocity_min = cfg[3] * scale_
	b.initial_velocity_max = cfg[4] * scale_
	b.gravity = Vector3(0, cfg[6], 0)
	b.spread = cfg[7]
	b.direction = Vector3.UP
	if cfg[10]:
		b.direction = Vector3.RIGHT
		b.flatness = 1.0
	b.scale_amount_min = 0.7
	b.scale_amount_max = 1.3
	var shrink := Curve.new()
	shrink.add_point(Vector2(0.0, 1.0))
	shrink.add_point(Vector2(1.0, 0.3))
	b.scale_amount_curve = shrink
	var tint: Color = Color(cfg[8]) if color == Color.WHITE else color
	var fade := Gradient.new()
	fade.colors = PackedColorArray([Color(tint, 1.0), Color(tint, 0.0)])
	b.color_ramp = fade
	if preset == &"sprinkles":
		var ramp := Gradient.new()
		ramp.offsets = PackedFloat32Array([0.0, 0.25, 0.5, 0.75, 1.0])
		ramp.colors = PackedColorArray(CANDY)
		b.color_initial_ramp = ramp
		var alpha := Gradient.new()
		alpha.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
		b.color_ramp = alpha
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE * cfg[5] * scale_
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.vertex_color_use_as_albedo = true
	mat.albedo_texture = load(TEX % cfg[0]) as Texture2D
	if cfg[9]:
		mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	quad.material = mat
	b.mesh = quad
	parent.add_child(b)
	b.global_position = pos
	b.emitting = true
	b.finished.connect(b.queue_free)
	return b
