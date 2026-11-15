class_name LaneDressing
extends RefCounted
## Props for one lane, by land, placed along its edges in lane-local space. They stay clear
## of the creature spot, the building spot and (human side) the boop button.

## Per land: [model path under res://assets (or "crystal"), height]. CC0: Quaternius, Kenney.
const PROPS: Array[Array] = [
	[["nature/Mushroom_Common", 0.34], ["nature/Mushroom_Common", 0.24], ["nature/Clover_1", 0.2], ["nature/Clover_2", 0.2]],
	[["nature/Rock_Medium_1", 0.3], ["nature/Rock_Medium_2", 0.26], ["nature/Rock_Medium_3", 0.22]],
	[["candy/lollypop.glb", 0.44], ["candy/cupcake.glb", 0.26], ["candy/donut-sprinkles.glb", 0.14], ["candy/ice-cream.glb", 0.36], ["candy/popsicle.glb", 0.36], ["candy/candy-bar.glb", 0.1], ["candy/sundae.glb", 0.3]],
	[["crystal", 0.42], ["nature/Rock_Medium_2", 0.24], ["crystal", 0.32], ["nature/Rock_Medium_3", 0.2]],
]
## Rock and crystal tints per land (alpha = strength).
const TINTS: Array[Color] = [Color(1, 1, 1, 0), Color("#3a2626", 0.75), Color(1, 1, 1, 0), Color("#e4f3ff", 0.65)]
const SWAY: Array[float] = [0.05, 0.0, 0.0, 0.0]
const HALF := Vector2(1.1, 2.15)
const CREATURE_R := 0.8
const BUILDING_R := 0.6
const BOOP_R := 0.5


static func build(land: int, player: int, seed: int) -> Node3D:
	var root := Node3D.new()
	root.name = "Dressing"
	var rng := RandomNumberGenerator.new()
	rng.seed = 9100 + seed
	var count: int = 7 + rng.randi_range(0, 3)
	var options: Array = PROPS[land]
	var placed: int = 0
	var guard: int = 0
	while placed < count and guard < 400:
		guard += 1
		var side: float = -1.0 if rng.randf() < 0.5 else 1.0
		var pos := Vector3(side * rng.randf_range(0.78, 1.04), 0.0, rng.randf_range(-HALF.y, HALF.y))
		if not is_clear(pos, player):
			continue
		var pick: Array = options[rng.randi_range(0, options.size() - 1)]
		var prop: Node3D = _make(pick[0], pick[1] * rng.randf_range(0.85, 1.2), land)
		prop.position = pos
		prop.rotation.y = rng.randf() * TAU
		root.add_child(prop)
		placed += 1
	return root


static func is_clear(local: Vector3, player: int) -> bool:
	if absf(local.x) > HALF.x or absf(local.z) > HALF.y:
		return false
	var s: float = 1.0 if player == 0 else -1.0
	var cz: float = Board.SIDE_Z[player] - Board.STRIP_Z[player]
	var p := Vector2(local.x, local.z)
	if p.distance_to(Vector2(0.0, cz)) < CREATURE_R:
		return false
	if p.distance_to(Vector2(BuildingView.OFFSET.x * s, cz + BuildingView.OFFSET.z * s)) < BUILDING_R:
		return false
	if player == 0 and p.distance_to(Vector2(UnitOverlay.BOOP_OFFSET.x, cz + UnitOverlay.BOOP_OFFSET.z)) < BOOP_R:
		return false
	return true


static func prop_positions(root: Node3D) -> Array[Vector3]:
	var out: Array[Vector3] = []
	for c: Node in root.get_children():
		out.append((c as Node3D).position)
	return out


static func _make(path: String, height: float, land: int) -> Node3D:
	if path == "crystal":
		return _crystal(height)
	var full: String = "res://assets/%s" % (path if path.contains(".") else path + ".gltf")
	var mdl: Node3D = Palette.model(full, height)
	Toon.apply(mdl, TINTS[land], SWAY[land])
	return mdl


## A small cluster of pointed ice prisms.
static func _crystal(height: float) -> Node3D:
	var holder := Node3D.new()
	var ice: ShaderMaterial = Toon.plain(Color("#7cc4f0"))
	var tilts: Array[Vector3] = [Vector3(0, 0, 0), Vector3(0.35, 0, 0.25), Vector3(-0.3, 0, -0.35)]
	var scales: Array[float] = [1.0, 0.7, 0.55]
	for i: int in 3:
		var h: float = height * scales[i]
		var prism := Palette.mesh(Palette.cylinder(0.0, h * 0.22, h, 5), ice, Vector3(0.06 * i - 0.06, h / 2.0, 0.05 * (i % 2)))
		prism.rotation = tilts[i]
		holder.add_child(prism)
	return holder
