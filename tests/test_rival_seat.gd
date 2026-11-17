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
