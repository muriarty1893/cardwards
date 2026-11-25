extends TestCase
## The aim arrow's chevron strip flows toward the target (Dark Moon spec 1).


func test_chevrons_flow_toward_target() -> bool:
	var a := AttackArrow.new()
	a.aim(Vector2(100, 500), Vector2(600, 200), true)
	var before: Array[float] = a.chevron_offsets()
	assert_true(before.size() >= 4, "a strip of chevrons along the shaft")
	a._process(0.1)
	var after: Array[float] = a.chevron_offsets()
	assert_true(after[0] > before[0] or after[0] < before[0] - 1.0, "they move along the curve (or wrap round)")
	assert_true(a.is_processing(), "animates while shown")
	a.clear()
	assert_true(not a.is_processing(), "stops when hidden")
	a.free()
	return true
