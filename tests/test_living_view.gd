extends TestCase
## The living board in the real match scene: lands change on the board as they do in the state,
## reactions, level-ups and fields play without errors, and houses follow their creatures.


func _fast(m: MatchController) -> void:
	m.player.speed = 20.0
	m.pace = 20.0


func _clear(m: MatchController) -> void:
	for p: int in 2:
		for l: int in 4:
			m.state.players[p].lanes[l].creature = null
			m.state.players[p].lanes[l].building = null
	m.sync_all()


func _lands_match(m: MatchController, label: String) -> void:
	for p: int in 2:
		for l: int in 4:
			assert_eq(m.board.island(p, l).land, m.state.players[p].lanes[l].land, "%s: land p%d l%d" % [label, p, l])


func test_claim_and_melt_on_board() -> bool:
	var m: MatchController = await Fx.load_match()
	assert_true(m != null, "match loaded")
	_fast(m)
	_clear(m)
	var s: GameState = m.state
	s.players[0].magic = 9
	await m.perform(Action.play(0, Fx.give(s, 0, &"flarebeak"), 2))
	assert_eq(m.board.island(0, 2).land, CardData.Land.EMBER, "the tile turned Ember")
	s.players[1].lanes[3].land = CardData.Land.FROST
	Fx.put_creature(s, 1, 3, &"blizzard_titan")
	m.sync_all()
	s.players[0].magic = 9
	await m.perform(Action.play(0, Fx.give(s, 0, &"fireball"), -1, [{"player": 1, "lane": 3}]))
	assert_eq(m.board.island(1, 3).land, Lands.MEADOW, "melt thawed the tile on the board")
	_lands_match(m, "after melt")
	m.queue_free()
	return true


func test_level_up_plays() -> bool:
	var m: MatchController = await Fx.load_match()
	_fast(m)
	_clear(m)
	var s: GameState = m.state
	Fx.put_creature(s, 0, 0, &"glacier_tortoise")
	s.players[0].lanes[0].creature.xp = 1
	Fx.put_creature(s, 1, 0, &"mossback")
	m.sync_all()
	await m.perform(Action.attack(0, 0, 0))
	assert_eq(s.players[0].lanes[0].creature.level, 2, "levelled in the state")
	var v: CreatureView = m.creature_views[0][0]
	assert_eq(v.level, 2, "the view shows level 2")
	assert_true(v.height > v.base_height, "and grew")
	assert_eq(Engine.time_scale, 1.0, "time scale restored")
	m.queue_free()
	return true


func test_field_shows_and_hud() -> bool:
	var m: MatchController = await Fx.load_match()
	_fast(m)
	var s: GameState = m.state
	s.players[0].magic = 9
	await m.perform(Action.play(0, Fx.give(s, 0, &"volcano"), -1))
	assert_eq(m.field_fx.land, CardData.Land.EMBER, "volcano look on")
	assert_true(m.field_fx.prop() != null, "a prop rose")
	assert_true(m.hud.field_text().contains("VOLCANO"), "HUD names the field")
	s.players[0].magic = 9
	await m.perform(Action.play(0, Fx.give(s, 0, &"bark_shield"), -1))
	assert_true(m.hud.armour_visible(true), "armour shield shows")
	m.queue_free()
	return true


func test_houses_follow_creatures() -> bool:
	var m: MatchController = await Fx.load_match()
	_fast(m)
	_clear(m)
	var s: GameState = m.state
	Fx.put_creature(s, 0, 1, &"sporeling")
	Fx.put_creature(s, 0, 2, &"mossback")
	m.sync_all()
	assert_true(is_instance_valid(m.house_views[0][1]), "sporeling brought a house")
	assert_true(not is_instance_valid(m.house_views[0][2]), "mossback has none")
	var v: CreatureView = m.creature_views[0][1]
	v.enter_house()
	await (Engine.get_main_loop() as SceneTree).create_timer(0.6).timeout
	assert_true((m.house_views[0][1] as CreatureHouse).occupied, "inside: the house is lit")
	v.busy = true
	assert_true(not v.inside_house and v.scale.is_equal_approx(Vector3.ONE), "taking the creature pops it out")
	v.busy = false
	s.players[0].lanes[1].creature = null
	m.sync_all()
	var h: Variant = m.house_views[0][1]
	assert_true(not is_instance_valid(h) or (h as CreatureHouse).resident == null, "the empty house sinks away")
	m.queue_free()
	return true
