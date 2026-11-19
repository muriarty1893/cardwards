extends TestCase
## Board look 2, spec 2: each land look builds its named set pieces (rock-cluster fallback is not used).


func _pieces(land: int, v: int, p: int = 1, corner: int = 0) -> Node3D:
	var shape: TileShape = TileShape.of(BoardLayout.make(5), 1, Board.STRIP_Z[p])
	return LaneDressing.build(land, p, 3, 1.0, shape, v, corner)


static func _names(root: Node3D) -> Array[String]:
	var out: Array[String] = []
	for c: Node in root.get_node("SetPieces").get_children():
		out.append(String(c.name))
	return out


func _expect(land: int, v: int, wanted: Array[String], fx: bool) -> void:
	var root: Node3D = _pieces(land, v)
	var names: Array[String] = _names(root)
	assert_true(not "Rocks" in names, "land %d v%d has its own look (%s)" % [land, v, names])
	for w: String in wanted:
		var hit: bool = false
		for n: String in names:
			hit = hit or n.begins_with(w)
		assert_true(hit, "land %d v%d has %s (%s)" % [land, v, w, names])
	var fxs: int = root.find_children("*", "SetPieceFx", true, false).size()
	assert_true((fxs > 0) == fx, "land %d v%d timed effects %s (%d)" % [land, v, fx, fxs])
	root.free()


func test_ember_looks() -> bool:
	_expect(1, 0, ["Volcano"], true)
	_expect(1, 1, ["BasaltColumns", "Bridge"], false)
	_expect(1, 2, ["Ridge", "Vents", "Stumps"], true)
	return true


func test_mushroom_looks() -> bool:
	_expect(0, 0, ["Pond", "LongGrass", "Reeds"], false)
	_expect(0, 1, ["GiantShrooms", "Log", "FairyRing"], false)
	_expect(0, 2, ["Knoll", "Boulders"], false)
	return true


func test_frost_looks() -> bool:
	_expect(3, 0, ["Castle", "Drifts"], false)
	_expect(3, 1, ["FrozenLake", "Pines", "Watchtower"], false)
	_expect(3, 2, ["Ridge", "Crystals", "IceBoulders"], false)
	return true


func test_candy_looks() -> bool:
	_expect(2, 0, ["ChocolateRiver", "WaferBridge", "Gumdrops"], false)
	_expect(2, 1, ["Lollipops", "CaneFence", "FrostingHills"], false)
	_expect(2, 2, ["SundaePeak", "Donuts"], false)
	return true


## Pond Glade built without the bake step, so its parts can be inspected.
static func _pond_parts(seed: int, p: int = 1) -> Node3D:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var shape: TileShape = TileShape.of(BoardLayout.make(5), 1, Board.STRIP_Z[p])
	var ctx: Dictionary = SetPieces.context(0, 0, 0, p, shape, 1.0, rng)
	LandLooks.build(ctx)
	return ctx["root"]


func test_pond_shoreline_uneven() -> bool:
	for seed: float in [0.0, 1.3, 4.0]:
		var lo: float = INF
		var hi: float = 0.0
		for k: int in 64:
			var e: float = SetPieces.pond_edge(k * TAU / 64.0, seed)
			lo = minf(lo, e)
			hi = maxf(hi, e)
		assert_true(lo >= 0.62 and hi <= 0.99, "shoreline inside its quad (seed %.1f: %.2f..%.2f)" % [seed, lo, hi])
		assert_true(hi - lo >= 0.1, "shoreline is uneven, not an oval (seed %.1f: %.2f)" % [seed, hi - lo])
	assert_true(absf(SetPieces.pond_edge(1.0, 0.0) - SetPieces.pond_edge(1.0, 2.0)) > 0.01, "seeds give different shores")
	return true


func test_pond_bank_and_pads() -> bool:
	for seed: int in [3, 17, 88]:
		var root: Node3D = _pond_parts(seed)
		var pond: Node3D = root.get_node("Pond")
		var pool: MeshInstance3D = null
		for c: Node in pond.get_children():
			var sm := (c as MeshInstance3D).material_override as ShaderMaterial if c is MeshInstance3D else null
			if sm and sm.shader.resource_path.ends_with("pond.gdshader"):
				pool = c
		assert_true(pool != null, "seed %d has the water" % seed)
		var mat := pool.material_override as ShaderMaterial
		var shore_seed: float = mat.get_shader_parameter("shape_seed")
		var radii: Vector2 = mat.get_shader_parameter("radii")
		var stones: int = 0
		var pads: int = 0
		for c: Node in pond.get_children():
			var n := c as Node3D
			var v := Vector2(n.position.x / radii.x, n.position.z / radii.y)
			var edge: float = SetPieces.pond_edge(atan2(v.y, v.x), shore_seed)
			if String(c.name).begins_with("Stone"):
				stones += 1
				assert_true(absf(v.length() - edge) < edge * 0.1, "seed %d %s sits on the shore (%.2f vs %.2f)" % [seed, c.name, v.length(), edge])
			elif String(c.name).begins_with("LilyPad"):
				pads += 1
				assert_true(v.length() < edge * 0.9, "seed %d %s floats in open water" % [seed, c.name])
		assert_true(stones >= 5, "seed %d has bank stones (%d)" % [seed, stones])
		assert_true(pads >= 3, "seed %d has lily pads (%d)" % [seed, pads])
		root.free()
	return true


func test_lily_pad_notched() -> bool:
	var pad: MeshInstance3D = SetPieces.lily_pad(0.08, 0.0)
	var verts: PackedVector3Array = pad.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var angles: Array[float] = []
	for v: Vector3 in verts:
		if Vector2(v.x, v.z).length() > 0.04:
			angles.append(fposmod(atan2(v.z, v.x), TAU))
	angles.sort()
	var gap: float = angles[0] + TAU - angles[angles.size() - 1]
	for i: int in angles.size() - 1:
		gap = maxf(gap, angles[i + 1] - angles[i])
	assert_true(rad_to_deg(gap) >= 25.0, "pad has its notch (%.0f°)" % rad_to_deg(gap))
	assert_true(MeshBaker.is_plain(pad.get_active_material(0)), "pad bakes with the other plain parts")
	pad.free()
	return true
