class_name Toon
extends RefCounted
## The cartoon material used on every model. Materials are cached and shared by their
## arguments; per-piece hit flash and dissolve are instance uniforms, so sharing is safe.
## Only `fx` materials (creatures) carry those instance uniforms: WebGL fits roughly 256
## such instances, far fewer than the scenery uses.

const SHADER_PATH := "res://view/look/toon.gdshader"
const CUTOUT_PATH := "res://view/look/toon_cutout.gdshader"
const FX_PATH := "res://view/look/toon_fx.gdshader"
const FX_CUTOUT_PATH := "res://view/look/toon_fx_cutout.gdshader"
const NO_TINT := Color(1, 1, 1, 0)

## Shader path -> loaded Shader.
static var _shaders: Dictionary = {}
static var _cache: Dictionary = {}


## `cutout` > 0 selects the alpha-tested variant with that threshold; `fx` adds hit flash and dissolve.
static func material(tex: Texture2D, color: Color, tint: Color = NO_TINT, sway: float = 0.0, vertex_color: bool = false, cutout: float = 0.0, fx: bool = false) -> ShaderMaterial:
	var key: String = "%d|%s|%s|%.3f|%s|%.2f|%s" % [tex.get_instance_id() if tex else 0, color.to_html(), tint.to_html(), sway, vertex_color, cutout, fx]
	if _cache.has(key):
		return _cache[key]
	var path: String
	if fx:
		path = FX_CUTOUT_PATH if cutout > 0.0 else FX_PATH
	else:
		path = CUTOUT_PATH if cutout > 0.0 else SHADER_PATH
	if not _shaders.has(path):
		_shaders[path] = load(path) as Shader
	var m := ShaderMaterial.new()
	m.shader = _shaders[path]
	if cutout > 0.0:
		m.set_shader_parameter("alpha_cut", cutout)
	if tex:
		m.set_shader_parameter("albedo_tex", tex)
	m.set_shader_parameter("albedo_color", color)
	m.set_shader_parameter("tint", tint)
	m.set_shader_parameter("sway", sway)
	m.set_shader_parameter("use_vertex_color", vertex_color)
	_cache[key] = m
	return m


static func plain(color: Color, sway: float = 0.0, fx: bool = false) -> ShaderMaterial:
	return material(null, color, NO_TINT, sway, false, 0.0, fx)


## Swap every surface material under `root` for the toon material, keeping albedo texture and colour.
## Pass `fx` for pieces that use set_flash / set_dissolve.
static func apply(root: Node, tint: Color = NO_TINT, sway: float = 0.0, fx: bool = false) -> void:
	for mi: MeshInstance3D in _meshes(root):
		if mi.mesh == null:
			continue
		for i: int in mi.mesh.get_surface_count():
			var src: Material = mi.get_active_material(i)
			if is_toon(src):
				continue
			var tex: Texture2D = null
			var col := Color.WHITE
			var vcol: bool = false
			var cut: float = 0.0
			var base := src as BaseMaterial3D
			if base:
				tex = base.albedo_texture
				col = base.albedo_color
				vcol = base.vertex_color_use_as_albedo
				if base.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR:
					cut = base.alpha_scissor_threshold
				elif base.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED and tex:
					cut = 0.5
			mi.set_surface_override_material(i, material(tex, col, tint, sway, vcol, cut, fx))
		mi.material_override = null


static func is_toon(m: Material) -> bool:
	var sm := m as ShaderMaterial
	return sm != null and sm.shader != null and sm.shader.resource_path in [SHADER_PATH, CUTOUT_PATH, FX_PATH, FX_CUTOUT_PATH]


static func set_flash(root: Node, v: float) -> void:
	_set_instance(root, &"flash", v)


static func set_dissolve(root: Node, v: float) -> void:
	_set_instance(root, &"dissolve", v)


static func _set_instance(root: Node, param: StringName, v: float) -> void:
	var nodes: Array[Node] = root.find_children("*", "GeometryInstance3D", true, false)
	if root is GeometryInstance3D:
		nodes.append(root)
	for n: Node in nodes:
		(n as GeometryInstance3D).set_instance_shader_parameter(param, v)


static func _meshes(root: Node) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	if root is MeshInstance3D:
		out.append(root)
	for n: Node in root.find_children("*", "MeshInstance3D", true, false):
		out.append(n as MeshInstance3D)
	return out
