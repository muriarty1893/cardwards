class_name FieldFx
extends Node3D
## The look of the field spell in play (living board spec 8), around the board: weather falling
## (or drifting up) over the tray, the room light tinted, and a toy prop that rises on the
## table beside the board — a little volcano, a storm cloud, a ring of giant mushrooms or a
## cotton-candy cloud. The lane overlay itself is Board.set_field.

## Free table space left of the board, between the candle and the cupcake (and not straight
## above the candle on screen).
const PROP_AT := Vector3(-8.2, 0.0, -1.0)
const TEX := "res://assets/fx/particles/%s.png"
## Sun / ambient tint per land (MUSHROOM, EMBER, CANDY, FROST).
const SUN_TINT: Array[Color] = [Color("#e2ffd2"), Color("#ffbf94"), Color("#ffdcf0"), Color("#d4e6ff"), Color.WHITE, Color("#ffd89a")]
const CANDY: Array[Color] = [Color("#ff5a7a"), Color("#ffd84a"), Color("#5ad1ff"), Color("#7aff7a"), Color("#ffffff")]

var land: int = -1
var room: Room
var _weather: CPUParticles3D
var _extra: CPUParticles3D
var _prop: Node3D
var _sun_base := Color.WHITE
var _amb_base := Color.WHITE
var _quality: int = 0


func setup(r: Room, quality: int) -> void:
	room = r
	_quality = quality
	if room and room.sun:
		_sun_base = room.sun.light_color
		_amb_base = room.env.ambient_light_color


