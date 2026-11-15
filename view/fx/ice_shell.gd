class_name IceShell
extends Node3D
## Cracked ice around a frozen creature. Grows in; shatter() bursts into shards and frees it.

static var _mat: ShaderMaterial


static func attach(target: CreatureView) -> IceShell:
	var s := IceShell.new()
	if _mat == null:
		_mat = ShaderMaterial.new()
		_mat.shader = load("res://view/fx/ice_shell.gdshader") as Shader
		_mat.set_shader_parameter("cell_tex", NoiseBank.cells())
	var h: float = target.height
	var mesh := SphereMesh.new()
	mesh.radius = 1.0
	mesh.height = 2.0
	var mi := Palette.mesh(mesh, _mat, Vector3.ZERO, false)
	mi.scale = Vector3(h * 0.62, h * 0.58, h * 0.62)
	s.add_child(mi)
	target.add_child(s)
	s.position = Vector3(0, Island.TOP_Y - CreatureView.BASE_Y + h * 0.5, 0)
	s.scale = Vector3.ONE * 0.01
	s.create_tween().tween_property(s, "scale", Vector3.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	return s


func shatter() -> void:
	var host: Node = get_parent()
	var stage: Node = host.get_parent() if host and host.get_parent() else host
	if stage:
		Burst.spawn(stage, &"snow", global_position, Color("#e8f6ff"), 1.3)
		Burst.spawn(stage, &"sparks", global_position, Color("#bfe8ff"), 1.0)
	queue_free()
