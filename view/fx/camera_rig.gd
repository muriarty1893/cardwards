class_name CameraRig
extends Node3D
## The match camera. A seat view from the player's chair and a closer, steeper "lean in" view,
## with the mouse wheel / pinch sliding between them (`zoom` 0..1); an opening sweep around the
## room; a low close-up behind an attacker; ink outlines; shake and punch-zoom on top of
## whatever the base pose is. While a cinematic plays, zoom input is ignored. The whole view
## can be turned around the table (right- or middle-drag, Q/E or the arrow keys; R resets).

signal sweep_finished

## Looks down at the board a little more steeply than the first tabletop pass (20.6° → 25°), so
## the board fills more of the view and the rival less; the rival's head still fits at the top.
const SEAT_POS := Vector3(0, 8.0, 14.0)
const SEAT_LOOK := Vector3(0, 0.5, -2.0)
const SEAT_FOV := 58.0
const LEAN_POS := Vector3(0, 10.0, 9.0)
const LEAN_LOOK := Vector3(0, 0.0, 2.5)
const LEAN_FOV := 46.0
## One wheel notch at zoom speed 1.
const ZOOM_STEP := 0.15
## Zoom follows its target with this time constant (≈ settled in 0.25 s).
const ZOOM_SMOOTH := 0.07
const SWEEP_TIME := 3.0
## Opening sweep keys [position, look-at]: a corner by the windows, past the rival's shoulder,
## then down into the seat view (appended at play time for the current zoom).
const SWEEP_KEYS: Array[Array] = [
	[Vector3(-34, 16, -26), Vector3(0, 3, -12)],
	[Vector3(-20, 13, -6), Vector3(0, 5, -12)],
	[Vector3(12, 12, 6), Vector3(0, 2, -6)],
]
## Close-up: this far behind and above the attacker, looking past it at the target.
const CLOSE_BACK := 2.4
const CLOSE_UP := 2.5
const CLOSE_FOV := 50.0
const CLOSE_IN := 0.22
const CLOSE_OUT := 0.3

## Turning the view: around the table centre (yaw, full circle) and up/down (tilt, radians;
## positive looks more from above).
const ORBIT_PIVOT := Vector3.ZERO
const ORBIT_DRAG := 0.006
const ORBIT_KEY_SPEED := 1.6
const TILT_MIN := -0.12
const TILT_MAX := 0.55

var camera: Camera3D
var yaw: float = 0.0
var tilt: float = 0.0
var _yaw_target: float = 0.0
var _tilt_target: float = 0.0
## Mouse button held for an orbit drag (0 = none).
var _orbit_button: int = 0
## 0 = seat view, 1 = lean in.
var zoom: float = 0.0
var in_cinematic: bool = false
var sweeping: bool = false
var close_up_count: int = 0
var _zoom_target: float = 0.0
var _base := Transform3D.IDENTITY
var _base_fov: float = SEAT_FOV
var _punch: float = 0.0
var _shake: float = 0.0
var _rng := RandomNumberGenerator.new()
var _cine: Tween
var _sweep_from: Array[Array] = []


func _ready() -> void:
	camera = Camera3D.new()
	add_child(camera)
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--zoom="):
			zoom = clampf(float(arg.substr(7)), 0.0, 1.0)
		elif arg.begins_with("--orbit="):
			set_orbit(deg_to_rad(float(arg.substr(8))), 0.15, true)
	_zoom_target = zoom
	_base = pose_at(zoom)
	_base_fov = fov_at(zoom)
	_apply()
	camera.make_current()
	Outline.attach(camera)


## Camera pose on the seat → lean-in path (eased so the middle of the wheel range moves most),
## turned by the current orbit.
func pose_at(z: float) -> Transform3D:
	var e: float = smoothstep(0.0, 1.0, clampf(z, 0.0, 1.0))
	var pos: Vector3 = SEAT_POS.lerp(LEAN_POS, e)
	var look: Vector3 = SEAT_LOOK.lerp(LEAN_LOOK, e)
	return orbit(Transform3D(Basis.looking_at(look - pos, Vector3.UP), pos), yaw, tilt)


## `t` turned around the table centre: tilted up by `up` radians, then turned by `turn`.
static func orbit(t: Transform3D, turn: float, up: float) -> Transform3D:
	if turn == 0.0 and up == 0.0:
		return t
	var rot := Basis(Vector3.UP, turn) * Basis(Vector3.RIGHT, -up)
	return Transform3D(rot * t.basis, ORBIT_PIVOT + rot * (t.origin - ORBIT_PIVOT))


## Turns the view to (turn, up) radians; instant skips the easing.
func set_orbit(turn: float, up: float, instant: bool = false) -> void:
	_yaw_target = turn
	_tilt_target = clampf(up, TILT_MIN, TILT_MAX)
	if instant:
		yaw = _yaw_target
		tilt = _tilt_target


