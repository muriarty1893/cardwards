extends TestCase
## Living board spec 2-4: bare lanes, claiming, the level count, home quirks and land reactions.

const M := CardData.Land.MUSHROOM
const E := CardData.Land.EMBER
const K := CardData.Land.CANDY
const F := CardData.Land.FROST
const W := Lands.MEADOW


func _events(ev: Array[GameEvent], type: StringName) -> Array[GameEvent]:
	return ev.filter(func(e: GameEvent) -> bool: return e.type == type)


func test_creature_claims_meadow() -> bool:
	var s: GameState = Fx.blank()
	s.players[0].magic = 9
	var ev: Array[GameEvent] = Rules.apply(s, Action.play(0, Fx.give(s, 0, &"flarebeak"), 2))
	assert_eq(s.players[0].lanes[2].land, E, "flarebeak claims its lane")
	var lc: Array[GameEvent] = _events(ev, &"land_changed")
	assert_eq(lc.size(), 1, "one land change")
	assert_eq([lc[0].data["from"], lc[0].data["land"], lc[0].data["cause"]], [W, E, &"claim"], "meadow → ember, claim")
	var types: Array[StringName] = Fx.types(ev)
	assert_true(types.find(&"creature_played") < types.find(&"land_changed"), "the creature lands first")
	return true


func test_creature_keeps_other_land() -> bool:
	var s: GameState = Fx.blank([F, W, W, W])
	s.players[0].magic = 9
	Fx.put_creature(s, 0, 1, &"flarebeak")
	s.players[0].lanes[1].land = E
	# A level-1 Ember creature in a Frostpeak lane: allowed with another Ember lane, land stays.
	var ev: Array[GameEvent] = Rules.apply(s, Action.play(0, Fx.give(s, 0, &"cinderpup"), 0))
	assert_eq(s.players[0].lanes[0].land, F, "creatures never convert a land")
	assert_eq(_events(ev, &"land_changed").size(), 0, "no change")
	return true


func test_building_converts() -> bool:
	var s: GameState = Fx.blank([F, W, W, W])
	s.players[0].magic = 9
	var ev: Array[GameEvent] = Rules.apply(s, Action.play(0, Fx.give(s, 0, &"kiln_tower"), 0))
	assert_eq(s.players[0].lanes[0].land, E, "buildings reshape the lane")
	assert_eq(_events(ev, &"land_changed")[0].data["cause"], &"building", "cause building")
	return true


func test_neutral_and_spells_claim_nothing() -> bool:
	var s: GameState = Fx.blank()
	s.players[0].magic = 9
	Rules.apply(s, Action.play(0, Fx.give(s, 0, &"star_shard"), -1))
	for l: int in 4:
		assert_eq(s.players[0].lanes[l].land, W, "lane %d still Meadow" % l)
	return true


func test_level_counts_target_meadow() -> bool:
	var s: GameState = Fx.blank([E, W, F, F])
	s.players[0].magic = 9
	var i: int = Fx.give(s, 0, &"magmaw")  # Ember level 2
	assert_eq(Rules.validate(s, Action.play(0, i, 1)), "", "1 Ember lane + the Meadow it lands in")
	assert_eq(Rules.validate(s, Action.play(0, i, 2)), "Needs 2 Ember Flats lanes", "a Frostpeak lane doesn't count")
	assert_eq(Rules.validate(s, Action.play(0, i, 0)), "Needs 2 Ember Flats lanes", "its own Ember lane counts once")
	var s2: GameState = Fx.blank()
	s2.players[0].magic = 9
	assert_eq(Rules.validate(s2, Action.play(0, Fx.give(s2, 0, &"flarebeak"), 0)), "", "a level 1 opens any Meadow")
	assert_eq(Rules.validate(s2, Action.play(0, Fx.give(s2, 0, &"inferno_drake"), 0)), "Needs 3 Ember Flats lanes", "level 3 needs two claimed")
	return true


func test_home_quirks() -> bool:
	var s: GameState = Fx.blank([M, E, K, F])
	Fx.put_creature(s, 0, 1, &"flarebeak")  # 3/3 Ember
	assert_eq(Rules.effective_attack(s, 0, 1), 4, "Fired up: +1 ATK at home")
	Fx.put_creature(s, 0, 2, &"gumdrop")  # 2/4 Candy
	assert_eq(Rules.effective_max_hp(s, 0, 2), 5, "Plump: +1 HP at home")
	Fx.put_creature(s, 0, 3, &"frostfang")  # Frost
	assert_eq(Rules.damage_reduction(s, 0, 3), 1, "Ice skin")
	Fx.put_creature(s, 0, 0, &"sporeling", 1)  # 1/2 Mushroom, damaged
	s.active = 1
	Rules.apply(s, Action.end_turn(1))
	assert_eq(s.players[0].lanes[0].creature.damage, 0, "Rooted: heals 1 at the start of your turn")
	# Away from home: nothing.
	var s2: GameState = Fx.blank([F, W, W, W])
	Fx.put_creature(s2, 0, 0, &"flarebeak")
	Fx.put_creature(s2, 0, 1, &"cinderpup")
	assert_eq(Rules.effective_attack(s2, 0, 0), 3, "Ember creature on Frostpeak: no bonus")
	assert_eq(Rules.effective_attack(s2, 0, 1), 2, "on Meadow: no bonus")
	return true


