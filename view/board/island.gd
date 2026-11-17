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

var land: int = 0
var highlight: Highlight = Highlight.OFF
var _mat: ShaderMaterial


var _player: int = 0
var _lane: int = 0
var _dressing: Node3D


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
	if is_instance_valid(_dressing):
		_dressing.free()
	_dressing = LaneDressing.build(land, _player, _player * 4 + _lane, density)
	_dressing.position.y = TOP_Y
	add_child(_dressing)


func set_highlight(mode: Highlight) -> void:
	highlight = mode
	_mat.set_shader_parameter("highlight", float(mode))


func contains(local_x: float, local_z: float) -> bool:
	return absf(local_x) <= WIDTH / 2.0 and absf(local_z) <= LENGTH / 2.0
