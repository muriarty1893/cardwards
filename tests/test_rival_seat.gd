extends TestCase
## The rival seated across the table: idle pose, upper-body reactions that return to idle,
## a looping win cheer, and the body behind the far table edge.

const BARBARIAN := "res://assets/heroes/Barbarian.glb"


func _seat() -> RivalSeat:
	var tree := Engine.get_main_loop() as SceneTree
	var seat := RivalSeat.new()
	tree.root.add_child(seat)
	seat.setup(BARBARIAN)
	await tree.process_frame
	return seat


func _wait(seconds: float) -> void:
	await (Engine.get_main_loop() as SceneTree).create_timer(seconds).timeout


func test_rival_seated_idle() -> bool:
	var seat: RivalSeat = await _seat()
	assert_eq(seat.upper_anim(), &"Sit_Chair_Idle", "seated idle")
	seat.free()
	return true


func test_rival_reactions() -> bool:
	var seat: RivalSeat = await _seat()
	for pair: Array in [[seat.play_card, &"Interact"], [seat.cheer, &"Cheer"], [seat.flinch, &"Hit_A"]]:
		(pair[0] as Callable).call()
		await (Engine.get_main_loop() as SceneTree).process_frame
		assert_eq(seat.upper_anim(), pair[1], "reaction %s" % pair[1])
		await _wait(seat.clip_length(pair[1]) + 0.15)
		assert_eq(seat.upper_anim(), &"Sit_Chair_Idle", "back to idle after %s" % pair[1])
	seat.free()
	return true


func test_rival_win_loops() -> bool:
	var seat: RivalSeat = await _seat()
	seat.win()
	await _wait(3.0)
	assert_eq(seat.upper_anim(), &"Cheer", "still cheering after 3 s")
	seat.free()
	return true


## The body sits behind the far table edge; only arms and cards may reach over it.
func test_rival_beyond_table() -> bool:
	var seat: RivalSeat = await _seat()
	var spine: Vector3 = seat.bone_position(&"spine")
	assert_true(spine.z < Room.TABLE_RECT.position.y, "spine z %.2f behind the table edge %.2f" % [spine.z, Room.TABLE_RECT.position.y])
	assert_true(seat.bone_position(&"head").y > 1.5, "head above the tabletop (%.2f)" % seat.bone_position(&"head").y)
	seat.free()
	return true


## The card hand stays up while idle: the hold clip's arm-raise is never replayed (it made the
## hand drop to the table and swing back every second).
func test_hold_pose_is_steady() -> bool:
	var seat: RivalSeat = await _seat()
	await _wait(0.5)
	var lo: float = 99.0
	var hi: float = -99.0
	var last := Vector3.INF
	var worst: float = 0.0
	for i: int in 150:
		await (Engine.get_main_loop() as SceneTree).process_frame
		var p: Vector3 = seat.bone_position(&"handslot.r")
		lo = minf(lo, p.y)
		hi = maxf(hi, p.y)
		if last != Vector3.INF:
			worst = maxf(worst, (p - last).length())
		last = p
	assert_true(hi - lo < 0.15, "hand height sways at most a little (%.3f..%.3f)" % [lo, hi])
	assert_true(worst < 0.05, "no frame-to-frame jumps (worst %.3f)" % worst)
	seat.free()
	return true


## The fan shows as many card backs as the rival holds.
func test_fan_follows_hand_count() -> bool:
	var seat: RivalSeat = await _seat()
	for n: int in [0, 3, 8, 2]:
		seat.set_hand_count(n)
		assert_eq(seat.hand_count(), n, "fan holds %d" % n)
	await _wait(0.4)
	assert_eq(seat.find_child("CardFan", true, false).get_child_count(), 2, "dropped cards are freed")
	seat.free()
	return true
