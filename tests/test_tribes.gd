extends TestCase
## Living board spec 5: every creature has a tribe; 2 / 3+ of a tribe give its bonus; card
## steps that need "N other <tribe>".


func test_every_creature_has_a_tribe() -> bool:
	for c: CardData in CardDB.all_cards():
		if c.is_creature():
			assert_true(c.tribe in Tribes.ORDER, "%s has a tribe" % c.id)
		else:
			assert_eq(c.tribe, &"", "%s (not a creature) has none" % c.id)
	return true


func test_pack_beasts() -> bool:
	var s: GameState = Fx.blank()
	Fx.put_creature(s, 0, 0, &"snowmite")  # 1/3 beast
	assert_eq(Rules.effective_attack(s, 0, 0), 1, "one beast: no pack")
	Fx.put_creature(s, 0, 1, &"frostfang")  # 3/3 beast
	assert_eq(Rules.effective_attack(s, 0, 0), 2, "two beasts: +1")
	Fx.put_creature(s, 0, 2, &"blazehorn")
	assert_eq(Rules.effective_attack(s, 0, 0), 3, "three beasts: +2")
	Fx.put_creature(s, 0, 3, &"gumdrop")
	assert_eq(Rules.effective_attack(s, 0, 3), 2, "a blob gets nothing from the pack")
	return true


func test_squish_blobs_and_deaths() -> bool:
	var s: GameState = Fx.blank()
	Fx.put_creature(s, 0, 0, &"gumdrop", 5)  # 2/4, alive only with Squish (+2)
	Fx.put_creature(s, 0, 1, &"taffy_snail")
	assert_eq(Rules.effective_max_hp(s, 0, 0), 6, "two blobs: +2 HP")
	s.players[0].lanes[1].creature.damage = 99
	var ev: Array[GameEvent] = []
	Rules.resolve_deaths(s, ev)
	assert_true(s.players[0].lanes[0].creature == null, "losing the bonus kills the damaged blob too")
	return true


func test_flock_hits_heroes_harder() -> bool:
	var s: GameState = Fx.blank()
	Fx.put_creature(s, 0, 0, &"flarebeak")  # 3/3 flyer
	Fx.put_creature(s, 0, 1, &"ashmite")
	Rules.apply(s, Action.attack(0, 0, -1))
	assert_eq(s.players[1].hero_hp, GameState.START_HP - 4, "3 + flock 1 to the hero")
	return true


func test_grove_and_haunt() -> bool:
	var s: GameState = Fx.blank()
	Fx.put_creature(s, 0, 0, &"sporeling")
	Fx.put_creature(s, 0, 1, &"puffcap")
	Fx.put_creature(s, 0, 2, &"rootstalker")
	s.players[0].hero_hp = 10
	s.active = 1
	Rules.apply(s, Action.end_turn(1))
	assert_eq(s.players[0].hero_hp, 10 + 3 - GameState.FATIGUE_DAMAGE, "grove heals 3 with 3 sprouts (then fatigue draw)")
	var s2: GameState = Fx.blank()
	Fx.put_creature(s2, 0, 0, &"sugar_sprite")
	Fx.put_creature(s2, 0, 1, &"iceling")
	assert_eq(Rules.spell_power(s2, 0), 1, "haunt: spell power +1")
	return true


func test_need_other_tribe() -> bool:
	var s: GameState = Fx.blank()
	s.players[0].magic = 9
	Rules.apply(s, Action.play(0, Fx.give(s, 0, &"cinderpup"), 0))
	assert_eq(s.players[0].lanes[0].creature.atk_bonus, 0, "alone: no buff")
	Fx.put_creature(s, 0, 2, &"frostfang")
	Rules.apply(s, Action.play(0, Fx.give(s, 0, &"cinderpup"), 1))
	assert_eq(s.players[0].lanes[1].creature.atk_bonus, 1, "with another beast: +1/+1")
	return true
