extends TestCase
## MeshBaker: a set piece's plain-coloured toon meshes become one vertex-coloured mesh (fewer draw calls) that looks
## the same: same shape where it stood, same colours, normals facing the same way.


## Visible leaf meshes under `root` drawn only with plain-colour toon materials (no texture, tint, sway or vertex
## colours): the parts a bake should have merged.
static func _plain_meshes(root: Node) -> Array[MeshInstance3D]:
	var out: Array[MeshInstance3D] = []
	for n: Node in root.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if not mi.is_visible_in_tree() or mi.get_child_count() > 0:
			continue
		var plain: bool = true
		for i: int in mi.mesh.get_surface_count():
			var sm := mi.get_active_material(i) as ShaderMaterial
			plain = plain and sm != null and sm.shader != null and sm.shader.resource_path == Toon.SHADER_PATH \
				and sm.get_shader_parameter("albedo_tex") == null and not sm.get_shader_parameter("use_vertex_color") \
				and (sm.get_shader_parameter("tint") as Color).a == 0.0 and float(sm.get_shader_parameter("sway")) == 0.0
		if plain:
			out.append(mi)
	return out


## Box around every mesh vertex under `root`, in root space.
static func _vertex_box(root: Node3D) -> AABB:
	var box := AABB()
	var first: bool = true
	for n: Node in root.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		var xf := Transform3D.IDENTITY
		var p: Node = mi
		while p != root:
			xf = (p as Node3D).transform * xf
			p = p.get_parent()
		for s: int in mi.mesh.get_surface_count():
			for v: Vector3 in xf * (mi.mesh.surface_get_arrays(s)[Mesh.ARRAY_VERTEX] as PackedVector3Array):
				if first:
					box = AABB(v, Vector3.ZERO)
					first = false
				else:
					box = box.expand(v)
	return box


## A piece like the builders make: a scaled, turned holder with three coloured primitives, a glow mesh and particles.
static func _piece() -> Node3D:
	var root := Node3D.new()
	var body := Node3D.new()
	body.scale = Vector3(1.0, 1.0, 1.4)
	body.rotation.y = 0.7
	body.position = Vector3(0.2, 0.0, -0.1)
	root.add_child(body)
	body.add_child(SetPieces.cyl(0.1, 0.3, 0.6, Color("#7a4636"), Vector3.ZERO, 12))
	body.add_child(SetPieces.sphere(0.12, Color("#8a7c80"), Vector3(0.3, 0.05, 0.0), Vector3(1.0, 0.6, 1.0), 8))
	root.add_child(SetPieces.box(Vector3(0.2, 0.1, 0.3), Color("#ffcf3a"), Vector3(-0.4, 0.0, 0.2)))
	var glow := Palette.mesh(Palette.sphere(0.05, 8), SetPieceFx.glow(Color("#ff7a1a")), Vector3(0, 0.6, 0), false)
	glow.name = "Glow"
	body.add_child(glow)
	var sparks := CPUParticles3D.new()
	sparks.name = "Sparks"
	root.add_child(sparks)
	return root


func test_bake_merges_plain_meshes() -> bool:
	var root: Node3D = _piece()
	var box_before: AABB = _vertex_box(root)
	var merged: int = MeshBaker.bake(root)
	assert_eq(merged, 3, "three plain meshes merged")
	var plain: Array[MeshInstance3D] = _plain_meshes(root)
	assert_eq(plain.size(), 0, "no separate plain meshes left")
	var baked: Array[Node] = root.find_children(MeshBaker.BAKED_NAME + "*", "MeshInstance3D", true, false)
	assert_eq(baked.size(), 1, "one baked mesh")
	assert_true(root.find_child("Glow", true, false) != null, "glow mesh kept (its material is animated)")
	assert_true(root.find_child("Sparks", true, false) != null, "particles kept")
	var box_after: AABB = _vertex_box(root)
	assert_true(box_after.position.distance_to(box_before.position) < 0.002 and box_after.size.distance_to(box_before.size) < 0.002, "same space covered (%s vs %s)" % [box_after, box_before])
	root.free()
	return true


