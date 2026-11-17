class_name Board
extends Node3D
## The board on the table: soil base, stone rim and the 8 lanes, plus the lanes' ambient particles.
## The room around it (light, environment, scenery) is Room.

const LANE_X: Array[float] = [-3.6, -1.2, 1.2, 3.6]
## Centre of each side's strips. Player 0 (human) is near the camera.
const STRIP_Z: Array[float] = [2.33, -2.33]
## Where creatures stand: near the centre line, facing off.
const SIDE_Z: Array[float] = [1.45, -1.45]
const CREATURE_Y := 0.58
var ambient: Ambient
var _islands: Array[Array] = [[], []]


func build(lands: Array[Array]) -> void:
	_build_base()
	_build_rim()
	for p: int in 2:
		for l: int in 4:
			var isl := Island.new()
			isl.position = Vector3(LANE_X[l], 0, STRIP_Z[p])
			add_child(isl)
			isl.setup(lands[p][l], p, l)
			_islands[p].append(isl)
	ambient = Ambient.build(lands, Settings.quality)
	add_child(ambient)
	apply_quality(Settings.quality)
	if not Settings.changed.is_connected(_on_settings_changed):
		Settings.changed.connect(_on_settings_changed)


## Low: half the ambient particles. (Light, shadows and MSAA are Room.apply_quality.)
func apply_quality(q: int) -> void:
	ambient.set_quality(q)


func _on_settings_changed() -> void:
	apply_quality(Settings.quality)


func island(player: int, lane: int) -> Island:
	return _islands[player][lane]


func anchor(player: int, lane: int) -> Vector3:
	return Vector3(LANE_X[lane], CREATURE_Y, SIDE_Z[player])


## World point a creature lunges to when attacking the hero behind `player`'s lane.
func hero_point(player: int, lane: int) -> Vector3:
	return Vector3(LANE_X[lane], CREATURE_Y, 3.6 if player == 0 else -3.6)


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


## Dark soil under the lane block, showing as borders between lanes.
func _build_base() -> void:
	add_child(Palette.mesh(_box(Vector3(9.8, 0.1, 9.3)), Toon.plain(Color("#5a4632")), Vector3(0, 0.05, 0), false))


## Low stone wall with a turf top around the lane block.
func _build_rim() -> void:
	var outer := Vector2(10.4, 9.9)
	var w: float = 0.35
	var h: float = 0.22
	var stone: ShaderMaterial = Toon.plain(Color("#c7b48e"))
	var turf: ShaderMaterial = Toon.plain(Color("#74c257"))
	var parts: Array[Array] = [
		[Vector3(outer.x, h, w), Vector3(0, h / 2.0, outer.y / 2.0 - w / 2.0)],
		[Vector3(outer.x, h, w), Vector3(0, h / 2.0, -outer.y / 2.0 + w / 2.0)],
		[Vector3(w, h, outer.y - 2.0 * w), Vector3(outer.x / 2.0 - w / 2.0, h / 2.0, 0)],
		[Vector3(w, h, outer.y - 2.0 * w), Vector3(-outer.x / 2.0 + w / 2.0, h / 2.0, 0)],
	]
	for part: Array in parts:
		var size: Vector3 = part[0]
		var pos: Vector3 = part[1]
		add_child(Palette.mesh(_box(size), stone, pos))
		add_child(Palette.mesh(_box(Vector3(size.x - 0.06, 0.05, size.z - 0.06)), turf, pos + Vector3(0, h / 2.0 + 0.02, 0), false))