## Back to the player's seat (the shorter way round).
func reset_orbit() -> void:
	set_orbit(0.0, 0.0)
	yaw = wrapf(yaw, -PI, PI)


func is_turned() -> bool:
	return absf(wrapf(_yaw_target, -PI, PI)) > 0.01 or absf(_tilt_target) > 0.01


func fov_at(z: float) -> float:
	return lerpf(SEAT_FOV, LEAN_FOV, smoothstep(0.0, 1.0, clampf(z, 0.0, 1.0)))


func set_zoom(z: float, instant: bool = false) -> void:
	_zoom_target = clampf(z, 0.0, 1.0)
	if instant:
		zoom = _zoom_target
		if not in_cinematic:
			_base = pose_at(zoom)
			_base_fov = fov_at(zoom)
			_apply()


## Wheel notches (+ leans in). Ignored while a cinematic plays.
func zoom_by(steps: float) -> void:
	if in_cinematic:
		return
	set_zoom(_zoom_target + steps * ZOOM_STEP * Settings.zoom_speed)


func _unhandled_input(event: InputEvent) -> void:
	var key := event as InputEventKey
	if key and key.pressed and not key.echo and key.keycode == KEY_R:
		reset_orbit()
		return
	var mb := event as InputEventMouseButton
	if mb and mb.pressed:
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_by(maxf(mb.factor, 1.0) if mb.factor > 0.0 else 1.0)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_by(-(maxf(mb.factor, 1.0) if mb.factor > 0.0 else 1.0))
		return
	var mg := event as InputEventMagnifyGesture
	if mg:
		zoom_by((mg.factor - 1.0) * 6.0)


## During the opening sweep, any click or key press only skips it. Otherwise a right- or
## middle-button drag turns the view (a plain right click still cancels in InputController).
func _input(event: InputEvent) -> void:
	if not sweeping:
		var mb := event as InputEventMouseButton
		if mb and mb.button_index in [MOUSE_BUTTON_RIGHT, MOUSE_BUTTON_MIDDLE]:
			_orbit_button = mb.button_index if mb.pressed else 0
		var mm := event as InputEventMouseMotion
		if mm and _orbit_button != 0 and not in_cinematic:
			set_orbit(_yaw_target - mm.relative.x * ORBIT_DRAG, _tilt_target + mm.relative.y * ORBIT_DRAG * 0.6)
		return
	var press: bool = (event is InputEventMouseButton and (event as InputEventMouseButton).pressed) or (event is InputEventKey and (event as InputEventKey).pressed)
	if press:
		skip_sweep()
		get_viewport().set_input_as_handled()


# --- opening sweep -------------------------------------------------------------------------

func _sweep_keys() -> Array[Array]:
	var keys: Array[Array] = SWEEP_KEYS.duplicate()
	var seat: Transform3D = pose_at(zoom)
	keys.append([seat.origin, seat.origin - seat.basis.z * 20.0])
	return keys


## Camera pose `t` seconds into the opening sweep (smooth through the keys, eased overall).
func sweep_pose(t: float) -> Transform3D:
	var keys: Array[Array] = _sweep_keys()
	var u: float = smoothstep(0.0, 1.0, clampf(t / SWEEP_TIME, 0.0, 1.0)) * float(keys.size() - 1)
	var i: int = mini(int(u), keys.size() - 2)
	var w: float = u - float(i)
	var pos: Vector3 = _catmull(keys, i, w, 0)
	var look: Vector3 = _catmull(keys, i, w, 1)
	return Transform3D(Basis.looking_at(look - pos, Vector3.UP), pos)


static func _catmull(keys: Array[Array], i: int, w: float, slot: int) -> Vector3:
	var a: Vector3 = keys[i][slot]
	var b: Vector3 = keys[i + 1][slot]
	var pre: Vector3 = keys[maxi(i - 1, 0)][slot]
	var post: Vector3 = keys[mini(i + 2, keys.size() - 1)][slot]
	return a.cubic_interpolate(b, pre, post, w)


func play_sweep() -> void:
	_stop_cinematic()
	in_cinematic = true
	sweeping = true
	_cine = create_tween()
	_cine.tween_method(func(t: float) -> void:
		_base = sweep_pose(t)
		_base_fov = lerpf(50.0, fov_at(zoom), smoothstep(0.0, 1.0, t / SWEEP_TIME)), 0.0, SWEEP_TIME, SWEEP_TIME)
	_cine.tween_callback(_end_sweep)
	await sweep_finished


