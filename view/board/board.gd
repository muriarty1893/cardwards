class_name Board
extends Node3D
## The board: a wooden tray on the table holding 8 land tiles (4 lanes, each split at the middle
## into your half and the rival's), a glowing seam along the middle, and the lanes' ambient
## particles. Each half-lane has a building spot at its back (owner's edge), a roam zone in front
## of it for the creature, and (your side) a boop button spot. The room around it is Room.

const LANE_X: Array[float] = [-4.05, -1.35, 1.35, 4.05]
## Width of the glowing seam between the two halves (z = 0).
const SEAM := 0.3
## Centre of each side's tiles. Player 0 (human) is near the camera.
const STRIP_Z: Array[float] = [2.85, -2.85]
## The wooden tray around the tiles (world x/z).
const TRAY_RECT := Rect2(-6.0, -6.1, 12.0, 12.2)
## The back of each half-lane (owner's edge) holds the building; the rest is the roam zone.
const BUILDING_DEPTH := 0.25
## Roam zone inset from the lane edges and the seam.
const ROAM_INSET := 0.25
## Boop button spot: this far left of the lane centre, level with the building.
const BOOP_X := -0.95
## Origin height of a creature view (its feet are on the tile surface, Island.TOP_Y).
const CREATURE_Y := 0.58
const FRAME := Color("#8a5a34")
const FRAME_DARK := Color("#5b3a22")
const BRASS := Color("#e0b04a")
const SEAM_COLOR := Color("#ffe9a8")
## Ground cover within this distance of a creature leans away from it.
const BEND_R := 0.4
var ambient: Ambient
var _density: float = -1.0
var _islands: Array[Array] = [[], []]


func build(lands: Array[Array]) -> void:
	_density = density_for(Settings.quality)
	_build_tray()
	for p: int in 2:
		for l: int in 4:
			var isl := Island.new()
			isl.position = Vector3(LANE_X[l], 0, STRIP_Z[p])
			add_child(isl)
			isl.setup(lands[p][l], p, l, _density)
			_islands[p].append(isl)
	ambient = Ambient.build(lands, Settings.quality)
	add_child(ambient)
	apply_quality(Settings.quality)
	if not Settings.changed.is_connected(_on_settings_changed):
		Settings.changed.connect(_on_settings_changed)


## Low: half the ambient particles and ground cover. (Light, shadows and MSAA are Room's.)
func apply_quality(q: int) -> void:
	ambient.set_quality(q)
	var d: float = density_for(q)
	if d != _density:
		_density = d
		for p: int in 2:
			for isl: Island in _islands[p]:
				isl.set_density(d)


static func density_for(q: int) -> float:
	return 0.5 if q == GameSettings.Quality.LOW else 1.0


## Up to 8 creature positions the ground cover bends away from (radius BEND_R).
func set_bend_points(points: PackedVector3Array) -> void:
	var arr: Array[Vector4] = []
	for i: int in 8:
		if i < points.size():
			arr.append(Vector4(points[i].x, points[i].y, points[i].z, BEND_R))
		else:
			arr.append(Vector4.ZERO)
	LaneDressing.cover_material().set_shader_parameter("bend_points", arr)


func _on_settings_changed() -> void:
	apply_quality(Settings.quality)


func island(player: int, lane: int) -> Island:
	return _islands[player][lane]


## Centre of the creature's roam zone, at a creature view's origin height.
func anchor(player: int, lane: int) -> Vector3:
	var c: Vector2 = roam_rect(player, lane).get_center()
	return Vector3(c.x, CREATURE_Y, c.y)


## Where `player`'s creature in `lane` may wander (world x/z): the half-lane's front part (seam
## side), inset from the lane edges and the seam.
func roam_rect(player: int, lane: int) -> Rect2:
	var s: float = 1.0 if player == 0 else -1.0
	var near: float = SEAM / 2.0 + ROAM_INSET
	var far: float = SEAM / 2.0 + Island.LENGTH * (1.0 - BUILDING_DEPTH) - 0.1
	var z0: float = minf(near * s, far * s)
	var w: float = Island.WIDTH - 2.0 * ROAM_INSET
	return Rect2(LANE_X[lane] - w / 2.0, z0, w, far - near)


