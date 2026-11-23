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


func test_keyword_fx_attach_and_detach() -> bool:
	var r: Node3D = _root()
	var v := CreatureView.create(CardDB.card(&"mossback"))
	r.add_child(v)
	var all: Array[StringName] = [&"guard", &"bubble", &"hidden", &"second_wind", &"venom", &"sturdy", &"bask", &"leech"]
	var fx: KeywordFx = KeywordFx.sync(v, all, -1.0)
	assert_true(fx != null, "fx node made")
	for k: StringName in KeywordFx.LASTING:
		assert_true(fx.has_part(k), "%s look on" % k)
	assert_true(v.hidden_look, "hidden makes the body see-through")
	KeywordFx.sync(v, [&"guard"] as Array[StringName], -1.0)
	assert_true(fx.has_part(&"guard"), "guard kept")
	for k: StringName in [&"bubble", &"hidden", &"second_wind", &"venom", &"sturdy", &"bask"]:
		assert_true(not fx.has_part(k), "%s look gone" % k)
	assert_true(not v.hidden_look, "body solid again")
	KeywordFx.sync(v, [] as Array[StringName], -1.0)
	assert_true(not fx.has_part(&"guard"), "guard gone")
	assert_true(KeywordFx.sync(CreatureView.create(CardDB.card(&"mossback")), [&"leech"] as Array[StringName], 1.0) == null, "no node for badge-only keywords")
	r.queue_free()
	return true


func test_keyword_shaders_compile() -> bool:
	for path: String in ["res://view/fx/bubble.gdshader", "res://view/fx/shield_wall.gdshader", "res://view/fx/hidden_shimmer.gdshader"]:
		var sh := load(path) as Shader
		assert_true(sh != null and sh.code != "", "%s loads" % path)
		assert_true(sh.get_shader_uniform_list() != null, "%s compiles" % path)
	return true


func test_keyword_looks_follow_the_match() -> bool:
	var m: MatchController = await Fx.load_match()
	Fx.put_creature(m.state, 1, 2, &"mossback")
	m.sync_all()
	var fx: KeywordFx = KeywordFx.of(m.creature_views[1][2])
	assert_true(fx != null and fx.has_part(&"guard"), "rival's Guard has its wall")
	assert_eq(fx.enemy_z, 1.0, "facing the human's side")
	m.state.players[1].lanes[2].creature.hushed = true
	m.refresh_pieces()
	assert_true(not fx.has_part(&"guard"), "hush takes the wall away")
	m.queue_free()
	return true
