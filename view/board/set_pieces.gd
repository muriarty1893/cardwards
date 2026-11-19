class_name SetPieces
extends RefCounted
## Each land's big features (board look 2, spec 2): 3 looks per land, built from toon-shaded primitives and CC0
## models in tile-local space. Pieces go in a back corner (beside the building and boop plate) or the thin bands
## along the lane's sides, never in the roam zone, on the building, house or plate. Every top-level piece carries a
## "footprint" meta (tile-local Rect2 on the ground) so tests and the ground cover can keep clear of it.

## Corner boxes keep this far from the lane centre (building ±0.5, plate ±0.59).
const CLEAR_X := 0.64
const EDGE_IN := 0.05
## Side pieces keep this far (z) from the creature house's centre.
const HOUSE_CLEAR := 0.34
## Tall pieces on your side (near the camera) are scaled down so they never hide your creatures.
const NEAR_SCALE := 0.9


## The pieces for `land`'s look `variant`; empty for Meadow. `corner` 0 = left back corner, 1 = right.
static func build(land: int, variant: int, corner: int, player: int, shape: TileShape, density: float, rng: RandomNumberGenerator) -> Node3D:
	var root := Node3D.new()
	root.name = "SetPieces"
	if land == Lands.MEADOW:
		return root
	var ctx := {
		"land": land, "variant": variant, "corner": corner, "player": player, "shape": shape,
		"density": density, "rng": rng, "root": root,
		"box": corner_box(shape, player, corner),
		"other_box": corner_box(shape, player, 1 - corner),
		"band": edge_band(shape, player, corner),
		"other_band": edge_band(shape, player, 1 - corner),
		"scale": NEAR_SCALE if player == 0 else 1.0,
	}
	if not LandLooks.build(ctx):
		rocks(ctx, ctx["box"], 3)
	# Each piece's plain-coloured parts become one mesh (a full board drew ~250 of them one by one). Pieces stay
	# separate nodes: they pop up one by one when a land changes.
	for piece: Node in root.get_children():
		if piece is Node3D:
			MeshBaker.bake(piece)
	return root


# --- zones (tile-local) ---------------------------------------------------------------------------

## The back corner beside the building and the boop plate, as a tile-local rect.
static func corner_box(shape: TileShape, player: int, corner: int) -> Rect2:
	var lay: BoardLayout = shape.layout
	var roam: Rect2 = Board.roam_rect_for(lay, player, shape.lane)
	var half: float = Island.LENGTH / 2.0
	var z0: float
	var z1: float
	if player == 0:
		z0 = roam.end.y - shape.tile_z + 0.06
		z1 = half - 0.1
	else:
		z0 = -half + 0.1
		z1 = roam.position.y - shape.tile_z - 0.06
	var inner: Vector2 = lay.inner_span(shape.lane, shape.tile_z + z0, shape.tile_z + z1)
	var bz: float = Board.building_point_for(lay, player, shape.lane).z - shape.tile_z
	var pz: float = Board.PLATE_Z - shape.tile_z
	var c_lo: float = minf(shape.centre(bz), shape.centre(pz))
	var c_hi: float = maxf(shape.centre(bz), shape.centre(pz))
	var x0: float
	var x1: float
	if corner == 0:
		x0 = inner.x - shape.tile_x + EDGE_IN
		x1 = c_lo - CLEAR_X
	else:
		x0 = c_hi + CLEAR_X
		x1 = inner.y - shape.tile_x - EDGE_IN
	return Rect2(x0, z0, maxf(x1 - x0, 0.05), z1 - z0)


## The thin strip between the roam zone and the lane's `side` edge (0 left, 1 right), along the roam zone.
static func edge_band(shape: TileShape, player: int, side: int) -> Rect2:
	var lay: BoardLayout = shape.layout
	var roam: Rect2 = Board.roam_rect_for(lay, player, shape.lane)
	var inner: Vector2 = lay.inner_span(shape.lane, roam.position.y, roam.end.y)
	var z0: float = roam.position.y - shape.tile_z + 0.05
	var z1: float = roam.end.y - shape.tile_z - 0.05
	if side == 0:
		var a: float = inner.x - shape.tile_x + 0.03
		var b: float = roam.position.x - shape.tile_x - 0.02
		return Rect2(a, z0, maxf(b - a, 0.02), z1 - z0)
	var c: float = roam.end.x - shape.tile_x + 0.02
	var d: float = inner.y - shape.tile_x - 0.03
	# The creature house stands on the right side: keep to the longer stretch beside it.
	var hz: float = Board.house_point_for(lay, player, shape.lane).z - shape.tile_z
	var a0: float = z0
	var a1: float = hz - HOUSE_CLEAR
	var b0: float = hz + HOUSE_CLEAR
	var b1: float = z1
	if a1 - a0 >= b1 - b0:
		return Rect2(c, a0, maxf(d - c, 0.02), a1 - a0)
	return Rect2(c, b0, maxf(d - c, 0.02), b1 - b0)


## The side the corner box is on (-1 left, +1 right), for pieces that face the lane centre.
static func corner_sign(ctx: Dictionary) -> float:
	return -1.0 if int(ctx["corner"]) == 0 else 1.0


# --- kit --------------------------------------------------------------------------------------------

## Adds `node` as a piece at tile-local `pos` with ground footprint `fp` (clamped into `within`).
static func add_piece(ctx: Dictionary, node: Node3D, pos: Vector3, fp: Rect2, within: Rect2) -> Node3D:
	node.position = pos
	node.set_meta("footprint", fp.intersection(within) if within.intersects(fp) else Rect2(within.get_center(), Vector2.ZERO))
	(ctx["root"] as Node3D).add_child(node)
	return node