## Centre of the half-lane's back part (owner's edge), on the tile surface.
func building_point(player: int, lane: int) -> Vector3:
	var s: float = 1.0 if player == 0 else -1.0
	var z: float = SEAM / 2.0 + Island.LENGTH * (1.0 - BUILDING_DEPTH / 2.0)
	return Vector3(LANE_X[lane], Island.TOP_Y, z * s)


## The human's boop button spot in `lane`, beside the building.
func boop_point(lane: int) -> Vector3:
	var b: Vector3 = building_point(0, lane)
	return Vector3(LANE_X[lane] + BOOP_X, Island.TOP_Y, b.z)


## World point a creature lunges to when attacking the hero behind `player`'s lane: just past
## the tray edge on that side.
func hero_point(player: int, lane: int) -> Vector3:
	return Vector3(LANE_X[lane], CREATURE_Y, 6.6 if player == 0 else -6.6)


func lane_at_screen(cam: Camera3D, screen_pos: Vector2) -> Dictionary:
	var origin: Vector3 = cam.project_ray_origin(screen_pos)
	var dir: Vector3 = cam.project_ray_normal(screen_pos)
	if absf(dir.y) < 0.0001:
		return {}
	var t: float = (Island.TOP_Y - origin.y) / dir.y
	if t < 0.0:
		return {}
	var hit: Vector3 = origin + dir * t
	for p: int in 2:
		for l: int in 4:
			if island(p, l).contains(hit.x - LANE_X[l], hit.z - STRIP_Z[p]):
				return {"player": p, "lane": l}
	return {}


func _box(size: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = size
	return b


## Wooden tray: a dark base under the tiles (showing as thin gaps between lanes), a raised frame
## with brass corner caps, low dividers between lanes and a glowing seam across the middle.
func _build_tray() -> void:
	var r: Rect2 = TRAY_RECT
	var wood: ShaderMaterial = Toon.plain(FRAME)
	var dark: ShaderMaterial = Toon.plain(FRAME_DARK)
	var brass: ShaderMaterial = Toon.plain(BRASS)
	add_child(Palette.mesh(_box(Vector3(r.size.x, 0.12, r.size.y)), dark, Vector3(r.get_center().x, 0.06, r.get_center().y), false))
	var w: float = 0.42
	var h: float = 0.3
	var c: Vector2 = r.get_center()
	var sides: Array[Array] = [
		[Vector3(r.size.x, h, w), Vector3(c.x, h / 2.0, r.end.y - w / 2.0)],
		[Vector3(r.size.x, h, w), Vector3(c.x, h / 2.0, r.position.y + w / 2.0)],
		[Vector3(w, h, r.size.y - 2.0 * w), Vector3(r.end.x - w / 2.0, h / 2.0, c.y)],
		[Vector3(w, h, r.size.y - 2.0 * w), Vector3(r.position.x + w / 2.0, h / 2.0, c.y)],
	]
	for part: Array in sides:
		add_child(Palette.mesh(_box(part[0]), wood, part[1]))
	for corner: Vector2 in [r.position, Vector2(r.end.x, r.position.y), Vector2(r.position.x, r.end.y), r.end]:
		var inward := Vector2(signf(c.x - corner.x), signf(c.y - corner.y)) * (w / 2.0)
		add_child(Palette.mesh(_box(Vector3(w + 0.1, h + 0.08, w + 0.1)), brass, Vector3(corner.x + inward.x, (h + 0.08) / 2.0, corner.y + inward.y)))
	# Low dividers between lanes.
	for i: int in 3:
		var x: float = (LANE_X[i] + LANE_X[i + 1]) / 2.0
		add_child(Palette.mesh(_box(Vector3(0.08, 0.2, r.size.y - 2.0 * w)), dark, Vector3(x, 0.1, c.y), false))
	# The seam: a thin warm glow across the middle.
	var seam_mat := StandardMaterial3D.new()
	seam_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	seam_mat.albedo_color = SEAM_COLOR
	add_child(Palette.mesh(_box(Vector3(r.size.x - 2.0 * w, 0.04, SEAM * 0.6)), seam_mat, Vector3(c.x, Island.TOP_Y + 0.01, 0.0), false))
