class_name KeywordFx
extends Node3D
## The lasting keyword looks on one creature (spec 3): Guard's hexagon wall facing the enemy,
## Bubble's soap bubble, Hidden's see-through shimmer, Second Wind's halo and Venom's drips.
## One KeywordFx node per CreatureView; sync() adds and removes parts to match the keywords.

## Keywords with a lasting look (the rest are tag chips plus one-shot moments).
const LASTING: Array[StringName] = [&"guard", &"bubble", &"hidden", &"second_wind", &"venom", &"sturdy", &"bask"]
const NODE_NAME := "KeywordFx"
const GUARD_GOLD := Color("#ffb21e")
const VENOM_GREEN := Color("#7dff4a")

static var _shield_mat: ShaderMaterial
static var _bubble_mat: ShaderMaterial
static var _halo_mat: StandardMaterial3D
static var _drop_mat: StandardMaterial3D

var view: CreatureView
## +1 or -1: which way along z the enemy sits (the Guard wall stands on that side).
var enemy_z: float = -1.0
var _parts: Dictionary = {}
var _t: float = 0.0


## Makes `v`'s keyword looks match `kws` (creates the KeywordFx node on first use).
static func sync(v: CreatureView, kws: Array[StringName], enemy_side_z: float) -> KeywordFx:
	var fx: KeywordFx = v.get_node_or_null(NODE_NAME) as KeywordFx
	if fx == null:
		if kws.filter(func(k: StringName) -> bool: return k in LASTING).is_empty():
			return null
		fx = KeywordFx.new()
		fx.name = NODE_NAME
		fx.view = v
		v.add_child(fx)
	fx.enemy_z = enemy_side_z
	fx.set_keywords(kws)
	return fx


static func of(v: CreatureView) -> KeywordFx:
	return v.get_node_or_null(NODE_NAME) as KeywordFx if is_instance_valid(v) else null


func set_keywords(kws: Array[StringName]) -> void:
	for k: StringName in LASTING:
		var want: bool = k in kws
		if want and not _parts.has(k):
			attach(k)
		elif not want and _parts.has(k):
			detach(k)


func has_part(kw: StringName) -> bool:
	return _parts.has(kw)


func part(kw: StringName) -> Node3D:
	return _parts.get(kw) as Node3D


## Body centre height above the view's origin (where the ice shell sits too).
func _mid() -> float:
	return Island.TOP_Y - CreatureView.BASE_Y + view.height * 0.5


