class_name MeshBaker
extends RefCounted
## Bakes a scenery piece's many small plain-coloured toon meshes (cones, spheres, boxes) into one mesh, so the piece
## costs one draw call instead of dozens. Each part's colour goes into its vertex colours (sRGB, exact) under one
## shared toon material; vertices and normals are moved into the piece's space. Parts with other materials (textures,
## tints, sway, glows, water), with children, skins, blend shapes or a "no_bake" meta, hidden parts, particles and
## multimeshes are left as they are, so builders can still animate those.

const BAKED_NAME := "Baked"

static var _material: ShaderMaterial


## The material every baked mesh shares.
static func baked_material() -> ShaderMaterial:
	if _material == null:
		_material = Toon.material(null, Color.WHITE, Toon.NO_TINT, 0.0, true, 0.0, false, true)
	return _material


## Merges the plain toon meshes under `root` (not `root` itself) into one MeshInstance3D per shadow setting and
## render layer mask, added to `root`, and frees the originals. Returns how many meshes were merged; 0 (and nothing
## changes) when fewer than two qualify.
static func bake(root: Node3D) -> int:
	var groups: Dictionary = {}
	var found: Array[MeshInstance3D] = []
	_collect(root, Transform3D.IDENTITY, groups, found)
	if found.size() < 2:
		return 0
	var made: int = 0
	for key: String in groups:
		var items: Array = groups[key]
		var first: MeshInstance3D = items[0][0]
		var mi := MeshInstance3D.new()
		made += 1
		mi.name = BAKED_NAME if made == 1 else "%s%d" % [BAKED_NAME, made]
		mi.mesh = _merge(items)
		mi.material_override = baked_material()
		mi.cast_shadow = first.cast_shadow
		mi.layers = first.layers
		root.add_child(mi)
	for mi: MeshInstance3D in found:
		mi.get_parent().remove_child(mi)
		mi.free()
	return found.size()


## Walks `node`'s children with `xf` = node's transform in root space, sorting bakeable meshes into `groups`.
static func _collect(node: Node, xf: Transform3D, groups: Dictionary, found: Array[MeshInstance3D]) -> void:
	for child: Node in node.get_children():
		var n := child as Node3D
		if n == null or not n.visible or n.top_level:
			continue
		var cxf: Transform3D = xf * n.transform
		var mi := n as MeshInstance3D
		if mi and _bakeable(mi):
			var key: String = "%d|%d" % [mi.cast_shadow, mi.layers]
			if not groups.has(key):
				groups[key] = []
			(groups[key] as Array).append([mi, cxf])
			found.append(mi)
		else:
			_collect(n, cxf, groups, found)


static func _bakeable(mi: MeshInstance3D) -> bool:
	if mi.mesh == null or mi.get_child_count() > 0 or mi.has_meta(&"no_bake") or mi.skin != null:
		return false
	if mi.transparency > 0.0 or mi.mesh.get_surface_count() == 0:
		return false
	var am := mi.mesh as ArrayMesh
	if am and am.get_blend_shape_count() > 0:
		return false
	for i: int in mi.mesh.get_surface_count():
		if am and (am.surface_get_primitive_type(i) != Mesh.PRIMITIVE_TRIANGLES or (am.surface_get_format(i) & Mesh.ARRAY_FORMAT_NORMAL) == 0):
			return false
		if not is_plain(mi.get_active_material(i)):
			return false
	return true


## A shared toon material with just a colour: no texture, tint, sway, vertex colours, cutout or hit effects.
static func is_plain(m: Material) -> bool:
	var sm := m as ShaderMaterial
	if sm == null or sm.shader == null or sm.shader.resource_path != Toon.SHADER_PATH:
		return false
	if sm.get_shader_parameter("albedo_tex") != null or sm.get_shader_parameter("use_vertex_color"):
		return false
	var tint: Variant = sm.get_shader_parameter("tint")
	var sway: Variant = sm.get_shader_parameter("sway")
	return (tint == null or (tint as Color).a == 0.0) and (sway == null or float(sway) == 0.0)


## One triangle surface from `items` ([MeshInstance3D, transform in root space]).
static func _merge(items: Array) -> ArrayMesh:
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var cols := PackedColorArray()
	var idx := PackedInt32Array()
	for it: Array in items:
		var mi: MeshInstance3D = it[0]
		var xf: Transform3D = it[1]
		# Normals move with the inverse transpose (right under squash and stretch; under a uniform scale it is just
		# the rotation, so they stay unit length). A mirrored part is re-wound so its faces keep facing the way its
		# normals point.
		var nb: Basis = xf.basis.inverse().transposed()
		var similar: bool = _is_similarity(nb)
		if similar:
			nb = nb.scaled(Vector3.ONE / nb.x.length())
		var nxf := Transform3D(nb, Vector3.ZERO)
		var mirrored: bool = xf.basis.determinant() < 0.0
		for s: int in mi.mesh.get_surface_count():
			var arrays: Array = mi.mesh.surface_get_arrays(s)
			var v: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var base: int = verts.size()
			verts.append_array(xf * v)
			var tn: PackedVector3Array = nxf * (arrays[Mesh.ARRAY_NORMAL] as PackedVector3Array)
			if not similar:
				for k: int in tn.size():
					tn[k] = tn[k].normalized()
			norms.append_array(tn)
			var c := PackedColorArray()
			c.resize(v.size())
			c.fill((mi.get_active_material(s) as ShaderMaterial).get_shader_parameter("albedo_color"))
			cols.append_array(c)
			var src: Variant = arrays[Mesh.ARRAY_INDEX]
			var ind: PackedInt32Array = src if src is PackedInt32Array else PackedInt32Array()
			if ind.is_empty():
				ind.resize(v.size())
				for k: int in v.size():
					ind[k] = k
			if base > 0:
				for k: int in ind.size():
					ind[k] += base
			if mirrored:
				for t: int in range(0, ind.size() - 2, 3):
					var tmp: int = ind[t + 1]
					ind[t + 1] = ind[t + 2]
					ind[t + 2] = tmp
			idx.append_array(ind)
	var arr: Array = []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_NORMAL] = norms
	arr[Mesh.ARRAY_COLOR] = cols
	arr[Mesh.ARRAY_INDEX] = idx
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	return mesh


## True when `b` is a rotation (or mirror) times one uniform scale: its columns are equally long and at right angles.
static func _is_similarity(b: Basis) -> bool:
	var lx: float = b.x.length()
	if lx < 0.000001:
		return false
	var tol: float = lx * 0.0001
	return absf(b.y.length() - lx) < tol and absf(b.z.length() - lx) < tol \
		and absf(b.x.dot(b.y)) < tol * lx and absf(b.x.dot(b.z)) < tol * lx and absf(b.y.dot(b.z)) < tol * lx
