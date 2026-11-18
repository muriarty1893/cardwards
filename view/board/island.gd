class_name Island
extends Node3D
## One land: a long painted lane strip with wavy outlined edges and land props.
## (Named Island for history; it is the tile a creature and building stand on.)

## GUARD: an enemy Guard that must be attacked first (pulsing red-gold). MERGE: the partner of the dragged card
## (a swirling gold-and-pink band).
enum Highlight { OFF, VALID, TARGET, GUARD, MERGE }

const WIDTH := 2.6
const LENGTH := 5.4
const TOP_Y := 0.14
const EDGE: Array[Color] = [Color("#ffe14a"), Color("#4ae8ff")]
## Seconds for a land change to sweep the tile.
const MORPH_TIME := 1.1
const FIELD_FADE := 1.2

var land: int = 0
## The land's look (0..2) and set-piece corner (0 left, 1 right), rolled each time the land is set.
var variant: int = 0
var corner: int = 0
## How many times the land has changed (feeds the look roll).
var changes: int = 0
var highlight: Highlight = Highlight.OFF
var _mat: ShaderMaterial


var _player: int = 0
var _lane: int = 0
var shape: TileShape
var _mesh_size := Vector2.ZERO
var _dressing: Node3D
var _density: float = 1.0
var _field_tween: Tween
var _wipe: Tween


## `shape_`: the tile's outline (its lane's curves); a straight full-width tile when null.
func setup(land_type: int, player: int = 0, lane: int = 0, density: float = 1.0, shape_: TileShape = null) -> void:
	land = land_type
	_player = player
	_lane = lane
	shape = shape_ if shape_ else TileShape.straight(lane, position.z)
	_roll()
	var plane := PlaneMesh.new()
	# Wide enough for the lane at its widest; the shader clips to the curves.
	_mesh_size = Vector2(2.0 * shape.max_half_extent() + 0.04, LENGTH)
	plane.size = _mesh_size
	_mat = ShaderMaterial.new()
	_mat.shader = load("res://view/board/lane.gdshader") as Shader
	_mat.set_shader_parameter("land", land)
	_mat.set_shader_parameter("size", _mesh_size)
	_mat.set_shader_parameter("wave_seed", float(player * 4 + lane) * 1.7)
	var lc: Array[Vector4] = shape.left_curve()
	var rc: Array[Vector4] = shape.right_curve()
	_mat.set_shader_parameter("left_c1", lc[0])
	_mat.set_shader_parameter("left_c2", lc[1])
	_mat.set_shader_parameter("right_c1", rc[0])
	_mat.set_shader_parameter("right_c2", rc[1])
	_mat.set_shader_parameter("tile_origin", Vector2(shape.tile_x, shape.tile_z))
	_mat.set_shader_parameter("outer_left", 1.0 if lane == 0 else 0.0)
	_mat.set_shader_parameter("outer_right", 1.0 if lane == 3 else 0.0)
	_apply_look_uniforms()
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
	_dressing = LaneDressing.build(land, _player, _player * 4 + _lane, density, shape, variant, corner)
	_dressing.position.y = TOP_Y
	add_child(_dressing)


## Turns the tile into `new_land`: the ground wipes outward from `origin` (tile-local x/z) behind
## a bright front, the old cover sinks and the new cover and props spring up as the front passes.
func change_land(new_land: int, origin: Vector2 = Vector2.ZERO, animate: bool = true) -> void:
	if new_land == land:
		return
	var old: int = land
	land = new_land
	changes += 1
	_roll()
	# A change while the last one is still sweeping: finish that one first.
	if _wipe and _wipe.is_valid():
		_wipe.kill()
	_mat.set_shader_parameter("prev_land", old)
	_mat.set_shader_parameter("land", new_land)
	_mat.set_shader_parameter("morph_origin", origin)
	var old_dressing: Node3D = _dressing
	_dressing = LaneDressing.build(land, _player, _player * 4 + _lane, _density, shape, variant, corner)
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
	# Props and set pieces pop up one by one as the front reaches them.
	var reach: float = Vector2(WIDTH, LENGTH).length() + 0.6
	var pops: Array[Node] = _dressing.get_node("Accents").get_children()
	pops.append_array(_dressing.get_node("SetPieces").get_children())
	for prop: Node in pops:
		var n := prop as Node3D
		var d: float = Vector2(n.position.x, n.position.z).distance_to(origin)
		var full: Vector3 = n.scale
		n.scale = Vector3.ONE * 0.01
		var pop := n.create_tween()
		pop.tween_interval(MORPH_TIME * clampf(d / reach, 0.0, 1.0))
		pop.tween_property(n, "scale", full, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


## Shows `land_` with a chosen look right away (dev previews and tests).
func set_look(land_: int, variant_: int, corner_: int) -> void:
	land = land_
	variant = variant_
	corner = corner_
	_mat.set_shader_parameter("land", land)
	_mat.set_shader_parameter("prev_land", land)
	_mat.set_shader_parameter("morph", 1.0)
	_apply_look_uniforms()
	set_density(_density)


## Variant (x) and corner (y) for player `p`'s tile in `lane` after `n` land changes, from the layout seed.
static func roll_look(seed: int, p: int, lane: int, n: int) -> Vector2i:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash([seed, p, lane, n, 0x1a4d])
	return Vector2i(rng.randi() % LaneDressing.VARIANTS, rng.randi() % 2)


func _roll() -> void:
	var r: Vector2i = roll_look(shape.layout.seed, _player, _lane, changes)
	variant = r.x
	corner = r.y
	if _mat:
		_apply_look_uniforms()


## The lane shader paints the look's flat features (lava trickles, streams, paths) from these.
func _apply_look_uniforms() -> void:
	_mat.set_shader_parameter("variant", variant)
	_mat.set_shader_parameter("corner_side", -1.0 if corner == 0 else 1.0)
	var box: Rect2 = SetPieces.corner_box(shape, _player, corner)
	_mat.set_shader_parameter("corner_box", Vector4(box.position.x, box.position.y, box.end.x, box.end.y))
	var band: Rect2 = SetPieces.edge_band(shape, _player, corner)
	_mat.set_shader_parameter("side_band", Vector4(band.position.x, band.position.y, band.end.x, band.end.y))


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
	return shape.contains(local_x, local_z)


func material() -> ShaderMaterial:
	return _mat


func mesh_size() -> Vector2:
	return _mesh_size
