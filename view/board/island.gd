class_name Island
extends Node3D
## One land: a long painted lane strip with wavy outlined edges and land props.
## (Named Island for history; it is the tile a creature and building stand on.)

## GUARD: an enemy Guard that must be attacked first (pulsing red-gold).
enum Highlight { OFF, VALID, TARGET, GUARD }

const WIDTH := 2.6
const LENGTH := 5.4
const TOP_Y := 0.14
const EDGE: Array[Color] = [Color("#ffe14a"), Color("#4ae8ff")]
## Seconds for a land change to sweep the tile.
const MORPH_TIME := 1.1
const FIELD_FADE := 1.2

var land: int = 0
var highlight: Highlight = Highlight.OFF
var _mat: ShaderMaterial


var _player: int = 0
var _lane: int = 0
var _dressing: Node3D
var _density: float = 1.0
var _field_tween: Tween
var _wipe: Tween


func setup(land_type: int, player: int = 0, lane: int = 0, density: float = 1.0) -> void:
	land = land_type
	_player = player
	_lane = lane
	var plane := PlaneMesh.new()
	# A little wider than the hit area so the wavy painted edge fits inside the mesh.
	plane.size = Vector2(WIDTH + 0.12, LENGTH)
	_mat = ShaderMaterial.new()
	_mat.shader = load("res://view/board/lane.gdshader") as Shader
	_mat.set_shader_parameter("land", land)
	_mat.set_shader_parameter("size", Vector2(WIDTH + 0.12, LENGTH))
	_mat.set_shader_parameter("wave_seed", float(player * 4 + lane) * 1.7)
	_mat.set_shader_parameter("fbm_tex", NoiseBank.fbm())
	_mat.set_shader_parameter("cell_tex", NoiseBank.cells())
	_mat.set_shader_parameter("edge_color", EDGE[player])
	var mi := Palette.mesh(plane, _mat, Vector3(0, TOP_Y, 0), false)
	add_child(mi)
	set_density(density)


## Rebuilds the ground cover at `density` (1 = High, 0.5 = Low).
func set_density(density: float) -> void:
	_density = density
	if is_instance_valid(_dressing):
		_dressing.free()
	_dressing = LaneDressing.build(land, _player, _player * 4 + _lane, density)
	_dressing.position.y = TOP_Y
	add_child(_dressing)


## Turns the tile into `new_land`: the ground wipes outward from `origin` (tile-local x/z) behind
## a bright front, the old cover sinks and the new cover and props spring up as the front passes.
func change_land(new_land: int, origin: Vector2 = Vector2.ZERO, animate: bool = true) -> void:
	if new_land == land:
		return
	var old: int = land
	land = new_land
	# A change while the last one is still sweeping: finish that one first.
	if _wipe and _wipe.is_valid():
		_wipe.kill()
	_mat.set_shader_parameter("prev_land", old)
	_mat.set_shader_parameter("land", new_land)
	_mat.set_shader_parameter("morph_origin", origin)
	var old_dressing: Node3D = _dressing
	_dressing = LaneDressing.build(land, _player, _player * 4 + _lane, _density)
	_dressing.position.y = TOP_Y
	add_child(_dressing)
	if not animate or not is_inside_tree():
		_mat.set_shader_parameter("morph", 1.0)
		if is_instance_valid(old_dressing):
			old_dressing.free()
		return
	_mat.set_shader_parameter("morph", 0.0)
	_wipe = create_tween()
	_wipe.tween_method(func(v: float) -> void: _mat.set_shader_parameter("morph", v), 0.0, 1.0, MORPH_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	if is_instance_valid(old_dressing):
		var sink := create_tween()
		sink.tween_property(old_dressing, "scale", Vector3(1.0, 0.01, 1.0), MORPH_TIME * 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
		sink.tween_callback(old_dressing.queue_free)
	var cover: Node3D = _dressing.get_node("Cover")
	cover.scale = Vector3(1.0, 0.01, 1.0)
	var grow := create_tween()
	grow.tween_interval(MORPH_TIME * 0.35)
	grow.tween_property(cover, "scale", Vector3.ONE, MORPH_TIME * 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# Props pop up one by one as the front reaches them.
	var reach: float = Vector2(WIDTH, LENGTH).length() + 0.6
	for prop: Node in _dressing.get_node("Accents").get_children():
		var n := prop as Node3D
		var d: float = Vector2(n.position.x, n.position.z).distance_to(origin)
		var full: Vector3 = n.scale
		n.scale = Vector3.ONE * 0.01
		var pop := n.create_tween()
		pop.tween_interval(MORPH_TIME * clampf(d / reach, 0.0, 1.0))
		pop.tween_property(n, "scale", full, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## A field's weather over the tile (`field_land` -1 clears it), faded in or out.
func set_field(field_land: int, animate: bool = true) -> void:
	if _field_tween and _field_tween.is_valid():
		_field_tween.kill()
	var cur: Variant = _mat.get_shader_parameter("field_amount")
	var from: float = cur if cur is float else 0.0
	if field_land >= 0:
		_mat.set_shader_parameter("field_land", field_land)
	if not animate or not is_inside_tree():
		_mat.set_shader_parameter("field_amount", 1.0 if field_land >= 0 else 0.0)
		if field_land < 0:
			_mat.set_shader_parameter("field_land", -1)
		return
	_field_tween = create_tween()
	_field_tween.tween_method(func(v: float) -> void: _mat.set_shader_parameter("field_amount", v), from if field_land < 0 else 0.0, 1.0 if field_land >= 0 else 0.0, FIELD_FADE)
	if field_land < 0:
		_field_tween.tween_callback(func() -> void: _mat.set_shader_parameter("field_land", -1))


func set_highlight(mode: Highlight) -> void:
	highlight = mode
	_mat.set_shader_parameter("highlight", float(mode))


func contains(local_x: float, local_z: float) -> bool:
	return absf(local_x) <= WIDTH / 2.0 and absf(local_z) <= LENGTH / 2.0
