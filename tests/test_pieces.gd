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
			assert_true(m != null and m.shader.resource_path in [Toon.FX_PATH, Toon.FX_CUTOUT_PATH], "%s fx toon" % c.id)
		v.free()
	return true

func test_blob_shadows_where_sun_casts_none() -> bool:
	for forced: bool in [false, true]:
		BlobShadow.force_blobs = forced
		var want: bool = not BlobShadow.sun_shadows()
		if forced:
			assert_true(want, "forcing blobs turns sun shadows off")
		var cv := CreatureView.create(CardDB.card(&"cinderpup"))
		assert_eq(cv.find_child("BlobShadow", false, false) != null, want, "creature blob (forced %s)" % forced)
		cv.free()
		for c: CardData in CardDB.all_cards():
			if c.kind == CardData.Kind.BUILDING:
				var bv := BuildingView.create(c)
				assert_eq(bv.find_child("BlobShadow", false, false) != null, want, "building blob (forced %s)" % forced)
				bv.free()
				break
	BlobShadow.force_blobs = false
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


func test_death_does_not_return_to_idle() -> bool:
	var tree := Engine.get_main_loop() as SceneTree
	var v := CreatureView.create(CardDB.card(&"gumdrop"))
	tree.root.add_child(v)
	await tree.process_frame
	var ap := v.body.find_child("AnimationPlayer", true, false) as AnimationPlayer
	assert_true(v.play_death() > 0.0, "gumdrop has a death clip")
	ap.animation_finished.emit(&"Death")
	assert_eq(ap.current_animation, &"Death", "still on the death pose after it ends")
	v.queue_free()
	await tree.process_frame
	return true
