extends TestCase

const M := CardData.Land.MUSHROOM
const E := CardData.Land.EMBER
const K := CardData.Land.CANDY
const F := CardData.Land.FROST


func test_play_creature() -> bool:
	var s: GameState = Fx.blank()
	var i: int = Fx.give(s, 0, &"mossback")
	var ev: Array[GameEvent] = Rules.apply(s, Action.play(0, i, 2))
	assert_eq(s.players[0].magic, 0, "magic spent (mossback costs 2)")
	assert_true(s.players[0].lanes[2].creature != null, "creature placed")
	assert_eq(s.players[0].lanes[2].creature.card.id, &"mossback", "right creature")
	assert_eq(s.players[0].hand.size(), 0, "left hand")
	assert_true(&"creature_played" in Fx.types(ev), "creature_played event")
	return true


func test_not_enough_magic() -> bool:
	var s: GameState = Fx.blank()
	s.players[0].magic = 0
	var i: int = Fx.give(s, 0, &"mossback")
	assert_eq(Rules.validate(s, Action.play(0, i, 0)), "Not enough magic", "message")
	assert_eq(Rules.apply(s, Action.play(0, i, 0)).size(), 0, "no events")
	assert_eq(s.players[0].hand.size(), 1, "still in hand")
	return true


func test_level_requirement() -> bool:
	var s: GameState = Fx.blank([E, M, K, F])
	s.players[0].magic = 9
	var i: int = Fx.give(s, 0, &"magmaw")
	assert_eq(Rules.validate(s, Action.play(0, i, 0)), "Needs 2 Ember Flats lands", "needs 2 ember")
	var s2: GameState = Fx.blank([E, E, K, F])
	s2.players[0].magic = 9
	var j: int = Fx.give(s2, 0, &"magmaw")
	assert_eq(Rules.validate(s2, Action.play(0, j, 3)), "", "ok on a frost land with 2 ember lands")
	return true


func test_lane_occupied() -> bool:
	var s: GameState = Fx.blank()
	s.players[0].magic = 9
	Rules.apply(s, Action.play(0, Fx.give(s, 0, &"mossback"), 1))
	assert_eq(Rules.validate(s, Action.play(0, Fx.give(s, 0, &"iceling"), 1)), "Lane already has a creature", "creature taken")
	s.players[0].hand.clear()
	assert_eq(Rules.apply(s, Action.play(0, Fx.give(s, 0, &"spore_hut"), 1)).size() > 0, true, "building with creature ok")
	assert_eq(Rules.validate(s, Action.play(0, Fx.give(s, 0, &"kiln_tower"), 1)), "Lane already has a building", "building taken")
	return true


func test_spell_discarded() -> bool:
	var s: GameState = Fx.blank()
	Fx.fill_deck(s, 0, &"mossback", 5)
	var ev: Array[GameEvent] = Rules.apply(s, Action.play(0, Fx.give(s, 0, &"sugar_rush"), -1))
	assert_true(&"spell_cast" in Fx.types(ev), "spell_cast")
	assert_eq(s.players[0].discard.size(), 1, "spell in discard")
	assert_eq(s.players[0].discard[0].id, &"sugar_rush", "it is sugar rush")
	return true


func test_wrong_phase() -> bool:
	var s: GameState = Fx.blank()
	s.phase = GameState.Phase.ATTACK
	assert_eq(Rules.validate(s, Action.play(0, Fx.give(s, 0, &"mossback"), 0)), "Can't do that now", "wrong phase")
	return true


func test_no_such_card() -> bool:
	var s: GameState = Fx.blank()
	assert_eq(Rules.validate(s, Action.play(0, 3, 0)), "No such card", "bad index")
	return true
