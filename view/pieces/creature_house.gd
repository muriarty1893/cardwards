class_name CreatureHouse
extends Node3D
## A little home some creatures bring when they are played (decoration only, living board spec
## 9): a mushroom cottage, a stone hut, a candy house or an igloo, by the creature's land. It
## pops up beside the roam zone; when its creature is inside, the window glows, the chimney
## puffs and the house wobbles. When the creature is gone it darkens and sinks away.

## Creatures that bring a house (small ones).
const OWNERS: Array[StringName] = [
	&"sporeling", &"puffcap", &"glimmer_morel", &"cinderpup", &"flarebeak", &"ashmite",
	&"gumdrop", &"taffy_snail", &"sugar_sprite", &"snowmite", &"iceling", &"frostfang",
]
const WINDOW_OFF := Color("#3a3040")
const WINDOW_ON := Color("#ffd86a")

var land: int = 0
## The creature that lives here (CreatureView).
var resident: Node3D
## +1 or -1: which way the door faces along z (towards the seam).
var facing: float = -1.0
var _window: MeshInstance3D
var _window_mat: StandardMaterial3D
var _chimney_top := Vector3.INF
var _smoke_in: float = 0.0
var occupied: bool = false
var _wobble: Tween


static func wants_house(id: StringName) -> bool:
	return id in OWNERS


static func create(l: int, door_towards: float) -> CreatureHouse:
	var h := CreatureHouse.new()
	h.name = "House"
	h.land = l
	h.facing = door_towards
	h._build()
	return h


## Where the creature stands to go in (world space, in front of the door).
func door_point() -> Vector3:
	return global_position + Vector3(0, 0, facing * 0.42)


func _build() -> void:
	var body := Node3D.new()
	body.name = "Body"
	add_child(body)
	# Doors face the seam: the model is built facing -z and turned when facing is +1.
	body.rotation.y = 0.0 if facing < 0.0 else PI
	var door_mat: ShaderMaterial = Toon.plain(Color("#5a3a22"))
	_window_mat = StandardMaterial3D.new()
	_window_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_window_mat.albedo_color = WINDOW_OFF
	match land:
		CardData.Land.MUSHROOM:
			body.add_child(Palette.mesh(Palette.cylinder(0.2, 0.24, 0.34, 12), Toon.plain(Color("#fff1d6")), Vector3(0, 0.17, 0)))
			var cap := SphereMesh.new()
			cap.radius = 0.36
			cap.height = 0.34
			cap.is_hemisphere = true
			cap.radial_segments = 14
			cap.rings = 4
			body.add_child(Palette.mesh(cap, Toon.plain(Color("#e4503a")), Vector3(0, 0.32, 0)))
			for i: int in 5:
				var a: float = float(i) * 1.3
				body.add_child(Palette.mesh(Palette.cylinder(0.045, 0.045, 0.03, 8), Toon.plain(Color.WHITE), Vector3(cos(a) * 0.22, 0.47 + 0.03 * (i % 2), sin(a) * 0.22)))
			body.add_child(Palette.mesh(_box(Vector3(0.12, 0.18, 0.03)), door_mat, Vector3(0, 0.09, -0.215)))
			_window = Palette.mesh(Palette.cylinder(0.045, 0.045, 0.02, 10), _window_mat, Vector3(0.12, 0.22, -0.2), false)
			_window.rotation.x = PI / 2.0
		CardData.Land.EMBER:
			body.add_child(Palette.mesh(Palette.cylinder(0.24, 0.27, 0.3, 10), Toon.plain(Color("#8a7a72")), Vector3(0, 0.15, 0)))
			body.add_child(Palette.mesh(Palette.cylinder(0.0, 0.34, 0.28, 10), Toon.plain(Color("#9a3a2a")), Vector3(0, 0.44, 0)))
			body.add_child(Palette.mesh(_box(Vector3(0.08, 0.2, 0.08)), Toon.plain(Color("#5a4a44")), Vector3(0.14, 0.5, 0.05)))
			_chimney_top = Vector3(0.14, 0.62, 0.05)
			body.add_child(Palette.mesh(_box(Vector3(0.12, 0.17, 0.03)), door_mat, Vector3(0, 0.085, -0.255)))
			_window = Palette.mesh(_box(Vector3(0.07, 0.07, 0.02)), _window_mat, Vector3(-0.13, 0.19, -0.235), false)
		CardData.Land.CANDY:
			body.add_child(Palette.mesh(_box(Vector3(0.4, 0.28, 0.34)), Toon.plain(Color("#c98a52")), Vector3(0, 0.14, 0)))
			for side: float in [-1.0, 1.0]:
				var roof := Palette.mesh(_box(Vector3(0.26, 0.04, 0.42)), Toon.plain(Color("#ff9dcc")), Vector3(side * 0.1, 0.36, 0))
				roof.rotation.z = -side * 0.62
				body.add_child(roof)
			for i: int in 4:
				var cols: Array[Color] = [Color("#ff5a5a"), Color("#5ad1ff"), Color("#ffd84a"), Color("#7aff7a")]
				var dot := SphereMesh.new()
				dot.radius = 0.03
				dot.height = 0.06
				dot.radial_segments = 6
				dot.rings = 3
				body.add_child(Palette.mesh(dot, Toon.plain(cols[i]), Vector3(-0.15 + 0.1 * i, 0.27, -0.175)))
			body.add_child(Palette.mesh(_box(Vector3(0.11, 0.16, 0.03)), Toon.plain(Color("#ffffff")), Vector3(0.07, 0.08, -0.175)))
			_window = Palette.mesh(_box(Vector3(0.07, 0.07, 0.02)), _window_mat, Vector3(-0.1, 0.16, -0.175), false)
			_chimney_top = Vector3(-0.12, 0.5, 0.08)
			body.add_child(Palette.mesh(Palette.cylinder(0.03, 0.03, 0.18, 6), Toon.plain(Color("#ffffff")), Vector3(-0.12, 0.42, 0.08)))
		_:
			var dome := SphereMesh.new()
			dome.radius = 0.3
			dome.height = 0.3
			dome.is_hemisphere = true
			dome.radial_segments = 16
			dome.rings = 5
			body.add_child(Palette.mesh(dome, Toon.plain(Color("#eef6ff")), Vector3.ZERO))
			var tunnel := Palette.mesh(Palette.cylinder(0.12, 0.12, 0.2, 10), Toon.plain(Color("#dcecff")), Vector3(0, 0.06, -0.3))
			tunnel.rotation.x = PI / 2.0
			body.add_child(tunnel)
			body.add_child(Palette.mesh(Palette.cylinder(0.08, 0.08, 0.02, 10), door_mat, Vector3(0, 0.06, -0.405), false))
			(body.get_child(body.get_child_count() - 1) as Node3D).rotation.x = PI / 2.0
			_window = Palette.mesh(Palette.cylinder(0.04, 0.04, 0.02, 8), _window_mat, Vector3(0.14, 0.17, -0.22), false)
			_window.rotation.x = PI / 2.0 - 0.6
	body.add_child(_window)


