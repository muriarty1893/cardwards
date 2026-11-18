class_name Separators
extends Node3D
## The lines between lanes (board look 2, spec 1.2-1.3): one thin raised ribbon per inner border curve, running the
## whole board. Hidden (reveal 0) until the board splits after the opening sweep, then drawn outward from the seam.

const WIDTH := 0.1
const HEIGHT := 0.025
## Samples along the board.
const SAMPLES := 72
## Across-profile: offset (fraction of half width) and height (fraction of HEIGHT), a low rounded arch.
const PROFILE: Array[Vector2] = [Vector2(-1.0, 0.0), Vector2(-0.55, 0.75), Vector2(0.0, 1.0), Vector2(0.55, 0.75), Vector2(1.0, 0.0)]
## Over the board ends a little so the ribbon reaches the frame.
const OVERHANG := 0.04

var reveal: float = 0.0:
	set(v):
		reveal = clampf(v, 0.0, 1.0)
		if _mat:
			_mat.set_shader_parameter("reveal", reveal)
var _mat: ShaderMaterial
var _lines: Array[PackedVector3Array] = []


func build(layout: BoardLayout) -> void:
	name = "Separators"
	_mat = ShaderMaterial.new()
	_mat.shader = load("res://view/board/separator.gdshader") as Shader
	_mat.set_shader_parameter("reveal", reveal)
	for i: int in 3:
		var line := PackedVector3Array()
		var z_end: float = BoardLayout.Z_END + OVERHANG
		for k: int in SAMPLES:
			var z: float = lerpf(-z_end, z_end, k / float(SAMPLES - 1))
			line.append(Vector3(layout.border_x(i, z), Island.TOP_Y + HEIGHT, z))
		_lines.append(line)
		var mi := MeshInstance3D.new()
		mi.name = "Ribbon%d" % i
		mi.mesh = _ribbon(layout, i, z_end)
		mi.material_override = _mat
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(mi)


func ribbon_count() -> int:
	return _lines.size()


## Ribbon i's top centre line (world space).
func centre_line(i: int) -> PackedVector3Array:
	return _lines[i]


func _ribbon(layout: BoardLayout, i: int, z_end: float) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var cols: int = PROFILE.size()
	for k: int in SAMPLES:
		var z: float = lerpf(-z_end, z_end, k / float(SAMPLES - 1))
		var x: float = layout.border_x(i, z)
		var slope: float = (layout.border_x(i, z + 0.01) - layout.border_x(i, z - 0.01)) / 0.02
		var across := Vector2(1.0, -slope).normalized()
		for j: int in cols:
			var pr: Vector2 = PROFILE[j]
			var off: float = pr.x * WIDTH / 2.0
			st.set_uv(Vector2(float(j) / float(cols - 1), z / z_end))
			st.set_normal(Vector3.UP)
			st.add_vertex(Vector3(x + across.x * off, Island.TOP_Y + 0.004 + pr.y * HEIGHT, z + across.y * off))
	for k: int in SAMPLES - 1:
		for j: int in cols - 1:
			var a: int = k * cols + j
			var b: int = a + cols
			st.add_index(a); st.add_index(b); st.add_index(a + 1)
			st.add_index(a + 1); st.add_index(b); st.add_index(b + 1)
	return st.commit()
