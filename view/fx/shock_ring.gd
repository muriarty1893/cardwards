class_name ShockRing
extends MeshInstance3D
## A flat ring that spreads out over the ground and fades (hits, Hush, landings). Frees itself.

static var _mesh: TorusMesh


static func spawn(parent: Node, pos: Vector3, color: Color, radius: float = 1.0, duration: float = 0.4) -> ShockRing:
	var r := ShockRing.new()
	if _mesh == null:
		_mesh = TorusMesh.new()
		_mesh.inner_radius = 0.42
		_mesh.outer_radius = 0.5
		_mesh.rings = 32
		_mesh.ring_segments = 6
	r.mesh = _mesh
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = Color(color, 0.9)
	r.material_override = mat
	r.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	r.scale = Vector3(0.3, 0.2, 0.3) * radius
	parent.add_child(r)
	r.global_position = pos
	var tw := r.create_tween().set_parallel(true)
	tw.tween_property(r, "scale", Vector3(2.2 * radius, 0.2, 2.2 * radius), duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tw.tween_property(mat, "albedo_color:a", 0.0, duration).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(r.queue_free)
	return r