func _box(size: Vector3) -> BoxMesh:
	var b := BoxMesh.new()
	b.size = size
	return b


## Springs up out of the ground.
func pop_in() -> void:
	scale = Vector3.ONE * 0.01
	var tw := create_tween()
	tw.tween_property(self, "scale", Vector3.ONE, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if is_inside_tree():
		Burst.spawn(get_parent(), &"dust_ring", global_position + Vector3(0, 0.05, 0), Color.WHITE, 0.5)


## The resident is gone: lights out, then it sinks into the ground and frees itself.
func sink_away() -> void:
	set_occupied(false)
	resident = null
	var tw := create_tween()
	tw.tween_interval(0.3)
	tw.tween_property(self, "scale", Vector3(1.2, 0.01, 1.2), 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tw.tween_callback(queue_free)


func set_occupied(on: bool) -> void:
	if on == occupied:
		return
	occupied = on
	_window_mat.albedo_color = WINDOW_ON if on else WINDOW_OFF
	_smoke_in = 0.2
	if _wobble and _wobble.is_valid():
		_wobble.kill()
	var body: Node3D = get_node("Body")
	body.scale = Vector3.ONE
	_wobble = create_tween()
	_wobble.tween_property(body, "scale", Vector3(1.12, 0.88, 1.12), 0.08)
	_wobble.tween_property(body, "scale", Vector3.ONE, 0.35).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)


func _process(delta: float) -> void:
	if not occupied or not _chimney_top.is_finite():
		return
	_smoke_in -= delta
	if _smoke_in <= 0.0:
		_smoke_in = 0.7
		var body: Node3D = get_node("Body")
		Burst.spawn(get_parent(), &"smoke", body.global_transform * _chimney_top, Color("#d8d4dc"), 0.25)
