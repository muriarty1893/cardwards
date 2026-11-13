class_name Island
extends Node3D
## One floating land tile with decorations and a highlight ring.

enum Highlight { OFF, VALID, TARGET }

const RADIUS := 1.05

var land: int = 0
var _ring: MeshInstance3D
var _ring_mat: StandardMaterial3D
var _mode: Highlight = Highlight.OFF
var _t: float = 0.0


func setup(land_type: int) -> void:
	land = land_type
	add_child(Palette.mesh(Palette.cylinder(RADIUS, RADIUS, 0.28, 32), Palette.mat(Palette.LAND_TOP[land])))
	add_child(Palette.mesh(Palette.cylinder(RADIUS, 0.8, 0.35, 32), Palette.mat(Palette.LAND_SIDE[land], 1.0), Vector3(0, -0.3, 0)))
	_decorate()
	var torus := TorusMesh.new()
	torus.inner_radius = RADIUS + 0.02
	torus.outer_radius = RADIUS + 0.12
	torus.rings = 48
	_ring_mat = StandardMaterial3D.new()
	_ring_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_ring_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_ring = Palette.mesh(torus, _ring_mat, Vector3(0, 0.16, 0), false)
	_ring.visible = false
	add_child(_ring)


func set_highlight(mode: Highlight) -> void:
	_mode = mode
	_ring.visible = mode != Highlight.OFF
	_ring_mat.albedo_color = Color.WHITE if mode == Highlight.VALID else Palette.GOLD


func _process(delta: float) -> void:
	if _mode == Highlight.OFF:
		return
	_t += delta
	_ring_mat.albedo_color.a = 0.55 + 0.45 * sin(_t * 5.0)


## Small props at the back of the tile so the creature spot stays clear.
func _decorate() -> void:
	var spots: Array[Vector3] = [Vector3(-0.62, 0, -0.5), Vector3(0.66, 0, -0.42), Vector3(-0.75, 0, 0.35)]
	match land:
		CardData.Land.MUSHROOM:
			for i: int in spots.size():
				var s: float = [1.0, 0.7, 0.55][i]
				var p: Vector3 = spots[i]
				add_child(Palette.mesh(Palette.cylinder(0.05 * s, 0.07 * s, 0.3 * s, 8), Palette.mat(Color("#fff3dd")), p + Vector3(0, 0.14 + 0.15 * s, 0)))
				var cap := SphereMesh.new()
				cap.radius = 0.2 * s
				cap.height = 0.2 * s
				cap.is_hemisphere = true
				add_child(Palette.mesh(cap, Palette.mat(Color("#e8443a"), 0.6), p + Vector3(0, 0.14 + 0.3 * s, 0)))
		CardData.Land.EMBER:
			var rock := Palette.mat(Color("#3a2a2a"), 0.9, true)
			rock.emission_enabled = true
			rock.emission = Color("#ff4400")
			rock.emission_energy_multiplier = 0.6
			for p: Vector3 in spots:
				var r := Palette.mesh(Palette.sphere(0.17, 6), rock, p + Vector3(0, 0.2, 0))
				r.scale = Vector3(1.0, 0.8, 1.1)
				r.rotation = Vector3(0.3, p.x * 2.0, 0.2)
				add_child(r)
		CardData.Land.CANDY:
			var colors: Array[Color] = [Color("#ff4fa0"), Color("#4fd0ff"), Color("#ffd84a")]
			for i: int in spots.size():
				var p: Vector3 = spots[i]
				add_child(Palette.mesh(Palette.cylinder(0.025, 0.025, 0.45, 6), Palette.mat(Color.WHITE), p + Vector3(0, 0.36, 0)))
				var pop := TorusMesh.new()
				pop.inner_radius = 0.05
				pop.outer_radius = 0.16
				var t := Palette.mesh(pop, Palette.mat(colors[i], 0.4), p + Vector3(0, 0.62, 0))
				t.rotation.x = PI / 2.0
				add_child(t)
		CardData.Land.FROST:
			var ice := Palette.mat(Color("#bfe8ff"), 0.1)
			ice.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			ice.albedo_color.a = 0.85
			for i: int in spots.size():
				var h: float = [0.5, 0.35, 0.28][i]
				var cone := Palette.cylinder(0.0, 0.11, h, 5)
				add_child(Palette.mesh(cone, ice, spots[i] + Vector3(0, 0.14 + h / 2.0, 0)))
