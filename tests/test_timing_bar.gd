extends TestCase


func test_zone_at() -> bool:
	assert_eq(TimingBar.zone_at(0.5), Action.Hit.CRIT, "centre green")
	assert_eq(TimingBar.zone_at(0.44), Action.Hit.CRIT, "green starts at 0.44")
	assert_eq(TimingBar.zone_at(0.35), Action.Hit.NORMAL, "left yellow")
	assert_eq(TimingBar.zone_at(0.65), Action.Hit.NORMAL, "right yellow")
	assert_eq(TimingBar.zone_at(0.1), Action.Hit.GLANCE, "left red")
	assert_eq(TimingBar.zone_at(0.95), Action.Hit.GLANCE, "right red")
	return true


func test_timeout_is_normal() -> bool:
	var tree := Engine.get_main_loop() as SceneTree
	var bar := TimingBar.new()
	tree.root.add_child(bar)
	var start: int = Time.get_ticks_msec()
	var hit: Action.Hit = await bar.run_attack()
	var elapsed: float = (Time.get_ticks_msec() - start) / 1000.0
	assert_eq(hit, Action.Hit.NORMAL, "no tap -> NORMAL")
	# TIMEOUT (2 s) plus the 0.35 s the bar stays up after it stops.
	assert_true(elapsed >= 2.2 and elapsed <= 2.7, "about 2 s + hide (%.2f)" % elapsed)
	var blocked: bool = await bar.run_block()
	assert_eq(blocked, false, "no tap -> no block")
	bar.queue_free()
	return true


func test_tap_in_green() -> bool:
	var tree := Engine.get_main_loop() as SceneTree
	var bar := TimingBar.new()
	tree.root.add_child(bar)
	var run: Callable = func() -> Action.Hit: return await bar.run_attack()
	bar.force_needle = 0.5
	var press := InputEventKey.new()
	press.keycode = KEY_SPACE
	press.pressed = true
	tree.create_timer(0.2).timeout.connect(func() -> void: bar._input(press))
	var hit: Action.Hit = await run.call()
	assert_eq(hit, Action.Hit.CRIT, "tap at 0.5 -> CRIT")
	bar.queue_free()
	return true
