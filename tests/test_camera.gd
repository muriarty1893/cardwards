extends TestCase
## Camera rig: the opening sweep ends at (or skips to) the seat view, attack close-ups return to
## the player's zoom and can be turned off, and nothing else moves the camera mid-cinematic.


func _rig() -> CameraRig:
	var rig := CameraRig.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(rig)
	await (Engine.get_main_loop() as SceneTree).process_frame
	return rig


static func _same(a: Transform3D, b: Transform3D) -> bool:
	return a.origin.distance_to(b.origin) < 0.001 and a.basis.z.distance_to(b.basis.z) < 0.001


func _wait(seconds: float) -> void:
	await (Engine.get_main_loop() as SceneTree).create_timer(seconds).timeout


func test_sweep_ends_at_seat() -> bool:
	var rig: CameraRig = await _rig()
	rig.set_zoom(0.0, true)
	await rig.play_sweep()
	await (Engine.get_main_loop() as SceneTree).process_frame
	assert_true(_same(rig.camera.global_transform, rig.pose_at(0.0)), "sweep ends at the seat view")
	assert_true(not rig.in_cinematic, "cinematic over")
	rig.free()
	return true


func test_skip_jumps_to_seat() -> bool:
	var rig: CameraRig = await _rig()
	rig.set_zoom(0.0, true)
	rig.play_sweep()
	await _wait(0.5)
	assert_true(rig.in_cinematic, "sweeping")
	rig.skip_sweep()
	await (Engine.get_main_loop() as SceneTree).process_frame
	assert_true(_same(rig.camera.global_transform, rig.pose_at(0.0)), "skip lands on the seat view")
	assert_true(not rig.in_cinematic, "cinematic over after skip")
	rig.free()
	return true


func test_close_up_returns_to_zoom() -> bool:
	var rig: CameraRig = await _rig()
	rig.set_zoom(0.6, true)
	await rig.close_up(Vector3(-1.35, 0.6, 2.0), Vector3(1.35, 0.6, -2.0), 0.5)
	await (Engine.get_main_loop() as SceneTree).process_frame
	assert_true(_same(rig.camera.global_transform, rig.pose_at(0.6)), "back at the player's zoom")
	assert_eq(rig.zoom, 0.6, "zoom kept")
	assert_eq(rig.close_up_count, 1, "one close-up played")
	rig.free()
	return true


func test_close_ups_off_never_moves() -> bool:
	var rig: CameraRig = await _rig()
	var was: bool = Settings.battle_closeups
	Settings.battle_closeups = false
	rig.set_zoom(0.3, true)
	var moved: Array[bool] = [false]
	var watch := func() -> void:
		if not _same(rig.camera.global_transform, rig.pose_at(0.3)):
			moved[0] = true
	(Engine.get_main_loop() as SceneTree).process_frame.connect(watch)
	await rig.close_up(Vector3(-1.35, 0.6, 2.0), Vector3(1.35, 0.6, -2.0), 0.5)
	await _wait(0.6)
	(Engine.get_main_loop() as SceneTree).process_frame.disconnect(watch)
	Settings.battle_closeups = was
	assert_true(not moved[0], "camera stayed on the zoom path")
	assert_eq(rig.close_up_count, 0, "no close-up counted")
	rig.free()
	return true


func test_zoom_ignored_during_cinematic() -> bool:
	var rig: CameraRig = await _rig()
	rig.set_zoom(0.2, true)
	rig.close_up(Vector3(-1.35, 0.6, 2.0), Vector3(1.35, 0.6, -2.0), 0.6)
	await (Engine.get_main_loop() as SceneTree).process_frame
	rig.zoom_by(3.0)
	await _wait(0.9)
	assert_eq(rig.zoom, 0.2, "zoom unchanged by wheel during a close-up")
	rig.free()
	return true


func test_wheel_zooms_in_and_out() -> bool:
	var rig: CameraRig = await _rig()
	rig.set_zoom(0.0, true)
	rig.zoom_by(2.0)
	await _wait(0.5)
	assert_true(rig.zoom > 0.25, "leaned in (%f)" % rig.zoom)
	rig.zoom_by(-10.0)
	await _wait(0.5)
	assert_true(rig.zoom < 0.01, "back to the seat (%f)" % rig.zoom)
	rig.free()
	return true


## A click during the opening sweep only skips it: no card picked up, no aim started.
func test_click_during_sweep_only_skips() -> bool:
	var m: MatchController = await Fx.load_match()
	var hand_before: int = m.state.players[0].hand.size()
	m.sweep()
	await _wait(0.3)
	assert_true(m.rig.in_cinematic, "sweeping")
	var at: Vector2 = m.hand.cards_rect().get_center()
	for pressed: bool in [true, false]:
		var ev := InputEventMouseButton.new()
		ev.button_index = MOUSE_BUTTON_LEFT
		ev.pressed = pressed
		ev.position = at
		ev.global_position = at
		m.get_viewport().push_input(ev)
		await (Engine.get_main_loop() as SceneTree).process_frame
	await _wait(0.2)
	assert_true(not m.rig.in_cinematic, "sweep skipped")
	assert_eq(m.input.mode, InputController.Mode.IDLE, "no aim or drag started")
	assert_eq(m.state.players[0].hand.size(), hand_before, "no card played")
	assert_true(not m.busy, "match ready again")
	m.queue_free()
	await (Engine.get_main_loop() as SceneTree).process_frame
	return true


## Turning the view keeps the camera the same distance from the table centre, still looking at
## the table, and R / reset_orbit brings it back to the seat.
func test_orbit_turns_around_table() -> bool:
	var rig: CameraRig = await _rig()
	rig.set_zoom(0.0, true)
	var seat: Transform3D = rig.pose_at(0.0)
	rig.set_orbit(PI, 0.0, true)
	await (Engine.get_main_loop() as SceneTree).process_frame
	var back: Transform3D = rig.camera.global_transform
	assert_true(absf(back.origin.length() - seat.origin.length()) < 0.01, "same distance from the centre")
	assert_true(back.origin.z < -5.0, "now on the rival's side (z %.2f)" % back.origin.z)
	assert_true((-back.basis.z).dot(-back.origin.normalized()) > 0.8, "still looking at the table")
	assert_true(rig.is_turned(), "turned")
	rig.set_orbit(0.0, 10.0, true)
	assert_true(absf(rig.tilt - CameraRig.TILT_MAX) < 0.001, "tilt clamps")
	rig.reset_orbit()
	await _wait(0.6)
	assert_true(_same(rig.camera.global_transform, seat), "reset returns to the seat view")
	assert_true(not rig.is_turned(), "not turned")
	rig.free()
	return true
