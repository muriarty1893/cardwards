extends TestCase
## Living board spec 8: one field for both players; a new one replaces the old.

const M := CardData.Land.MUSHROOM
const E := CardData.Land.EMBER
const K := CardData.Land.CANDY
const F := CardData.Land.FROST
const W := Lands.MEADOW


func _play_field(s: GameState, p: int, id: StringName) -> Array[GameEvent]:
	s.active = p
	s.players[p].magic = 9
	return Rules.apply(s, Action.play(p, Fx.give(s, p, id), -1))


func test_field_replaces_old() -> bool:
	var s: GameState = Fx.blank()
	var ev: Array[GameEvent] = _play_field(s, 0, &"volcano")
	assert_eq(s.field.id, &"volcano", "volcano in play")
	assert_true(not CardDB.card(&"volcano") in s.players[0].discard, "a field isn't discarded while in play")
	assert_true(&"field_set" in Fx.types(ev), "field_set event")
	_play_field(s, 1, &"snowstorm")
	assert_eq([s.field.id, s.field_owner], [&"snowstorm", 1], "snowstorm replaces it")
	assert_true(CardDB.card(&"volcano") in s.players[0].discard, "the old field goes to its owner's discard")
	return true


func test_volcano() -> bool:
	var s: GameState = Fx.blank([E, F, W, W], [W, W, W, W])
	Fx.put_creature(s, 0, 0, &"ashmite")  # 2/2 flyer at home: 3
	Fx.put_creature(s, 0, 1, &"snowmite")  # 1/3 frost
	_play_field(s, 0, &"volcano")
	assert_eq(Rules.effective_attack(s, 0, 0), 4, "Ember Flats +1 on top of home")
	Rules.apply(s, Action.end_turn(0))
	assert_eq(s.players[0].lanes[1].creature.damage, 1, "end of turn: 1 to the active player's creatures on Frostpeak")
	assert_eq(s.players[0].lanes[1].land, F, "no melt from the field")
	return true


func test_snowstorm() -> bool:
	var s: GameState = Fx.blank([E, F, W, W])
	Fx.put_creature(s, 0, 0, &"flarebeak")  # 3 at home: 4
	Fx.put_creature(s, 0, 1, &"frostfang")  # 3, frost
	Fx.put_creature(s, 0, 2, &"gumdrop")  # 2, meadow
	_play_field(s, 1, &"snowstorm")
	assert_eq(Rules.effective_attack(s, 0, 0), 2, "no Fired up, and −1 off Frostpeak")
	assert_eq(Rules.effective_attack(s, 0, 1), 3, "Frostpeak creature unharmed")
	assert_eq(Rules.effective_attack(s, 0, 2), 1, "Meadow −1")
	return true


func test_spore_bloom_and_sugar_rain() -> bool:
	var s: GameState = Fx.blank([E, W, W, W], [W, W, W, W])
	_play_field(s, 0, &"spore_bloom")
	s.active = 1
	Rules.apply(s, Action.end_turn(1))  # p0's turn starts
	assert_eq(s.players[0].lanes[1].land, M, "p0's first Meadow lane sprouts")
	var s2: GameState = Fx.blank([K, W, W, W])
	Fx.put_creature(s2, 0, 0, &"gumdrop")
	Fx.fill_deck(s2, 0, &"gumdrop", 3)
	_play_field(s2, 0, &"sugar_rain")
	var hand: int = s2.players[0].hand.size()
	s2.active = 1
	Rules.apply(s2, Action.end_turn(1))
	assert_eq(s2.players[0].hand.size(), hand + 2, "normal draw + sugar rain")
	return true


func test_field_survives_clone() -> bool:
	var s: GameState = Fx.blank()
	_play_field(s, 0, &"volcano")
	var c: GameState = s.clone()
	assert_eq([c.field, c.field_owner], [s.field, s.field_owner], "clone keeps the field")
	return true
