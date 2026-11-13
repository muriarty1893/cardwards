class_name Palette
extends RefCounted
## Shared colours for the toy-diorama look.

const LAND_TOP: Array[Color] = [Color("#7bd36a"), Color("#ff7a3a"), Color("#ffb3dd"), Color("#dff4ff")]
const LAND_SIDE: Array[Color] = [Color("#8a5a3a"), Color("#5a3a3a"), Color("#c88a5a"), Color("#7aa0c0")]
const LAND_CARD: Array[Color] = [Color("#7bd36a"), Color("#ff8a4a"), Color("#ff9fcf"), Color("#9fd8ff")]
const SKY := Color("#8fd3ff")
const MEADOW := Color("#9be07a")
const SLAB := Color("#c89a6a")
const INK := Color("#223333")
const PAPER := Color("#fff8e8")
const GOLD := Color("#ffcf3a")
const HP := Color("#e5384f")
const MAGIC := Color("#3a7bff")


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
