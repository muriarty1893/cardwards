class_name Island
extends Node3D
## One land: a long lane strip with a procedural surface, glowing edge and a few props.
## (Named Island for history; it is the tile a creature and building stand on.)

enum Highlight { OFF, VALID, TARGET }

const WIDTH := 2.32
const LENGTH := 4.5
const TOP_Y := 0.14
const EDGE: Array[Color] = [Color("#ffe14a"), Color("#4ae8ff")]

var land: int = 0
var _mat: ShaderMaterial


func setup(land_type: int, player: int = 0) -> void:
	land = land_type
	var plane := PlaneMesh.new()
	plane.size = Vector2(WIDTH, LENGTH)
	_mat = ShaderMaterial.new()
	_mat.shader = load("res://view/board/lane.gdshader") as Shader
	_mat.set_shader_parameter("land", land)
	_mat.set_shader_parameter("size", Vector2(WIDTH, LENGTH))
	_mat.set_shader_parameter("edge_color", EDGE[player])
	var mi := Palette.mesh(plane, _mat, Vector3(0, TOP_Y, 0), false)
	add_child(mi)


func set_highlight(mode: Highlight) -> void:
	_mat.set_shader_parameter("highlight", float(mode))


func contains(local_x: float, local_z: float) -> bool:
	return absf(local_x) <= WIDTH / 2.0 and absf(local_z) <= LENGTH / 2.0
