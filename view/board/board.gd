class_name Board
extends Node3D
## The diorama: environment, light, meadow, slab and the 8 islands.

const LANE_X: Array[float] = [-3.9, -1.3, 1.3, 3.9]
## Player 0 (human) is near the camera.
const SIDE_Z: Array[float] = [1.6, -2.8]
const CREATURE_Y := 0.58

var _islands: Array[Array] = [[], []]


func build(lands: Array[Array]) -> void:
	_build_environment()
	_build_scenery()
	var slab := Palette.mesh(_box(Vector3(11, 0.5, 8.6)), Palette.mat(Palette.SLAB, 0.9), Vector3(0, -0.55, -0.6))
	add_child(slab)
	add_child(Palette.mesh(_box(Vector3(10.6, 0.05, 0.12)), Palette.mat(Color.WHITE), Vector3(0, -0.28, -0.6), false))
	for p: int in 2:
		for l: int in 4:
			var isl := Island.new()
			isl.position = Vector3(LANE_X[l], 0, SIDE_Z[p])
			add_child(isl)
			isl.setup(lands[p][l])
			_islands[p].append(isl)


func island(player: int, lane: int) -> Island:
	return _islands[player][lane]


func anchor(player: int, lane: int) -> Vector3:
	return Vector3(LANE_X[lane], CREATURE_Y, SIDE_Z[player])


## World point a creature lunges to when attacking the hero behind `player`'s lane.
func hero_point(player: int, lane: int) -> Vector3:
	var z: float = SIDE_Z[player] + (1.6 if player == 0 else -1.6)
	return Vector3(LANE_X[lane], CREATURE_Y, z)


func lane_at_screen(cam: Camera3D, screen_pos: Vector2) -> Dictionary:
	var origin: Vector3 = cam.project_ray_origin(screen_pos)
	var dir: Vector3 = cam.project_ray_normal(screen_pos)
	if absf(dir.y) < 0.0001:
		return {}
	var t: float = (0.15 - origin.y) / dir.y
	if t < 0.0:
		return {}
	var hit: Vector3 = origin + dir * t
	for p: int in 2:
		for l: int in 4:
			var c: Vector3 = Vector3(LANE_X[l], 0, SIDE_Z[p])
			if Vector2(hit.x - c.x, hit.z - c.z).length() <= Island.RADIUS:
				return {"player": p, "lane": l}
	return {}


func _box(size: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = size
	return b


func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Palette.SKY
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#dfefff")
	env.ambient_light_energy = 0.3
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_DEPTH
	env.fog_light_color = Palette.SKY
	env.fog_depth_begin = 18.0
	env.fog_depth_end = 34.0
	env.ssao_enabled = true
	env.ssao_intensity = 1.2
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.light_color = Color("#fff4d6")
	sun.light_energy = 1.9
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 40.0
	add_child(sun)
	sun.look_at_from_position(Vector3(5, 10, 6), Vector3.ZERO)


func _build_scenery() -> void:
	var meadow := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = 40.0
	disc.bottom_radius = 40.0
	disc.height = 0.1
	disc.radial_segments = 48
	meadow.mesh = disc
	meadow.material_override = Palette.mat(Palette.MEADOW, 1.0)
	meadow.position = Vector3(0, -1.65, 0)
	add_child(meadow)
	var rng := RandomNumberGenerator.new()
	rng.seed = 2026
	var tops: Array[Color] = [Color("#5fc45a"), Color("#ff9fcf"), Color("#ffd84a"), Color("#7fd8ff")]
	for i: int in 26:
		var a: float = rng.randf() * TAU
		var r: float = rng.randf_range(12.0, 22.0)
		var tree := Node3D.new()
		tree.position = Vector3(cos(a) * r, -1.6, sin(a) * r - 2.0)
		tree.add_child(Palette.mesh(Palette.cylinder(0.12, 0.18, 0.9, 8), Palette.mat(Color("#8a5a3a")), Vector3(0, 0.45, 0)))
		tree.add_child(Palette.mesh(Palette.sphere(rng.randf_range(0.7, 1.1), 14), Palette.mat(tops[i % 4], 0.9), Vector3(0, 1.3, 0)))
		add_child(tree)
