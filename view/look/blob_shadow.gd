class_name BlobShadow
extends MeshInstance3D
## Soft dark disc under a piece, standing in for the sun's cast shadow where the sun casts none.
## The Compatibility renderer (web) draws a shadowed light in an extra pass and adds it in sRGB
## space, so ambient + shadowed sun came out about twice as bright as on desktop (measured:
## 0.79 grey instead of 0.56). There the sun casts no shadows and pieces get these blobs instead.
## The blob leans away from the sun in world space, whichever way its parent turns.

const INK_ALPHA := 0.42

## Tests set this to exercise the blob path on any renderer.
static var force_blobs: bool = false
static var _mat: StandardMaterial3D

## Height above the parent's origin, in the parent's space.
var ground_y: float = 0.0
## World-space shift from the parent's origin, away from the sun.
var lean := Vector3.ZERO


## True where the sun casts real shadows (Forward+ and Mobile).
static func sun_shadows() -> bool:
	return not force_blobs and RenderingServer.get_current_rendering_method() != "gl_compatibility"


## A blob of `radius` for a piece `height` tall, lying at `ground_y` in its parent's space.
static func build(radius: float, height: float = 1.0, at_y: float = 0.0) -> BlobShadow:
	var plane := PlaneMesh.new()
	plane.size = Vector2(radius, radius) * 2.0
	var b := BlobShadow.new()
	b.name = "BlobShadow"
	b.mesh = plane
	b.material_override = _material()
	b.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	b.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	b.ground_y = at_y
	b.position.y = at_y
	# Shadow of the piece's middle: the ground shift of a point at 0.35 of its height.
	var s: Vector3 = Board.SUN_FROM
	b.lean = Vector3(-s.x / s.y, 0.0, -s.z / s.y) * height * 0.35
	return b


func _process(_delta: float) -> void:
	var p := get_parent() as Node3D
	if p == null:
		return
	var local: Vector3 = p.global_basis.inverse() * lean
	position = Vector3(local.x, ground_y, local.z)


static func _material() -> StandardMaterial3D:
	if _mat:
		return _mat
	var g := Gradient.new()
	g.set_color(0, Color(Palette.INK, INK_ALPHA))
	g.set_color(1, Color(Palette.INK, 0.0))
	g.add_point(0.5, Color(Palette.INK, INK_ALPHA * 0.85))
	var tex := GradientTexture2D.new()
	tex.gradient = g
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 64
	tex.height = 64
	_mat = StandardMaterial3D.new()
	_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mat.albedo_texture = tex
	_mat.disable_receive_shadows = true
	# Under particles and damage numbers, like the ink outline.
	_mat.render_priority = -100
	return _mat
