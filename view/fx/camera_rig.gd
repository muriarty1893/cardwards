class_name CameraRig
extends Node3D
## Fixed match camera, high and close like a card table, with ink outlines and a small decaying shake.

const HOME := Vector3(0, 8.5, 9.5)
const LOOK := Vector3(0, 0, 0.9)

var camera: Camera3D
var _shake: float = 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	camera = Camera3D.new()
	camera.fov = 30.0
	add_child(camera)
	camera.look_at_from_position(HOME, LOOK)
	camera.make_current()
	Outline.attach(camera)


func kick(strength: float) -> void:
	_shake = maxf(_shake, strength)


func _process(delta: float) -> void:
	if _shake <= 0.0:
		return
	_shake = maxf(0.0, _shake - delta * 4.0 * maxf(_shake, 0.1))
	var off := Vector3(_rng.randf_range(-1, 1), _rng.randf_range(-1, 1), 0) * _shake * 0.4
	camera.position = HOME + off