## Shows `new_land`'s field (-1: none).
func set_field(new_land: int, animate: bool = true) -> void:
	if new_land == land:
		return
	land = new_land
	var live: bool = animate and is_inside_tree()
	for e: CPUParticles3D in [_weather, _extra]:
		if is_instance_valid(e):
			e.emitting = false
			if live:
				get_tree().create_timer(e.lifetime).timeout.connect(e.queue_free)
			else:
				e.free()
	_weather = null
	_extra = null
	if is_instance_valid(_prop):
		var old: Node3D = _prop
		if live:
			var sink := old.create_tween()
			sink.tween_property(old, "scale", Vector3.ONE * 0.01, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
			sink.tween_callback(old.queue_free)
		else:
			old.free()
	_prop = null
	_tint(SUN_TINT[land] if land >= 0 else Color.WHITE, live)
	if land < 0:
		return
	_weather = _make_weather(land)
	add_child(_weather)
	if land == CardData.Land.EMBER:
		_extra = _make_embers()
		add_child(_extra)
	_prop = _make_prop(land)
	_prop.position = PROP_AT
	add_child(_prop)
	if live:
		_prop.scale = Vector3.ONE * 0.01
		var rise := _prop.create_tween()
		rise.tween_interval(0.2)
		rise.tween_property(_prop, "scale", Vector3.ONE, 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func set_quality(q: int) -> void:
	_quality = q
	for e: CPUParticles3D in [_weather, _extra]:
		if is_instance_valid(e):
			e.amount = maxi(4, int(e.get_meta(&"full", e.amount)) / (2 if q == GameSettings.Quality.LOW else 1))


func prop() -> Node3D:
	return _prop


func _tint(mult: Color, live: bool) -> void:
	if room == null or room.sun == null:
		return
	var sun_to: Color = _sun_base * mult
	var amb_to: Color = _amb_base * mult
	if not live:
		room.sun.light_color = sun_to
		room.env.ambient_light_color = amb_to
		return
	var tw := create_tween().set_parallel()
	tw.tween_property(room.sun, "light_color", sun_to, 1.0)
	tw.tween_property(room.env, "ambient_light_color", amb_to, 1.0)


func _particles(tex: String, size: float, amount: int) -> CPUParticles3D:
	var e := CPUParticles3D.new()
	e.amount = amount if _quality != GameSettings.Quality.LOW else maxi(4, amount / 2)
	e.set_meta(&"full", amount)
	e.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	e.emission_box_extents = Vector3(6.2, 0.2, 6.2)
	e.local_coords = false
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE * size
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.vertex_color_use_as_albedo = true
	mat.albedo_texture = load(TEX % tex) as Texture2D
	quad.material = mat
	e.mesh = quad
	var fade := Gradient.new()
	fade.offsets = PackedFloat32Array([0.0, 0.15, 0.85, 1.0])
	fade.colors = PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 1), Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	e.color_ramp = fade
	return e


func _make_weather(l: int) -> CPUParticles3D:
	var e: CPUParticles3D
	match l:
		CardData.Land.EMBER:  # ash flakes drifting down
			e = _particles("circle_05", 0.08, 50)
			e.color = Color("#6a6266")
			e.position = Vector3(0, 4.5, 0)
			e.direction = Vector3(0.3, -1, 0)
			e.spread = 25.0
			e.gravity = Vector3(0, -0.2, 0)
			e.initial_velocity_min = 0.3
			e.initial_velocity_max = 0.6
			e.lifetime = 7.0
		CardData.Land.FROST:  # snow blowing across
			e = _particles("circle_05", 0.09, 90)
			e.color = Color.WHITE
			e.position = Vector3(-1.5, 5.0, 0)
			e.direction = Vector3(0.6, -1, 0.1)
			e.spread = 15.0
			e.gravity = Vector3(0.3, -0.4, 0)
			e.initial_velocity_min = 0.6
			e.initial_velocity_max = 1.1
			e.lifetime = 5.0
		CardData.Land.MUSHROOM:  # glowing spores rising
			e = _particles("circle_05", 0.08, 45)
			(e.mesh.material as StandardMaterial3D).blend_mode = BaseMaterial3D.BLEND_MODE_ADD
			e.color = Color("#b8ff8a")
			e.position = Vector3(0, 0.4, 0)
			e.direction = Vector3.UP
			e.spread = 30.0
			e.gravity = Vector3(0, 0.05, 0)
			e.initial_velocity_min = 0.1
			e.initial_velocity_max = 0.3
			e.lifetime = 8.0
		CardData.Land.DUNES:  # heat motes drifting up off the hot sand
			e = _particles("circle_05", 0.07, 45)
			(e.mesh.material as StandardMaterial3D).blend_mode = BaseMaterial3D.BLEND_MODE_ADD
			e.color = Color("#ffb04a")
			e.position = Vector3(0, 0.3, 0)
			e.direction = Vector3(0.2, 1, 0)
			e.spread = 25.0
			e.gravity = Vector3(0, 0.12, 0)
			e.initial_velocity_min = 0.15
			e.initial_velocity_max = 0.35
			e.lifetime = 6.0
		_:  # sugar rain: sprinkles
			e = _particles("circle_05", 0.08, 70)
			var ramp := Gradient.new()
			ramp.offsets = PackedFloat32Array([0.0, 0.25, 0.5, 0.75, 1.0])
			ramp.colors = PackedColorArray(CANDY)
			e.color_initial_ramp = ramp
			e.position = Vector3(0, 5.0, 0)
			e.direction = Vector3.DOWN
			e.spread = 8.0
			e.gravity = Vector3(0, -1.2, 0)
			e.initial_velocity_min = 0.8
			e.initial_velocity_max = 1.4
			e.lifetime = 3.5
	e.preprocess = e.lifetime
	return e


## Volcano: embers rising from the lava lanes.
func _make_embers() -> CPUParticles3D:
	var e := _particles("spark_04", 0.07, 30)
	(e.mesh.material as StandardMaterial3D).blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	e.color = Color("#ff8a2a")
	e.position = Vector3(0, 0.3, 0)
	e.direction = Vector3.UP
	e.spread = 20.0
	e.gravity = Vector3(0, 0.3, 0)
	e.initial_velocity_min = 0.4
	e.initial_velocity_max = 0.8
	e.lifetime = 3.0
	e.preprocess = e.lifetime
	return e


func _make_prop(l: int) -> Node3D:
	var root := Node3D.new()
	root.name = "FieldProp"
	match l:
		CardData.Land.EMBER:
			root.add_child(Palette.mesh(Palette.cylinder(0.45, 1.7, 2.3, 12), Toon.plain(Color("#6a3a2e")), Vector3(0, 1.15, 0)))
			root.add_child(Palette.mesh(Palette.cylinder(0.5, 0.5, 0.08, 12), _glow(Color("#ff7a1a")), Vector3(0, 2.32, 0), false))
			for i: int in 3:
				var a: float = TAU * float(i) / 3.0 + 0.4
				var drip := Palette.mesh(Palette.cylinder(0.1, 0.16, 1.1, 6), _glow(Color("#ff5a1a")), Vector3(cos(a) * 0.75, 1.75, sin(a) * 0.75), false)
				drip.rotation = Vector3(sin(a) * 0.55, 0, -cos(a) * 0.55)
				root.add_child(drip)
			var smoke := _particles("smoke_07", 0.9, 10)
			smoke.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
			smoke.emission_sphere_radius = 0.2
			smoke.color = Color("#7a7276")
			smoke.position = Vector3(0, 2.5, 0)
			smoke.direction = Vector3.UP
			smoke.spread = 15.0
			smoke.gravity = Vector3(0.2, 0.4, 0)
			smoke.initial_velocity_min = 0.5
			smoke.initial_velocity_max = 0.9
			smoke.lifetime = 3.0
			smoke.scale_amount_min = 0.6
			smoke.scale_amount_max = 1.4
			root.add_child(smoke)
		CardData.Land.FROST:
			var cloud := _cloud(Color("#8a9ab8"))
			cloud.position.y = 3.2
			root.add_child(cloud)
			var snow := _particles("circle_05", 0.1, 12)
			snow.emission_box_extents = Vector3(1.3, 0.1, 0.8)
			snow.spread = 20.0
			snow.color = Color.WHITE
			snow.position = Vector3(0, 2.8, 0)
			snow.direction = Vector3.DOWN
			snow.gravity = Vector3(0, -1.0, 0)
			snow.initial_velocity_min = 0.4
			snow.initial_velocity_max = 0.8
			snow.lifetime = 2.6
			root.add_child(snow)
			var bob := cloud.create_tween().set_loops()
			bob.tween_property(cloud, "position:y", 3.45, 1.6).set_trans(Tween.TRANS_SINE)
			bob.tween_property(cloud, "position:y", 3.2, 1.6).set_trans(Tween.TRANS_SINE)
		CardData.Land.MUSHROOM:
			for i: int in 3:
				var a: float = TAU * float(i) / 3.0
				var h: float = [2.2, 1.6, 1.3][i]
				var m := Node3D.new()
				m.position = Vector3(cos(a) * 0.8, 0, sin(a) * 0.8)
				m.add_child(Palette.mesh(Palette.cylinder(0.2, 0.28, h, 10), Toon.plain(Color("#fff1d6")), Vector3(0, h / 2.0, 0)))
				var cap := SphereMesh.new()
				cap.radius = 0.45 + 0.12 * (2 - i)
				cap.height = cap.radius
				cap.is_hemisphere = true
				cap.radial_segments = 14
				cap.rings = 4
				m.add_child(Palette.mesh(cap, Toon.plain(Color("#e4503a")), Vector3(0, h - 0.05, 0)))
				for j: int in 4:
					var b := Palette.mesh(Palette.cylinder(0.07, 0.07, 0.04, 8), Toon.plain(Color.WHITE), Vector3(cos(j * 1.7) * cap.radius * 0.55, h + cap.radius * 0.62, sin(j * 1.7) * cap.radius * 0.55))
					m.add_child(b)
				root.add_child(m)
		CardData.Land.DUNES:
			# A blazing sun hangs over the table, its rays slowly turning.
			var sun := Node3D.new()
			sun.position.y = 3.4
			sun.add_child(Palette.mesh(Palette.sphere(0.55, 16), _glow(Color("#ffd04a")), Vector3.ZERO, false))
			for i: int in 8:
				var a: float = TAU * float(i) / 8.0
				var ray := Palette.mesh(Palette.cylinder(0.0, 0.14, 0.5, 4), _glow(Color("#ffb03a")), Vector3(cos(a) * 0.85, sin(a) * 0.85, 0), false)
				ray.rotation.z = a - PI / 2.0
				sun.add_child(ray)
			root.add_child(sun)
			var spin := sun.create_tween().set_loops()
			spin.tween_property(sun, "rotation:z", TAU, 12.0).from(0.0)
		_:
			var cloud := _cloud(Color("#ffb3dd"))
			cloud.position.y = 3.0
			root.add_child(cloud)
			var rain := _particles("circle_05", 0.1, 12)
			rain.spread = 20.0
			var ramp := Gradient.new()
			ramp.offsets = PackedFloat32Array([0.0, 0.25, 0.5, 0.75, 1.0])
			ramp.colors = PackedColorArray(CANDY)
			rain.color_initial_ramp = ramp
			rain.emission_box_extents = Vector3(1.3, 0.1, 0.8)
			rain.position = Vector3(0, 2.6, 0)
			rain.direction = Vector3.DOWN
			rain.gravity = Vector3(0, -2.0, 0)
			rain.initial_velocity_min = 0.6
			rain.initial_velocity_max = 1.0
			rain.lifetime = 1.6
			root.add_child(rain)
			var bob := cloud.create_tween().set_loops()
			bob.tween_property(cloud, "position:y", 3.25, 1.4).set_trans(Tween.TRANS_SINE)
			bob.tween_property(cloud, "position:y", 3.0, 1.4).set_trans(Tween.TRANS_SINE)
	return root


func _cloud(col: Color) -> Node3D:
	var c := Node3D.new()
	var puffs: Array[Vector4] = [Vector4(0, 0, 0, 0.75), Vector4(0.7, -0.1, 0.1, 0.55), Vector4(-0.7, -0.1, -0.05, 0.6), Vector4(0.25, 0.35, -0.1, 0.5), Vector4(-0.3, 0.25, 0.2, 0.45)]
	for p: Vector4 in puffs:
		var s := SphereMesh.new()
		s.radius = p.w
		s.height = p.w * 1.6
		s.radial_segments = 12
		s.rings = 6
		c.add_child(Palette.mesh(s, Toon.plain(col), Vector3(p.x, p.y, p.z)))
	return c


func _glow(col: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.albedo_color = col
	m.emission_enabled = true
	m.emission = col
	return m