func test_baked_colours_and_material() -> bool:
	var root: Node3D = _piece()
	MeshBaker.bake(root)
	var mi := root.find_child(MeshBaker.BAKED_NAME + "*", true, false) as MeshInstance3D
	var arrays: Array = mi.mesh.surface_get_arrays(0)
	var cols: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
	var seen := {}
	for c: Color in cols:
		seen[c.to_html(false)] = true
	assert_eq(seen.size(), 3, "three colours kept (%s)" % [seen.keys()])
	for want: String in ["7a4636", "8a7c80", "ffcf3a"]:
		assert_true(seen.has(want), "colour %s kept exactly (sRGB in the vertex colour)" % want)
	var sm := mi.get_active_material(0) as ShaderMaterial
	assert_true(sm != null and sm.shader.resource_path == Toon.SHADER_PATH, "toon material")
	assert_true(sm.get_shader_parameter("use_vertex_color") and sm.get_shader_parameter("vertex_color_srgb"), "uses sRGB vertex colours")
	assert_eq(sm.get_shader_parameter("albedo_color"), Color.WHITE, "white albedo")
	assert_true(sm == MeshBaker.baked_material(), "one shared material for every baked mesh")
	root.free()
	return true


func test_baked_normals_follow_transform() -> bool:
	# A sphere squashed to half height and turned: every vertex normal is the ellipsoid's true normal there
	# (x/a², y/b², z/c² in the sphere's own frame), unit length.
	var root := Node3D.new()
	var holder := Node3D.new()
	holder.rotation = Vector3(0.0, 1.1, 0.0)
	root.add_child(holder)
	holder.add_child(SetPieces.sphere(0.5, Color.RED, Vector3.ZERO, Vector3(1.0, 0.5, 1.0), 12))
	holder.add_child(SetPieces.sphere(0.2, Color.BLUE, Vector3(2.0, 0.0, 0.0), Vector3.ONE, 8))
	MeshBaker.bake(root)
	var mi := root.find_child(MeshBaker.BAKED_NAME + "*", true, false) as MeshInstance3D
	var arrays: Array = mi.mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var norms: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var rot: Basis = holder.basis
	var checked: int = 0
	var worst: float = 1.0
	var top_y: float = -1.0
	for i: int in verts.size():
		if verts[i].length() > 0.6:
			continue   # the blue sphere
		var p: Vector3 = rot.inverse() * verts[i]
		var want: Vector3 = (rot * Vector3(p.x / 0.25, p.y / 0.0625, p.z / 0.25)).normalized()
		worst = minf(worst, norms[i].dot(want))
		assert_true(absf(norms[i].length() - 1.0) < 0.01, "unit normal (%s)" % norms[i])
		top_y = maxf(top_y, verts[i].y)
		checked += 1
	assert_true(checked > 50, "red sphere vertices checked (%d)" % checked)
	assert_true(worst > 0.999, "normals match the squashed shape (worst dot %.4f)" % worst)
	assert_true(absf(top_y - 0.25) < 0.01, "squashed top at 0.25 (%.3f)" % top_y)
	root.free()
	return true


func test_mirrored_parts_keep_facing() -> bool:
	# A mirrored (negative scale) part: triangles are re-wound so their faces still point along their normals.
	var root := Node3D.new()
	root.add_child(SetPieces.box(Vector3(0.4, 0.4, 0.4), Color.RED, Vector3.ZERO))
	var mirrored := SetPieces.box(Vector3(0.4, 0.4, 0.4), Color.BLUE, Vector3(1.0, 0.0, 0.0))
	mirrored.scale = Vector3(-1.0, 1.0, 1.0)
	root.add_child(mirrored)
	MeshBaker.bake(root)
	var mi := root.find_child(MeshBaker.BAKED_NAME + "*", true, false) as MeshInstance3D
	var arrays: Array = mi.mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var norms: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var bad: int = 0
	for t: int in idx.size() / 3:
		var a: int = idx[t * 3]
		var b: int = idx[t * 3 + 1]
		var c: int = idx[t * 3 + 2]
		# Godot's front faces wind clockwise: the face normal (b - a) x (c - a) points against the vertex normals.
		var fn: Vector3 = (verts[b] - verts[a]).cross(verts[c] - verts[a])
		if fn.length() < 0.000001:
			continue
		if fn.dot(norms[a] + norms[b] + norms[c]) > 0.0:
			bad += 1
	assert_eq(bad, 0, "every triangle winds the same way as on the original meshes")
	root.free()
	return true


