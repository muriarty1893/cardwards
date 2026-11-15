class_name Board
extends Node3D
## The board on its meadow: sky, light, painted ground, scenery ring, stone rim and the 8 lanes.

const LANE_X: Array[float] = [-3.6, -1.2, 1.2, 3.6]
## Centre of each side's strips. Player 0 (human) is near the camera.
const STRIP_Z: Array[float] = [2.33, -2.33]
## Where creatures stand: near the centre line, facing off.
const SIDE_Z: Array[float] = [1.45, -1.45]
const CREATURE_Y := 0.58
## Where the sun shines from, towards the board centre.
const SUN_FROM := Vector3(5, 12, 7)
## Scenery never goes inside this x/z rectangle (the lane block plus a margin).
const INNER_CLEAR := Rect2(-6.4, -6.0, 12.8, 12.0)
const NATURE := "res://assets/nature/%s.gltf"
## [models, base height, count, sway]
const SCENERY: Array[Array] = [
	[["CommonTree_1", "CommonTree_3", "Pine_2"], 3.0, 20, 0.04],
	[["Bush_Common_Flowers"], 0.9, 16, 0.04],
	[["Rock_Medium_1", "Rock_Medium_2", "Rock_Medium_3"], 0.7, 14, 0.0],
	[["Flower_3_Group", "Flower_4_Group", "Grass_Common_Tall", "Fern_1"], 0.45, 20, 0.04],
]

var env: Environment
var ambient: Ambient
var _islands: Array[Array] = [[], []]
var _clouds: Array[Node3D] = []
var _scenery: Array[Vector3] = []


func build(lands: Array[Array]) -> void:
	_build_environment()
	_build_ground()
	_build_rim()
	_build_clouds()
	_build_scenery()
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


## Low: no SSAO, no glow, 1024 shadow atlas, no MSAA, half the ambient particles.
## No glow on the Compatibility renderer (web) either: its glow works on 8-bit sRGB colour and
## blooms every bright lane over the pieces, so they look hazy and see-through.
func apply_quality(q: int) -> void:
	var low: bool = q == GameSettings.Quality.LOW
	env.ssao_enabled = not low
	env.glow_enabled = not low and RenderingServer.get_current_rendering_method() != "gl_compatibility"
	RenderingServer.directional_shadow_atlas_set_size(1024 if low else 4096, true)
	RenderingServer.directional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_HARD if low else RenderingServer.SHADOW_QUALITY_SOFT_VERY_LOW)
	if is_inside_tree():
		get_viewport().msaa_3d = Viewport.MSAA_DISABLED if low else Viewport.MSAA_2X
	ambient.set_quality(q)


func _on_settings_changed() -> void:
	apply_quality(Settings.quality)


func scenery_positions() -> Array[Vector3]:
	return _scenery


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
	sky_mat.sky_top_color = Color("#4aa3ff")
	sky_mat.sky_horizon_color = Color("#dff3ff")
	sky_mat.sky_curve = 0.15
	sky_mat.ground_bottom_color = Color("#6cb552")
	sky_mat.ground_horizon_color = Color("#b5e58a")
	sky_mat.ground_curve = 0.05
	sky_mat.sun_angle_max = 0.0
	var sky := Sky.new()
	sky.sky_material = sky_mat
	env = Environment.new()
	env.background_mode = Environment.BG_SKY
	env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color.WHITE
	env.ambient_light_energy = 0.38
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.ssao_enabled = true
	env.ssao_intensity = 1.0
	env.glow_enabled = true
	env.glow_intensity = 0.3
	env.glow_hdr_threshold = 1.0
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.light_color = Color("#fff4e0")
	sun.light_energy = 0.9
	# Off on the Compatibility renderer (web), where shadowed lights over-brighten; see BlobShadow.
	sun.shadow_enabled = BlobShadow.sun_shadows()
	sun.directional_shadow_max_distance = 30.0
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	add_child(sun)
	sun.look_at_from_position(SUN_FROM, Vector3.ZERO)


func _build_ground() -> void:
	var mat := ShaderMaterial.new()
	mat.shader = load("res://view/look/ground.gdshader") as Shader
	mat.set_shader_parameter("fbm_tex", NoiseBank.fbm())
	# Four tiles around the rim instead of one big plane, so the meadow is never shaded
	# underneath the lanes (overdraw is costly on integrated GPUs).
	var half := 300.0
	var hole := Vector2(10.4, 9.9) / 2.0
	var tiles: Array[Rect2] = [
		Rect2(-half, -half, 2.0 * half, half - hole.y),
		Rect2(-half, hole.y, 2.0 * half, half - hole.y),
		Rect2(-half, -hole.y, half - hole.x, 2.0 * hole.y),
		Rect2(hole.x, -hole.y, half - hole.x, 2.0 * hole.y),
	]
	for r: Rect2 in tiles:
		var plane := PlaneMesh.new()
		plane.size = r.size
		add_child(Palette.mesh(plane, mat, Vector3(r.get_center().x, 0.0, r.get_center().y), false))
	# Dark soil under the lane block, showing as borders between lanes.
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


## Puffy cartoon clouds low on the horizon (seen from the menu camera).
func _build_clouds() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	var white: ShaderMaterial = Toon.plain(Color("#ffffff"))
	var puff := Palette.sphere(1.0, 16)
	for i: int in 14:
		var a: float = rng.randf() * TAU
		var r: float = rng.randf_range(45.0, 85.0)
		var cluster := Node3D.new()
		cluster.position = Vector3(cos(a) * r, rng.randf_range(5.0, 11.0), sin(a) * r)
		for j: int in rng.randi_range(4, 7):
			var mi := Palette.mesh(puff, white, Vector3(rng.randf_range(-3.5, 3.5), rng.randf_range(-0.4, 0.8), rng.randf_range(-1.5, 1.5)), false)
			var k: float = rng.randf_range(1.6, 3.0)
			mi.scale = Vector3(k, k * 0.75, k)
			cluster.add_child(mi)
		add_child(cluster)
		_clouds.append(cluster)


## Trees, bushes, rocks and flowers in a ring around the board (fixed seed).
func _build_scenery() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2026
	for group: Array in SCENERY:
		var names: Array = group[0]
		var base_h: float = group[1]
		var count: int = group[2]
		var sway: float = group[3]
		for i: int in count:
			var pos := Vector3.ZERO
			while true:
				pos = Vector3(rng.randf_range(-24.0, 24.0), 0.0, rng.randf_range(-22.0, 22.0))
				if not INNER_CLEAR.has_point(Vector2(pos.x, pos.z)):
					break
			var path: String = NATURE % names[i % names.size()]
			var mdl: Node3D = Palette.model(path, base_h * rng.randf_range(0.8, 1.3))
			Toon.apply(mdl, Toon.NO_TINT, sway)
			mdl.position = pos
			mdl.rotation.y = rng.randf() * TAU
			add_child(mdl)
			_scenery.append(pos)


func _process(delta: float) -> void:
	for c: Node3D in _clouds:
		c.position.x += delta * 0.3
		if c.position.x > 90.0:
			c.position.x = -90.0
