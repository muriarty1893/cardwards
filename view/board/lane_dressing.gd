class_name LaneDressing
extends RefCounted
## What grows on one half-lane tile, by land, in tile-local space:
## - Cover: dense MultiMesh pieces (tufts, tiny mushrooms, moss / rocks, glowing vents, dry
##   tufts / sprinkles, gumdrops, lollipop trees / snowdrifts, ice crystals, frosty tufts). They
##   share one material (cover_material) that sways and bends away from creatures.
## - Accents: a few model props (Quaternius, Kenney; CC0) along the long edges.
## Nothing goes on the building spot or the boop spot.

## Accent models per land: [model path under res://assets (or "crystal"), height].
const PROPS: Array[Array] = [
	[["nature/Mushroom_Common", 0.34], ["nature/Mushroom_Common", 0.24], ["nature/Clover_1", 0.2], ["nature/Clover_2", 0.2]],
	[["nature/Rock_Medium_1", 0.3], ["nature/Rock_Medium_2", 0.26], ["nature/Rock_Medium_3", 0.22]],
	[["candy/lollypop.glb", 0.44], ["candy/cupcake.glb", 0.26], ["candy/donut-sprinkles.glb", 0.14], ["candy/ice-cream.glb", 0.36], ["candy/popsicle.glb", 0.36], ["candy/candy-bar.glb", 0.1], ["candy/sundae.glb", 0.3]],
	[["crystal", 0.42], ["nature/Rock_Medium_2", 0.24], ["crystal", 0.32], ["nature/Rock_Medium_3", 0.2]],
]
## Rock and crystal tints per land (alpha = strength).
const TINTS: Array[Color] = [Color(1, 1, 1, 0), Color("#3a2626", 0.75), Color(1, 1, 1, 0), Color("#e4f3ff", 0.65)]
const SWAY: Array[float] = [0.05, 0.0, 0.0, 0.0]
const HALF := Vector2(Island.WIDTH / 2.0 - 0.06, Island.LENGTH / 2.0 - 0.12)
const BUILDING_R := 0.8
const BOOP_R := 0.45
## Cover pieces per half-lane at High (Low passes density 0.5): Mushroom, Ember, Candy, Frost.
const DENSITY: Array[int] = [160, 90, 120, 110]
## Tall cover keeps within this distance of the lane's long edges.
const EDGE_BAND := 0.35
## Per land: [mesh kind, share of DENSITY, min size, max size, flexibility, edge only, colours].
const KINDS: Array = [
	[[&"tuft", 0.66, 0.16, 0.28, 1.0, false, ["#62c443", "#7ad552", "#4faa39"]],
		[&"mushroom", 0.2, 0.1, 0.17, 0.15, false, ["#ffffff", "#ffe2c6"]],
		[&"moss", 0.14, 0.14, 0.28, 0.0, false, ["#57a845", "#62b04c"]]],
	[[&"rock", 0.5, 0.08, 0.2, 0.0, false, ["#3a2c2a", "#4b3a34", "#2e2422"]],
		[&"vent", 0.17, 0.14, 0.26, 0.0, false, ["#ff8a2a"]],
		[&"tuft", 0.33, 0.12, 0.22, 0.8, false, ["#b5652e", "#8f4a22", "#c9813a"]]],
	[[&"sprinkle", 0.55, 0.7, 1.1, 0.0, false, ["#ff5a7a", "#ffd84a", "#5ad1ff", "#7aff7a", "#c38cff", "#ffffff"]],
		[&"gumdrop", 0.33, 0.08, 0.14, 0.0, false, ["#ff5a7a", "#ffd84a", "#5ad1ff", "#7aff7a", "#c38cff"]],
		[&"lollipop", 0.12, 0.3, 0.5, 0.35, true, ["#ffffff"]]],
	[[&"drift", 0.2, 0.1, 0.22, 0.0, false, ["#ffffff", "#eef6ff"]],
		[&"crystal", 0.36, 0.12, 0.3, 0.25, false, ["#9fd8ff", "#c6ecff", "#7cc4f0"]],
		[&"tuft", 0.44, 0.12, 0.2, 0.9, false, ["#cfe8f2", "#e6f4fa", "#b7dbe8"]]],
]

static var _material: ShaderMaterial
static var _glow: StandardMaterial3D
static var _meshes: Dictionary = {}