func test_bake_leaves_special_meshes() -> bool:
	var root := Node3D.new()
	var keep := SetPieces.box(Vector3.ONE * 0.2, Color.RED, Vector3.ZERO)
	keep.name = "Keep"
	keep.set_meta("no_bake", true)
	root.add_child(keep)
	var parent := SetPieces.box(Vector3.ONE * 0.2, Color.GREEN, Vector3(1, 0, 0))
	parent.name = "Parent"
	parent.add_child(SetPieces.box(Vector3.ONE * 0.1, Color.BLUE, Vector3(0, 0.3, 0)))
	root.add_child(parent)
	var hidden := SetPieces.box(Vector3.ONE * 0.2, Color.WHITE, Vector3(2, 0, 0))
	hidden.name = "Hidden"
	hidden.visible = false
	root.add_child(hidden)
	var swaying := SetPieces.mesh(Palette.sphere(0.1, 8), Color.WHITE)
	swaying.material_override = Toon.plain(Color.WHITE, 0.05)
	swaying.name = "Swaying"
	root.add_child(swaying)
	root.add_child(SetPieces.box(Vector3.ONE * 0.2, Color.YELLOW, Vector3(3, 0, 0)))
	var merged: int = MeshBaker.bake(root)
	assert_eq(merged, 2, "only the plain leaf meshes merged (the child box and the yellow box)")
	for n: String in ["Keep", "Parent", "Hidden", "Swaying"]:
		assert_true(root.find_child(n, true, false) != null, "%s kept" % n)
	root.free()
	return true


func test_bake_splits_by_shadow() -> bool:
	var root := Node3D.new()
	root.add_child(SetPieces.box(Vector3.ONE * 0.2, Color.RED, Vector3.ZERO))
	root.add_child(SetPieces.box(Vector3.ONE * 0.2, Color.GREEN, Vector3(1, 0, 0)))
	var flat := SetPieces.box(Vector3.ONE * 0.2, Color.BLUE, Vector3(2, 0, 0))
	flat.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(flat)
	var flat2 := SetPieces.box(Vector3.ONE * 0.2, Color.BLUE, Vector3(3, 0, 0))
	flat2.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(flat2)
	MeshBaker.bake(root)
	var baked: Array[Node] = root.find_children(MeshBaker.BAKED_NAME + "*", "MeshInstance3D", true, false)
	assert_eq(baked.size(), 2, "one baked mesh per shadow setting")
	var settings := {}
	for b: Node in baked:
		settings[(b as MeshInstance3D).cast_shadow] = true
	assert_eq(settings.size(), 2, "shadow settings kept")
	root.free()
	return true


func test_single_mesh_untouched() -> bool:
	var root := Node3D.new()
	var only := SetPieces.box(Vector3.ONE * 0.2, Color.RED, Vector3.ZERO)
	only.name = "Only"
	root.add_child(only)
	assert_eq(MeshBaker.bake(root), 0, "nothing to gain from one mesh")
	assert_true(root.get_node_or_null("Only") != null, "left as it was")
	root.free()
	return true


## Every land look: each set piece draws its plain-coloured parts with at most one mesh per shadow setting.
func test_set_pieces_are_baked() -> bool:
	var lay: BoardLayout = BoardLayout.make(5)
	var before_total: int = 0
	for land: int in 4:
		for v: int in LaneDressing.VARIANTS:
			for p: int in 2:
				var shape: TileShape = TileShape.of(lay, 1, Board.STRIP_Z[p])
				var root: Node3D = LaneDressing.build(land, p, 3, 1.0, shape, v, 0)
				for piece: Node in root.get_node("SetPieces").get_children():
					var plain: Array[MeshInstance3D] = _plain_meshes(piece)
					if piece is MeshInstance3D and plain.has(piece):
						plain.erase(piece)
					var baked: int = piece.find_children(MeshBaker.BAKED_NAME + "*", "MeshInstance3D", true, false).size()
					# A lone plain part is left alone (nothing to gain); otherwise none may be left unbaked.
					assert_true(plain.size() == 0 or (plain.size() == 1 and baked == 0), "land %d v%d p%d: %s has no unbaked plain meshes (%d)" % [land, v, p, piece.name, plain.size()])
					before_total += baked
				root.free()
	assert_true(before_total > 0, "looks have baked meshes")
	return true
