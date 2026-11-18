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
