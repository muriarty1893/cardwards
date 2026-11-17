class_name Room
extends Node3D
## The sunny cottage room around the table: walls with three windows behind the rival, plank
## floor, ceiling beams, the hills and a floating island outside, sunbeams with dust, KayKit
## furniture, and a few things on the table. Pure decoration; owns the sun and the
## environment. The tabletop is the plane y = 0 and the board lies on it.

## KayKit models are in their own units (a table is 1.0 tall); this many board units each.
const SCALE := 8.0
## Tabletop (world x/z). Its surface is y = 0.
const TABLE_RECT := Rect2(-12.0, -9.5, 24.0, 19.0)
## Where the board lies: no prop may stand in this x/z rect above the tabletop.
const BOARD_CLEAR := Rect2(-6.4, -6.4, 12.8, 12.8)
## Rival chair centre (z), just beyond the far table edge.
const SEAT_Z := -12.6
const FLOOR_Y := -8.0
const CEIL_Y := 24.0
const HALF_W := 44.0
const WINDOW_Z := -36.0
const BACK_Z := 34.0
## Window centres (x); each is WINDOW_SIZE wide, from the sill at y = 0 up to y = WINDOW_SIZE.y.
const WINDOWS: Array[float] = [-22.0, 0.0, 22.0]
const WINDOW_SIZE := Vector2(12.0, 17.0)
## The sun: high and from the left, a little in front, so pieces' faces towards the player stay
## lit with one light (a second directional light costs ~8 ms a frame on integrated GPUs).
const SUN_FROM := Vector3(-14, 30, 6)
## The painted sunbeams slant in from the windows behind the rival (they are fake light).
const BEAM_FROM := Vector3(-12, 30, -24)
const DUST_HIGH := 70
const PATH := "res://assets/room/%s.gltf"
const NATURE := "res://assets/nature/%s.gltf"
## The cat curls up on the armchair seat (height above the floor) and breathes slowly.
const CAT_SEAT_Y := 4.2
## How far forward of the armchair centre the seat cushion is.
const CAT_FORWARD := 2.6
const CAT := "res://assets/monsters/blob/Cat.gltf"
const CANDY_COLORS: Array[Color] = [Color("#ff5a7a"), Color("#ffd84a"), Color("#5ad1ff"), Color("#7aff7a"), Color("#c38cff")]

var env: Environment
var sun: DirectionalLight3D
var _props: Array[Node3D] = []
var _dust: CPUParticles3D
## The lower sheet of each sunbeam (hidden on Low).
var _low_beams: Array[MeshInstance3D] = []
var _island: Node3D
var _cat: Node3D
var _t: float = 0.0


func build(quality: int) -> void:
	_build_lights()
	_build_shell()
	_build_window_view()
	_build_sunbeams()
	_build_dust()
	_build_furniture()
	_build_table()
	apply_quality(quality)
	if not Settings.changed.is_connected(_on_settings_changed):
		Settings.changed.connect(_on_settings_changed)


## Every placed prop (furniture and table things; not walls, floor or the table itself).
func props() -> Array[Node3D]:
	return _props


func dust_amount() -> int:
	return _dust.amount


## Low: no SSAO, no glow, 1024 shadow atlas, shorter shadow distance, no MSAA, half the dust.
## No glow on the Compatibility renderer (web) either: its glow works on 8-bit sRGB colour and
## blooms every bright surface, so the pieces look hazy.
func apply_quality(q: int) -> void:
	var low: bool = q == GameSettings.Quality.LOW
	env.ssao_enabled = not low
	env.glow_enabled = not low and RenderingServer.get_current_rendering_method() != "gl_compatibility"
	sun.directional_shadow_max_distance = 22.0 if low else 30.0
	RenderingServer.directional_shadow_atlas_set_size(1024 if low else 4096, true)
	RenderingServer.directional_soft_shadow_filter_set_quality(RenderingServer.SHADOW_QUALITY_HARD if low else RenderingServer.SHADOW_QUALITY_SOFT_VERY_LOW)
	if is_inside_tree():
		get_viewport().msaa_3d = Viewport.MSAA_DISABLED if low else Viewport.MSAA_2X
	_dust.amount = DUST_HIGH / 2 if low else DUST_HIGH
	for b: MeshInstance3D in _low_beams:
		b.visible = not low


