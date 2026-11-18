class_name Board
extends Node3D
## The board: a wooden tray on the table holding 8 land tiles (4 lanes, each split at the middle
## into your half and the rival's), a glowing seam along the middle, and the lanes' ambient
## particles. Each half-lane has a building spot at its back (owner's edge), a roam zone in front
## of it for the creature, and (your side) a boop button spot. The room around it is Room.

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
## Boop plate: centred across your lane at this z (world), between the roam zone and the building row.
const PLATE_Z := 4.0
## The roam zone stops this much short of the building row, leaving room for the plate.
const ROAM_BACK := 0.45
## A creature house sits this far right of the lane centre, a little seam-side of the tile
## centre; creatures with a house roam a zone this much narrower on that side.
const HOUSE_X := 0.88
const HOUSE_Z := 2.2
const HOUSE_CLEAR := 0.5
## Origin height of a creature view (its feet are on the tile surface, Island.TOP_Y).
const CREATURE_Y := 0.58
const FRAME := Color("#8a5a34")
const FRAME_DARK := Color("#5b3a22")
const BRASS := Color("#e0b04a")
const SEAM_COLOR := Color("#ffe9a8")
## Split reveal: line draw time, tile settle drop and stagger.
const SPLIT_TIME := 0.6
const SETTLE_DROP := 0.03
const SETTLE_STAGGER := 0.08
## Ground cover within this distance of a creature leans away from it.
const BEND_R := 0.4
## Emitted when the split reveal (lines drawn, tiles settled) has finished.
signal split_done

var ambient: Ambient
var separators: Separators
## True once the board has split into lanes after the opening sweep.
var split_revealed: bool = false
## The lane shapes for this match (river curves; straight until build() gets one).
var layout: BoardLayout = BoardLayout.straight()
var _density: float = -1.0
var _islands: Array[Array] = [[], []]
var _plates: Array[BoopPlate] = []


func build(lands: Array[Array], layout_: BoardLayout = null) -> void:
	if layout_:
		layout = layout_
	_density = density_for(Settings.quality)
	_build_tray()
	for p: int in 2:
		for l: int in 4:
			var isl := Island.new()
			isl.position = Vector3(lane_x(l), 0, STRIP_Z[p])
			add_child(isl)
			isl.setup(lands[p][l], p, l, _density, TileShape.of(layout, l, STRIP_Z[p]))
			_islands[p].append(isl)
	separators = Separators.new()
	add_child(separators)
	separators.build(layout)
	for l: int in 4:
		var plate := BoopPlate.new()
		var bp: Vector3 = boop_point(l)
		plate.position.x = bp.x
		plate.position.z = bp.z
		add_child(plate)
		_plates.append(plate)
	var xs: Array[float] = []
	for l: int in 4:
		xs.append(lane_x(l))
	ambient = Ambient.build(lands, Settings.quality, xs)
	add_child(ambient)
	apply_quality(Settings.quality)
	if not Settings.changed.is_connected(_on_settings_changed):
		Settings.changed.connect(_on_settings_changed)


