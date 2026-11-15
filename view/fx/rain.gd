class_name Rain
extends Node3D
## Particles falling onto a set of points for a while (Ember Rain, Rain of Spores).

## preset -> [texture, colour, additive]
const LOOK: Dictionary = {
	&"embers": ["flame_02", "#ff8a2a", true],
	&"spores": ["circle_05", "#9bff6a", true],
	&"snow": ["circle_05", "#ffffff", false],
	&"sprinkles": ["circle_05", "#ff8ad8", false],
}


static func over(parent: Node, points: Array[Vector3], preset: StringName, duration: float) -> Rain:
	var r := Rain.new()
	parent.add_child(r)
	var look: Array = LOOK.get(preset, LOOK[&"embers"])
	for p: Vector3 in points:
		var e := CPUParticles3D.new()
		e.amount = 22
		e.lifetime = 0.6
		e.local_coords = false
		e.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
		e.emission_box_extents = Vector3(0.8, 0.1, 1.0)
		e.direction = Vector3.DOWN
		e.spread = 8.0
		e.gravity = Vector3(0, -9.0, 0)
		e.initial_velocity_min = 2.0
		e.initial_velocity_max = 3.0
		var quad := QuadMesh.new()
		quad.size = Vector2(0.2, 0.32)
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.vertex_color_use_as_albedo = true
		mat.albedo_texture = load(Burst.TEX % look[0]) as Texture2D
		if look[2]:
			mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
		quad.material = mat
		e.mesh = quad
		e.color = Color(look[1] as String)
		r.add_child(e)
		e.global_position = p + Vector3(0, 3.2, 0)
		e.emitting = true
	var tw := r.create_tween()
	tw.tween_interval(duration)
	tw.tween_callback(func() -> void:
		for c: Node in r.get_children():
			(c as CPUParticles3D).emitting = false)
	tw.tween_interval(0.7)
	tw.tween_callback(r.queue_free)
	return r