func _on_settings_changed() -> void:
	apply_quality(Settings.quality)


func _process(delta: float) -> void:
	_t += delta
	if _island:
		_island.position.y = 25.0 + sin(_t * 0.4) * 0.8
		_island.rotation.y = sin(_t * 0.1) * 0.15
	if _cat:
		var breath: float = 1.0 + sin(_t * 1.6) * 0.04
		_cat.scale = Vector3(1.0, breath, 1.0 + (breath - 1.0) * 0.5)


# --- light and environment ---------------------------------------------------------------

func _build_lights() -> void:
	env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#e9d2ad")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#fff2e0")
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.ssao_enabled = true
	env.ssao_intensity = 1.0
	env.glow_enabled = true
	env.glow_intensity = 0.3
	env.glow_hdr_threshold = 1.0
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	sun = DirectionalLight3D.new()
	sun.name = "Sun"
	sun.light_color = Color("#ffe9c8")
	sun.light_energy = 0.85
	# Off on the Compatibility renderer (web), where shadowed lights over-brighten; see BlobShadow.
	sun.shadow_enabled = BlobShadow.sun_shadows()
	sun.directional_shadow_max_distance = 30.0
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	add_child(sun)
	sun.look_at_from_position(SUN_FROM, Vector3.ZERO)



# --- walls, floor, ceiling ---------------------------------------------------------------

func _surface(mode: int, color: Color, seam: Color = Color("#6b4428")) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = load("res://view/room/wood.gdshader") as Shader
	m.set_shader_parameter("mode", mode)
	m.set_shader_parameter("base_color", color)
	m.set_shader_parameter("seam_color", seam)
	return m


## A box spanning `from`..`to` (world corners).
func _slab(from: Vector3, to: Vector3, mat: Material) -> MeshInstance3D:
	var b := BoxMesh.new()
	b.size = (to - from).abs()
	var mi := Palette.mesh(b, mat, (from + to) / 2.0, false)
	add_child(mi)
	return mi