func attach(kw: StringName) -> void:
	var n: Node3D
	match kw:
		&"guard":
			n = _make_shield()
		&"bubble":
			n = _make_bubble()
		&"hidden":
			n = Node3D.new()
			view.set_hidden_look(true)
		&"second_wind":
			n = _make_halo()
		&"venom":
			n = _make_drips()
		&"sturdy":
			n = _make_plates()
		&"bask":
			n = _make_sun_glow()
		_:
			return
	n.name = "kw_%s" % kw
	add_child(n)
	_parts[kw] = n
	if kw != &"hidden":
		var full: Vector3 = n.scale
		n.scale = full * 0.05
		n.create_tween().tween_property(n, "scale", full, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Removes a look at once (one-shot moments animate their own leaving first).
func detach(kw: StringName) -> void:
	var n: Node3D = _parts.get(kw)
	_parts.erase(kw)
	if kw == &"hidden" and is_instance_valid(view):
		view.set_hidden_look(false)
	if is_instance_valid(n):
		n.queue_free()


func _process(delta: float) -> void:
	_t += delta
	var shield: Node3D = _parts.get(&"guard")
	if is_instance_valid(shield):
		# The wall faces the enemy whatever way the creature is looking.
		shield.global_rotation = Vector3(0, 0.0 if enemy_z < 0.0 else PI, 0)
		shield.global_position = global_position + Vector3(0, Island.TOP_Y - CreatureView.BASE_Y - 0.05, 0)
	var bubble: Node3D = _parts.get(&"bubble")
	if is_instance_valid(bubble) and bubble.get_meta(&"settled", false):
		var w: float = 1.0 + sin(_t * 3.1) * 0.025
		bubble.scale = bubble.get_meta(&"base") * Vector3(w, 2.0 - w, w)
	elif is_instance_valid(bubble) and bubble.scale.is_equal_approx(bubble.get_meta(&"base")):
		bubble.set_meta(&"settled", true)
	var plates: Node3D = _parts.get(&"sturdy")
	if is_instance_valid(plates):
		plates.rotation.y = _t * 0.6
	var glow: Node3D = _parts.get(&"bask")
	if is_instance_valid(glow):
		var k: float = 1.0 + sin(_t * 2.2) * 0.08
		glow.scale = Vector3(k, 1.0, k)
	var halo: Node3D = _parts.get(&"second_wind")
	if is_instance_valid(halo):
		halo.rotation.y = _t * 1.4
		halo.position.y = Island.TOP_Y - CreatureView.BASE_Y + view.height + 0.14 + sin(_t * 2.0) * 0.03


func _make_shield() -> Node3D:
	if _shield_mat == null:
		_shield_mat = ShaderMaterial.new()
		_shield_mat.shader = load("res://view/fx/shield_wall.gdshader") as Shader
		_shield_mat.set_shader_parameter("tint", GUARD_GOLD)
	var holder := Node3D.new()
	var mi := MeshInstance3D.new()
	mi.mesh = shield_arc(0.62, view.height * 1.05 + 0.25, 150.0)
	mi.material_override = _shield_mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	holder.add_child(mi)
	return holder


## A curved band (an arc of a cylinder) bowing out towards -z, from the ground up to `h`.
static func shield_arc(radius: float, h: float, degrees: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var steps: int = 14
	var half: float = deg_to_rad(degrees) / 2.0
	for i: int in steps:
		var a0: float = -half + (2.0 * half) * float(i) / steps
		var a1: float = -half + (2.0 * half) * float(i + 1) / steps
		var p0 := Vector3(sin(a0) * radius, 0, -cos(a0) * radius)
		var p1 := Vector3(sin(a1) * radius, 0, -cos(a1) * radius)
		var u0: float = float(i) / steps
		var u1: float = float(i + 1) / steps
		var quad: Array = [[p0, Vector2(u0, 1)], [p1, Vector2(u1, 1)], [p1 + Vector3(0, h, 0), Vector2(u1, 0)],
			[p0, Vector2(u0, 1)], [p1 + Vector3(0, h, 0), Vector2(u1, 0)], [p0 + Vector3(0, h, 0), Vector2(u0, 0)]]
		for v: Array in quad:
			st.set_normal(Vector3((v[0] as Vector3).x, 0, (v[0] as Vector3).z).normalized())
			st.set_uv(v[1])
			st.add_vertex(v[0])
	return st.commit()


func _make_bubble() -> Node3D:
	if _bubble_mat == null:
		_bubble_mat = ShaderMaterial.new()
		_bubble_mat.shader = load("res://view/fx/bubble.gdshader") as Shader
	var s := SphereMesh.new()
	s.radius = 1.0
	s.height = 2.0
	s.radial_segments = 24
	s.rings = 12
	var mi := MeshInstance3D.new()
	mi.mesh = s
	mi.material_override = _bubble_mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var r: float = maxf(view.height * 0.66, 0.42)
	mi.position = Vector3(0, _mid(), 0)
	mi.scale = Vector3.ONE * r
	mi.set_meta(&"base", mi.scale)
	return mi


func _make_halo() -> Node3D:
	if _halo_mat == null:
		_halo_mat = StandardMaterial3D.new()
		_halo_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		# See-through (no depth write) so the ink outline pass doesn't paint the thin ring black.
		_halo_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_halo_mat.albedo_color = Color("#ffe27a", 0.95)
		_halo_mat.emission_enabled = true
		_halo_mat.emission = Color("#ffd040")
	var t := TorusMesh.new()
	t.inner_radius = 0.16
	t.outer_radius = 0.23
	t.rings = 24
	t.ring_segments = 8
	var mi := MeshInstance3D.new()
	mi.mesh = t
	mi.material_override = _halo_mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.position = Vector3(0, Island.TOP_Y - CreatureView.BASE_Y + view.height + 0.14, 0)
	mi.rotation.x = 0.18
	return mi


func _make_drips() -> Node3D:
	if _drop_mat == null:
		_drop_mat = StandardMaterial3D.new()
		_drop_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_drop_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		_drop_mat.albedo_color = Color(VENOM_GREEN, 0.95)
	var holder := Node3D.new()
	# A small poison puddle under the creature...
	var puddle := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = maxf(view.height * 0.5, 0.3)
	disc.bottom_radius = disc.top_radius
	disc.height = 0.01
	disc.radial_segments = 20
	disc.rings = 1
	puddle.mesh = disc
	var pm := StandardMaterial3D.new()
	pm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	pm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	pm.albedo_color = Color(VENOM_GREEN, 0.35)
	puddle.material_override = pm
	puddle.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	puddle.position = Vector3(0, Island.TOP_Y - CreatureView.BASE_Y + 0.02, 0)
	holder.add_child(puddle)
	# ...and drops that ooze off the body and fall into it.
	var p := CPUParticles3D.new()
	var drop := SphereMesh.new()
	drop.radius = 0.045
	drop.height = 0.12
	drop.radial_segments = 6
	drop.rings = 3
	drop.material = _drop_mat
	p.mesh = drop
	p.amount = 8
	p.lifetime = 1.0
	p.local_coords = false
	p.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = maxf(view.height * 0.3, 0.18)
	p.direction = Vector3.DOWN
	p.spread = 5.0
	p.initial_velocity_min = 0.0
	p.initial_velocity_max = 0.05
	p.gravity = Vector3(0, -0.9, 0)
	p.scale_amount_min = 0.7
	p.scale_amount_max = 1.2
	p.position = Vector3(0, _mid() + view.height * 0.1, 0)
	holder.add_child(p)
	return holder


## Sturdy: little sandstone plates circling slowly round the creature's middle.
func _make_plates() -> Node3D:
	var holder := Node3D.new()
	holder.position = Vector3(0, Island.TOP_Y - CreatureView.BASE_Y + view.height * 0.35, 0)
	var r: float = clampf(view.height * 0.55, 0.32, 0.55)
	var mat: ShaderMaterial = Toon.plain(Color("#8a7458"))
	for i: int in 4:
		var a: float = TAU * i / 4.0
		var b := BoxMesh.new()
		b.size = Vector3(0.24, 0.18, 0.05)
		var plate := MeshInstance3D.new()
		plate.mesh = b
		plate.material_override = mat
		plate.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		plate.position = Vector3(cos(a) * r, 0.04 * (i % 2), sin(a) * r)
		plate.rotation.y = -a + PI / 2.0
		holder.add_child(plate)
	return holder


## Bask: a warm, softly pulsing patch of sunlight on the ground under the creature.
func _make_sun_glow() -> Node3D:
	var disc := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	var r: float = maxf(view.height * 0.8, 0.5)
	plane.size = Vector2(r, r) * 2.0
	disc.mesh = plane
	var mat := ShaderMaterial.new()
	mat.shader = _sun_shader()
	disc.material_override = mat
	disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	disc.position = Vector3(0, Island.TOP_Y - CreatureView.BASE_Y + 0.025, 0)
	return disc


static var _sun: Shader


static func _sun_shader() -> Shader:
	if _sun == null:
		_sun = Shader.new()
		_sun.code = """
shader_type spatial;
render_mode blend_add, unshaded, depth_draw_never, cull_disabled, shadows_disabled;
#include "res://view/look/color_space.gdshaderinc"
void fragment() {
	float d = length(UV * 2.0 - 1.0);
	float ring = smoothstep(0.06, 0.0, abs(d - 0.82)) * 0.9;
	float a = smoothstep(1.0, 0.2, d) * (0.5 + 0.15 * sin(TIME * 2.0)) + ring;
	ALBEDO = out_col(src_lin(vec3(1.0, 0.5, 0.12)) * a);
	ALPHA = a;
}
"""
	return _sun