## Freeze the sweep at `t` seconds (for screenshots).
func hold_sweep(t: float) -> void:
	_stop_cinematic()
	in_cinematic = true
	_base = sweep_pose(t)
	_base_fov = lerpf(50.0, fov_at(zoom), smoothstep(0.0, 1.0, t / SWEEP_TIME))
	_apply()


func skip_sweep() -> void:
	if not sweeping:
		return
	_stop_cinematic()
	_end_sweep()


func _end_sweep() -> void:
	sweeping = false
	in_cinematic = false
	_cine = null
	_base = pose_at(zoom)
	_base_fov = fov_at(zoom)
	_apply()
	sweep_finished.emit()


func _stop_cinematic() -> void:
	if _cine and _cine.is_valid():
		_cine.kill()
	_cine = null


# --- attack close-up -----------------------------------------------------------------------

## Low behind `from`, looking past it at `to`, for `duration` seconds, then back to the zoom
## path. Does nothing (and counts nothing) when battle close-ups are off.
func close_up(from: Vector3, to: Vector3, duration: float) -> void:
	if not Settings.battle_closeups or sweeping:
		return
	_stop_cinematic()
	in_cinematic = true
	close_up_count += 1
	var flat := Vector3(to.x - from.x, 0.0, to.z - from.z)
	if flat.length() < 0.01:
		flat = Vector3(0, 0, -1)
	var dir: Vector3 = flat.normalized()
	var pos: Vector3 = from - dir * CLOSE_BACK + Vector3(0, CLOSE_UP, 0) + dir.cross(Vector3.UP) * 0.8
	var look: Vector3 = from.lerp(to, 0.75) + Vector3(0, 0.1, 0)
	var close := Transform3D(Basis.looking_at(look - pos, Vector3.UP), pos)
	var start: Transform3D = _base
	var start_fov: float = _base_fov
	var hold: float = maxf(duration - CLOSE_IN - CLOSE_OUT, 0.05)
	_cine = create_tween()
	_cine.tween_method(func(k: float) -> void:
		var e: float = smoothstep(0.0, 1.0, k)
		_base = start.interpolate_with(close, e)
		_base_fov = lerpf(start_fov, CLOSE_FOV, e), 0.0, 1.0, CLOSE_IN)
	_cine.tween_interval(hold)
	_cine.tween_method(func(k: float) -> void:
		var e: float = smoothstep(0.0, 1.0, k)
		_base = close.interpolate_with(pose_at(zoom), e)
		_base_fov = lerpf(CLOSE_FOV, fov_at(zoom), e), 0.0, 1.0, CLOSE_OUT)
	var tw: Tween = _cine
	await tw.finished
	if _cine == tw:
		_cine = null
		in_cinematic = false
		_base = pose_at(zoom)
		_base_fov = fov_at(zoom)
		_apply()


# --- shake and punch -----------------------------------------------------------------------

## Quick zoom-in and back (crits).
func punch_zoom(amount: float = 4.0, duration: float = 0.25) -> void:
	var tw := create_tween()
	tw.tween_property(self, "_punch", amount, duration * 0.35).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "_punch", 0.0, duration * 0.65).set_trans(Tween.TRANS_SINE)


func kick(strength: float) -> void:
	_shake = maxf(_shake, strength)


func _process(delta: float) -> void:
	var turn: float = 0.0
	if Input.is_key_pressed(KEY_Q) or Input.is_key_pressed(KEY_LEFT):
		turn += 1.0
	if Input.is_key_pressed(KEY_E) or Input.is_key_pressed(KEY_RIGHT):
		turn -= 1.0
	if turn != 0.0 and not in_cinematic:
		_yaw_target += turn * ORBIT_KEY_SPEED * delta
	var k: float = 1.0 - exp(-delta / ZOOM_SMOOTH)
	yaw = lerpf(yaw, _yaw_target, k)
	tilt = lerpf(tilt, _tilt_target, k)
	if absf(yaw - _yaw_target) < 0.0005:
		yaw = _yaw_target
	if absf(tilt - _tilt_target) < 0.0005:
		tilt = _tilt_target
	if not in_cinematic:
		zoom = lerpf(zoom, _zoom_target, 1.0 - exp(-delta / ZOOM_SMOOTH))
		if absf(zoom - _zoom_target) < 0.0005:
			zoom = _zoom_target
		_base = pose_at(zoom)
		_base_fov = fov_at(zoom)
	if _shake > 0.0:
		_shake = maxf(0.0, _shake - delta * 4.0 * maxf(_shake, 0.1))
	_apply()


func _apply() -> void:
	if camera == null:
		return
	var t: Transform3D = _base
	if _shake > 0.0:
		t.origin += t.basis * Vector3(_rng.randf_range(-1, 1), _rng.randf_range(-1, 1), 0) * _shake * 0.4
	camera.global_transform = t
	camera.fov = _base_fov - _punch
