extends TestCase
## The cottage room around the table: one environment and sun, props kept off the board,
## table props on the table, web-safe materials and a Low preset that thins the dust.


func _room(q: int = GameSettings.Quality.HIGH) -> Room:
	var room := Room.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(room)
	room.build(q)
	await (Engine.get_main_loop() as SceneTree).process_frame
	return room


static func _world_box(n: Node3D) -> AABB:
	return n.global_transform * Palette.bounds(n)


static func _xz(box: AABB) -> Rect2:
	return Rect2(box.position.x, box.position.z, box.size.x, box.size.z)


func test_room_builds_one_environment() -> bool:
	var room: Room = await _room()
	assert_eq(room.find_children("*", "WorldEnvironment", true, false).size(), 1, "one WorldEnvironment")
	assert_true(room.env != null, "env exposed")
	assert_true(room.sun != null, "sun exposed")
	room.free()
	return true


## The sun casts real shadows unless pieces use blob shadows instead (Compatibility / web).
func test_sun_shadows_or_blobs() -> bool:
	var room: Room = await _room()
	var shadowed: int = 0
	for n: Node in room.find_children("*", "DirectionalLight3D", true, false):
		if (n as DirectionalLight3D).shadow_enabled:
			shadowed += 1
	assert_eq(room.sun.shadow_enabled, BlobShadow.sun_shadows(), "sun shadows only where supported")
	assert_true(shadowed <= 1, "only the sun may cast shadows (%d)" % shadowed)
	assert_eq(room.find_children("*", "DirectionalLight3D", true, false).size(), 1, "one directional light (a second one costs ~8 ms a frame on integrated GPUs)")
	room.free()
	return true


## Nothing stands over the board: a prop whose footprint overlaps the board area stays below the tabletop.
func test_props_clear_of_board() -> bool:
	var room: Room = await _room()
	assert_true(room.props().size() >= 20, "room is furnished (%d props)" % room.props().size())
	for p: Node3D in room.props():
		var box: AABB = _world_box(p)
		if _xz(box).intersects(Room.BOARD_CLEAR):
			assert_true(box.end.y <= 0.01, "%s over the board (top %.2f)" % [p.name, box.end.y])
	room.free()
	return true


func test_table_props_on_table() -> bool:
	var room: Room = await _room()
	var n: int = 0
	for p: Node3D in room.props():
		if not p.get_meta(&"table", false):
			continue
		n += 1
		var box: AABB = _world_box(p)
		assert_true(Room.TABLE_RECT.encloses(_xz(box)), "%s inside the tabletop" % p.name)
		assert_true(absf(box.position.y) < 0.06, "%s rests on the tabletop (y %.2f)" % [p.name, box.position.y])
	assert_true(n >= 3, "at least 3 table props (%d)" % n)
	room.free()
	return true


## WebGL fits only ~256 instances with instance uniforms, so the room must use the plain toon shader.
func test_room_uses_no_instance_fx() -> bool:
	var room: Room = await _room()
	var fx: int = 0
	for n: Node in room.find_children("*", "GeometryInstance3D", true, false):
		var mats: Array[Material] = [(n as GeometryInstance3D).material_override]
		var mi := n as MeshInstance3D
		if mi and mi.mesh:
			for i: int in mi.mesh.get_surface_count():
				mats.append(mi.get_active_material(i))
		for m: Material in mats:
			var sm := m as ShaderMaterial
			if sm and sm.shader and sm.shader.resource_path in [Toon.FX_PATH, Toon.FX_CUTOUT_PATH]:
				fx += 1
				break
	assert_eq(fx, 0, "room meshes with per-instance fx")
	room.free()
	return true


func test_low_quality_halves_dust() -> bool:
	var room: Room = await _room()
	var high: int = room.dust_amount()
	room.apply_quality(GameSettings.Quality.LOW)
	var low: int = room.dust_amount()
	assert_true(high > 0, "dust at High")
	assert_true(low <= int(high * 0.55), "Low dust %d <= 55%% of %d" % [low, high])
	room.free()
	return true


func test_quality_presets() -> bool:
	var tree := Engine.get_main_loop() as SceneTree
	var room: Room = await _room()
	await tree.process_frame
	room.apply_quality(GameSettings.Quality.LOW)
	assert_true(not room.env.ssao_enabled, "low: no SSAO")
	assert_true(not room.env.glow_enabled, "low: no glow")
	assert_eq(room.get_viewport().msaa_3d, Viewport.MSAA_DISABLED, "low: no MSAA")
	room.apply_quality(GameSettings.Quality.HIGH)
	assert_true(room.env.ssao_enabled, "high: SSAO")
	assert_true(room.env.glow_enabled, "high: glow")
	assert_eq(room.get_viewport().msaa_3d, Viewport.MSAA_2X, "high: MSAA 2x")
	room.queue_free()
	await tree.process_frame
	return true