func test_melt() -> bool:
	var s: GameState = Fx.blank()
	s.players[1].lanes[2].land = F
	Fx.put_creature(s, 1, 2, &"glacier_tortoise")  # 3/6 bubble
	s.players[1].lanes[2].creature.bubble = false
	s.players[0].magic = 9
	var ev: Array[GameEvent] = Rules.apply(s, Action.play(0, Fx.give(s, 0, &"fireball"), -1, [{"player": 1, "lane": 2}]))
	assert_eq(s.players[1].lanes[2].creature.damage, 4, "fireball 3 + melt 1")
	assert_eq(s.players[1].lanes[2].land, W, "Frostpeak thawed into Meadow")
	assert_eq(_events(ev, &"land_reaction")[0].data["reaction"], &"melt", "melt event")
	return true


func test_wildfire_and_caramel() -> bool:
	var s: GameState = Fx.blank()
	s.players[1].lanes[1].land = M
	for l: int in [0, 1, 2]:
		Fx.put_creature(s, 1, l, &"mossback")  # 1/5
	s.players[0].magic = 9
	Rules.apply(s, Action.play(0, Fx.give(s, 0, &"fireball"), -1, [{"player": 1, "lane": 1}]))
	assert_eq([s.players[1].lanes[0].creature.damage, s.players[1].lanes[1].creature.damage, s.players[1].lanes[2].creature.damage], [1, 3, 1], "wildfire spreads 1 to both sides")
	assert_eq(s.players[1].lanes[1].land, M, "the forest stays")
	var s2: GameState = Fx.blank()
	s2.players[1].lanes[0].land = K
	Fx.put_creature(s2, 1, 0, &"jellywobble")
	s2.players[0].magic = 9
	Rules.apply(s2, Action.play(0, Fx.give(s2, 0, &"fireball"), -1, [{"player": 1, "lane": 0}]))
	assert_true(s2.players[1].lanes[0].creature.is_frozen(), "caramel freezes")
	return true


func test_quench_bloom_sprout() -> bool:
	var s: GameState = Fx.blank()
	s.players[1].lanes[3].land = E
	Fx.put_creature(s, 1, 3, &"magmaw")
	s.players[0].magic = 9
	Rules.apply(s, Action.play(0, Fx.give(s, 0, &"cold_snap"), -1, [{"player": 1, "lane": 3}]))
	assert_eq(s.players[1].lanes[3].land, W, "quench cools Ember Flats into Meadow")
	assert_true(s.players[1].lanes[3].creature.is_frozen(), "still frozen")
	var s2: GameState = Fx.blank([M, W, W, W])
	Fx.put_creature(s2, 0, 0, &"mossback", 5)
	Fx.put_creature(s2, 0, 1, &"mossback", 4)
	s2.players[0].lanes[0].creature.hp_bonus = 5
	s2.players[0].magic = 9
	Rules.apply(s2, Action.play(0, Fx.give(s2, 0, &"rain_of_spores"), -1, [{"player": 0, "lane": 0}]))
	assert_eq(s2.players[0].lanes[0].creature.damage, 0, "bloom: heals 4 + 2")
	Rules.apply(s2, Action.play(0, Fx.give(s2, 0, &"rain_of_spores"), -1, [{"player": 0, "lane": 1}]))
	assert_eq(s2.players[0].lanes[1].land, M, "sprout: Meadow grows into Mushroom Forest")
	return true


func test_creature_abilities_dont_react() -> bool:
	var s: GameState = Fx.blank([E, W, W, W])
	s.players[1].lanes[1].land = F
	Fx.put_creature(s, 1, 1, &"mossback")
	s.players[0].magic = 9
	Rules.apply(s, Action.play(0, Fx.give(s, 0, &"blazehorn"), 1))  # on play: 2 damage to the opposing creature
	assert_eq(s.players[1].lanes[1].creature.damage, 2, "blazehorn hit")
	assert_eq(s.players[1].lanes[1].land, F, "only spells react")
	return true
