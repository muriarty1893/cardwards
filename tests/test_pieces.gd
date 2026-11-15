extends TestCase
## Creatures and buildings come from VisualDB with toon materials and level-based sizes.


func test_creature_heights_and_toon() -> bool:
	for c: CardData in CardDB.all_cards():
		if not c.is_creature():
			continue
		var v := CreatureView.create(c)
		var box: AABB = Palette.bounds(v.body)
		var h: float = box.size.y * v.body.scale.y
		var w: float = maxf(box.size.x, box.size.z) * v.body.scale.x
		var full_height: bool = absf(h - CreatureView.HEIGHTS[c.level]) < 0.03
		var width_capped: bool = h < CreatureView.HEIGHTS[c.level] and absf(w - CreatureView.MAX_WIDTH) < 0.03
		assert_true(full_height or width_capped, "%s height %f width %f" % [c.id, h, w])
		for mi: Node in v.body.find_children("*", "MeshInstance3D", true, false):
			var m := (mi as MeshInstance3D).get_active_material(0) as ShaderMaterial
			assert_true(m != null and m.shader.resource_path == Toon.SHADER_PATH, "%s toon" % c.id)
		v.free()
	return true

func test_missing_model_fallback() -> bool:
	var v := CreatureView.create(CardDB.card(&"cinderpup"), "res://nope.gltf")
	assert_true(v.body != null, "fallback body")
	v.free()
	return true

func test_fidget_respects_busy() -> bool:
	var v := CreatureView.create(CardDB.card(&"gumdrop"))
	v.busy = true
	assert_true(not v.fidget(), "no fidget while busy")
	v.free()
	return true
