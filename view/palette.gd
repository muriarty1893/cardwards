class_name Palette
extends RefCounted
## Shared colours for the toy-diorama look.

## Indexed by CardData.Land; the last entry is NEUTRAL (gold).
const LAND_TOP: Array[Color] = [Color("#7bd36a"), Color("#ff7a3a"), Color("#ffb3dd"), Color("#dff4ff"), Color("#ffcf3a"), Color("#f0cf86")]
const LAND_SIDE: Array[Color] = [Color("#8a5a3a"), Color("#5a3a3a"), Color("#c88a5a"), Color("#7aa0c0"), Color("#8a6a2a"), Color("#b98a52")]
const LAND_CARD: Array[Color] = [Color("#7bd36a"), Color("#ff8a4a"), Color("#ff9fcf"), Color("#9fd8ff"), Color("#ffcf3a"), Color("#e8b465")]
const SKY := Color("#8fd3ff")
const MEADOW := Color("#9be07a")
const SLAB := Color("#c89a6a")
const INK := Color("#223333")
const PAPER := Color("#fff8e8")
const GOLD := Color("#ffcf3a")
const HP := Color("#e5384f")
const MAGIC := Color("#3a7bff")
const TRAY := Color("#2d2a55")
const TRAY_DARK := Color("#171533")
const TRAY_LIGHT := Color("#4d489a")
const GREEN := Color("#3ad16a")


static func mat(c: Color, roughness: float = 0.8, flat: bool = false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = roughness
	if flat:
		m.shading_mode = BaseMaterial3D.SHADING_MODE_PER_VERTEX
	return m


static func mesh(m: Mesh, material: Material, pos: Vector3 = Vector3.ZERO, shadows: bool = true) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = m
	mi.material_override = material
	mi.position = pos
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	return mi


static func cylinder(top_r: float, bottom_r: float, h: float, segments: int = 24) -> CylinderMesh:
	var c := CylinderMesh.new()
	c.top_radius = top_r
	c.bottom_radius = bottom_r
	c.height = h
	c.radial_segments = segments
	return c


static func sphere(r: float, segments: int = 20) -> SphereMesh:
	var s := SphereMesh.new()
	s.radius = r
	s.height = r * 2.0
	s.radial_segments = segments
	s.rings = segments / 2
	return s


## Bounding box of every mesh under `root`, in `root`'s local space (root's own transform ignored).
static func bounds(root: Node) -> AABB:
	return _bounds(root, Transform3D.IDENTITY, true)


static func _bounds(n: Node, xf: Transform3D, is_root: bool) -> AABB:
	var out := AABB()
	var first: bool = true
	var here: Transform3D = xf
	if n is Node3D and not is_root:
		here = xf * (n as Node3D).transform
	if n is MeshInstance3D:
		out = _mesh_box_xf(n as MeshInstance3D, xf, here) * (n as MeshInstance3D).get_aabb()
		first = false
	for c: Node in n.get_children():
		var sub: AABB = _bounds(c, here, false)
		if sub.size == Vector3.ZERO:
			continue
		out = sub if first else out.merge(sub)
		first = false
	return out


## Where a mesh's box is drawn: `here` (its own place), except for a mesh skinned to its parent skeleton, which is
## drawn through its first bone's binding (some FBX rigs bind with a scale, e.g. the cute Mushroom at 0.58).
## `parent_xf` is the skeleton's place.
static func _mesh_box_xf(mi: MeshInstance3D, parent_xf: Transform3D, here: Transform3D) -> Transform3D:
	var skel := mi.get_parent() as Skeleton3D
	if mi.skin == null or skel == null or mi.skin.get_bind_count() == 0 or mi.get_node_or_null(mi.skeleton) != skel:
		return here
	var b: int = mi.skin.get_bind_bone(0)
	if b < 0:
		b = skel.find_bone(mi.skin.get_bind_name(0))
	if b < 0:
		return here
	return parent_xf * skel.get_bone_global_rest(b) * mi.skin.get_bind_pose(0)


## Instance a model scene scaled to fit `height` (and `max_width` if > 0), base at y = 0, centred on x/z.
static func model(path: String, height: float, max_width: float = 0.0) -> Node3D:
	var holder := Node3D.new()
	var inst := (load(path) as PackedScene).instantiate() as Node3D
	holder.add_child(inst)
	var box: AABB = bounds(inst)
	var k: float = height / maxf(box.size.y, 0.01)
	if max_width > 0.0:
		k = minf(k, max_width / maxf(maxf(box.size.x, box.size.z), 0.01))
	inst.scale = Vector3.ONE * k
	var c: Vector3 = box.get_center()
	inst.position = Vector3(-c.x * k, -box.position.y * k, -c.z * k)
	return holder
