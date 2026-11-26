extends TestCase
## Toon material and ink outline wiring (the shading itself is checked by screenshot).


func _surfaces(root: Node) -> Array[Material]:
	var out: Array[Material] = []
	for mi: Node in root.find_children("*", "MeshInstance3D", true, false):
		for i: int in (mi as MeshInstance3D).mesh.get_surface_count():
			out.append((mi as MeshInstance3D).get_active_material(i))
	return out


func test_toon_apply_replaces_all_materials() -> bool:
	var inst := (load(Room.CAT) as PackedScene).instantiate()
	Toon.apply(inst, Color("#ff6a2a", 0.55))
	var mats: Array[Material] = _surfaces(inst)
	assert_true(mats.size() > 0, "has surfaces")
	for m: Material in mats:
		var sm := m as ShaderMaterial
		assert_true(sm != null and sm.shader.resource_path == Toon.SHADER_PATH, "toon shader")
		assert_true(sm != null and sm.get_shader_parameter("albedo_tex") != null, "keeps albedo texture")
		assert_true(sm != null and sm.get_shader_parameter("tint") == Color("#ff6a2a", 0.55), "tint set")
	inst.free()
	return true


func test_toon_fx_variant() -> bool:
	var inst := (load(Room.CAT) as PackedScene).instantiate()
	Toon.apply(inst, Toon.NO_TINT, 0.0, true)
	for m: Material in _surfaces(inst):
		var sm := m as ShaderMaterial
		assert_true(sm != null and sm.shader.resource_path in [Toon.FX_PATH, Toon.FX_CUTOUT_PATH], "fx toon shader")
	inst.free()
	assert_true(Toon.plain(Color.RED) != Toon.plain(Color.RED, 0.0, true), "fx and plain materials are separate")
	assert_true(Toon.plain(Color.RED, 0.0, true).shader.resource_path == Toon.FX_PATH, "plain fx material")
	return true


func test_blob_shadow() -> bool:
	var b: BlobShadow = BlobShadow.build(0.6)
	assert_eq(String(b.name), "BlobShadow", "named")
	assert_eq(b.cast_shadow, GeometryInstance3D.SHADOW_CASTING_SETTING_OFF, "casts no shadow itself")
	assert_true(b.mesh is PlaneMesh and is_equal_approx((b.mesh as PlaneMesh).size.x, 1.2), "flat disc of the radius")
	var m := b.material_override as StandardMaterial3D
	assert_true(m != null and m.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA, "see-through")
	assert_true(m != null and m.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED, "unshaded")
	var b2: BlobShadow = BlobShadow.build(0.3)
	assert_true(b2.material_override == m, "material shared")
	b.free()
	b2.free()
	return true


func test_blob_leans_away_from_sun() -> bool:
	var parent := Node3D.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(parent)
	var b: BlobShadow = BlobShadow.build(0.5, 1.0, 0.1)
	parent.add_child(b)
	await (Engine.get_main_loop() as SceneTree).process_frame
	for yaw: float in [0.0, PI, PI * 0.62]:
		parent.rotation.y = yaw
		b._process(0.0)
		var shift: Vector3 = b.global_position - parent.global_position
		# The blob shifts away from the sun (Room.SUN_FROM) on the ground plane.
		assert_true(shift.x * Room.SUN_FROM.x < 0.0 and shift.z * Room.SUN_FROM.z < 0.0, "leans away from sun at yaw %f (%s)" % [yaw, shift])
		assert_true(is_equal_approx(shift.y, 0.1), "stays at ground height")
	parent.free()
	return true


func test_material_cache() -> bool:
	assert_true(Toon.plain(Color.RED) == Toon.plain(Color.RED), "same args, same material")
	assert_true(Toon.plain(Color.RED) != Toon.plain(Color.BLUE), "different args, different material")
	return true


func test_outline_attach() -> bool:
	var cam := Camera3D.new()
	var o: Outline = Outline.attach(cam)
	assert_true(o.get_parent() == cam, "child of camera")
	assert_true(o.extra_cull_margin >= 16000.0, "never culled")
	cam.free()
	return true