## Splits each side's slab into its four lanes: the separator lines draw outward from the seam and the tiles do a
## small staggered settle (spec 1.3). Instant when `animate` is false. Emits split_done when finished.
func reveal_split(animate: bool) -> void:
	split_revealed = true
	if not animate or not is_inside_tree():
		separators.reveal = 1.0
		for p: int in 2:
			for isl: Island in _islands[p]:
				isl.position.y = 0.0
		for plate: BoopPlate in _plates:
			plate.rise(false)
		split_done.emit()
		return
	separators.reveal = 0.0
	var tw := create_tween()
	tw.tween_property(separators, "reveal", 1.0, SPLIT_TIME).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	for p: int in 2:
		for l: int in 4:
			var isl: Island = _islands[p][l]
			# Middle lanes first, then the outer ones; your side a beat after the rival's.
			var order: int = (0 if l == 1 or l == 2 else 1) + p
			var settle := isl.create_tween()
			settle.tween_interval(order * SETTLE_STAGGER)
			settle.tween_property(isl, "position:y", -SETTLE_DROP, 0.09).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			settle.tween_property(isl, "position:y", 0.0, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	await tw.finished
	for plate: BoopPlate in _plates:
		plate.rise(true)
	await get_tree().create_timer(0.3).timeout
	split_done.emit()


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


## Animates player p's lane into `land`, spreading from `origin` (a world point on the tile; the
## tile centre when not finite), and swaps its ambient particles.
func change_land(p: int, l: int, land: int, origin: Vector3 = Vector3.INF, animate: bool = true) -> void:
	var o := Vector2.ZERO
	if origin.is_finite():
		o = Vector2(origin.x - lane_x(l), origin.z - STRIP_Z[p])
	island(p, l).change_land(land, o, animate)
	ambient.set_land(p, l, land)


## Lays a field's weather over every tile (-1 clears it).
func set_field(land: int, animate: bool = true) -> void:
	for p: int in 2:
		for isl: Island in _islands[p]:
			isl.set_field(land, animate)


func island(player: int, lane: int) -> Island:
	return _islands[player][lane]


## The lane's centre ignoring the wobble (where its tiles sit).
func lane_x(lane: int) -> float:
	return layout.base_centre(lane)


## Centre of the creature's roam zone, at a creature view's origin height.
func anchor(player: int, lane: int) -> Vector3:
	var c: Vector2 = roam_rect(player, lane).get_center()
	return Vector3(c.x, CREATURE_Y, c.y)


## Where `player`'s creature in `lane` may wander (world x/z): the half-lane's front part (seam
## side), inset from the lane edges and the seam.
func roam_rect(player: int, lane: int) -> Rect2:
	var s: float = 1.0 if player == 0 else -1.0
	var near: float = SEAM / 2.0 + ROAM_INSET
	var far: float = SEAM / 2.0 + Island.LENGTH * (1.0 - BUILDING_DEPTH) - 0.1 - ROAM_BACK
	var z0: float = minf(near * s, far * s)
	var span: Vector2 = layout.inner_span(lane, z0, z0 + far - near)
	return Rect2(span.x + ROAM_INSET, z0, span.y - span.x - 2.0 * ROAM_INSET, far - near)


## Centre of the half-lane's back part (owner's edge), on the tile surface.
func building_point(player: int, lane: int) -> Vector3:
	var s: float = 1.0 if player == 0 else -1.0
	var z: float = (SEAM / 2.0 + Island.LENGTH * (1.0 - BUILDING_DEPTH / 2.0)) * s
	return Vector3(layout.centre_x(lane, z), Island.TOP_Y, z)


## Where a creature's house stands (tile surface).
func house_point(player: int, lane: int) -> Vector3:
	var z: float = HOUSE_Z * (1.0 if player == 0 else -1.0)
	return Vector3(layout.right_x(lane, z) - (Island.WIDTH / 2.0 - HOUSE_X), Island.TOP_Y, z)


## The centre of the human's boop plate in `lane`.
func boop_point(lane: int) -> Vector3:
	return Vector3(layout.centre_x(lane, PLATE_Z), Island.TOP_Y, PLATE_Z)


func boop_plate(lane: int) -> BoopPlate:
	return _plates[lane]


## The lane of the boop plate under world point `pos`, or -1.
func plate_at(pos: Vector3) -> int:
	if not pos.is_finite():
		return -1
	for l: int in _plates.size():
		if _plates[l].contains(pos):
			return l
	return -1


## World point a creature lunges to when attacking the hero behind `player`'s lane: just past
## the tray edge on that side.
func hero_point(player: int, lane: int) -> Vector3:
	return Vector3(lane_x(lane), CREATURE_Y, 6.6 if player == 0 else -6.6)


## The point on the tile surface under `screen_pos` (Vector3.INF if the ray misses the plane).
func ground_at_screen(cam: Camera3D, screen_pos: Vector2) -> Vector3:
	var origin: Vector3 = cam.project_ray_origin(screen_pos)
	var dir: Vector3 = cam.project_ray_normal(screen_pos)
	if absf(dir.y) < 0.0001:
		return Vector3.INF
	var t: float = (Island.TOP_Y - origin.y) / dir.y
	if t < 0.0:
		return Vector3.INF
	return origin + dir * t


func lane_at_screen(cam: Camera3D, screen_pos: Vector2) -> Dictionary:
	var hit: Vector3 = ground_at_screen(cam, screen_pos)
	if not hit.is_finite():
		return {}
	return lane_at_world(hit)


## {"player", "lane"} of the tile under world x/z, or {} (the seam, or off the board).
func lane_at_world(pos: Vector3) -> Dictionary:
	for p: int in 2:
		if absf(pos.z - STRIP_Z[p]) <= Island.LENGTH / 2.0:
			var l: int = layout.lane_at(pos.x, pos.z)
			return {} if l < 0 else {"player": p, "lane": l}
	return {}


func _box(size: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = size
	return b


## Wooden tray: a dark base under the tiles, a raised frame with brass corner caps and a glowing seam across the
## middle. Lanes meet edge to edge; Separators draw the lines between them.
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
		add_child(Palette.mesh(_box(part[0]), wood, part[1], false))
	for corner: Vector2 in [r.position, Vector2(r.end.x, r.position.y), Vector2(r.position.x, r.end.y), r.end]:
		var inward := Vector2(signf(c.x - corner.x), signf(c.y - corner.y)) * (w / 2.0)
		add_child(Palette.mesh(_box(Vector3(w + 0.1, h + 0.08, w + 0.1)), brass, Vector3(corner.x + inward.x, (h + 0.08) / 2.0, corner.y + inward.y), false))
	# The seam: a thin warm glow across the middle.
	var seam_mat := StandardMaterial3D.new()
	seam_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	seam_mat.albedo_color = SEAM_COLOR
	add_child(Palette.mesh(_box(Vector3(r.size.x - 2.0 * w, 0.04, SEAM * 0.6)), seam_mat, Vector3(c.x, Island.TOP_Y + 0.01, 0.0), false))
