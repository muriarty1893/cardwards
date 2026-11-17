extends TestCase
## Creatures wander their half-lane: always inside the zone, still while resting, stopped at
## once when claimed (busy / aiming), resuming after; own RNG; lane moves switch the zone.

const ZONE := Rect2(-1.05, 0.4, 2.1, 3.7)
const DT := 1.0 / 30.0


func _view(id: StringName = &"cinderpup", seed: int = 7) -> CreatureView:
	var v := CreatureView.create(CardDB.card(id))
	(Engine.get_main_loop() as SceneTree).root.add_child(v)
	var c: Vector2 = ZONE.get_center()
	v.position = Vector3(c.x, Board.CREATURE_Y, c.y)
	v.wanderer.setup(v, ZONE, seed)
	v.wanderer.auto = false
	return v


static func _xz(v: Node3D) -> Vector2:
	return Vector2(v.position.x, v.position.z)


func _step_until(v: CreatureView, state: Wanderer.State, max_steps: int = 600) -> bool:
	for i: int in max_steps:
		v.wanderer.step(DT)
		if v.wanderer.state == state:
			return true
	return false


func test_stays_in_zone_120s() -> bool:
	for seed: int in [1, 2, 3]:
		var v: CreatureView = _view(&"cinderpup", seed)
		var grown: Rect2 = ZONE.grow(0.01)
		var moved: float = 0.0
		var last: Vector2 = _xz(v)
		for i: int in 3600:
			v.wanderer.step(DT)
			var p: Vector2 = _xz(v)
			moved += p.distance_to(last)
			last = p
			if not grown.has_point(p):
				assert_true(false, "seed %d step %d left the zone at %s" % [seed, i, p])
				break
		assert_true(moved > 5.0, "seed %d actually wandered (%.1f)" % [seed, moved])
		v.free()
	return true


func test_rest_does_not_move() -> bool:
	var v: CreatureView = _view()
	v.wanderer.set_resting(true)
	var at: Vector2 = _xz(v)
	for i: int in 300:
		v.wanderer.step(DT)
	assert_eq(v.wanderer.state, Wanderer.State.REST, "resting")
	assert_true(_xz(v).distance_to(at) < 0.0001, "did not move while resting")
	v.free()
	return true


func test_claim_stops_within_one_step() -> bool:
	var v: CreatureView = _view()
	assert_true(_step_until(v, Wanderer.State.ROAM), "starts walking")
	v.wanderer.step(DT)
	v.busy = true
	v.wanderer.step(DT)
	assert_eq(v.wanderer.state, Wanderer.State.HELD, "held at once")
	var at: Vector2 = _xz(v)
	for i: int in 30:
		v.wanderer.step(DT)
	assert_true(_xz(v).distance_to(at) < 0.001, "stays put while busy")
	v.free()
	return true


func test_release_resumes() -> bool:
	var v: CreatureView = _view()
	v.busy = true
	v.wanderer.step(DT)
	var at: Vector2 = _xz(v)
	v.busy = false
	var moved: bool = false
	for i: int in 150:
		v.wanderer.step(DT)
		if _xz(v).distance_to(at) > 0.05:
			moved = true
			break
	assert_true(moved, "wanders again within 5 s")
	v.free()
	return true


func test_aim_faces_target() -> bool:
	var v: CreatureView = _view()
	v.aiming = true
	v.aim_at = v.position + Vector3(3, 0, 0)
	for i: int in 30:
		v.wanderer.step(DT)
	var fwd := Vector2(sin(v.rotation.y), cos(v.rotation.y))
	assert_true(rad_to_deg(fwd.angle_to(Vector2(1, 0))) < 15.0 and rad_to_deg(fwd.angle_to(Vector2(1, 0))) > -15.0, "faces the aim target (%s)" % fwd)
	assert_eq(v.wanderer.state, Wanderer.State.HELD, "held while aiming")
	v.free()
	return true


func test_never_touches_match_rng() -> bool:
	var s: GameState = Fx.blank()
	var before: int = s.rng.state
	var views: Array[CreatureView] = []
	for i: int in 8:
		views.append(_view(&"cinderpup", i))
	for k: int in 1800:
		for v: CreatureView in views:
			v.wanderer.step(DT)
	assert_eq(s.rng.state, before, "match RNG untouched")
	for v: CreatureView in views:
		v.free()
	return true


## A creature moved to another lane wanders its new half-lane, never the old one.
func test_lane_move_updates_zone() -> bool:
	var m: MatchController = await Fx.load_match()
	Fx.put_creature(m.state, 0, 0, &"lollibat")
	m.sync_all()
	var v: CreatureView = m.creature_views[0][0]
	var lanes: Array = m.state.players[0].lanes
	lanes[3].creature = lanes[0].creature
	lanes[0].creature = null
	await m.player.move_piece({"player": 0, "from": 0, "to": 3}, false)
	assert_eq(v.wanderer.zone, m.board.roam_rect(0, 3), "zone switched to lane 3")
	v.wanderer.auto = false
	var grown: Rect2 = m.board.roam_rect(0, 3).grow(0.01)
	var inside: bool = true
	for i: int in 1800:
		v.wanderer.step(DT)
		if not grown.has_point(_xz(v)):
			inside = false
	assert_true(inside, "stays in the new lane")
	m.queue_free()
	await (Engine.get_main_loop() as SceneTree).process_frame
	return true


## Freed mid-walk: nothing errors and its footstep puffs run out on their own.
func test_freed_mid_walk_is_safe() -> bool:
	var tree := Engine.get_main_loop() as SceneTree
	var parent := Node3D.new()
	tree.root.add_child(parent)
	var v := CreatureView.create(CardDB.card(&"cinderpup"))
	parent.add_child(v)
	v.position = Vector3(0, Board.CREATURE_Y, 2.0)
	v.wanderer.setup(v, ZONE, 3)
	v.wanderer.footstep = func(at: Vector3) -> void: Burst.spawn(parent, &"leaves", at, Color.WHITE, 0.3)
	for i: int in 60:
		await tree.process_frame
	v.queue_free()
	await tree.create_timer(2.0).timeout
	assert_true(not is_instance_valid(v), "freed")
	assert_eq(parent.find_children("*", "Burst", true, false).size(), 0, "footstep puffs gone")
	parent.free()
	return true
