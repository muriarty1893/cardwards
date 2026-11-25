extends TestCase
## Changed copies, legendaries, neutral cards, 40-card decks and the game history (Dark Moon spec 2.4, 3.1, 3.2).


func test_variant_keeps_id_and_changes() -> bool:
	var base: CardData = CardDB.card(&"gumdrop")
	var v: CardData = CardDB.variant(base, {"attack": 2, "health": 2})
	assert_eq(v.id, base.id, "same card id")
	assert_eq(v.attack, base.attack + 2, "+2 attack")
	assert_eq(v.health, base.health + 2, "+2 health")
	assert_eq(v.changes, {"attack": 2, "health": 2}, "records the changes")
	assert_true(base.changes.is_empty(), "the printed card is untouched")
	var w: CardData = CardDB.variant(v, {"cost": -1, "attack": 1})
	assert_eq(w.changes, {"attack": 3, "health": 2, "cost": -1}, "changes add up")
	assert_eq(w.cost, maxi(base.cost - 1, 0), "cost lowered")
	var z: CardData = CardDB.variant(base, {"cost": -20})
	assert_eq(z.cost, 0, "cost never below 0")
	var k: CardData = CardDB.variant(base, {"keywords": [&"guard"]})
	assert_true(&"guard" in k.keywords, "gains a keyword")
	assert_true(not &"guard" in base.keywords, "the printed card doesn't")
	assert_true(CardDB.is_changed(k) and not CardDB.is_changed(base), "is_changed")
	return true


func test_digest_covers_variants() -> bool:
	var s: GameState = Fx.blank()
	var t: GameState = Fx.blank()
	s.players[0].hand.append(CardDB.variant(CardDB.card(&"gumdrop"), {"attack": 1}))
	t.players[0].hand.append(CardDB.variant(CardDB.card(&"gumdrop"), {"attack": 1}))
	assert_eq(s.digest(), t.digest(), "same copies, same digest")
	t.players[0].hand[t.players[0].hand.size() - 1] = CardDB.variant(CardDB.card(&"gumdrop"), {"attack": 2})
	assert_true(s.digest() != t.digest(), "different changes, different digest")
	return true


func test_deck_rules() -> bool:
	var leg: CardData = Fx.card(&"t_legend", CardData.Kind.CREATURE, 5, 5, 5)
	leg.legendary = true
	CardDB.add_test_card(leg)
	var filler: CardData = CardDB.card(&"gumdrop")
	var cards: Array[CardData] = []
	for i: int in 28:
		cards.append(CardDB.card(CardDB.collectible_cards().filter(func(c: CardData) -> bool: return c.land != CardData.Land.NEUTRAL and not c.legendary)[i / 2].id))
	cards.append(leg)
	cards.append(leg)
	assert_true(DeckStore.validate(cards).begins_with("At most 1"), "only one copy of a legendary")
	cards[29] = filler
	assert_eq(DeckStore.validate(cards), "", "one legendary is fine")
	var neu: CardData = Fx.card(&"t_neutral", CardData.Kind.CREATURE, 2, 2, 2)
	neu.land = CardData.Land.NEUTRAL
	CardDB.add_test_card(neu)
	cards[29] = neu
	assert_eq(DeckStore.validate(cards), "", "neutral cards can go in decks")
	cards[29] = CardDB.card(&"star_shard")
	assert_true(DeckStore.validate(cards) != "", "but not Star Shard")
	cards[29] = filler
	var big: CardData = Fx.card(&"t_big40", CardData.Kind.CREATURE, 4, 4, 4)
	big.allows_40 = true
	CardDB.add_test_card(big)
	var forty: Array[CardData] = cards.duplicate()
	for i: int in 10:
		forty.append(CardDB.card(CardDB.collectible_cards().filter(func(c: CardData) -> bool: return c.land != CardData.Land.NEUTRAL and not c.legendary)[20 + i / 2].id))
	assert_true(DeckStore.validate(forty) != "", "40 cards need a 40-card enabler")
	forty[39] = big
	assert_eq(DeckStore.validate(forty), "", "40 with an enabler")
	assert_eq(DeckStore.size_for(forty), 40, "deck size 40")
	assert_eq(DeckStore.size_for(cards), 30, "else 30")
	for id: StringName in [&"t_legend", &"t_neutral", &"t_big40"]:
		CardDB.remove_test_card(id)
	return true


func test_history() -> bool:
	var s: GameState = Rules.setup(CardDB.deck(&"grove_guard"), CardDB.deck(&"blaze_rush"), 3)
	var h: Dictionary = s.players[0].history
	assert_eq(int(h["start_size"]), 30, "start size")
	assert_eq(bool(h["start_no_dupes"]), false, "starter decks have duplicates")
	assert_true(&"sporeling" in (h["start_ids"] as Array), "remembers what the deck started with")
	var b: GameState = Fx.blank()
	b.players[0].hand.append(CardDB.card(&"bark_shield"))
	b.players[0].magic = 10
	Rules.apply(b, Action.play(0, b.players[0].hand.size() - 1, -1))
	assert_eq(b.players[0].history["spells"], [&"bark_shield"] as Array[StringName], "spells played")
	Fx.put_creature(b, 1, 0, &"gumdrop")
	Rules.destroy_creature(b, 1, 0, [])
	Rules.resolve_deaths(b, [])
	assert_eq(int(b.players[1].history["deaths_own"]), 1, "owner's deaths")
	assert_eq(GameHistory.deaths_all(b), 1, "deaths this game, both sides")
	return true


func test_forty_enabler_still_allows_thirty() -> bool:
	var big: CardData = Fx.card(&"t_big40b", CardData.Kind.CREATURE, 4, 4, 4)
	big.allows_40 = true
	CardDB.add_test_card(big)
	var cards: Array[CardData] = CardDB.deck(&"grove_guard").cards.duplicate()
	cards[29] = big
	assert_eq(DeckStore.validate(cards), "", "30 cards with a 40-card enabler is fine")
	CardDB.remove_test_card(&"t_big40b")
	return true
