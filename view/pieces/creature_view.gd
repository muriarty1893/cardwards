class_name CreatureView
extends Node3D
## A chunky blob creature built from primitives. A scene at
## res://view/pieces/creatures/<id>.tscn (root extends CreatureView) overrides the blob.

const BASE_Y := 0.58

## id -> [body colour, scale, feature]
const LOOKS: Dictionary = {
	&"sporeling": ["#9be36a", 0.9, &"cap"], &"mossback": ["#5aa34a", 1.05, &"shell"],
	&"puffcap": ["#f2e6c8", 0.95, &"cap"], &"glimmer_morel": ["#c9a46a", 1.05, &"cap"],
	&"rootstalker": ["#7a5a3a", 1.1, &"horns"], &"elder_shroomhulk": ["#6fbf5a", 1.3, &"cap"],
	&"cinderpup": ["#ff9a3a", 0.85, &"ears"], &"ashmite": ["#6a5050", 0.85, &"spikes"],
	&"flarebeak": ["#ff6a3a", 0.95, &"wings"], &"magmaw": ["#d8402a", 1.1, &"horns"],
	&"blazehorn": ["#ff7a2a", 1.15, &"horns"], &"inferno_drake": ["#e5384f", 1.3, &"wings"],
	&"gumdrop": ["#ff6ab0", 0.85, &"none"], &"taffy_snail": ["#ffd84a", 0.95, &"shell"],
	&"lollibat": ["#b06cff", 0.9, &"wings"], &"sugar_sprite": ["#7fe0ff", 0.95, &"ears"],
	&"jellywobble": ["#4ad0ff", 1.1, &"none"], &"bonbon_behemoth": ["#ff8ad8", 1.3, &"ears"],
	&"snowmite": ["#e8f6ff", 0.85, &"ears"], &"iceling": ["#9fd8ff", 0.95, &"spikes"],
	&"frostfang": ["#6aa8ff", 1.0, &"ears"], &"glacier_tortoise": ["#7fb0c8", 1.15, &"shell"],
	&"rimewing": ["#bfe8ff", 1.05, &"wings"], &"blizzard_titan": ["#5a8adf", 1.3, &"horns"],
}

var card: CardData
var busy: bool = false
var body: Node3D
var _badge: Label3D
var _ice: MeshInstance3D
var _phase: float = 0.0
var _t: float = 0.0
var _mat: StandardMaterial3D


static func create(c: CardData) -> CreatureView:
	var path: String = "res://view/pieces/creatures/%s.tscn" % c.id
	var v: CreatureView
	if ResourceLoader.exists(path):
		v = (load(path) as PackedScene).instantiate() as CreatureView
	else:
		v = CreatureView.new()
		v._build_blob(c)
	v.card = c
	v._add_badge()
	v._phase = randf() * TAU
	return v


func _build_blob(c: CardData) -> void:
	var look: Array = LOOKS.get(c.id, ["#ffd84a", 1.0, &"none"])
	var col := Color(look[0] as String)
	var sc: float = look[1]
	var feature: StringName = look[2]
	body = Node3D.new()
	body.scale = Vector3.ONE * sc
	add_child(body)
	_mat = Palette.mat(col, 0.45)
	var main := Palette.mesh(Palette.sphere(0.45, 24), _mat)
	main.scale = Vector3(1, 0.9, 1)
	body.add_child(main)
	var white := Palette.mat(Color.WHITE, 0.3)
	var black := Palette.mat(Color("#111111"), 0.3)
	for s: float in [-1.0, 1.0]:
		body.add_child(Palette.mesh(Palette.sphere(0.1, 12), white, Vector3(0.15 * s, 0.12, 0.38)))
		body.add_child(Palette.mesh(Palette.sphere(0.05, 10), black, Vector3(0.15 * s, 0.12, 0.47)))
		var foot := Palette.mesh(Palette.sphere(0.13, 10), _mat, Vector3(0.22 * s, -0.38, 0.1))
		foot.scale = Vector3(1, 0.6, 1)
		body.add_child(foot)
	var accent := Palette.mat(col.darkened(0.35), 0.6)
	match feature:
		&"cap":
			var cap := SphereMesh.new()
			cap.radius = 0.42
			cap.height = 0.3
			cap.is_hemisphere = true
			body.add_child(Palette.mesh(cap, Palette.mat(Color("#e8443a"), 0.6), Vector3(0, 0.3, 0)))
		&"horns":
			for s: float in [-1.0, 1.0]:
				var h := Palette.mesh(Palette.cylinder(0.0, 0.08, 0.3, 8), Palette.mat(Color("#fff3dd")), Vector3(0.22 * s, 0.45, 0.05))
				h.rotation.z = -0.4 * s
				body.add_child(h)
		&"ears":
			for s: float in [-1.0, 1.0]:
				var e := Palette.mesh(Palette.sphere(0.12, 10), accent, Vector3(0.28 * s, 0.38, 0))
				e.scale = Vector3(0.6, 1.3, 0.5)
				body.add_child(e)
		&"spikes":
			for i: int in 5:
				var a: float = -0.8 + i * 0.4
				var sp := Palette.mesh(Palette.cylinder(0.0, 0.06, 0.2, 6), accent, Vector3(sin(a) * 0.3, 0.38 + cos(a) * 0.05, -0.15))
				sp.rotation.z = -a * 0.8
				body.add_child(sp)
		&"wings":
			for s: float in [-1.0, 1.0]:
				var w := Palette.mesh(Palette.sphere(0.2, 10), accent, Vector3(0.45 * s, 0.1, -0.1))
				w.scale = Vector3(1.2, 0.35, 0.8)
				w.rotation.z = 0.5 * s
				body.add_child(w)
		&"shell":
			var sh := SphereMesh.new()
			sh.radius = 0.4
			sh.height = 0.4
			sh.is_hemisphere = true
			var shell := Palette.mesh(sh, accent, Vector3(0, 0.05, -0.12))
			shell.rotation.x = -0.6
			body.add_child(shell)


func _add_badge() -> void:
	_badge = Label3D.new()
	_badge.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_badge.no_depth_test = true
	_badge.font_size = 44
	_badge.outline_size = 14
	_badge.outline_modulate = Palette.INK
	_badge.pixel_size = 0.006
	_badge.position = Vector3(0, 0.75 * (body.scale.y if body else 1.0) + 0.2, 0)
	add_child(_badge)
	_ice = Palette.mesh(BoxMesh.new(), _ice_mat(), Vector3(0, 0, 0), false)
	_ice.scale = Vector3.ONE * 1.05 * (body.scale.x if body else 1.0)
	_ice.visible = false
	add_child(_ice)


func _ice_mat() -> StandardMaterial3D:
	var m := Palette.mat(Color("#bfe8ff"), 0.05)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color.a = 0.45
	return m


func set_stats(atk: int, hp_left: int, max_hp: int) -> void:
	_badge.text = "%d  ♥%d" % [atk, hp_left]
	_badge.modulate = Color.WHITE if hp_left >= max_hp else Color("#ffb0b0")


func set_frozen(on: bool) -> void:
	_ice.visible = on


func _process(delta: float) -> void:
	_t += delta
	if busy or body == null:
		return
	var hop: float = maxf(0.0, sin(_t * 2.6 + _phase))
	body.position.y = hop * 0.15
	body.scale.y = body.scale.x * (1.0 - (1.0 - hop) * 0.06)
