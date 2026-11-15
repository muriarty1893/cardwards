extends TestCase
## Toon material and ink outline wiring (the shading itself is checked by screenshot).


func _surfaces(root: Node) -> Array[Material]:
	var out: Array[Material] = []
	for mi: Node in root.find_children("*", "MeshInstance3D", true, false):
		for i: int in (mi as MeshInstance3D).mesh.get_surface_count():
			out.append((mi as MeshInstance3D).get_active_material(i))
	return out


func test_toon_apply_replaces_all_materials() -> bool:
	var inst := (load("res://assets/monsters/blob/Mushnub.gltf") as PackedScene).instantiate()
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