## The shared cover material (Board.set_bend_points writes its bend_points).
static func cover_material() -> ShaderMaterial:
	if _material == null:
		_material = ShaderMaterial.new()
		_material.shader = load("res://view/board/dressing.gdshader") as Shader
		var empty: Array[Vector4] = []
		empty.resize(8)
		empty.fill(Vector4.ZERO)
		_material.set_shader_parameter("bend_points", empty)
	return _material


static func build(land: int, player: int, seed: int, density: float = 1.0) -> Node3D:
	var root := Node3D.new()
	root.name = "Dressing"
	var rng := RandomNumberGenerator.new()
	rng.seed = 9100 + seed
	root.add_child(_accents(land, player, rng))
	var cover := Node3D.new()
	cover.name = "Cover"
	root.add_child(cover)
	for kind: Array in KINDS[land]:
		var n: int = int(round(DENSITY[land] * float(kind[1]) * density))
		if n > 0:
			cover.add_child(_cover(kind, n, player, rng))
	return root


static func _accents(land: int, player: int, rng: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	root.name = "Accents"
	var count: int = 4 + rng.randi_range(0, 2)
	var options: Array = PROPS[land]
	var placed: int = 0
	var guard: int = 0
	while placed < count and guard < 400:
		guard += 1
		var side: float = -1.0 if rng.randf() < 0.5 else 1.0
		var pos := Vector3(side * rng.randf_range(HALF.x - 0.22, HALF.x), 0.0, rng.randf_range(-HALF.y, HALF.y))
		if not is_clear(pos, player):
			continue
		var pick: Array = options[rng.randi_range(0, options.size() - 1)]
		var prop: Node3D = _make(pick[0], pick[1] * rng.randf_range(0.85, 1.2), land)
		prop.position = pos
		prop.rotation.y = rng.randf() * TAU
		root.add_child(prop)
		placed += 1
	return root


static func _cover(kind: Array, n: int, player: int, rng: RandomNumberGenerator) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	mm.mesh = _mesh(kind[0])
	mm.instance_count = n
	var colors: Array = kind[6]
	var edge_only: bool = kind[5]
	for i: int in n:
		var pos := Vector3.ZERO
		for t: int in 60:
			var x: float = rng.randf_range(-HALF.x, HALF.x)
			if edge_only:
				x = signf(rng.randf() - 0.5) * rng.randf_range(Island.WIDTH / 2.0 - EDGE_BAND, HALF.x)
			pos = Vector3(x, 0.0, rng.randf_range(-HALF.y, HALF.y))
			if is_clear(pos, player):
				break
		var k: float = rng.randf_range(kind[2], kind[3])
		var basis := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * k)
		mm.set_instance_transform(i, Transform3D(basis, pos))
		var c := Color(colors[rng.randi_range(0, colors.size() - 1)]).srgb_to_linear()
		var shade: float = rng.randf_range(0.88, 1.08)
		mm.set_instance_custom_data(i, Color(c.r * shade, c.g * shade, c.b * shade, float(kind[4])))
	var mmi := MultiMeshInstance3D.new()
	mmi.name = String(kind[0]).capitalize()
	mmi.multimesh = mm
	mmi.material_override = _glow_material() if kind[0] == &"vent" else cover_material()
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mmi


## Tile-local test: not on the building spot (back of the half-lane) or the boop spot.
static func is_clear(local: Vector3, player: int) -> bool:
	if absf(local.x) > HALF.x or absf(local.z) > HALF.y:
		return false
	# Tile-local spots (the tile centre is LANE_X, STRIP_Z): building at the back, boop beside it.
	var s: float = 1.0 if player == 0 else -1.0
	var back_z: float = (Board.SEAM / 2.0 + Island.LENGTH * (1.0 - Board.BUILDING_DEPTH / 2.0)) * s - Board.STRIP_Z[player]
	var p := Vector2(local.x, local.z)
	if p.distance_to(Vector2(0.0, back_z)) < BUILDING_R:
		return false
	if player == 0 and p.distance_to(Vector2(Board.BOOP_X, back_z)) < BOOP_R:
		return false
	return true


## Positions of the accent props (not the cover).
static func prop_positions(root: Node3D) -> Array[Vector3]:
	var out: Array[Vector3] = []
	var accents: Node = root.get_node_or_null("Accents")
	if accents == null:
		return out
	for c: Node in accents.get_children():
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


# --- cover meshes (unit size, base at y = 0, vertex colours in linear space) --------------

static func _glow_material() -> StandardMaterial3D:
	if _glow == null:
		_glow = StandardMaterial3D.new()
		_glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_glow.albedo_color = Color("#ff8a2a")
		_glow.emission_enabled = true
		_glow.emission = Color("#ff6a1a")
	return _glow