static func mesh(m: Mesh, color: Color, pos: Vector3 = Vector3.ZERO, shadows: bool = true) -> MeshInstance3D:
	return Palette.mesh(m, Toon.plain(color), pos, shadows)


static func sphere(r: float, color: Color, pos: Vector3, squash: Vector3 = Vector3.ONE, segments: int = 14) -> MeshInstance3D:
	var mi := mesh(Palette.sphere(r, segments), color, pos)
	mi.scale = squash
	return mi


static func cone(r: float, h: float, color: Color, pos: Vector3, segments: int = 12) -> MeshInstance3D:
	return mesh(Palette.cylinder(0.0, r, h, segments), color, pos + Vector3(0, h / 2.0, 0))


static func cyl(r_top: float, r_bottom: float, h: float, color: Color, pos: Vector3, segments: int = 14) -> MeshInstance3D:
	return mesh(Palette.cylinder(r_top, r_bottom, h, segments), color, pos + Vector3(0, h / 2.0, 0))


static func box(size: Vector3, color: Color, pos: Vector3) -> MeshInstance3D:
	var b := BoxMesh.new()
	b.size = size
	return mesh(b, color, pos + Vector3(0, size.y / 2.0, 0))


## A CC0 model (path under res://assets) toon-shaded and scaled to `height`.
static func model(path: String, height: float, tint: Color = Toon.NO_TINT, sway: float = 0.0) -> Node3D:
	var full: String = "res://assets/%s" % (path if path.contains(".") else path + ".gltf")
	var mdl: Node3D = Palette.model(full, height)
	Toon.apply(mdl, tint, sway)
	return mdl


## A flat pool (0 water, 1 ice, 2 chocolate) filling an ellipse of radii (rx, rz) at y just above the ground.
static func pool(kind: int, rx: float, rz: float) -> MeshInstance3D:
	var q := QuadMesh.new()
	q.size = Vector2(rx * 2.0, rz * 2.0)
	q.orientation = PlaneMesh.FACE_Y
	var m := ShaderMaterial.new()
	m.shader = load("res://view/board/pond.gdshader") as Shader
	m.set_shader_parameter("kind", kind)
	m.set_shader_parameter("cell_tex", NoiseBank.cells())
	var mi := Palette.mesh(q, m, Vector3(0, 0.012, 0), false)
	return mi


## Tall swaying grass (the cover's tuft, bending away from creatures) scattered in `area`.
static func long_grass(ctx: Dictionary, area: Rect2, n: int, colors: Array, h: Vector2 = Vector2(0.38, 0.62)) -> MultiMeshInstance3D:
	var rng: RandomNumberGenerator = ctx["rng"]
	n = int(round(n * float(ctx["density"])))
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = true
	mm.use_colors = true
	mm.mesh = LaneDressing._mesh(&"tuft")
	mm.instance_count = maxi(n, 1)
	for i: int in mm.instance_count:
		var pos := Vector3(rng.randf_range(area.position.x, area.end.x), 0.0, rng.randf_range(area.position.y, area.end.y))
		var k: float = rng.randf_range(h.x, h.y) * float(ctx["scale"])
		var basis := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(k * 0.7, k, k * 0.7))
		mm.set_instance_transform(i, Transform3D(basis, pos))
		var c := Color(colors[rng.randi_range(0, colors.size() - 1)]).srgb_to_linear()
		mm.set_instance_custom_data(i, Color(c.r, c.g, c.b, 1.0))
		mm.set_instance_color(i, Color.WHITE)
	var mmi := MultiMeshInstance3D.new()
	mmi.multimesh = mm
	mmi.material_override = LaneDressing.cover_material()
	mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mmi


## A storybook toadstool: cream stem, round cap with white spots, base at y = 0.
static func toadstool(h: float, cap: Color, rng: RandomNumberGenerator) -> Node3D:
	var t := Node3D.new()
	var stem_r: float = h * 0.13
	t.add_child(cyl(stem_r * 0.85, stem_r * 1.15, h * 0.72, Color("#f3e6c8"), Vector3.ZERO, 10))
	var cr: float = h * 0.42
	t.add_child(sphere(cr, cap, Vector3(0, h * 0.72, 0), Vector3(1.0, 0.62, 1.0), 16))
	for i: int in 5:
		var a: float = rng.randf() * TAU
		var e: float = rng.randf_range(0.25, 0.85)
		var dir := Vector3(cos(a) * e, 0.0, sin(a) * e)
		var pos := Vector3(dir.x * cr, h * 0.72 + cr * 0.62 * sqrt(maxf(1.0 - e * e, 0.0)), dir.z * cr)
		t.add_child(sphere(cr * 0.14, Color("#fff8ec"), pos, Vector3(1.0, 0.5, 1.0), 8))
	return t


## A small cluster of `n` rocks inside `area` (the fallback look).
static func rocks(ctx: Dictionary, area: Rect2, n: int) -> void:
	var rng: RandomNumberGenerator = ctx["rng"]
	var holder := Node3D.new()
	holder.name = "Rocks"
	var r: float = minf(area.size.x, area.size.y) * 0.22
	for i: int in n:
		var p := Vector3(rng.randf_range(area.position.x + r, area.end.x - r), 0.0, rng.randf_range(area.position.y + r, area.end.y - r))
		holder.add_child(sphere(r * rng.randf_range(0.6, 1.0), Color("#7a6e66"), p + Vector3(0, r * 0.3, 0), Vector3(1.0, 0.6, 1.0)))
	add_piece(ctx, holder, Vector3.ZERO, area, area)
