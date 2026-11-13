extends TestCase

const TARGETS: Array[StringName] = [&"none", &"any_creature", &"own_creature", &"own_empty_lane", &"own_two_creatures", &"discard_creature"]


func test_card_count() -> bool:
	var cards: Array[CardData] = CardDB.all_cards()
	assert_eq(cards.size(), 40, "40 cards")
	for land: int in 4:
		var n: int = 0
		for c: CardData in cards:
			if c.land == land:
				n += 1
		assert_eq(n, 10, "10 cards for land %d" % land)
	return true


func test_card_shapes() -> bool:
	for c: CardData in CardDB.all_cards():
		if c.kind == CardData.Kind.CREATURE:
			assert_true(c.level >= 1 and c.level <= 3, "%s level" % c.id)
			assert_true(c.attack >= 0 and c.health > 0, "%s stats" % c.id)
		else:
			assert_eq(c.level, 0, "%s non-creature level 0" % c.id)
		assert_true(c.cost >= 0 and c.cost <= 2, "%s cost" % c.id)
		assert_true(c.target in TARGETS, "%s target" % c.id)
		if c.trigger != &"":
			assert_true(c.ability_id != &"", "%s ability for trigger" % c.id)
	return true


func test_spot_values() -> bool:
	var e: CardData = CardDB.card(&"elder_shroomhulk")
	assert_eq([e.level, e.cost, e.attack, e.health], [3, 2, 5, 10], "elder_shroomhulk")
	assert_eq(CardDB.card(&"swap_trick").cost, 0, "swap_trick cost")
	assert_eq(CardDB.card(&"blazehorn").attack, 6, "blazehorn attack")
	return true


func test_decks() -> bool:
	var decks: Array[DeckData] = CardDB.all_decks()
	assert_eq(decks.size(), 4, "4 decks")
	for d: DeckData in decks:
		assert_eq(d.cards.size(), 30, "%s 30 cards" % d.id)
		assert_eq(d.lands.size(), 4, "%s 4 lands" % d.id)
		var main_land: int = d.lands[0]
		for c: CardData in d.cards:
			if c.land != main_land:
				assert_true(c.level <= 1, "%s splash card %s level <= 1" % [d.id, c.id])
	var br: DeckData = CardDB.deck(&"blaze_rush")
	assert_eq(br.lands, [CardData.Land.EMBER, CardData.Land.EMBER, CardData.Land.CANDY, CardData.Land.EMBER], "blaze_rush lands")
	return true
