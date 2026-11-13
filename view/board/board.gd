class_name Board
extends Node3D
## The diorama: environment, light, meadow, slab and the 8 islands.

const LANE_X: Array[float] = [-3.6, -1.2, 1.2, 3.6]
## Centre of each side's strips. Player 0 (human) is near the camera.
const STRIP_Z: Array[float] = [2.33, -2.33]
## Where creatures stand: near the centre line, facing off.
const SIDE_Z: Array[float] = [1.45, -1.45]
const CREATURE_Y := 0.58

var _islands: Array[Array] = [[], []]
var _clouds: Array[Node3D] = []
var _islets: Array[Node3D] = []
var _time: float = 0.0


func build(lands: Array[Array]) -> void:
	_build_environment()
	_build_scenery()
	add_child(Palette.mesh(_box(Vector3(10.2, 0.5, 9.9)), Palette.mat(Color("#3a3466"), 0.7), Vector3(0, -0.13, 0)))
	add_child(Palette.mesh(_box(Vector3(10.6, 0.3, 10.3)), Palette.mat(Color("#171533"), 0.8), Vector3(0, -0.3, 0)))
	var rock := Palette.cylinder(7.2, 1.2, 5.0, 9)
	var under := Palette.mesh(rock, Palette.mat(Color("#6a5a8c"), 1.0, true), Vector3(0, -2.95, 0))
	under.rotation.y = 0.4
	add_child(under)
	for p: int in 2:
		for l: int in 4:
			var isl := Island.new()
			isl.position = Vector3(LANE_X[l], 0, STRIP_Z[p])
			add_child(isl)
			isl.setup(lands[p][l], p)
			_islands[p].append(isl)


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


func _build_environment() -> void:
	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color("#4f6fe0")
	sky_mat.sky_horizon_color = Color("#ffc4dc")
	sky_mat.sky_curve = 0.12
	sky_mat.ground_bottom_color = Color("#8f86e8")
	sky_mat.ground_horizon_color = Color("#ffc4dc")
	sky_mat.ground_curve = 0.08
	sky_mat.sun_angle_max = 0.0
	var sky := Sky.new()
	sky.sky_material = sky_mat
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#e6dcff")
	env.ambient_light_energy = 0.5
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.ssao_enabled = true
	env.ssao_intensity = 1.5
	env.glow_enabled = true
	env.glow_intensity = 0.35
	env.glow_bloom = 0.05
	env.glow_hdr_threshold = 1.1
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.light_color = Color("#fff1d8")
	sun.light_energy = 1.35
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 40.0
	add_child(sun)
	sun.look_at_from_position(Vector3(5, 10, 6), Vector3.ZERO)


## A sea of clouds below the floating board, plus a few drifting higher up.
func _build_scenery() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2026
	var mats: Array[StandardMaterial3D] = []
	for c: Color in [Color("#ffffff"), Color("#ffe6f2"), Color("#e6e0ff")]:
		var m := Palette.mat(c, 1.0)
		m.emission_enabled = true
		m.emission = c
		m.emission_energy_multiplier = 0.12
		mats.append(m)
	var puff := Palette.sphere(1.0, 16)
	for i: int in 90:
		var a: float = rng.randf() * TAU
		var r: float = rng.randf_range(3.0, 34.0)
		var cluster := Node3D.new()
		cluster.position = Vector3(cos(a) * r, rng.randf_range(-7.5, -3.2) - r * 0.05, sin(a) * r)
		if absf(cluster.position.x) < 7.0 and absf(cluster.position.z) < 7.0:
			cluster.position.y = minf(cluster.position.y, -4.5)
		var mat: StandardMaterial3D = mats[rng.randi_range(0, 2)]
		for j: int in rng.randi_range(4, 7):
			var mi := Palette.mesh(puff, mat, Vector3(rng.randf_range(-2.4, 2.4), rng.randf_range(-0.3, 0.5), rng.randf_range(-1.6, 1.6)), false)
			var k: float = rng.randf_range(1.1, 2.4)
			mi.scale = Vector3(k, k * 0.7, k)
			cluster.add_child(mi)
		add_child(cluster)
		_clouds.append(cluster)


	_build_islets(rng)


## Small floating islets with trees, rocks and peaks around the board.
func _build_islets(rng: RandomNumberGenerator) -> void:
	var spots: Array[Vector3] = [
		Vector3(-9.2, -0.4, -3.5), Vector3(9.4, -0.2, -4.2), Vector3(-10.5, -1.2, 2.2), Vector3(10.8, -1.0, 1.6),
		Vector3(-5.5, 0.3, -9.0), Vector3(5.2, 0.5, -9.5), Vector3(0.0, 0.9, -11.5), Vector3(-14.0, 0.2, -8.0), Vector3(14.0, 0.4, -8.5),
	]
	var sets: Array[Array] = [
		["trees", "rock"], ["pines", "tree1"], ["tree2", "rocks"], ["trees", "gold"],
		["mountain", "pine"], ["mountains"], ["mountain", "trees"], ["pines", "rocks"], ["trees", "tree2"],
	]
	var grass := Palette.mat(Color("#6fcf5a"), 0.9)
	var stone := Palette.mat(Color("#7a6a9c"), 1.0, true)
	for i: int in spots.size():
		var isl := Node3D.new()
		isl.position = spots[i]
		var r: float = rng.randf_range(1.5, 2.3)
		isl.add_child(Palette.mesh(Palette.cylinder(r, r * 0.92, 0.3, 10), grass, Vector3(0, -0.15, 0)))
		isl.add_child(Palette.mesh(Palette.cylinder(r * 0.92, 0.15, r * 1.3, 7), stone, Vector3(0, -0.3 - r * 0.65, 0)))
		var names: Array = sets[i]
		for j: int in names.size():
			var big: bool = (names[j] as String).begins_with("mountain")
			var mdl: Node3D = Palette.model("res://assets/scenery/%s.gltf" % names[j], 2.6 if big else rng.randf_range(1.3, 1.9), r * (1.7 if big else 1.1))
			var ang: float = rng.randf() * TAU
			var d: float = 0.0 if names.size() == 1 else r * 0.42
			mdl.position = Vector3(cos(ang + j * PI) * d, 0, sin(ang + j * PI) * d)
			mdl.rotation.y = rng.randf() * TAU
			isl.add_child(mdl)
		add_child(isl)
		_islets.append(isl)


func _process(delta: float) -> void:
	_time += delta
	for i: int in _islets.size():
		_islets[i].position.y += sin(_time * 0.6 + i * 1.7) * delta * 0.08
	for c: Node3D in _clouds:
		c.position.x += delta * 0.12
		if c.position.x > 36.0:
			c.position.x = -36.0