func _build_shell() -> void:
	var planks := _surface(0, Color("#c98d5a"), Color("#7a4a2a"))
	var plaster := _surface(1, Color("#f4e4c6"))
	var timber := _surface(2, Color("#9a6440"))
	var panel := _surface(2, Color("#b9804f"))
	var floor_mesh := PlaneMesh.new()
	floor_mesh.size = Vector2(HALF_W * 2.0, BACK_Z - WINDOW_Z)
	add_child(Palette.mesh(floor_mesh, planks, Vector3(0, FLOOR_Y, (BACK_Z + WINDOW_Z) / 2.0), false))
	var ceil_mesh := PlaneMesh.new()
	ceil_mesh.size = floor_mesh.size
	ceil_mesh.flip_faces = true
	add_child(Palette.mesh(ceil_mesh, plaster, Vector3(0, CEIL_Y, (BACK_Z + WINDOW_Z) / 2.0), false))
	var t: float = 1.2
	# Window wall: a band under the sills, one over the windows, piers between them.
	var wz: float = WINDOW_Z - t / 2.0
	_slab(Vector3(-HALF_W, FLOOR_Y, wz - t / 2.0), Vector3(HALF_W, 0.0, wz + t / 2.0), plaster)
	_slab(Vector3(-HALF_W, WINDOW_SIZE.y, wz - t / 2.0), Vector3(HALF_W, CEIL_Y, wz + t / 2.0), plaster)
	var edges: Array[float] = [-HALF_W]
	for cx: float in WINDOWS:
		edges.append(cx - WINDOW_SIZE.x / 2.0)
		edges.append(cx + WINDOW_SIZE.x / 2.0)
	edges.append(HALF_W)
	for i: int in range(0, edges.size(), 2):
		_slab(Vector3(edges[i], 0.0, wz - t / 2.0), Vector3(edges[i + 1], WINDOW_SIZE.y, wz + t / 2.0), plaster)
	# Side and back walls.
	_slab(Vector3(-HALF_W - t, FLOOR_Y, WINDOW_Z - t), Vector3(-HALF_W, CEIL_Y, BACK_Z + t), plaster)
	_slab(Vector3(HALF_W, FLOOR_Y, WINDOW_Z - t), Vector3(HALF_W + t, CEIL_Y, BACK_Z + t), plaster)
	_slab(Vector3(-HALF_W, FLOOR_Y, BACK_Z), Vector3(HALF_W, CEIL_Y, BACK_Z + t), plaster)
	# Wood panelling on the lower walls and a skirting rail.
	var ph: float = -1.0
	_slab(Vector3(-HALF_W, FLOOR_Y, WINDOW_Z), Vector3(HALF_W, ph, WINDOW_Z + 0.3), panel)
	_slab(Vector3(-HALF_W, FLOOR_Y, BACK_Z - 0.3), Vector3(HALF_W, ph, BACK_Z), panel)
	_slab(Vector3(-HALF_W, FLOOR_Y, WINDOW_Z), Vector3(-HALF_W + 0.3, ph, BACK_Z), panel)
	_slab(Vector3(HALF_W - 0.3, FLOOR_Y, WINDOW_Z), Vector3(HALF_W, ph, BACK_Z), panel)
	for z: float in [WINDOW_Z + 0.45, BACK_Z - 0.45]:
		_slab(Vector3(-HALF_W, ph, z - 0.3), Vector3(HALF_W, ph + 0.6, z + 0.3), timber)
	for x: float in [-HALF_W + 0.45, HALF_W - 0.45]:
		_slab(Vector3(x - 0.3, ph, WINDOW_Z), Vector3(x + 0.3, ph + 0.6, BACK_Z), timber)
	# Window frames: sill, lintel, jambs and a cross bar.
	for cx: float in WINDOWS:
		var l: float = cx - WINDOW_SIZE.x / 2.0
		var r: float = cx + WINDOW_SIZE.x / 2.0
		_slab(Vector3(l - 0.8, -0.5, WINDOW_Z - 1.4), Vector3(r + 0.8, 0.3, WINDOW_Z + 1.2), timber)
		_slab(Vector3(l - 0.8, WINDOW_SIZE.y - 0.3, WINDOW_Z - 1.4), Vector3(r + 0.8, WINDOW_SIZE.y + 0.7, WINDOW_Z + 0.4), timber)
		for x: float in [l, r]:
			_slab(Vector3(x - 0.5, 0.0, WINDOW_Z - 1.4), Vector3(x + 0.5, WINDOW_SIZE.y, WINDOW_Z + 0.4), timber)
		_slab(Vector3(cx - 0.25, 0.0, WINDOW_Z - 0.9), Vector3(cx + 0.25, WINDOW_SIZE.y, WINDOW_Z - 0.5), timber)
		_slab(Vector3(l, WINDOW_SIZE.y * 0.62 - 0.25, WINDOW_Z - 0.9), Vector3(r, WINDOW_SIZE.y * 0.62 + 0.25, WINDOW_Z - 0.5), timber)
	# Ceiling beams.
	for z: float in [-26.0, -14.0, -2.0, 10.0, 22.0]:
		_slab(Vector3(-HALF_W, CEIL_Y - 1.8, z - 0.8), Vector3(HALF_W, CEIL_Y, z + 0.8), timber)
	for x: float in [-20.0, 20.0]:
		_slab(Vector3(x - 0.9, CEIL_Y - 2.6, WINDOW_Z), Vector3(x + 0.9, CEIL_Y - 1.8, BACK_Z), timber)