static func _mesh(kind: StringName) -> Mesh:
	if _meshes.has(kind):
		return _meshes[kind]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	match kind:
		&"tuft":
			for i: int in 5:
				var a: float = float(i) / 5.0 * TAU + 0.3
				var lean := Vector3(cos(a), 0.0, sin(a)) * 0.35
				var side := Vector3(-sin(a), 0.0, cos(a)) * 0.13
				_tri(st, -side, side, lean * 1.4 + Vector3(0, 1.0 - 0.12 * (i % 2), 0), Color(0.55, 0.55, 0.55), Color(0.55, 0.55, 0.55), Color(1.05, 1.05, 1.05))
		&"mushroom":
			_append(st, Palette.cylinder(0.16, 0.2, 0.55, 8), Transform3D(Basis(), Vector3(0, 0.275, 0)), Color("#fff1d6").srgb_to_linear())
			var cap := SphereMesh.new()
			cap.radius = 0.45
			cap.height = 0.45
			cap.is_hemisphere = true
			cap.radial_segments = 10
			cap.rings = 3
			_append(st, cap, Transform3D(Basis(), Vector3(0, 0.5, 0)), Color("#e4503a").srgb_to_linear())
		&"moss":
			_append(st, _blob(1.0, 0.12, 8, 3), Transform3D(), Color(0.95, 0.95, 0.95))
		&"rock", &"drift":
			_append(st, _blob(1.0, 0.65 if kind == &"rock" else 0.35, 6 if kind == &"rock" else 10, 3), Transform3D(), Color(1, 1, 1))
		&"vent":
			_append(st, Palette.cylinder(1.0, 1.0, 0.04, 10), Transform3D(Basis(), Vector3(0, 0.03, 0)), Color(1, 1, 1))
		&"sprinkle":
			var b := BoxMesh.new()
			b.size = Vector3(0.12, 0.035, 0.035)
			_append(st, b, Transform3D(Basis(), Vector3(0, 0.02, 0)), Color(1, 1, 1))
		&"gumdrop":
			var g := SphereMesh.new()
			g.radius = 1.0
			g.height = 1.4
			g.is_hemisphere = true
			g.radial_segments = 10
			g.rings = 4
			_append(st, g, Transform3D(), Color(1, 1, 1))
		&"lollipop":
			_append(st, Palette.cylinder(0.035, 0.035, 0.75, 6), Transform3D(Basis(), Vector3(0, 0.375, 0)), Color(1, 1, 1))
			for r: int in 3:
				var col: Color = Color("#ff5a9a").srgb_to_linear() if r % 2 == 0 else Color(1, 1, 1)
				_append(st, Palette.cylinder(0.32 - 0.1 * r, 0.32 - 0.1 * r, 0.07 + 0.01 * r, 14), Transform3D(Basis(Vector3.RIGHT, PI / 2.0), Vector3(0, 0.95, 0.005 * r)), col)
		&"crystal":
			for i: int in 3:
				var h: float = [1.0, 0.7, 0.55][i]
				var tilt := Basis(Vector3(0.35 * (i - 1), 0, 0.3 * (i % 2)).normalized() if i > 0 else Vector3.UP, 0.35 if i > 0 else 0.0)
				_append(st, Palette.cylinder(0.0, h * 0.24, h, 5), Transform3D(tilt, Vector3(0.08 * i - 0.08, h / 2.0, 0.06 * (i % 2))), Color(1, 1, 1))
	st.generate_normals()
	var mesh: Mesh = st.commit()
	_meshes[kind] = mesh
	return mesh


static func _tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, ca: Color, cb: Color, cc: Color) -> void:
	for v: Array in [[a, ca], [b, cb], [c, cc]]:
		st.set_color(v[1])
		st.add_vertex(v[0])


## Every triangle of `src` (surface 0), transformed, with one vertex colour.
static func _append(st: SurfaceTool, src: PrimitiveMesh, xf: Transform3D, col: Color) -> void:
	var arrays: Array = src.get_mesh_arrays()
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	st.set_color(col)
	if idx.is_empty():
		for v: Vector3 in verts:
			st.add_vertex(xf * v)
		return
	for i: int in idx:
		st.add_vertex(xf * verts[i])


## A squashed low-poly dome: radius `r`, height `h`.
static func _blob(r: float, h: float, segments: int, rings: int) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = h * 2.0
	s.is_hemisphere = true
	s.radial_segments = segments
	s.rings = rings
	return s
