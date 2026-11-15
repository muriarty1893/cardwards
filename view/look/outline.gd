class_name Outline
extends MeshInstance3D
## Full-screen ink outline pass. Attach one to the active camera.

const SHADER_PATH := "res://view/look/outline.gdshader"
## The Mobile renderer has no normal-roughness buffer: silhouettes from depth only.
const DEPTH_ONLY_PATH := "res://view/look/outline_depth.gdshader"

## Normal-based edges (inner creases). Depth edges are always on.
var use_normals: bool = true:
	set(v):
		use_normals = v
		if material_override:
			(material_override as ShaderMaterial).set_shader_parameter("use_normals", v)


static func attach(cam: Camera3D) -> Outline:
	var o := Outline.new()
	o.name = "Outline"
	var quad := QuadMesh.new()
	quad.size = Vector2(2, 2)
	o.mesh = quad
	var m := ShaderMaterial.new()
	var forward_plus: bool = RenderingServer.get_current_rendering_method() == "forward_plus"
	m.shader = load(SHADER_PATH if forward_plus else DEPTH_ONLY_PATH) as Shader
	m.set_shader_parameter("ink", Palette.INK)
	# Drawn before other transparent things, so particles and numbers sit on top of the lines.
	m.render_priority = -128
	o.material_override = m
	o.extra_cull_margin = 16384.0
	o.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	o.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	cam.add_child(o)
	return o