# --- outside the windows -------------------------------------------------------------------

func _build_window_view() -> void:
	var sky_tex := GradientTexture2D.new()
	var g := Gradient.new()
	g.set_color(0, Color("#5daeff"))
	g.set_color(1, Color("#fff0d2"))
	g.add_point(0.7, Color("#bfe2ff"))
	sky_tex.gradient = g
	sky_tex.fill_from = Vector2(0, 0)
	sky_tex.fill_to = Vector2(0, 1)
	var sky_mat := StandardMaterial3D.new()
	sky_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	sky_mat.albedo_texture = sky_tex
	var sky := QuadMesh.new()
	sky.size = Vector2(360, 150)
	add_child(Palette.mesh(sky, sky_mat, Vector3(0, 40, -130), false))
	var ground := PlaneMesh.new()
	ground.size = Vector2(360, 100)
	add_child(Palette.mesh(ground, Toon.plain(Color("#8fd46a")), Vector3(0, FLOOR_Y - 1.0, WINDOW_Z - 51.0), false))
	var puff := Palette.sphere(1.0, 24)
	for h: Array in [[Vector3(-46, FLOOR_Y - 8, -88), Vector3(46, 20, 22), "#7cc65a"], [Vector3(18, FLOOR_Y - 10, -100), Vector3(62, 24, 26), "#6ab64e"], [Vector3(80, FLOOR_Y - 6, -84), Vector3(40, 18, 20), "#86cf63"], [Vector3(-100, FLOOR_Y - 6, -96), Vector3(50, 22, 22), "#74bf57"]]:
		var mi := Palette.mesh(puff, Toon.plain(Color(h[2])), h[0], false)
		mi.scale = h[1]
		add_child(mi)
	var trees: Array[String] = ["CommonTree_1", "CommonTree_3", "Pine_2"]
	var rng := RandomNumberGenerator.new()
	rng.seed = 31
	for i: int in 9:
		var mdl: Node3D = Palette.model(NATURE % trees[i % trees.size()], rng.randf_range(13.0, 21.0))
		Toon.apply(mdl, Toon.NO_TINT, 0.03)
		mdl.position = Vector3(rng.randf_range(-70.0, 70.0), FLOOR_Y - 1.0, rng.randf_range(-48.0, -76.0))
		mdl.rotation.y = rng.randf() * TAU
		_no_shadows(mdl)
		add_child(mdl)
	_island = _floating_island()
	_island.position = Vector3(32, 25, -110)
	add_child(_island)


func _floating_island() -> Node3D:
	var root := Node3D.new()
	root.name = "FloatingIsland"
	var rock := Palette.mesh(Palette.cylinder(9.0, 0.8, 11.0, 18), Toon.plain(Color("#b89b7a")), Vector3(0, -5.5, 0), false)
	root.add_child(rock)
	var turf := Palette.mesh(Palette.cylinder(9.6, 9.2, 1.4, 18), Toon.plain(Color("#86d65f")), Vector3(0, 0.4, 0), false)
	root.add_child(turf)
	for p: Vector3 in [Vector3(-3, 1, 1), Vector3(3.5, 1, -2)]:
		var t: Node3D = Palette.model(NATURE % "CommonTree_1", 7.0)
		Toon.apply(t)
		t.position = p
		_no_shadows(t)
		root.add_child(t)
	return root


# --- sunbeams and dust ---------------------------------------------------------------------

func _beam_texture() -> ImageTexture:
	var img := Image.create(32, 64, false, Image.FORMAT_RGBA8)
	for y: int in 64:
		var along: float = float(y) / 63.0
		var fade: float = pow(1.0 - along, 1.6) * smoothstep(0.0, 0.08, along)
		for x: int in 32:
			var u: float = absf(float(x) / 31.0 - 0.5) * 2.0
			var edge: float = 1.0 - smoothstep(0.55, 1.0, u)
			img.set_pixel(x, y, Color(1, 1, 1, fade * edge))
	return ImageTexture.create_from_image(img)


