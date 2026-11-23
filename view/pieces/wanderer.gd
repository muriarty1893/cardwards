class_name Wanderer
extends Node
## Moves its CreatureView around the roam zone (cosmetic only): walk to a random spot, pause
## (face the enemy, fidget, sometimes wave at a neighbour), repeat. While the creature isn't
## ready it rests in place; while the event player has it (busy), it's being aimed with, or it
## is frozen, it holds still. Uses its own RNG, never the match's. A creature with a house
## (CreatureView.house) walks home every 12-25 s, stays inside 3-6 s and comes back out.

enum State { ROAM, PAUSE, REST, HELD, TO_HOUSE, INSIDE }

## Walking speed by creature level (board units per second).
const SPEEDS: Array[float] = [0.6, 0.6, 0.5, 0.4]
const TURN_RATE := 6.0
const PAUSE_MIN := 1.5
const PAUSE_MAX := 4.0
const WAVE_CHANCE := 0.25
const WAVE_RANGE := 1.2
const STEP_EVERY := 0.35
const ARRIVE := 0.04
const HOUSE_MIN := 12.0
const HOUSE_MAX := 25.0
const INSIDE_MIN := 3.0
const INSIDE_MAX := 6.0

var view: CreatureView
var zone := Rect2()
var state: State = State.PAUSE
## When false the owner calls step() itself (tests).
var auto: bool = true:
	set(v):
		auto = v
		set_process(v and view != null)
## Heading to show while paused (radians, 0 faces +z): the enemy side, turned to the camera.
var rest_heading: float = 0.0
## Called with a world point for each footstep puff while walking (set by the match).
var footstep: Callable
## Returns the CreatureViews on the same side (for waving at a neighbour).
var neighbours: Callable
var step_every: float = STEP_EVERY

var _rng := RandomNumberGenerator.new()
var _target := Vector2.ZERO
var _pause_left: float = 0.0
var _resting: bool = false
var _step_in: float = 0.0
var _face: float = 0.0
var _house_in: float = 0.0
var _inside_left: float = 0.0


func setup(v: CreatureView, z: Rect2, seed: int) -> void:
	view = v
	zone = z
	_rng.seed = seed
	_face = v.rotation.y
	_house_in = _rng.randf_range(HOUSE_MIN * 0.5, HOUSE_MAX)
	_start_pause(_rng.randf_range(0.3, PAUSE_MAX))
	set_process(auto)


## A new zone (the creature moved lanes): walk into it from wherever it is.
func set_zone(z: Rect2) -> void:
	zone = z
	if state == State.ROAM or state == State.PAUSE:
		_start_roam()


func set_resting(on: bool) -> void:
	_resting = on


func _process(delta: float) -> void:
	step(delta)


func step(delta: float) -> void:
	if view == null or not is_instance_valid(view):
		return
	if view.busy or view.aiming or view.is_frozen_visual():
		if view.inside_house:
			view.exit_house(true)
		if state != State.HELD:
			state = State.HELD
			view.play_move(false)
		if view.aiming:
			var d := Vector2(view.aim_at.x - view.position.x, view.aim_at.z - view.position.z)
			if d.length() > 0.01:
				_turn_to(atan2(d.x, d.y), delta)
		return
	if view.look_point.is_finite() and state != State.INSIDE:
		# Watching something (the card being dragged): stand still and face it.
		if state == State.ROAM or state == State.TO_HOUSE:
			_start_pause(0.5)
		var w := Vector2(view.look_point.x - view.position.x, view.look_point.z - view.position.z)
		if w.length() > 0.01:
			_turn_to(atan2(w.x, w.y), delta)
		return
	if _resting and state != State.INSIDE:
		if state != State.REST:
			state = State.REST
			view.play_move(false)
		return
	if state == State.HELD or state == State.REST:
		_start_pause(_rng.randf_range(0.4, 1.2))
	match state:
		State.ROAM, State.TO_HOUSE:
			_walk(delta)
		State.PAUSE:
			_turn_to(_face, delta)
			_pause_left -= delta
			_house_in -= delta
			if _house_in <= 0.0 and is_instance_valid(view.house):
				_start_house_walk()
			elif _pause_left <= 0.0:
				_start_roam()
		State.INSIDE:
			_inside_left -= delta
			if _inside_left <= 0.0 and not _resting:
				view.exit_house()
				_house_in = _rng.randf_range(HOUSE_MIN, HOUSE_MAX)
				_start_pause(_rng.randf_range(PAUSE_MIN, PAUSE_MAX))


func _walk(delta: float) -> void:
	var here := Vector2(view.position.x, view.position.z)
	var to: Vector2 = _target - here
	var dist: float = to.length()
	if dist <= ARRIVE:
		if state == State.TO_HOUSE and is_instance_valid(view.house):
			state = State.INSIDE
			_inside_left = _rng.randf_range(INSIDE_MIN, INSIDE_MAX)
			view.play_move(false)
			view.enter_house()
		else:
			_start_pause(_rng.randf_range(PAUSE_MIN, PAUSE_MAX))
		return
	var speed: float = SPEEDS[clampi(view.card.level if view.card else 1, 0, 3)]
	var move: float = minf(speed * delta, dist)
	here += to / dist * move
	view.position.x = here.x
	view.position.z = here.y
	_turn_to(atan2(to.x, to.y), delta)
	_step_in -= delta
	if _step_in <= 0.0:
		_step_in = step_every
		if footstep.is_valid():
			footstep.call(Vector3(here.x, Island.TOP_Y + 0.05, here.y))


func _start_roam() -> void:
	state = State.ROAM
	_target = Vector2(_rng.randf_range(zone.position.x, zone.end.x), _rng.randf_range(zone.position.y, zone.end.y))
	_step_in = _rng.randf_range(0.0, step_every)
	view.play_move(true)


func _start_house_walk() -> void:
	state = State.TO_HOUSE
	var door: Vector3 = view.house.door_point()
	_target = Vector2(door.x, door.z)
	_step_in = _rng.randf_range(0.0, step_every)
	view.play_move(true)


func _start_pause(seconds: float) -> void:
	state = State.PAUSE
	_pause_left = seconds
	view.play_move(false)
	_face = rest_heading
	if _rng.randf() < WAVE_CHANCE and neighbours.is_valid():
		for other: Variant in neighbours.call():
			if not is_instance_valid(other) or other == view:
				continue
			var d := Vector2((other as Node3D).position.x - view.position.x, (other as Node3D).position.z - view.position.z)
			if d.length() <= WAVE_RANGE:
				_face = atan2(d.x, d.y)
				view.wave()
				break


func _turn_to(heading: float, delta: float) -> void:
	view.rotation.y = rotate_toward(view.rotation.y, heading, TURN_RATE * delta)
