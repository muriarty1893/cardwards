class_name DragCard3D
extends Node3D
## The card you drag, once it is over the board (board look 2, spec 3.2): a real 3D card under the mouse, hovering
## above the tiles and lying almost flat (tilted toward you so it stays readable), swaying a little with the
## mouse's speed, with a soft shadow on the board. The hand hides its 2D card meanwhile.

## Height above the tile surface.
const HOVER := 0.9
## World width of the card (height follows the card's shape).
const WIDTH := 1.6
## Tilt toward the camera from flat.
const TILT_DEG := 18.0
const MAX_ROLL_DEG := 10.0
const MAX_PITCH_DEG := 6.0
## Seconds for the card to fall from upright onto its back when it first crosses onto the board.
const FLATTEN := 0.12

var roll: float = 0.0
var pitch: float = 0.0
var _card: CardData
var _vp: SubViewport
var _quad: MeshInstance3D
var _shadow: MeshInstance3D
var _target := Vector3.ZERO
var _last_target := Vector3.INF
var _vel := Vector3.ZERO
## 0 upright (facing the camera) .. 1 lying at the drag tilt.
var _flat: float = 0.0


func _init() -> void:
	name = "DragCard3D"
	visible = false
	_vp = SubViewport.new()
	_vp.size = Vector2i(CardWidget.SIZE * 2.0)
	_vp.transparent_bg = true
	_vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(_vp)
	var q := QuadMesh.new()
	q.size = Vector2(WIDTH, WIDTH * CardWidget.SIZE.y / CardWidget.SIZE.x)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	mat.albedo_texture = _vp.get_texture()
	_quad = MeshInstance3D.new()
	_quad.name = "Card"
	_quad.mesh = q
	_quad.material_override = mat
	_quad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_quad)
	var sq := QuadMesh.new()
	sq.size = q.size * 1.05
	sq.orientation = PlaneMesh.FACE_Y
	var smat := StandardMaterial3D.new()
	smat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	smat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	smat.albedo_color = Color(0.1, 0.06, 0.04, 0.28)
	_shadow = MeshInstance3D.new()
	_shadow.name = "Shadow"
	_shadow.mesh = sq
	_shadow.material_override = smat
	_shadow.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_shadow)
	set_process(false)


## Starts showing `c` (renders its face once).
func show_card(c: CardData) -> void:
	if c != _card:
		_card = c
		for ch: Node in _vp.get_children():
			ch.free()
		var w := CardWidget.new()
		w.setup(c, -1)
		w.scale = Vector2.ONE * 2.0
		_vp.add_child(w)
		_vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	if not visible:
		visible = true
		_flat = 0.0
		_last_target = Vector3.INF
		_vel = Vector3.ZERO
		roll = 0.0
		pitch = 0.0
	set_process(true)


func hide_card() -> void:
	visible = false
	set_process(false)


## Puts the card under `screen` (on the plane HOVER above the tiles).
func follow(cam: Camera3D, screen: Vector2) -> void:
	var o: Vector3 = cam.project_ray_origin(screen)
	var d: Vector3 = cam.project_ray_normal(screen)
	if absf(d.y) < 0.0001:
		return
	var t: float = (Island.TOP_Y + HOVER - o.y) / d.y
	if t <= 0.0:
		return
	_target = o + d * t
	if not _last_target.is_finite():
		_last_target = _target
		global_position = _target
		_place_shadow()


## The card face's normal in world space.
func card_normal() -> Vector3:
	return (_quad.global_basis * Vector3(0, 0, 1)).normalized()


func _process(delta: float) -> void:
	step(delta)


## One frame of following and swaying (tests call this directly).
func step(delta: float) -> void:
	if delta <= 0.0:
		return
	var moved: Vector3 = _target - _last_target if _last_target.is_finite() else Vector3.ZERO
	_last_target = _target
	_vel = _vel.lerp(moved / delta, clampf(delta * 12.0, 0.0, 1.0))
	global_position = _target
	_flat = minf(_flat + delta / FLATTEN, 1.0)
	var max_roll: float = deg_to_rad(MAX_ROLL_DEG)
	var max_pitch: float = deg_to_rad(MAX_PITCH_DEG)
	var want_roll: float = clampf(-_vel.x * 0.05, -max_roll, max_roll)
	var want_pitch: float = clampf(_vel.z * 0.03, -max_pitch, max_pitch)
	roll = clampf(lerpf(roll, want_roll, clampf(delta * 10.0, 0.0, 1.0)), -max_roll, max_roll)
	pitch = clampf(lerpf(pitch, want_pitch, clampf(delta * 10.0, 0.0, 1.0)), -max_pitch, max_pitch)
	# Flat on the board is -90 degrees about x; tilted back toward the camera by TILT_DEG; upright when just
	# crossing onto the board.
	var lying: float = deg_to_rad(-90.0 + TILT_DEG) + pitch
	var upright: float = deg_to_rad(-25.0)
	var e: float = 1.0 - pow(1.0 - _flat, 3.0)
	_quad.rotation = Vector3(lerpf(upright, lying, e), 0.0, roll)
	_place_shadow()


func _place_shadow() -> void:
	_shadow.global_position = Vector3(global_position.x + 0.08, Island.TOP_Y + 0.02, global_position.z + 0.12)