## Two slanted sheets per window (from the lintel and from the sill to where the sun lands on
## the floor) read as a beam of light; additive, unshaded, no shadows.
func _build_sunbeams() -> void:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.albedo_texture = _beam_texture()
	mat.albedo_color = Color("#ffe6b0", 0.22)
	mat.disable_receive_shadows = true
	var d: Vector3 = -BEAM_FROM.normalized()
	for cx: float in WINDOWS:
		var l: float = cx - WINDOW_SIZE.x / 2.0 + 0.6
		var r: float = cx + WINDOW_SIZE.x / 2.0 - 0.6
		for y: float in [WINDOW_SIZE.y - 0.4, 0.4]:
			var a := Vector3(l, y, WINDOW_Z)
			var b := Vector3(r, y, WINDOW_Z)
			var k: float = (y - FLOOR_Y) / -d.y
			var st := SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			var quad: Array[Vector3] = [a, b, b + d * k, a + d * k]
			var uvs: Array[Vector2] = [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]
			for i: int in [0, 1, 2, 0, 2, 3]:
				st.set_uv(uvs[i])
				st.add_vertex(quad[i])
			var mi := MeshInstance3D.new()
			mi.name = "Sunbeam"
			mi.mesh = st.commit()
			mi.material_override = mat
			mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			add_child(mi)
			if y < 1.0:
				_low_beams.append(mi)


func _build_dust() -> void:
	_dust = CPUParticles3D.new()
	_dust.name = "Dust"
	_dust.amount = DUST_HIGH
	_dust.lifetime = 9.0
	_dust.preprocess = 9.0
	_dust.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	_dust.emission_box_extents = Vector3(30, 10, 8)
	_dust.position = Vector3(0, 5, -27)
	_dust.gravity = Vector3(0, -0.05, 0)
	_dust.direction = Vector3(1, 0.2, 0.4)
	_dust.spread = 180.0
	_dust.initial_velocity_min = 0.1
	_dust.initial_velocity_max = 0.35
	var quad := QuadMesh.new()
	quad.size = Vector2(0.22, 0.22)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.vertex_color_use_as_albedo = true
	mat.albedo_texture = load("res://assets/fx/particles/circle_05.png")
	quad.material = mat
	_dust.mesh = quad
	_dust.color = Color("#fff1c8", 0.8)
	var fade := Gradient.new()
	fade.offsets = PackedFloat32Array([0.0, 0.25, 0.75, 1.0])
	fade.colors = PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 1), Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	_dust.color_ramp = fade
	add_child(_dust)


# --- furniture -----------------------------------------------------------------------------

## A KayKit room model in the cartoon style, scaled `k` (a number or a Vector3) KayKit units →
## board units, its footprint centred on the holder's origin and its base at y = 0.
static func model(file: String, k: Variant = SCALE) -> Node3D:
	var holder := Node3D.new()
	holder.name = file.to_pascal_case()
	var inst := (load(PATH % file) as PackedScene).instantiate() as Node3D
	holder.add_child(inst)
	var s: Vector3 = k if k is Vector3 else Vector3.ONE * float(k)
	var box: AABB = Palette.bounds(inst)
	inst.scale = s
	var c: Vector3 = box.get_center()
	inst.position = Vector3(-c.x * s.x, -box.position.y * s.y, -c.z * s.z)
	Toon.apply(inst)
	return holder


## A room model placed at `pos`, turned `yaw` degrees (0 faces +z); `blob` > 0 adds a ground
## shadow of that radius; `on_table` things cast real shadows onto the table.
func _place(file: String, pos: Vector3, yaw: float = 0.0, k: Variant = SCALE, blob: float = 0.0, on_table: bool = false) -> Node3D:
	var holder: Node3D = model(file, k)
	if not on_table:
		_no_shadows(holder)
	holder.position = pos
	holder.rotation_degrees.y = yaw
	if blob > 0.0:
		holder.add_child(BlobShadow.build(blob, Palette.bounds(holder).size.y, 0.05))
	if on_table:
		holder.set_meta(&"table", true)
	add_child(holder)
	_props.append(holder)
	return holder


