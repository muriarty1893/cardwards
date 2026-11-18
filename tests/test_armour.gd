extends TestCase
## Living board spec 7: hero armour soaks damage first; spells and creatures give it.


func test_armour_soaks_first() -> bool:
	var s: GameState = Fx.blank()
	var ev: Array[GameEvent] = []
	Rules.gain_armour(s, 1, 3, ev)
	Rules.damage_hero(s, 1, 5, ev)
	assert_eq([s.players[1].armour, s.players[1].hero_hp], [0, 23], "3 soaked, 2 to HP")
	var hd: GameEvent = ev.filter(func(e: GameEvent) -> bool: return e.type == &"hero_damaged")[0]
	assert_eq([hd.data["amount"], hd.data["armour"]], [2, 3], "event splits HP and armour")
	Rules.gain_armour(s, 1, 50, ev)
	assert_eq(s.players[1].armour, GameState.MAX_ARMOUR, "capped")
	return true


func test_fatigue_ignores_armour() -> bool:
	var s: GameState = Fx.blank()
	s.players[0].armour = 5
	var ev: Array[GameEvent] = []
	Rules.draw(s, 0, ev)
	assert_eq([s.players[0].armour, s.players[0].hero_hp], [5, 25 - GameState.FATIGUE_DAMAGE], "fatigue goes straight to HP")
	return true


func test_armour_cards() -> bool:
	var s: GameState = Fx.blank()
	s.players[0].magic = 9
	Rules.apply(s, Action.play(0, Fx.give(s, 0, &"bark_shield"), -1))
	assert_eq(s.players[0].armour, 4, "bark shield")
	Rules.apply(s, Action.play(0, Fx.give(s, 0, &"mossback"), 0))
	assert_eq(s.players[0].armour, 6, "mossback +2")
	return true


func test_attack_into_armour() -> bool:
	var s: GameState = Fx.blank()
	Fx.put_creature(s, 0, 0, &"frostfang")  # 3 ATK
	s.players[1].armour = 2
	Rules.apply(s, Action.attack(0, 0, -1))
	assert_eq([s.players[1].armour, s.players[1].hero_hp], [0, 24], "attack eats armour then HP")
	return true
