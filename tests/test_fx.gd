extends TestCase
## Effects free themselves when done, even if their target disappears.


func _root() -> Node3D:
	var n := Node3D.new()
	(Engine.get_main_loop() as SceneTree).root.add_child(n)
	return n

func _wait(t: float) -> void:
	await (Engine.get_main_loop() as SceneTree).create_timer(t).timeout

func test_bursts_free_themselves() -> bool:
	var r: Node3D = _root()
	for p: StringName in [&"sparks", &"stars", &"dust_ring", &"leaves", &"embers", &"sprinkles", &"snow", &"smoke", &"heal"]:
		Burst.spawn(r, p, Vector3.ZERO)
	await _wait(1.6)
	assert_eq(r.get_child_count(), 0, "all bursts freed")
	r.free()
	return true

func test_projectile_arrives() -> bool:
	var r: Node3D = _root()
	var pr: Projectile = Projectile.launch(r, &"fire", Vector3.ZERO, Vector3(0, 0, -3), 0.3)
	var got: Array[bool] = [false]
	pr.arrived.connect(func() -> void: got[0] = true)
	await _wait(1.5)
	assert_true(got[0], "arrived emitted")
	assert_eq(r.get_child_count(), 0, "projectile and impact freed")
	r.free()
	return true

func test_projectile_survives_freed_target() -> bool:
	var r: Node3D = _root()
	var v := CreatureView.create(CardDB.card(&"gumdrop"))
	r.add_child(v)
	Projectile.launch(r, &"ice", Vector3.ZERO, v.global_position, 0.3)
	v.queue_free()
	await _wait(1.5)
	assert_eq(r.get_child_count(), 0, "no leftovers, no errors")
	r.free()
	return true

func test_ice_shell_attach_and_shatter() -> bool:
	var r: Node3D = _root()
	var v := CreatureView.create(CardDB.card(&"iceling"))
	r.add_child(v)
	var s: IceShell = IceShell.attach(v)
	assert_true(s.get_parent() == v, "on the creature")
	s.shatter()
	await _wait(1.5)
	assert_true(not is_instance_valid(s), "shell freed")
	r.free()
	return true