func _no_shadows(root: Node) -> void:
	for mi: Node in root.find_children("*", "GeometryInstance3D", true, false):
		(mi as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _build_furniture() -> void:
	var y: float = FLOOR_Y
	# Kitchen along the left wall.
	_place("kitchencounter_straight_A_decorated", Vector3(-HALF_W + 6.8, y, -22), 90, 6.0)
	_place("kitchencounter_straight_A_decorated", Vector3(-HALF_W + 6.8, y, -10), 90, 6.0)
	_place("stove_multi_decorated", Vector3(-HALF_W + 6.9, y, 3.5), 90, 6.0)
	_place("kitchencabinet", Vector3(-HALF_W + 3.2, y, -22), 90, 6.0)
	_place("kitchencabinet", Vector3(-HALF_W + 3.2, y, -10), 90, 6.0)
	# Cosy corner on the right.
	_place("cabinet_medium_decorated", Vector3(HALF_W - 4.2, y, -20), -90, SCALE, 7.0)
	_place("shelf_B_large_decorated", Vector3(HALF_W - 2.2, 9.0, -1.0), -90, 7.0)
	_place("armchair_pillows", Vector3(31, y, 10), -107, SCALE, 7.5)
	var fwd := Vector3(sin(deg_to_rad(-107.0)), 0, cos(deg_to_rad(-107.0)))
	_add_cat(Vector3(31, y + CAT_SEAT_Y, 10) + fwd * CAT_FORWARD, -107)
	_place("lamp_standing", Vector3(39, y, 22), 0, SCALE, 3.0)
	_place("pictureframe_large_A", Vector3(HALF_W - 0.9, 6.0, 12), -90, 6.0)
	_place("pictureframe_medium", Vector3(HALF_W - 0.9, 7.0, 21), -90, 6.0)
	_place("cactus_medium_A", Vector3(35, y, -30), 20, SCALE, 3.5)
	_place("cactus_medium_A", Vector3(-19, 0.3, WINDOW_Z + 0.9), -30, 2.8)
	# Behind the player (seen in the opening sweep).
	_place("door_A", Vector3(-24, y, BACK_Z - 3.2), 180, SCALE)
	_place("couch_pillows", Vector3(16, y, BACK_Z - 7.0), 180, SCALE, 11.0)
	# The rug under the table and the player's own chair.
	_place("rug_rectangle_stripes_A", Vector3(0, y, 0), 0, Vector3(13, 3, 13))
	_place("chair_A_wood", Vector3(0, y, TABLE_RECT.end.y + 4.0), 180, SCALE, 3.5)


## The cat sleeping on the armchair: idle played very slowly, lying low, breathing.
func _add_cat(pos: Vector3, yaw: float) -> void:
	_cat = Palette.model(CAT, 3.2)
	_cat.name = "Cat"
	Toon.apply(_cat)
	_no_shadows(_cat)
	_cat.position = pos
	_cat.rotation_degrees.y = yaw
	var ap := _cat.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if ap and ap.has_animation(&"Idle"):
		ap.play(&"Idle")
		ap.speed_scale = 0.3
	add_child(_cat)
	_props.append(_cat)
	var z := Label3D.new()
	z.name = "Snore"
	z.text = "z"
	z.font = load(UiStyle.TITLE_FONT) as Font
	z.font_size = 96
	z.outline_size = 18
	z.modulate = Color("#ffffff")
	z.outline_modulate = Color(Palette.INK)
	z.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	z.pixel_size = 0.012
	add_child(z)
	var tw := z.create_tween().set_loops()
	tw.tween_callback(func() -> void:
		z.position = pos + Vector3(0, 3.2, 0)
		z.modulate.a = 0.0)
	tw.tween_property(z, "modulate:a", 1.0, 0.6)
	tw.parallel().tween_property(z, "position", pos + Vector3(0.8, 5.2, 0), 2.2)
	tw.tween_property(z, "modulate:a", 0.0, 0.6)
	tw.tween_interval(0.8)


# --- the table and what is on it ------------------------------------------------------------

func _build_table() -> void:
	# Stretched to the tabletop rect; not a prop (the board lies on it).
	var holder := Node3D.new()
	holder.name = "Table"
	var inst := (load(PATH % "table_medium") as PackedScene).instantiate() as Node3D
	holder.add_child(inst)
	var box: AABB = Palette.bounds(inst)
	var s := Vector3(TABLE_RECT.size.x / box.size.x, -FLOOR_Y / box.size.y, TABLE_RECT.size.y / box.size.z)
	inst.scale = s
	inst.position = Vector3(-box.get_center().x * s.x, -box.position.y * s.y, -box.get_center().z * s.z)
	Toon.apply(inst)
	_no_shadows(inst)
	holder.position = Vector3(TABLE_RECT.get_center().x, FLOOR_Y, TABLE_RECT.get_center().y)
	add_child(holder)
	# A bowl of sweets, a candle on a plate, a mug, a stack of books and a cupcake.
	var bowl: Node3D = _place("bowl", Vector3(-9.6, 0, 5.2), 0, 2.8, 0.0, true)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for i: int in 7:
		var a: float = float(i) / 7.0 * TAU
		var r: float = 0.55 if i > 0 else 0.0
		var sweet := Palette.mesh(Palette.sphere(0.32, 12), Toon.plain(CANDY_COLORS[i % CANDY_COLORS.size()]), Vector3(cos(a) * r, 0.62 + rng.randf() * 0.12, sin(a) * r))
		bowl.add_child(sweet)
	var plate: Node3D = _place("plate", Vector3(-9.6, 0, -6.4), 0, 2.4, 0.0, true)
	plate.add_child(Palette.mesh(Palette.cylinder(0.32, 0.34, 1.8, 14), Toon.plain(Color("#fff3d6")), Vector3(0, 1.15, 0)))
	var flame := MeshInstance3D.new()
	var fq := QuadMesh.new()
	fq.size = Vector2(0.5, 0.8)
	var fm := StandardMaterial3D.new()
	fm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	fm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	fm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	fm.albedo_texture = load("res://assets/fx/particles/flame_02.png")
	fm.albedo_color = Color("#ffb347")
	fq.material = fm
	flame.mesh = fq
	flame.name = "Flame"
	flame.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	flame.position = Vector3(0, 2.4, 0)
	plate.add_child(flame)
	var mug := Node3D.new()
	mug.name = "Mug"
	mug.add_child(Palette.mesh(Palette.cylinder(0.75, 0.68, 1.5, 18), Toon.plain(Color("#d9643a")), Vector3(0, 0.75, 0)))
	var handle := TorusMesh.new()
	handle.inner_radius = 0.28
	handle.outer_radius = 0.48
	var hm := Palette.mesh(handle, Toon.plain(Color("#d9643a")), Vector3(0.8, 0.8, 0))
	hm.rotation_degrees.x = 90
	mug.add_child(hm)
	mug.position = Vector3(9.6, 0, -6.6)
	mug.set_meta(&"table", true)
	add_child(mug)
	_props.append(mug)
	_place("book_set", Vector3(10.0, 0, 0.6), 75, 3.6, 0.0, true)
	var cupcake: Node3D = Palette.model("res://assets/candy/cupcake.glb", 1.5)
	Toon.apply(cupcake)
	cupcake.name = "Cupcake"
	cupcake.position = Vector3(-9.8, 0, 0.6)
	cupcake.set_meta(&"table", true)
	add_child(cupcake)
	_props.append(cupcake)
